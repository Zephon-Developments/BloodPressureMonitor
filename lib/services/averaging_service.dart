import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing reading group averages using a 30-minute rolling window.
///
/// This service automatically groups blood pressure readings taken within 30
/// minutes of each other and calculates average values. Readings are grouped
/// based on the timestamp of the first reading in the group.
///
/// Example:
/// ```dart
/// final service = AveragingService();
/// await service.createOrUpdateGroupsForReading(newReading);
/// ```
class AveragingService {
  final DatabaseService _databaseService;
  final ReadingService _readingService;

  /// Creates an AveragingService with optional dependency injection.
  ///
  /// Parameters:
  /// - [databaseService]: Optional database service for testing
  /// - [readingService]: Optional reading service for testing
  AveragingService({
    DatabaseService? databaseService,
    ReadingService? readingService,
  })  : _databaseService = databaseService ?? DatabaseService(),
        _readingService = readingService ?? ReadingService();

  /// Creates or updates reading groups after a new reading is added.
  ///
  /// This method finds all readings within a 30-minute window of the new
  /// reading and groups them together. If the reading falls within an
  /// existing group's window, it joins that group. Otherwise, a new group
  /// is created.
  ///
  /// Parameters:
  /// - [reading]: The newly added reading to process for grouping
  ///
  /// Throws [StateError] if the reading has no ID (must be persisted first).
  Future<void> createOrUpdateGroupsForReading(Reading reading) async {
    if (reading.id == null) {
      throw StateError(
        'Reading must be persisted (have an ID) before grouping',
      );
    }

    // Get all readings within a 60-minute window (±30 minutes)
    final startTime = reading.takenAt.subtract(const Duration(minutes: 30));
    final endTime = reading.takenAt.add(const Duration(minutes: 30));

    final nearbyReadings = await _readingService.getReadingsInTimeRange(
      reading.profileId,
      startTime,
      endTime,
    );

    // Group readings by session ID or rolling 30-minute window
    final groups = _buildGroups(nearbyReadings);

    // Persist all groups
    await _persistGroups(reading.profileId, groups);
  }

  /// Recomputes all reading groups for a profile.
  ///
  /// This is useful when readings have been updated or deleted and the
  /// entire grouping needs to be recalculated. This method fetches all
  /// readings for the profile and rebuilds all groups from scratch.
  ///
  /// Parameters:
  /// - [profileId]: The profile whose readings should be regrouped
  Future<void> recomputeGroupsForProfile(int profileId) async {
    // Delete all existing groups for this profile
    final db = await _databaseService.database;
    await db.delete(
      'ReadingGroup',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );

    // Get all readings for the profile
    final allReadings = await _readingService.getReadingsByProfile(profileId);

    if (allReadings.isEmpty) return;

    // Sort by time ascending
    allReadings.sort((a, b) => a.takenAt.compareTo(b.takenAt));

    // Build groups
    final groups = _buildGroups(allReadings);

    // Persist groups
    await _persistGroups(profileId, groups);
  }

  /// Deletes reading groups that contain the specified reading.
  ///
  /// This should be called before deleting a reading to clean up any
  /// groups that would become invalid. After deletion, call
  /// [recomputeGroupsForProfile] to rebuild groups if needed.
  ///
  /// Parameters:
  /// - [readingId]: The ID of the reading being deleted
  Future<void> deleteGroupsForReading(int readingId) async {
    final db = await _databaseService.database;

    // Find groups containing this reading (use comma delimiters for exact match)
    final groups = await db.query(
      'ReadingGroup',
      where: "',' || memberReadingIds || ',' LIKE ?",
      whereArgs: ['%,$readingId,%'],
    );

    // Delete each group that contains this reading
    for (final group in groups) {
      await db.delete(
        'ReadingGroup',
        where: 'id = ?',
        whereArgs: [group['id']],
      );
    }
  }

  /// Builds reading groups using a 30-minute rolling window algorithm.
  ///
  /// Readings are grouped if they occur within 30 minutes of the first
  /// reading in the group. Manual session IDs force new groups even if
  /// within the time window.
  ///
  /// Parameters:
  /// - [readings]: List of readings to group (should be sorted by time)
  ///
  /// Returns: List of reading groups
  List<ReadingGroup> _buildGroups(List<Reading> readings) {
    if (readings.isEmpty) return [];

    // Sort by time ascending to process chronologically
    final sortedReadings = List<Reading>.from(readings)
      ..sort((a, b) => a.takenAt.compareTo(b.takenAt));

    final groups = <ReadingGroup>[];
    List<Reading> currentGroupReadings = [];
    DateTime? currentGroupStart;
    String? currentSessionId;

    for (final reading in sortedReadings) {
      final shouldStartNewGroup = currentGroupReadings.isEmpty ||
          reading.takenAt.difference(currentGroupStart!).inMinutes > 30 ||
          (reading.medsContext != null &&
              reading.medsContext != currentSessionId);

      if (shouldStartNewGroup) {
        // Save the current group if it exists
        if (currentGroupReadings.isNotEmpty) {
          groups.add(_createGroupFromReadings(currentGroupReadings));
        }

        // Start a new group
        currentGroupReadings = [reading];
        currentGroupStart = reading.takenAt;
        currentSessionId = reading.medsContext;
      } else {
        // Add to current group
        currentGroupReadings.add(reading);
      }
    }

    // Save the final group
    if (currentGroupReadings.isNotEmpty) {
      groups.add(_createGroupFromReadings(currentGroupReadings));
    }

    return groups;
  }

  /// Creates a ReadingGroup from a list of readings.
  ///
  /// Calculates average values for systolic, diastolic, and pulse, and
  /// builds a comma-separated list of member reading IDs.
  ///
  /// Parameters:
  /// - [readings]: List of readings to include in the group
  ///
  /// Returns: A new ReadingGroup with calculated averages
  ReadingGroup _createGroupFromReadings(List<Reading> readings) {
    if (readings.isEmpty) {
      throw ArgumentError('Cannot create group from empty readings list');
    }

    final avgSystolic =
        readings.map((r) => r.systolic).reduce((a, b) => a + b) /
            readings.length;
    final avgDiastolic =
        readings.map((r) => r.diastolic).reduce((a, b) => a + b) /
            readings.length;
    final avgPulse =
        readings.map((r) => r.pulse).reduce((a, b) => a + b) / readings.length;

    final memberIds = readings.map((r) => r.id.toString()).join(',');
    final sessionId = readings.first.medsContext;

    return ReadingGroup(
      profileId: readings.first.profileId,
      groupStartAt: readings.first.takenAt,
      windowMinutes: 30,
      avgSystolic: avgSystolic,
      avgDiastolic: avgDiastolic,
      avgPulse: avgPulse,
      memberReadingIds: memberIds,
      sessionId: sessionId,
    );
  }

  /// Persists reading groups to the database.
  ///
  /// Only deletes and replaces groups that overlap with the time range
  /// of the provided groups, preserving all other historical groups.
  ///
  /// Parameters:
  /// - [profileId]: The profile these groups belong to
  /// - [groups]: List of groups to persist
  Future<void> _persistGroups(int profileId, List<ReadingGroup> groups) async {
    if (groups.isEmpty) return;

    final db = await _databaseService.database;

    // Calculate the time range covered by the new groups
    final earliestTime = groups
        .map((g) => g.groupStartAt)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final latestTime = groups
        .map((g) => g.groupStartAt)
        .reduce((a, b) => a.isAfter(b) ? a : b)
        .add(const Duration(minutes: 30));

    // Use a transaction for atomic updates
    await db.transaction((txn) async {
      // Delete only groups that overlap with the time range being processed
      await txn.delete(
        'ReadingGroup',
        where: 'profileId = ? AND groupStartAt >= ? AND groupStartAt <= ?',
        whereArgs: [
          profileId,
          earliestTime.toIso8601String(),
          latestTime.toIso8601String(),
        ],
      );

      // Insert new groups
      for (final group in groups) {
        await txn.insert(
          'ReadingGroup',
          group.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}

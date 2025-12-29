import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing sleep entry CRUD operations.
///
/// Provides database operations for sleep entries with validation and
/// import support.
class SleepService {
  final DatabaseService _databaseService;

  /// Creates a [SleepService] with the given database service.
  SleepService(this._databaseService);

  /// Creates a new sleep entry in the database.
  ///
  /// Validates the sleep duration, quality, and times before insertion.
  ///
  /// Returns the created sleep entry with its assigned ID.
  ///
  /// Throws [ArgumentError] if validation fails.
  Future<SleepEntry> createSleepEntry(SleepEntry entry) async {
    // Validate sleep duration
    final durationValidation = validateSleepDuration(entry.durationMinutes);
    if (durationValidation.level == ValidationLevel.error) {
      throw ArgumentError(durationValidation.message);
    }

    // Validate sleep quality
    final qualityValidation = validateSleepQuality(entry.quality);
    if (qualityValidation.level == ValidationLevel.error) {
      throw ArgumentError(qualityValidation.message);
    }

    // Validate sleep times
    final timesValidation = validateSleepTimes(entry.startedAt, entry.endedAt);
    if (timesValidation.level == ValidationLevel.error) {
      throw ArgumentError(timesValidation.message);
    }

    final db = await _databaseService.database;
    final id = await db.insert(
      'SleepEntry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return entry.copyWith(id: id);
  }

  /// Retrieves a sleep entry by its ID.
  ///
  /// Returns the sleep entry if found, null otherwise.
  Future<SleepEntry?> getSleepEntry(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'SleepEntry',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return SleepEntry.fromMap(results.first);
  }

  /// Lists sleep entries for a profile within an optional date range.
  ///
  /// Parameters:
  /// - [profileId]: Profile ID to filter by
  /// - [from]: Optional start date (inclusive, based on endedAt or startedAt)
  /// - [to]: Optional end date (inclusive, based on endedAt or startedAt)
  ///
  /// Returns entries ordered by endedAt/startedAt descending (most recent first).
  Future<List<SleepEntry>> listSleepEntries({
    required int profileId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _databaseService.database;

    String where = 'profileId = ?';
    final List<Object?> whereArgs = [profileId];

    if (from != null) {
      where += ' AND (endedAt >= ? OR (endedAt IS NULL AND startedAt >= ?))';
      whereArgs.add(from.toIso8601String());
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      where += ' AND (endedAt <= ? OR (endedAt IS NULL AND startedAt <= ?))';
      whereArgs.add(to.toIso8601String());
      whereArgs.add(to.toIso8601String());
    }

    final results = await db.query(
      'SleepEntry',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'COALESCE(endedAt, startedAt) DESC',
    );

    return results.map((map) => SleepEntry.fromMap(map)).toList();
  }

  /// Updates an existing sleep entry.
  ///
  /// Validates the sleep duration, quality, and times before update.
  ///
  /// Returns the updated entry.
  ///
  /// Throws [ArgumentError] if validation fails or entry doesn't exist.
  Future<SleepEntry> updateSleepEntry(SleepEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('Cannot update sleep entry without an ID');
    }

    // Validate sleep duration
    final durationValidation = validateSleepDuration(entry.durationMinutes);
    if (durationValidation.level == ValidationLevel.error) {
      throw ArgumentError(durationValidation.message);
    }

    // Validate sleep quality
    final qualityValidation = validateSleepQuality(entry.quality);
    if (qualityValidation.level == ValidationLevel.error) {
      throw ArgumentError(qualityValidation.message);
    }

    // Validate sleep times
    final timesValidation = validateSleepTimes(entry.startedAt, entry.endedAt);
    if (timesValidation.level == ValidationLevel.error) {
      throw ArgumentError(timesValidation.message);
    }

    final db = await _databaseService.database;
    final count = await db.update(
      'SleepEntry',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    if (count == 0) {
      throw ArgumentError('Sleep entry with ID ${entry.id} not found');
    }

    return entry;
  }

  /// Deletes a sleep entry by ID.
  ///
  /// Returns `true` if an entry was deleted, `false` otherwise.
  Future<bool> deleteSleepEntry(int id) async {
    final db = await _databaseService.database;
    final count = await db.delete(
      'SleepEntry',
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  /// Finds the most recent sleep entry that ended before a morning reading.
  ///
  /// Searches for sleep entries that ended within the specified lookback window
  /// before the reading time (default 18 hours). Returns the sleep session with
  /// the latest endedAt time.
  ///
  /// Parameters:
  /// - [profileId]: Profile ID to search within
  /// - [readingTime]: The blood pressure reading time
  /// - [lookbackHours]: Hours to look back for sleep data (default: 18)
  ///
  /// Returns the most recent sleep entry that ended before the reading, or null.
  Future<SleepEntry?> findSleepForMorningReading({
    required int profileId,
    required DateTime readingTime,
    int lookbackHours = 18,
  }) async {
    final searchFrom = readingTime.subtract(Duration(hours: lookbackHours));

    final db = await _databaseService.database;
    final results = await db.query(
      'SleepEntry',
      where: '''
        profileId = ? 
        AND endedAt IS NOT NULL 
        AND endedAt < ? 
        AND endedAt >= ?
      ''',
      whereArgs: [
        profileId,
        readingTime.toIso8601String(),
        searchFrom.toIso8601String(),
      ],
      orderBy: 'endedAt DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return SleepEntry.fromMap(results.first);
  }

  /// Checks for potential duplicate sleep entries.
  ///
  /// Searches for entries with the same profileId, startedAt, source, and
  /// optionally sourceMetadata to prevent duplicate imports.
  ///
  /// Returns true if a duplicate is found.
  Future<bool> isDuplicate({
    required int profileId,
    required DateTime startedAt,
    required SleepSource source,
    String? sourceMetadata,
  }) async {
    final db = await _databaseService.database;

    String where = 'profileId = ? AND startedAt = ? AND source = ?';
    final List<Object?> whereArgs = [
      profileId,
      startedAt.toIso8601String(),
      source.toDbString(),
    ];

    if (sourceMetadata != null) {
      where += ' AND sourceMetadata = ?';
      whereArgs.add(sourceMetadata);
    }

    final results = await db.query(
      'SleepEntry',
      where: where,
      whereArgs: whereArgs,
      limit: 1,
    );

    return results.isNotEmpty;
  }
}

import 'dart:convert';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing medication intake logging.
///
/// Provides single and group intake logging with atomic transactions,
/// and late/missed status calculation based on schedule metadata.
class MedicationIntakeService {
  final DatabaseService _databaseService;

  /// Creates a [MedicationIntakeService] with the given database service.
  MedicationIntakeService(this._databaseService);

  /// Logs a single medication intake.
  ///
  /// Returns the created intake with its assigned ID.
  Future<MedicationIntake> logIntake(MedicationIntake intake) async {
    final db = await _databaseService.database;
    final id = await db.insert(
      'MedicationIntake',
      intake.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return intake.copyWith(id: id);
  }

  /// Logs multiple medications as a group intake atomically.
  ///
  /// Uses a database transaction to ensure all intakes are logged together.
  /// If any insert fails, the entire operation is rolled back.
  ///
  /// Parameters:
  /// - [groupId]: Optional ID of the medication group being logged
  /// - [medicationIds]: List of medication IDs to log intakes for
  /// - [profileId]: Profile ID for all intakes
  /// - [takenAt]: Timestamp when medications were taken
  /// - [scheduledFor]: Optional scheduled time for all intakes
  /// - [note]: Optional note to attach to all intakes
  ///
  /// Returns list of created intakes with assigned IDs.
  ///
  /// Throws [ArgumentError] if medicationIds is empty.
  Future<List<MedicationIntake>> logGroupIntake({
    int? groupId,
    required List<int> medicationIds,
    required int profileId,
    required DateTime takenAt,
    DateTime? scheduledFor,
    String? note,
  }) async {
    if (medicationIds.isEmpty) {
      throw ArgumentError('Cannot log group intake with no medications');
    }

    final db = await _databaseService.database;
    final intakes = <MedicationIntake>[];

    await db.transaction((txn) async {
      for (final medId in medicationIds) {
        final intake = MedicationIntake(
          medicationId: medId,
          profileId: profileId,
          takenAt: takenAt,
          scheduledFor: scheduledFor,
          groupId: groupId,
          note: note,
        );

        final id = await txn.insert(
          'MedicationIntake',
          intake.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        intakes.add(intake.copyWith(id: id));
      }
    });

    return intakes;
  }

  /// Retrieves a medication intake by ID.
  ///
  /// Returns `null` if no intake with the given ID exists.
  Future<MedicationIntake?> getIntake(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'MedicationIntake',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MedicationIntake.fromMap(results.first);
  }

  /// Lists medication intakes with optional filters.
  ///
  /// Parameters:
  /// - [profileId]: Filter by profile ID
  /// - [from]: Optional start date/time filter
  /// - [to]: Optional end date/time filter
  /// - [medicationId]: Optional filter by specific medication
  /// - [groupId]: Optional filter by intake group
  ///
  /// Returns intakes ordered by takenAt descending (newest first).
  Future<List<MedicationIntake>> listIntakes({
    required int profileId,
    DateTime? from,
    DateTime? to,
    int? medicationId,
    int? groupId,
  }) async {
    final db = await _databaseService.database;

    final where = <String>['profileId = ?'];
    final whereArgs = <Object>[profileId];

    if (from != null) {
      where.add('takenAt >= ?');
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      where.add('takenAt <= ?');
      whereArgs.add(to.toIso8601String());
    }

    if (medicationId != null) {
      where.add('medicationId = ?');
      whereArgs.add(medicationId);
    }

    if (groupId != null) {
      where.add('groupId = ?');
      whereArgs.add(groupId);
    }

    final results = await db.query(
      'MedicationIntake',
      where: where.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'takenAt DESC',
    );

    return results.map((map) => MedicationIntake.fromMap(map)).toList();
  }

  /// Finds medication intakes within a time window around an anchor time.
  ///
  /// Useful for correlating intakes with blood pressure readings.
  ///
  /// Parameters:
  /// - [profileId]: Profile ID to search within
  /// - [anchor]: Center point of the time window
  /// - [window]: Duration before and after anchor to include (default: 30 minutes)
  ///
  /// Returns intakes ordered by proximity to anchor time.
  Future<List<MedicationIntake>> findIntakesAround({
    required int profileId,
    required DateTime anchor,
    Duration window = const Duration(minutes: 30),
  }) async {
    final from = anchor.subtract(window);
    final to = anchor.add(window);

    return listIntakes(profileId: profileId, from: from, to: to);
  }

  /// Retrieves multiple intakes by their IDs.
  ///
  /// Useful for resolving intake references from blood pressure readings.
  ///
  /// Returns intakes in the same order as the input IDs.
  /// Missing intakes are omitted from the result.
  Future<List<MedicationIntake>> intakesByIds(List<int> ids) async {
    if (ids.isEmpty) return [];

    final db = await _databaseService.database;
    final placeholders = List.filled(ids.length, '?').join(',');

    final results = await db.query(
      'MedicationIntake',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    final intakeMap = {
      for (final result in results)
        result['id'] as int: MedicationIntake.fromMap(result),
    };

    return ids
        .map((id) => intakeMap[id])
        .whereType<MedicationIntake>()
        .toList();
  }

  /// Calculates the intake status relative to the schedule.
  ///
  /// Parses the medication's schedule metadata and compares the intake time
  /// to the scheduled time using the configured grace windows.
  ///
  /// Parameters:
  /// - [intake]: The intake to evaluate
  /// - [scheduleMetadata]: JSON schedule metadata from medication
  ///
  /// Returns the calculated [IntakeStatus].
  IntakeStatus calculateStatus({
    required MedicationIntake intake,
    String? scheduleMetadata,
  }) {
    // No schedule or scheduled time means unscheduled
    if (scheduleMetadata == null || intake.scheduledFor == null) {
      return IntakeStatus.unscheduled;
    }

    try {
      final schedule = jsonDecode(scheduleMetadata) as Map<String, dynamic>;
      final graceMinutesLate = schedule['graceMinutesLate'] as int? ?? 15;
      final graceMinutesMissed = schedule['graceMinutesMissed'] as int? ?? 60;

      final difference =
          intake.takenAt.difference(intake.scheduledFor!).inMinutes;

      // On time if within late grace window (could be early or slightly late)
      if (difference.abs() <= graceMinutesLate) {
        return IntakeStatus.onTime;
      }

      // Late if after scheduled but within missed window
      if (difference > graceMinutesLate && difference <= graceMinutesMissed) {
        return IntakeStatus.late;
      }

      // Missed if beyond the missed window
      if (difference > graceMinutesMissed) {
        return IntakeStatus.missed;
      }

      // If taken very early (before grace window), consider on time
      return IntakeStatus.onTime;
    } catch (e) {
      // If schedule parsing fails, treat as unscheduled
      return IntakeStatus.unscheduled;
    }
  }

  /// Deletes a medication intake by ID.
  ///
  /// Returns `true` if an intake was deleted, `false` otherwise.
  Future<bool> deleteIntake(int id) async {
    final db = await _databaseService.database;
    final count = await db.delete(
      'MedicationIntake',
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  /// Deletes all medication intakes for a profile.
  ///
  /// Returns the number of deleted rows.
  Future<int> deleteAllByProfile(int profileId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'MedicationIntake',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
  }
}

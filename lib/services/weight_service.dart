import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing weight entry CRUD operations.
///
/// Provides database operations for weight entries with validation and
/// unit conversion support.
class WeightService {
  final DatabaseService _databaseService;

  /// Creates a [WeightService] with the given database service.
  WeightService(this._databaseService);

  /// Creates a new weight entry in the database.
  ///
  /// Validates the weight value and unit before insertion.
  ///
  /// Returns the created weight entry with its assigned ID.
  ///
  /// Throws [ArgumentError] if validation fails.
  Future<WeightEntry> createWeightEntry(WeightEntry entry) async {
    // Validate weight value and unit
    final weightValidation =
        validateWeight(entry.weightValue, entry.unit.toDbString());
    if (weightValidation.level == ValidationLevel.error) {
      throw ArgumentError(weightValidation.message);
    }

    final db = await _databaseService.database;
    final id = await db.insert(
      'WeightEntry',
      entry.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return entry.copyWith(id: id);
  }

  /// Retrieves a weight entry by its ID.
  ///
  /// Returns the weight entry if found, null otherwise.
  Future<WeightEntry?> getWeightEntry(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'WeightEntry',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) return null;
    return WeightEntry.fromMap(results.first);
  }

  /// Lists weight entries for a profile within an optional date range.
  ///
  /// Parameters:
  /// - [profileId]: Profile ID to filter by
  /// - [from]: Optional start date (inclusive)
  /// - [to]: Optional end date (inclusive)
  ///
  /// Returns entries ordered by takenAt descending (most recent first).
  Future<List<WeightEntry>> listWeightEntries({
    required int profileId,
    DateTime? from,
    DateTime? to,
  }) async {
    final db = await _databaseService.database;

    String where = 'profileId = ?';
    final List<Object?> whereArgs = [profileId];

    if (from != null) {
      where += ' AND takenAt >= ?';
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      where += ' AND takenAt <= ?';
      whereArgs.add(to.toIso8601String());
    }

    final results = await db.query(
      'WeightEntry',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'takenAt DESC',
    );

    return results.map((map) => WeightEntry.fromMap(map)).toList();
  }

  /// Retrieves the most recent weight entry for a profile.
  ///
  /// Returns the latest entry if found, null otherwise.
  Future<WeightEntry?> getLatestWeightEntry(int profileId) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'WeightEntry',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'takenAt DESC',
      limit: 1,
    );

    if (results.isEmpty) return null;
    return WeightEntry.fromMap(results.first);
  }

  /// Updates an existing weight entry.
  ///
  /// Validates the weight value and unit before update.
  ///
  /// Returns the updated entry.
  ///
  /// Throws [ArgumentError] if validation fails or entry doesn't exist.
  Future<WeightEntry> updateWeightEntry(WeightEntry entry) async {
    if (entry.id == null) {
      throw ArgumentError('Cannot update weight entry without an ID');
    }

    // Validate weight value and unit
    final weightValidation =
        validateWeight(entry.weightValue, entry.unit.toDbString());
    if (weightValidation.level == ValidationLevel.error) {
      throw ArgumentError(weightValidation.message);
    }

    final db = await _databaseService.database;
    final count = await db.update(
      'WeightEntry',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );

    if (count == 0) {
      throw ArgumentError('Weight entry with ID ${entry.id} not found');
    }

    return entry;
  }

  /// Deletes all weight entries for a profile.
  ///
  /// Returns the number of deleted rows.
  Future<int> deleteAllByProfile(int profileId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'WeightEntry',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
  }

  /// Deletes a weight entry by ID.
  ///
  /// Returns `true` if an entry was deleted, `false` otherwise.
  Future<bool> deleteWeightEntry(int id) async {
    final db = await _databaseService.database;
    final count = await db.delete(
      'WeightEntry',
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  /// Finds the nearest weight entry for a reading time.
  ///
  /// Searches for weight entries within the same day and within the
  /// specified time window (default 1 hour).
  ///
  /// Parameters:
  /// - [profileId]: Profile ID to search within
  /// - [readingTime]: The blood pressure reading time
  /// - [window]: Time window to search (default: 1 hour)
  ///
  /// Returns the nearest weight entry within the window, or null if none found.
  Future<WeightEntry?> findWeightForReading({
    required int profileId,
    required DateTime readingTime,
    Duration window = const Duration(hours: 1),
  }) async {
    final startOfDay = DateTime(
      readingTime.year,
      readingTime.month,
      readingTime.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final from = readingTime.subtract(window);
    final to = readingTime.add(window);

    // Ensure we only search within the same day
    final searchFrom = from.isBefore(startOfDay) ? startOfDay : from;
    final searchTo = to.isAfter(endOfDay) ? endOfDay : to;

    final db = await _databaseService.database;
    final results = await db.query(
      'WeightEntry',
      where: 'profileId = ? AND takenAt >= ? AND takenAt <= ?',
      whereArgs: [
        profileId,
        searchFrom.toIso8601String(),
        searchTo.toIso8601String(),
      ],
      orderBy: 'takenAt DESC',
    );

    if (results.isEmpty) return null;

    // Find the nearest entry by time difference
    final entries = results.map((map) => WeightEntry.fromMap(map)).toList();
    entries.sort((a, b) {
      final aDiff = a.takenAt.difference(readingTime).abs();
      final bDiff = b.takenAt.difference(readingTime).abs();
      return aDiff.compareTo(bDiff);
    });

    return entries.first;
  }
}

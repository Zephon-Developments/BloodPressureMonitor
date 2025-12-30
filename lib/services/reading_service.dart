import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';

/// Service for managing blood pressure readings in encrypted local storage.
///
/// Provides CRUD operations for Reading entities with support for filtering
/// by profile and time ranges. Readings are used by the averaging engine to
/// generate ReadingGroup analytics.
class ReadingService {
  final DatabaseService _databaseService;

  /// Creates a ReadingService with optional dependency injection.
  ///
  /// Parameters:
  /// - [databaseService]: Optional database service for testing
  ReadingService({DatabaseService? databaseService})
      : _databaseService = databaseService ?? DatabaseService();

  /// Creates a new reading in the database.
  ///
  /// The [reading] should not have an id (or id should be null), as the
  /// database will auto-generate one. Returns the id of the newly created
  /// reading.
  ///
  /// Throws [DatabaseException] if the insert fails.
  Future<int> createReading(Reading reading) async {
    final db = await _databaseService.database;
    return await db.insert(
      'Reading',
      reading.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Retrieves a reading by its unique id.
  ///
  /// Returns the [Reading] if found, or `null` if no reading with the
  /// given [id] exists.
  Future<Reading?> getReading(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Reading',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Reading.fromMap(maps.first);
  }

  /// Retrieves all readings for a specific profile.
  ///
  /// Returns readings ordered by [takenAt] descending (newest first).
  /// Returns an empty list if no readings exist for the profile.
  ///
  /// Parameters:
  /// - [profileId]: The profile to fetch readings for
  /// - [limit]: Optional maximum number of readings to return
  Future<List<Reading>> getReadingsByProfile(
    int profileId, {
    int? limit,
  }) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Reading',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'takenAt DESC',
      limit: limit,
    );

    return maps.map((map) => Reading.fromMap(map)).toList();
  }

  /// Retrieves readings within a time range for a profile.
  ///
  /// Useful for 30-minute averaging windows and time-based analytics.
  /// Returns readings ordered by [takenAt] ascending (oldest first) to
  /// support chronological processing.
  ///
  /// Parameters:
  /// - [profileId]: The profile to fetch readings for
  /// - [startTime]: Inclusive start of time range (ISO 8601)
  /// - [endTime]: Inclusive end of time range (ISO 8601)
  Future<List<Reading>> getReadingsInTimeRange(
    int profileId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Reading',
      where: 'profileId = ? AND takenAt >= ? AND takenAt <= ?',
      whereArgs: [
        profileId,
        startTime.toIso8601String(),
        endTime.toIso8601String(),
      ],
      orderBy: 'takenAt ASC',
    );

    return maps.map((map) => Reading.fromMap(map)).toList();
  }

  /// Retrieves the most recent reading for a profile.
  ///
  /// Returns `null` if the profile has no readings. Useful for dashboard
  /// displays and determining if grouping should occur.
  Future<Reading?> getLatestReading(int profileId) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Reading',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'takenAt DESC',
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Reading.fromMap(maps.first);
  }

  /// Updates an existing reading.
  ///
  /// The [reading] must have a valid id. Returns the number of rows affected
  /// (should be 1 on success, 0 if reading not found).
  ///
  /// **Note**: Updating readings may affect pre-computed ReadingGroup averages.
  /// Consider triggering re-grouping after updates.
  ///
  /// Throws [DatabaseException] if the update fails.
  Future<int> updateReading(Reading reading) async {
    final db = await _databaseService.database;
    return await db.update(
      'Reading',
      reading.toMap(),
      where: 'id = ?',
      whereArgs: [reading.id],
    );
  }

  /// Deletes a reading by id.
  ///
  /// Returns the number of rows deleted (1 on success, 0 if reading not found).
  ///
  /// **Note**: Deleting readings may affect pre-computed ReadingGroup averages.
  /// Consider triggering re-grouping after deletions.
  Future<int> deleteReading(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Reading',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Deletes all readings for the provided profile.
  ///
  /// Returns the number of rows removed. Used for destructive bulk
  /// operations such as import overwrite flows.
  Future<int> deleteAllByProfile(int profileId) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Reading',
      where: 'profileId = ?',
      whereArgs: [profileId],
    );
  }

  /// Counts the total number of readings for a profile.
  ///
  /// Useful for analytics and determining if enough data exists for trends.
  Future<int> getReadingCount(int profileId) async {
    final db = await _databaseService.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM Reading WHERE profileId = ?',
      [profileId],
    );
    return result.first['count'] as int;
  }

  /// Retrieves all readings with a specific tag.
  ///
  /// Returns readings ordered by [takenAt] descending. The [tag] parameter
  /// is case-sensitive and must match exactly (no partial matching).
  ///
  /// **Note**: Tags are stored as comma-separated strings. This performs
  /// a LIKE query which may be slower on large datasets.
  Future<List<Reading>> getReadingsByTag(int profileId, String tag) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Reading',
      where: 'profileId = ? AND tags LIKE ?',
      whereArgs: [profileId, '%$tag%'],
      orderBy: 'takenAt DESC',
    );

    // Filter out false positives from LIKE query (e.g., "stress" matching "stressed")
    return maps
        .map((map) => Reading.fromMap(map))
        .where(
          (reading) =>
              reading.tags?.split(',').map((t) => t.trim()).contains(tag) ??
              false,
        )
        .toList();
  }

  /// Retrieves averaged reading groups within a date range.
  ///
  /// Returns groups ordered by [groupStartAt] ascending to support chart
  /// rendering in chronological order.
  Future<List<ReadingGroup>> getGroupsInRange({
    required int profileId,
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await _databaseService.database;
    final rows = await db.query(
      'ReadingGroup',
      where: 'profileId = ? AND groupStartAt >= ? AND groupStartAt <= ?',
      whereArgs: [
        profileId,
        start.toIso8601String(),
        end.toIso8601String(),
      ],
      orderBy: 'groupStartAt ASC',
    );

    return rows.map(ReadingGroup.fromMap).toList();
  }

  /// Retrieves readings whose ids are contained in [ids].
  ///
  /// Returns results without guaranteeing order, so callers should sort
  /// when a specific order is required. An empty list of ids returns an
  /// empty list.
  Future<List<Reading>> getReadingsByIds(List<int> ids) async {
    if (ids.isEmpty) {
      return <Reading>[];
    }

    final db = await _databaseService.database;
    final placeholders = List<String>.filled(ids.length, '?').join(',');
    final rows = await db.query(
      'Reading',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    return rows.map(Reading.fromMap).toList();
  }
}

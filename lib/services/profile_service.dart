import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';

/// Service for managing user profiles in encrypted local storage.
///
/// Provides CRUD operations for Profile entities with proper error handling
/// and type-safe database queries. All operations return Future to support
/// async database access patterns.
class ProfileService {
  final DatabaseService _databaseService = DatabaseService();

  /// Creates a new profile in the database.
  ///
  /// The [profile] should not have an id (or id should be null), as the
  /// database will auto-generate one. Returns the id of the newly created
  /// profile.
  ///
  /// Throws [DatabaseException] if the insert fails.
  Future<int> createProfile(Profile profile) async {
    final db = await _databaseService.database;
    return await db.insert(
      'Profile',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Retrieves a profile by its unique id.
  ///
  /// Returns the [Profile] if found, or `null` if no profile with the
  /// given [id] exists.
  Future<Profile?> getProfile(int id) async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Profile',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Profile.fromMap(maps.first);
  }

  /// Retrieves all profiles ordered by name.
  ///
  /// Returns an empty list if no profiles exist. Useful for profile
  /// selection screens and multi-user scenarios.
  Future<List<Profile>> getAllProfiles() async {
    final db = await _databaseService.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'Profile',
      orderBy: 'name ASC',
    );

    return maps.map((map) => Profile.fromMap(map)).toList();
  }

  /// Updates an existing profile.
  ///
  /// The [profile] must have a valid id. Returns the number of rows affected
  /// (should be 1 on success, 0 if profile not found).
  ///
  /// Throws [DatabaseException] if the update fails.
  Future<int> updateProfile(Profile profile) async {
    final db = await _databaseService.database;
    return await db.update(
      'Profile',
      profile.toMap(),
      where: 'id = ?',
      whereArgs: [profile.id],
    );
  }

  /// Deletes a profile by id.
  ///
  /// Cascades to all dependent data (readings, medications, etc.) due to
  /// foreign key ON DELETE CASCADE constraints. Returns the number of rows
  /// deleted (1 on success, 0 if profile not found).
  ///
  /// **Warning**: This operation is irreversible and will delete all health
  /// data associated with the profile.
  Future<int> deleteProfile(int id) async {
    final db = await _databaseService.database;
    return await db.delete(
      'Profile',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Counts the total number of profiles.
  ///
  /// Useful for determining if this is a new installation or for analytics.
  Future<int> getProfileCount() async {
    final db = await _databaseService.database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM Profile');
    return result.first['count'] as int;
  }
}

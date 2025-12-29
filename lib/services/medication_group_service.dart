import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing medication group CRUD operations.
///
/// Provides database operations for medication groups with validation.
class MedicationGroupService {
  final DatabaseService _databaseService;

  /// Creates a [MedicationGroupService] with the given database service.
  MedicationGroupService(this._databaseService);

  /// Creates a new medication group in the database.
  ///
  /// Validates the group name and ensures all member medications
  /// belong to the same profile.
  ///
  /// Returns the created group with its assigned ID.
  ///
  /// Throws [ArgumentError] if validation fails or member medications
  /// belong to different profiles.
  Future<MedicationGroup> createGroup(MedicationGroup group) async {
    // Validate name
    final nameValidation = validateGroupName(group.name);
    if (nameValidation.level == ValidationLevel.error) {
      throw ArgumentError(nameValidation.message);
    }

    // Validate member medications belong to same profile
    await _validateMembershipIntegrity(
      group.profileId,
      group.memberMedicationIds,
    );

    final db = await _databaseService.database;
    final id = await db.insert(
      'MedicationGroup',
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return group.copyWith(id: id);
  }

  /// Retrieves a medication group by ID.
  ///
  /// Returns `null` if no group with the given ID exists.
  Future<MedicationGroup?> getGroup(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'MedicationGroup',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return MedicationGroup.fromMap(results.first);
  }

  /// Lists all medication groups for a given profile.
  ///
  /// Returns groups ordered by name alphabetically.
  Future<List<MedicationGroup>> listGroupsByProfile(int profileId) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'MedicationGroup',
      where: 'profileId = ?',
      whereArgs: [profileId],
      orderBy: 'name ASC',
    );

    return results.map((map) => MedicationGroup.fromMap(map)).toList();
  }

  /// Updates an existing medication group.
  ///
  /// Validates the group name and ensures all member medications
  /// belong to the same profile.
  ///
  /// Returns the updated group.
  ///
  /// Throws [ArgumentError] if validation fails, group doesn't exist,
  /// or member medications belong to different profiles.
  Future<MedicationGroup> updateGroup(MedicationGroup group) async {
    if (group.id == null) {
      throw ArgumentError('Cannot update group without an ID');
    }

    // Validate name
    final nameValidation = validateGroupName(group.name);
    if (nameValidation.level == ValidationLevel.error) {
      throw ArgumentError(nameValidation.message);
    }

    // Validate member medications belong to same profile
    await _validateMembershipIntegrity(
      group.profileId,
      group.memberMedicationIds,
    );

    final db = await _databaseService.database;
    final count = await db.update(
      'MedicationGroup',
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );

    if (count == 0) {
      throw ArgumentError('Group with ID ${group.id} not found');
    }

    return group;
  }

  /// Deletes a medication group by ID.
  ///
  /// Related intake records will have their groupId set to NULL.
  ///
  /// Returns `true` if a group was deleted, `false` otherwise.
  Future<bool> deleteGroup(int id) async {
    final db = await _databaseService.database;
    final count = await db.delete(
      'MedicationGroup',
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }

  /// Validates that all medication IDs belong to the specified profile.
  ///
  /// Throws [ArgumentError] if any medication belongs to a different profile
  /// or doesn't exist.
  Future<void> _validateMembershipIntegrity(
    int profileId,
    List<int> medicationIds,
  ) async {
    if (medicationIds.isEmpty) {
      return;
    }

    final db = await _databaseService.database;
    final placeholders = List.filled(medicationIds.length, '?').join(',');

    final results = await db.query(
      'Medication',
      columns: ['id', 'profileId'],
      where: 'id IN ($placeholders)',
      whereArgs: medicationIds,
    );

    // Check all medications exist
    if (results.length != medicationIds.length) {
      final foundIds = results.map((r) => r['id'] as int).toSet();
      final missingIds =
          medicationIds.where((id) => !foundIds.contains(id)).toList();
      throw ArgumentError(
        'Medications not found: ${missingIds.join(', ')}',
      );
    }

    // Check all medications belong to the same profile
    final wrongProfileMeds = results.where((r) {
      return r['profileId'] as int != profileId;
    }).toList();

    if (wrongProfileMeds.isNotEmpty) {
      final wrongIds = wrongProfileMeds.map((r) => r['id']).join(', ');
      throw ArgumentError(
        'Medications $wrongIds belong to a different profile',
      );
    }
  }
}

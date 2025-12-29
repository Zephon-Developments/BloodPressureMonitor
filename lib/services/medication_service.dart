import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Service for managing medication CRUD operations.
///
/// Provides database operations for medications with validation.
class MedicationService {
  final DatabaseService _databaseService;

  /// Creates a [MedicationService] with the given database service.
  MedicationService(this._databaseService);

  /// Creates a new medication in the database.
  ///
  /// Validates the medication fields before insertion.
  ///
  /// Returns the created medication with its assigned ID.
  ///
  /// Throws [ArgumentError] if validation fails.
  Future<Medication> createMedication(Medication medication) async {
    // Validate fields
    final nameValidation = validateMedicationName(medication.name);
    if (nameValidation.level == ValidationLevel.error) {
      throw ArgumentError(nameValidation.message);
    }

    final dosageValidation = validateMedicationDosage(medication.dosage);
    if (dosageValidation.level == ValidationLevel.error) {
      throw ArgumentError(dosageValidation.message);
    }

    final unitValidation = validateMedicationUnit(medication.unit);
    if (unitValidation.level == ValidationLevel.error) {
      throw ArgumentError(unitValidation.message);
    }

    final frequencyValidation =
        validateMedicationFrequency(medication.frequency);
    if (frequencyValidation.level == ValidationLevel.error) {
      throw ArgumentError(frequencyValidation.message);
    }

    final db = await _databaseService.database;
    final id = await db.insert(
      'Medication',
      medication.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return medication.copyWith(id: id);
  }

  /// Retrieves a medication by ID.
  ///
  /// Returns `null` if no medication with the given ID exists.
  Future<Medication?> getMedication(int id) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'Medication',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return Medication.fromMap(results.first);
  }

  /// Lists all medications for a given profile.
  ///
  /// By default, only active medications are returned.
  /// Set [includeInactive] to true to include soft-deleted medications.
  ///
  /// Returns medications ordered by name alphabetically.
  Future<List<Medication>> listMedicationsByProfile(
    int profileId, {
    bool includeInactive = false,
  }) async {
    final db = await _databaseService.database;
    final where =
        includeInactive ? 'profileId = ?' : 'profileId = ? AND isActive = 1';
    final results = await db.query(
      'Medication',
      where: where,
      whereArgs: [profileId],
      orderBy: 'name ASC',
    );

    return results.map((map) => Medication.fromMap(map)).toList();
  }

  /// Searches medications by name substring (case-insensitive).
  ///
  /// Only returns active medications by default.
  ///
  /// Returns medications for the given profile matching the search term.
  Future<List<Medication>> searchMedicationsByName({
    required int profileId,
    required String searchTerm,
  }) async {
    final db = await _databaseService.database;
    final results = await db.query(
      'Medication',
      where: 'profileId = ? AND name LIKE ? AND isActive = 1',
      whereArgs: [profileId, '%$searchTerm%'],
      orderBy: 'name ASC',
    );

    return results.map((map) => Medication.fromMap(map)).toList();
  }

  /// Updates an existing medication.
  ///
  /// Validates the medication fields before update.
  ///
  /// Returns the updated medication.
  ///
  /// Throws [ArgumentError] if validation fails or medication doesn't exist.
  Future<Medication> updateMedication(Medication medication) async {
    if (medication.id == null) {
      throw ArgumentError('Cannot update medication without an ID');
    }

    // Validate fields
    final nameValidation = validateMedicationName(medication.name);
    if (nameValidation.level == ValidationLevel.error) {
      throw ArgumentError(nameValidation.message);
    }

    final dosageValidation = validateMedicationDosage(medication.dosage);
    if (dosageValidation.level == ValidationLevel.error) {
      throw ArgumentError(dosageValidation.message);
    }

    final unitValidation = validateMedicationUnit(medication.unit);
    if (unitValidation.level == ValidationLevel.error) {
      throw ArgumentError(unitValidation.message);
    }

    final frequencyValidation =
        validateMedicationFrequency(medication.frequency);
    if (frequencyValidation.level == ValidationLevel.error) {
      throw ArgumentError(frequencyValidation.message);
    }

    final db = await _databaseService.database;
    final count = await db.update(
      'Medication',
      medication.toMap(),
      where: 'id = ?',
      whereArgs: [medication.id],
    );

    if (count == 0) {
      throw ArgumentError('Medication with ID ${medication.id} not found');
    }

    return medication;
  }

  /// Soft-deletes a medication by setting isActive to false.
  ///
  /// This preserves historical intake records while hiding the medication
  /// from active lists.
  ///
  /// Returns `true` if a medication was soft-deleted, `false` otherwise.
  Future<bool> deleteMedication(int id) async {
    final db = await _databaseService.database;
    final count = await db.update(
      'Medication',
      {'isActive': 0},
      where: 'id = ?',
      whereArgs: [id],
    );

    return count > 0;
  }
}

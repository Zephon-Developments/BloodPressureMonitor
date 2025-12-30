import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';

/// Service for importing health data from CSV and JSON formats.
class ImportService {
  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;
  final MedicationService _medicationService;
  final MedicationIntakeService _intakeService;

  ImportService({
    required ReadingService readingService,
    required WeightService weightService,
    required SleepService sleepService,
    required MedicationService medicationService,
    required MedicationIntakeService intakeService,
  })  : _readingService = readingService,
        _weightService = weightService,
        _sleepService = sleepService,
        _medicationService = medicationService,
        _intakeService = intakeService;

  /// Imports data from a JSON file.
  Future<ImportResult> importFromJson({
    required File file,
    required int profileId,
    required ImportConflictMode conflictMode,
  }) async {
    final content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    final hasReadings = data.containsKey('readings');
    final hasWeight = data.containsKey('weight');
    final hasSleep = data.containsKey('sleep');
    final hasMedications = data.containsKey('medications');
    final hasIntakes = data.containsKey('medicationIntakes');

    if (conflictMode == ImportConflictMode.overwrite) {
      await _clearExistingData(
        profileId: profileId,
        clearReadings: hasReadings,
        clearWeight: hasWeight,
        clearSleep: hasSleep,
        clearMedications: hasMedications,
        clearMedicationIntakes: hasIntakes,
      );
    }

    int readingsImported = 0;
    int weightsImported = 0;
    int sleepLogsImported = 0;
    int medicationsImported = 0;
    int intakesImported = 0;
    int duplicatesSkipped = 0;
    final List<ImportError> errors = [];

    // Handle Readings
    if (hasReadings) {
      final List<dynamic> readingsData = data['readings'];
      for (final rMap in readingsData) {
        try {
          final reading = Reading.fromMap(rMap as Map<String, dynamic>);
          final adjustedReading = reading.copyWith(profileId: profileId);

          if (conflictMode == ImportConflictMode.append) {
            final existing = await _readingService.getReadingsInTimeRange(
              profileId,
              adjustedReading.takenAt,
              adjustedReading.takenAt,
            );
            final isDuplicate = existing.any(
              (e) =>
                  e.systolic == adjustedReading.systolic &&
                  e.diastolic == adjustedReading.diastolic,
            );
            if (isDuplicate) {
              duplicatesSkipped++;
              continue;
            }
          }

          await _readingService.createReading(adjustedReading);
          readingsImported++;
        } catch (e) {
          errors.add(
            ImportError(
              row: readingsImported + duplicatesSkipped + errors.length + 1,
              dataType: 'Reading',
              message: e.toString(),
            ),
          );
        }
      }
    }

    // Handle Weight
    if (hasWeight) {
      final List<dynamic> weightData = data['weight'];
      for (final wMap in weightData) {
        try {
          final entry = WeightEntry.fromMap(wMap as Map<String, dynamic>);
          final adjustedEntry = entry.copyWith(profileId: profileId);
          await _weightService.createWeightEntry(adjustedEntry);
          weightsImported++;
        } catch (e) {
          errors.add(
            ImportError(
              row: weightsImported + errors.length + 1,
              dataType: 'Weight',
              message: e.toString(),
            ),
          );
        }
      }
    }

    // Handle Sleep
    if (hasSleep) {
      final List<dynamic> sleepData = data['sleep'];
      for (final sMap in sleepData) {
        try {
          final entry = SleepEntry.fromMap(sMap as Map<String, dynamic>);
          final adjustedEntry = entry.copyWith(profileId: profileId);
          await _sleepService.createSleepEntry(adjustedEntry);
          sleepLogsImported++;
        } catch (e) {
          errors.add(
            ImportError(
              row: sleepLogsImported + errors.length + 1,
              dataType: 'Sleep',
              message: e.toString(),
            ),
          );
        }
      }
    }

    // Handle Medications
    if (hasMedications) {
      final List<dynamic> medData = data['medications'];
      for (final mMap in medData) {
        try {
          final med = Medication.fromMap(mMap as Map<String, dynamic>);
          final adjustedMed = med.copyWith(profileId: profileId);
          await _medicationService.createMedication(adjustedMed);
          medicationsImported++;
        } catch (e) {
          errors.add(
            ImportError(
              row: medicationsImported + errors.length + 1,
              dataType: 'Medication',
              message: e.toString(),
            ),
          );
        }
      }
    }

    // Handle Medication Intakes
    if (hasIntakes) {
      final List<dynamic> intakeData = data['medicationIntakes'];
      for (final iMap in intakeData) {
        try {
          final intake = MedicationIntake.fromMap(iMap as Map<String, dynamic>);
          final adjustedIntake = intake.copyWith(profileId: profileId);
          await _intakeService.logIntake(adjustedIntake);
          intakesImported++;
        } catch (e) {
          errors.add(
            ImportError(
              row: intakesImported + errors.length + 1,
              dataType: 'MedicationIntake',
              message: e.toString(),
            ),
          );
        }
      }
    }

    return ImportResult(
      readingsImported: readingsImported,
      weightsImported: weightsImported,
      sleepLogsImported: sleepLogsImported,
      medicationsImported: medicationsImported,
      intakesImported: intakesImported,
      duplicatesSkipped: duplicatesSkipped,
      errors: errors,
    );
  }

  /// Imports data from a CSV file.
  Future<ImportResult> importFromCsv({
    required File file,
    required int profileId,
    required ImportConflictMode conflictMode,
  }) async {
    final content = await file.readAsString();
    final List<List<dynamic>> rows =
        const CsvToListConverter(shouldParseNumbers: true).convert(content);

    if (conflictMode == ImportConflictMode.overwrite) {
      await _clearExistingData(
        profileId: profileId,
        clearReadings: true,
      );
    }

    int readingsImported = 0;
    int weightsImported = 0;
    int sleepLogsImported = 0;
    int medicationsImported = 0;
    int intakesImported = 0;
    int duplicatesSkipped = 0;
    final List<ImportError> errors = [];

    String currentSection = '';
    List<String> headers = [];

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final firstCell = row[0].toString();
      if (firstCell.startsWith('#')) {
        currentSection = firstCell.substring(2).trim();
        headers = [];
        continue;
      }

      if (headers.isEmpty) {
        headers = row.map((e) => e.toString()).toList();
        continue;
      }

      try {
        final map = Map<String, dynamic>.fromIterables(headers, row);

        if (currentSection == 'READINGS') {
          final reading = _parseReadingFromCsvMap(map, profileId);

          if (conflictMode == ImportConflictMode.append) {
            final existing = await _readingService.getReadingsInTimeRange(
              profileId,
              reading.takenAt,
              reading.takenAt,
            );
            final isDuplicate = existing.any(
              (e) =>
                  e.systolic == reading.systolic &&
                  e.diastolic == reading.diastolic,
            );
            if (isDuplicate) {
              duplicatesSkipped++;
              continue;
            }
          }

          await _readingService.createReading(reading);
          readingsImported++;
        }
        // Additional sections can be appended here as CSV support expands.
      } catch (e) {
        errors.add(
          ImportError(
            row: i + 1,
            dataType: currentSection,
            message: e.toString(),
          ),
        );
      }
    }

    return ImportResult(
      readingsImported: readingsImported,
      weightsImported: weightsImported,
      sleepLogsImported: sleepLogsImported,
      medicationsImported: medicationsImported,
      intakesImported: intakesImported,
      duplicatesSkipped: duplicatesSkipped,
      errors: errors,
    );
  }

  Reading _parseReadingFromCsvMap(Map<String, dynamic> map, int profileId) {
    return Reading(
      profileId: profileId,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      localOffsetMinutes: map['localOffsetMinutes'] as int,
      posture: map['posture']?.toString(),
      arm: map['arm']?.toString(),
      medsContext: map['medsContext']?.toString(),
      irregularFlag: map['irregularFlag'] == 1,
      tags: map['tags']?.toString(),
      note: map['note']?.toString(),
    );
  }

  Future<void> _clearExistingData({
    required int profileId,
    bool clearReadings = false,
    bool clearWeight = false,
    bool clearSleep = false,
    bool clearMedications = false,
    bool clearMedicationIntakes = false,
  }) async {
    if (clearMedicationIntakes) {
      await _intakeService.deleteAllByProfile(profileId);
    }
    if (clearMedications) {
      await _medicationService.deleteAllByProfile(profileId);
    }
    if (clearSleep) {
      await _sleepService.deleteAllByProfile(profileId);
    }
    if (clearWeight) {
      await _weightService.deleteAllByProfile(profileId);
    }
    if (clearReadings) {
      await _readingService.deleteAllByProfile(profileId);
    }
  }
}

extension ReadingExtension on Reading {
  Reading copyWith({
    int? id,
    int? profileId,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? takenAt,
    int? localOffsetMinutes,
    String? posture,
    String? arm,
    String? medsContext,
    bool? irregularFlag,
    String? tags,
    String? note,
  }) {
    return Reading(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      takenAt: takenAt ?? this.takenAt,
      localOffsetMinutes: localOffsetMinutes ?? this.localOffsetMinutes,
      posture: posture ?? this.posture,
      arm: arm ?? this.arm,
      medsContext: medsContext ?? this.medsContext,
      irregularFlag: irregularFlag ?? this.irregularFlag,
      tags: tags ?? this.tags,
      note: note ?? this.note,
    );
  }
}

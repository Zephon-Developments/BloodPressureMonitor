import 'dart:convert';
import 'dart:io';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';

/// Service for importing health data from JSON format.
///
/// Uses the Result pattern for explicit error handling.
class ImportService {
  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;
  final MedicationService _medicationService;
  final MedicationIntakeService _intakeService;
  final AveragingService _averagingService;

  ImportService({
    required ReadingService readingService,
    required WeightService weightService,
    required SleepService sleepService,
    required MedicationService medicationService,
    required MedicationIntakeService intakeService,
    AveragingService? averagingService,
  })  : _readingService = readingService,
        _weightService = weightService,
        _sleepService = sleepService,
        _medicationService = medicationService,
        _intakeService = intakeService,
        _averagingService = averagingService ?? AveragingService();

  /// Imports data from a JSON file.
  ///
  /// Returns a [Result] containing the [ImportResult] on success,
  /// or an [AppError] if the operation fails.
  Future<Result<ImportResult>> importFromJson({
    required File file,
    required int profileId,
    required ImportConflictMode conflictMode,
  }) async {
    try {
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);

      // Parse profile metadata if available
      ImportProfileInfo? profileInfo;
      if (data.containsKey('metadata')) {
        try {
          final metadata =
              ExportMetadata.fromMap(data['metadata'] as Map<String, dynamic>);
          profileInfo = ImportProfileInfo.fromMetadata(metadata);
        } catch (e) {
          // Ignore metadata parsing errors for backward compatibility
        }
      }

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
            final intake =
                MedicationIntake.fromMap(iMap as Map<String, dynamic>);
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

      // Recompute reading groups if any readings were imported
      if (readingsImported > 0) {
        await _averagingService.recomputeGroupsForProfile(profileId);
      }

      return Success(
        ImportResult(
          readingsImported: readingsImported,
          weightsImported: weightsImported,
          sleepLogsImported: sleepLogsImported,
          medicationsImported: medicationsImported,
          intakesImported: intakesImported,
          duplicatesSkipped: duplicatesSkipped,
          errors: errors,
          profileInfo: profileInfo,
        ),
      );
    } on FileSystemException catch (e) {
      return Failure(
        AppError.fileSystem(
          'Failed to read import file: ${e.message}',
          e,
        ),
      );
    } on FormatException catch (e) {
      return Failure(
        AppError.validation(
          'Invalid JSON format: ${e.message}',
          e,
        ),
      );
    } catch (e) {
      return Failure(
        AppError.unexpected(
          'Failed to import data: $e',
          e,
        ),
      );
    }
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

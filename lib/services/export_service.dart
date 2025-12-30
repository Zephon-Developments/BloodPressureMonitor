import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';

/// Service for exporting health data to CSV and JSON formats.
class ExportService {
  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;
  final MedicationService _medicationService;
  final MedicationIntakeService _intakeService;
  final AppInfoService _appInfoService;

  ExportService({
    required ReadingService readingService,
    required WeightService weightService,
    required SleepService sleepService,
    required MedicationService medicationService,
    required MedicationIntakeService intakeService,
    AppInfoService? appInfoService,
  })  : _readingService = readingService,
        _weightService = weightService,
        _sleepService = sleepService,
        _medicationService = medicationService,
        _intakeService = intakeService,
        _appInfoService = appInfoService ?? const AppInfoService();

  /// Generates a standardized filename for export files.
  String generateFilename({
    required String profileName,
    required String extension,
    DateTime? timestamp,
  }) {
    final ts = timestamp ?? DateTime.now();
    final dateStr =
        "${ts.year}${ts.month.toString().padLeft(2, '0')}${ts.day.toString().padLeft(2, '0')}_"
        "${ts.hour.toString().padLeft(2, '0')}${ts.minute.toString().padLeft(2, '0')}";
    return 'bp_export_${profileName.replaceAll(' ', '_')}_$dateStr.$extension';
  }

  /// Exports data for a profile to a JSON file.
  ///
  /// Returns the [File] object for the created export.
  Future<File> exportToJson({
    required int profileId,
    required String profileName,
    bool includeReadings = true,
    bool includeWeight = true,
    bool includeSleep = true,
    bool includeMedications = true,
  }) async {
    final data = <String, dynamic>{};

    // Add metadata
    final appVersion = await _appInfoService.getAppVersion();
    final metadata = ExportMetadata(
      version: 1,
      exportedAt: DateTime.now(),
      appVersion: appVersion,
      profileId: profileId,
      timezoneOffset: DateTime.now().timeZoneOffset.inMinutes,
    );
    data['metadata'] = metadata.toMap();

    if (includeReadings) {
      final readings = await _readingService.getReadingsByProfile(profileId);
      data['readings'] = readings.map((r) => r.toMap()).toList();
    }

    if (includeWeight) {
      final weightEntries =
          await _weightService.listWeightEntries(profileId: profileId);
      data['weight'] = weightEntries.map((w) => w.toMap()).toList();
    }

    if (includeSleep) {
      final sleepEntries =
          await _sleepService.listSleepEntries(profileId: profileId);
      data['sleep'] = sleepEntries.map((s) => s.toMap()).toList();
    }

    if (includeMedications) {
      final medications = await _medicationService.listMedicationsByProfile(
        profileId,
        includeInactive: true,
      );
      data['medications'] = medications.map((m) => m.toMap()).toList();

      final intakes = await _intakeService.listIntakes(profileId: profileId);
      data['medicationIntakes'] = intakes.map((i) => i.toMap()).toList();
    }

    final jsonString = jsonEncode(data);
    final directory = await getApplicationDocumentsDirectory();
    final filename =
        generateFilename(profileName: profileName, extension: 'json');
    final file = File('${directory.path}/$filename');

    return await file.writeAsString(jsonString);
  }

  /// Exports data for a profile to a CSV file.
  ///
  /// Since CSV is flat, this generates a multi-section CSV or multiple files.
  /// The plan suggests "flat tables per entity". I'll implement a single file
  /// with sections separated by headers for simplicity, or just focus on
  /// one entity if that's what's expected.
  ///
  /// Actually, the plan says "flat tables per entity". I'll implement it as
  /// a single file with section headers to keep it simple for the user.
  Future<File> exportToCsv({
    required int profileId,
    required String profileName,
    bool includeReadings = true,
    bool includeWeight = true,
    bool includeSleep = true,
    bool includeMedications = true,
  }) async {
    final List<List<dynamic>> rows = [];

    // Metadata row
    rows.add([
      '# METADATA',
      'ExportedAt: ${DateTime.now().toIso8601String()}',
      'Profile: $profileName',
      'WARNING: Sensitive Health Data',
    ]);
    rows.add([]); // Empty line

    if (includeReadings) {
      final readings = await _readingService.getReadingsByProfile(profileId);
      rows.add(['# READINGS']);
      rows.add([
        'id',
        'systolic',
        'diastolic',
        'pulse',
        'takenAt',
        'localOffsetMinutes',
        'posture',
        'arm',
        'medsContext',
        'irregularFlag',
        'tags',
        'note',
      ]);
      for (final r in readings) {
        rows.add([
          r.id,
          r.systolic,
          r.diastolic,
          r.pulse,
          r.takenAt.toIso8601String(),
          r.localOffsetMinutes,
          r.posture,
          r.arm,
          r.medsContext,
          r.irregularFlag ? 1 : 0,
          r.tags,
          r.note,
        ]);
      }
      rows.add([]); // Empty line
    }

    if (includeWeight) {
      final weightEntries =
          await _weightService.listWeightEntries(profileId: profileId);
      rows.add(['# WEIGHT']);
      rows.add([
        'id',
        'weightValue',
        'unit',
        'takenAt',
        'localOffsetMinutes',
        'notes',
        'saltIntake',
        'exerciseLevel',
        'stressLevel',
        'sleepQuality',
        'source',
        'createdAt',
      ]);
      for (final w in weightEntries) {
        rows.add([
          w.id,
          w.weightValue,
          w.unit.toDbString(),
          w.takenAt.toIso8601String(),
          w.localOffsetMinutes,
          w.notes,
          w.saltIntake,
          w.exerciseLevel,
          w.stressLevel,
          w.sleepQuality,
          w.source,
          w.createdAt.toIso8601String(),
        ]);
      }
      rows.add([]); // Empty line
    }

    if (includeSleep) {
      final sleepEntries =
          await _sleepService.listSleepEntries(profileId: profileId);
      rows.add(['# SLEEP']);
      rows.add([
        'id',
        'startedAt',
        'endedAt',
        'durationMinutes',
        'quality',
        'deepMinutes',
        'lightMinutes',
        'remMinutes',
        'awakeMinutes',
        'notes',
        'source',
        'createdAt',
      ]);
      for (final s in sleepEntries) {
        rows.add([
          s.id,
          s.startedAt.toIso8601String(),
          s.endedAt?.toIso8601String(),
          s.durationMinutes,
          s.quality,
          s.deepMinutes,
          s.lightMinutes,
          s.remMinutes,
          s.awakeMinutes,
          s.notes,
          s.source.toDbString(),
          s.createdAt.toIso8601String(),
        ]);
      }
      rows.add([]); // Empty line
    }

    if (includeMedications) {
      final medications = await _medicationService.listMedicationsByProfile(
        profileId,
        includeInactive: true,
      );
      rows.add(['# MEDICATIONS']);
      rows.add([
        'id',
        'name',
        'dosage',
        'unit',
        'frequency',
        'isActive',
        'createdAt',
      ]);
      for (final m in medications) {
        rows.add([
          m.id,
          m.name,
          m.dosage,
          m.unit,
          m.frequency,
          m.isActive ? 1 : 0,
          m.createdAt.toIso8601String(),
        ]);
      }
      rows.add([]); // Empty line

      final intakes = await _intakeService.listIntakes(profileId: profileId);
      rows.add(['# MEDICATION_INTAKES']);
      rows.add([
        'id',
        'medicationId',
        'takenAt',
        'localOffsetMinutes',
        'scheduledFor',
        'groupId',
        'note',
      ]);
      for (final i in intakes) {
        rows.add([
          i.id,
          i.medicationId,
          i.takenAt.toIso8601String(),
          i.localOffsetMinutes,
          i.scheduledFor?.toIso8601String(),
          i.groupId,
          i.note,
        ]);
      }
      rows.add([]); // Empty line
    }

    final csvString = const ListToCsvConverter().convert(rows);
    final directory = await getApplicationDocumentsDirectory();
    final filename =
        generateFilename(profileName: profileName, extension: 'csv');
    final file = File('${directory.path}/$filename');

    return await file.writeAsString(csvString);
  }
}

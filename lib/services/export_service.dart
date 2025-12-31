import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  /// Sanitizes a CSV cell value to prevent formula injection.
  ///
  /// Prefixes values starting with `=`, `+`, `-`, or `@` with a single quote
  /// to prevent them from being interpreted as formulas in spreadsheet software.
  /// This mitigates CSV injection attacks while preserving data readability.
  ///
  /// Returns null if the input is null, otherwise returns the sanitized string.
  String? _sanitizeCsvCell(String? value) {
    if (value == null || value.isEmpty) return value;

    final trimmed = value.trimLeft();
    if (trimmed.isEmpty) return value;

    final firstChar = trimmed[0];
    if (firstChar == '=' ||
        firstChar == '+' ||
        firstChar == '-' ||
        firstChar == '@') {
      return "'$value";
    }

    return value;
  }

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
          _sanitizeCsvCell(r.posture),
          _sanitizeCsvCell(r.arm),
          _sanitizeCsvCell(r.medsContext),
          r.irregularFlag ? 1 : 0,
          _sanitizeCsvCell(r.tags),
          _sanitizeCsvCell(r.note),
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
          _sanitizeCsvCell(w.unit.toDbString()),
          w.takenAt.toIso8601String(),
          w.localOffsetMinutes,
          _sanitizeCsvCell(w.notes),
          _sanitizeCsvCell(w.saltIntake),
          _sanitizeCsvCell(w.exerciseLevel),
          _sanitizeCsvCell(w.stressLevel),
          _sanitizeCsvCell(w.sleepQuality),
          _sanitizeCsvCell(w.source),
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
          _sanitizeCsvCell(s.notes),
          _sanitizeCsvCell(s.source.toDbString()),
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
          _sanitizeCsvCell(m.name),
          _sanitizeCsvCell(m.dosage),
          _sanitizeCsvCell(m.unit),
          _sanitizeCsvCell(m.frequency),
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
          _sanitizeCsvCell(i.note),
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

  /// Shares an export file using the platform share sheet.
  ///
  /// Uses the text "Sensitive health data – Blood Pressure Export" to warn
  /// recipients about the nature of the data being shared.
  Future<void> shareExport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sensitive health data – Blood Pressure Export',
    );
  }
}

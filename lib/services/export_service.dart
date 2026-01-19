import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';

/// Service for exporting health data to JSON format.
///
/// Exports are saved as human-readable JSON files with 2-space indentation.
/// Uses the Result pattern for explicit error handling.
class ExportService {
  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;
  final MedicationService _medicationService;
  final MedicationIntakeService _intakeService;
  final AppInfoService _appInfoService;

  const ExportService({
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

  /// Exports data for a profile to a JSON file with human-readable formatting.
  ///
  /// Returns a [Result] containing the [File] object for the created export,
  /// or an [AppError] if the operation fails.
  ///
  /// The exported JSON uses 2-space indentation for readability while
  /// maintaining full import compatibility.
  Future<Result<File>> exportToJson({
    required int profileId,
    required String profileName,
    bool includeReadings = true,
    bool includeWeight = true,
    bool includeSleep = true,
    bool includeMedications = true,
  }) async {
    try {
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

      // Use indented JSON encoder for human readability
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(data);

      final directory = await getApplicationDocumentsDirectory();
      final filename =
          generateFilename(profileName: profileName, extension: 'json');
      final file = File('${directory.path}/$filename');

      await file.writeAsString(jsonString);
      return Success(file);
    } on FileSystemException catch (e) {
      return Failure(
        AppError.fileSystem(
          'Failed to write export file: ${e.message}',
          e,
        ),
      );
    } catch (e) {
      return Failure(
        AppError.unexpected(
          'Failed to export data: $e',
          e,
        ),
      );
    }
  }

  /// Shares an export file using the platform share sheet.
  ///
  /// Uses warning text to inform recipients about the nature of the data.
  Future<void> shareExport(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sensitive health data – HealthLog Export',
    );
  }
}

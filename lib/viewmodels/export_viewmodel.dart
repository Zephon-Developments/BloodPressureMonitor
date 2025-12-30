import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/services/export_service.dart';

/// ViewModel for managing the export process.
class ExportViewModel extends ChangeNotifier {
  final ExportService _exportService;

  ExportViewModel({required ExportService exportService})
      : _exportService = exportService;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  String? _lastExportPath;
  String? get lastExportPath => _lastExportPath;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Exports data to JSON.
  Future<bool> exportToJson({
    required int profileId,
    required String profileName,
    bool includeReadings = true,
    bool includeWeight = true,
    bool includeSleep = true,
    bool includeMedications = true,
  }) async {
    _setExporting(true);
    _errorMessage = null;
    try {
      final file = await _exportService.exportToJson(
        profileId: profileId,
        profileName: profileName,
        includeReadings: includeReadings,
        includeWeight: includeWeight,
        includeSleep: includeSleep,
        includeMedications: includeMedications,
      );
      _lastExportPath = file.path;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setExporting(false);
    }
  }

  /// Exports data to CSV.
  Future<bool> exportToCsv({
    required int profileId,
    required String profileName,
    bool includeReadings = true,
    bool includeWeight = true,
    bool includeSleep = true,
    bool includeMedications = true,
  }) async {
    _setExporting(true);
    _errorMessage = null;
    try {
      final file = await _exportService.exportToCsv(
        profileId: profileId,
        profileName: profileName,
        includeReadings: includeReadings,
        includeWeight: includeWeight,
        includeSleep: includeSleep,
        includeMedications: includeMedications,
      );
      _lastExportPath = file.path;
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setExporting(false);
    }
  }

  void _setExporting(bool value) {
    _isExporting = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

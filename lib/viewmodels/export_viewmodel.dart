import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/services/export_service.dart';

/// ViewModel for managing the export process.
///
/// Handles the export of health data to JSON files and provides
/// state management for the export UI.
class ExportViewModel extends ChangeNotifier {
  final ExportService _exportService;

  /// Creates an [ExportViewModel] with the given [exportService].
  ExportViewModel({required ExportService exportService})
      : _exportService = exportService;

  bool _isExporting = false;

  /// Whether an export operation is currently in progress.
  bool get isExporting => _isExporting;

  String? _lastExportPath;

  /// The file path of the most recent successful export.
  String? get lastExportPath => _lastExportPath;

  String? _errorMessage;

  /// The current error message, if any.
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
      final result = await _exportService.exportToJson(
        profileId: profileId,
        profileName: profileName,
        includeReadings: includeReadings,
        includeWeight: includeWeight,
        includeSleep: includeSleep,
        includeMedications: includeMedications,
      );

      switch (result) {
        case Success(:final value):
          _lastExportPath = value.path;
          return true;
        case Failure(:final error):
          _errorMessage = error.userMessage;
          return false;
      }
    } finally {
      _setExporting(false);
    }
  }

  void _setExporting(bool value) {
    _isExporting = value;
    notifyListeners();
  }

  /// Clears the current error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Shares the last exported file using the platform share sheet.
  ///
  /// Returns `true` if the share was successful, `false` otherwise.
  Future<bool> shareLastExport() async {
    if (_lastExportPath == null) {
      _errorMessage = 'No file to share';
      notifyListeners();
      return false;
    }

    try {
      final file = File(_lastExportPath!);
      if (!await file.exists()) {
        _errorMessage = 'Export file no longer exists';
        notifyListeners();
        return false;
      }

      await _exportService.shareExport(file);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to share: $e';
      notifyListeners();
      return false;
    }
  }
}

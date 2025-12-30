import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/services/import_service.dart';

/// ViewModel for managing the import process.
class ImportViewModel extends ChangeNotifier {
  final ImportService _importService;

  ImportViewModel({required ImportService importService})
      : _importService = importService;

  bool _isImporting = false;
  bool get isImporting => _isImporting;

  ImportResult? _importResult;
  ImportResult? get importResult => _importResult;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  File? _selectedFile;
  File? get selectedFile => _selectedFile;

  bool _overwriteExisting = false;
  bool get overwriteExisting => _overwriteExisting;

  void setOverwrite(bool value) {
    _overwriteExisting = value;
    notifyListeners();
  }

  /// Picks a file from the device.
  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'csv'],
      );

      if (result != null && result.files.single.path != null) {
        _selectedFile = File(result.files.single.path!);
        _errorMessage = null;
        notifyListeners();
      }
    } catch (e) {
      _errorMessage = 'Failed to pick file: $e';
      notifyListeners();
    }
  }

  /// Imports data from the selected file.
  Future<bool> importData({
    required int profileId,
    required ImportConflictMode conflictMode,
  }) async {
    if (_selectedFile == null) {
      _errorMessage = 'No file selected';
      notifyListeners();
      return false;
    }

    _setImporting(true);
    _errorMessage = null;
    _importResult = null;

    try {
      final extension = _selectedFile!.path.split('.').last.toLowerCase();
      if (extension == 'json') {
        _importResult = await _importService.importFromJson(
          file: _selectedFile!,
          profileId: profileId,
          conflictMode: conflictMode,
        );
      } else if (extension == 'csv') {
        _importResult = await _importService.importFromCsv(
          file: _selectedFile!,
          profileId: profileId,
          conflictMode: conflictMode,
        );
      } else {
        _errorMessage = 'Unsupported file format: $extension';
        return false;
      }
      return true;
    } catch (e) {
      _errorMessage = 'Import failed: $e';
      return false;
    } finally {
      _setImporting(false);
    }
  }

  void _setImporting(bool value) {
    _isImporting = value;
    notifyListeners();
  }

  void clearSelection() {
    _selectedFile = null;
    _importResult = null;
    _errorMessage = null;
    notifyListeners();
  }
}

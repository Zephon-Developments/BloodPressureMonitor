import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/services/import_service.dart';

/// ViewModel for managing the import process.
typedef FilePickerInvoker = Future<FilePickerResult?> Function({
  required FileType type,
  List<String>? allowedExtensions,
});

/// ViewModel for managing the import process.
class ImportViewModel extends ChangeNotifier {
  final ImportService _importService;
  final FilePickerInvoker _pickFiles;

  ImportViewModel({
    required ImportService importService,
    FilePickerInvoker? pickFiles,
  })  : _importService = importService,
        _pickFiles = pickFiles ?? _defaultPickFiles;

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

  /// Sets the selected file for testing purposes.
  @visibleForTesting
  void setSelectedFileForTesting(File file) {
    _selectedFile = file;
    notifyListeners();
  }

  /// Picks a JSON file from the device.
  Future<void> pickFile() async {
    try {
      final platformFile = await _pickJsonFile();
      if (platformFile == null) {
        return;
      }

      final filePath = platformFile.path;
      if (filePath == null) {
        _errorMessage = 'Selected file is missing a valid path.';
        notifyListeners();
        return;
      }

      if (!_hasJsonExtension(filePath)) {
        _errorMessage = 'Please select a file with the .json extension.';
        _selectedFile = null;
        notifyListeners();
        return;
      }

      _selectedFile = File(filePath);
      _importResult = null;
      _errorMessage = null;
      notifyListeners();
    } on PlatformException catch (e) {
      _errorMessage = 'Unable to open file picker: ${e.message ?? e.code}';
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to pick file: $e';
      notifyListeners();
    }
  }

  Future<PlatformFile?> _pickJsonFile() async {
    try {
      final result = await _pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
      );
      return _firstFile(result);
    } on PlatformException catch (e) {
      if (_shouldFallbackToAny(e)) {
        final fallback = await _pickFiles(type: FileType.any);
        return _firstFile(fallback);
      }
      rethrow;
    }
  }

  PlatformFile? _firstFile(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) {
      return null;
    }
    return result.files.first;
  }

  bool _hasJsonExtension(String path) =>
      path.toLowerCase().trim().endsWith('.json');

  bool _shouldFallbackToAny(PlatformException exception) {
    final message = exception.message?.toLowerCase() ?? '';
    return message.contains('unsupported filter');
  }

  static Future<FilePickerResult?> _defaultPickFiles({
    required FileType type,
    List<String>? allowedExtensions,
  }) {
    return FilePicker.platform.pickFiles(
      type: type,
      allowedExtensions: allowedExtensions,
    );
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
      final result = await _importService.importFromJson(
        file: _selectedFile!,
        profileId: profileId,
        conflictMode: conflictMode,
      );

      switch (result) {
        case Success(:final value):
          _importResult = value;
          return true;
        case Failure(:final error):
          _errorMessage = error.userMessage;
          return false;
      }
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

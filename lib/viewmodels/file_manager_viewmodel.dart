import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/managed_file.dart';
import 'package:blood_pressure_monitor/models/auto_cleanup_policy.dart';
import 'package:blood_pressure_monitor/services/file_manager_service.dart';
import 'package:blood_pressure_monitor/services/export_service.dart';
import 'package:blood_pressure_monitor/services/pdf_report_service.dart';

/// ViewModel for the file manager screen.
class FileManagerViewModel extends ChangeNotifier {
  final FileManagerService _fileManagerService;
  final ExportService _exportService;
  final PdfReportService _pdfReportService;

  FileManagerViewModel({
    required FileManagerService fileManagerService,
    required ExportService exportService,
    required PdfReportService pdfReportService,
  })  : _fileManagerService = fileManagerService,
        _exportService = exportService,
        _pdfReportService = pdfReportService;

  List<ManagedFile> _files = [];
  List<ManagedFile> get files => List.unmodifiable(_files);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AutoCleanupPolicy? _policy;
  AutoCleanupPolicy? get policy => _policy;

  int _totalStorageBytes = 0;
  int get totalStorageBytes => _totalStorageBytes;

  String get formattedTotalStorage {
    if (_totalStorageBytes < 1024) {
      return '$_totalStorageBytes B';
    } else if (_totalStorageBytes < 1024 * 1024) {
      return '${(_totalStorageBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(_totalStorageBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Groups files by their kind.
  Map<FileKind, List<ManagedFile>> get filesByKind {
    final grouped = <FileKind, List<ManagedFile>>{};
    for (final file in _files) {
      grouped.putIfAbsent(file.kind, () => []).add(file);
    }
    return grouped;
  }

  /// Loads files and cleanup policy.
  Future<void> loadFiles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _files = await _fileManagerService.listFiles();
      _totalStorageBytes = await _fileManagerService.getTotalStorageBytes();
      _policy = await AutoCleanupPolicy.load();
    } catch (e) {
      _errorMessage = 'Failed to load files: $e';
      _files = [];
      _totalStorageBytes = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Deletes a single file.
  Future<bool> deleteFile(String path) async {
    try {
      final success = await _fileManagerService.deleteFile(path);
      if (success) {
        await loadFiles(); // Refresh the list
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to delete file: $e';
      notifyListeners();
      return false;
    }
  }

  /// Deletes multiple files.
  Future<void> deleteFiles(List<String> paths) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _fileManagerService.deleteFiles(paths);
      if (result.errors.isNotEmpty) {
        _errorMessage =
            'Deleted ${result.filesDeleted} files with ${result.errors.length} errors';
      }
      await loadFiles(); // Refresh the list
    } catch (e) {
      _errorMessage = 'Failed to delete files: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Runs automatic cleanup based on current policy.
  Future<String?> runAutoCleanup() async {
    if (_policy == null) {
      await loadFiles(); // Load policy if not yet loaded
    }

    if (_policy == null || !_policy!.enabled) {
      return 'Auto-cleanup is disabled';
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _fileManagerService.runAutoCleanup(_policy!);
      await loadFiles(); // Refresh the list

      if (result.filesDeleted == 0) {
        return 'No files needed cleanup';
      } else {
        return 'Deleted ${result.filesDeleted} files, freed ${result.formattedBytesFreed}';
      }
    } catch (e) {
      _errorMessage = 'Cleanup failed: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Shares a file using the appropriate share method based on file type.
  Future<void> shareFile(ManagedFile file) async {
    try {
      final ioFile = File(file.path);
      if (!await ioFile.exists()) {
        _errorMessage = 'File no longer exists';
        notifyListeners();
        return;
      }

      switch (file.kind) {
        case FileKind.exportJson:
        case FileKind.exportCsv:
          await _exportService.shareExport(ioFile);
          break;
        case FileKind.reportPdf:
          await _pdfReportService.shareReport(ioFile);
          break;
        case FileKind.unknown:
          _errorMessage = 'Cannot share unknown file type';
          notifyListeners();
          return;
      }
    } catch (e) {
      _errorMessage = 'Failed to share file: $e';
      notifyListeners();
    }
  }

  /// Updates the cleanup policy.
  Future<void> updatePolicy(AutoCleanupPolicy newPolicy) async {
    try {
      await newPolicy.save();
      _policy = newPolicy;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to save policy: $e';
      notifyListeners();
    }
  }

  /// Clears the error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

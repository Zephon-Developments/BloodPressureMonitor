import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:blood_pressure_monitor/models/managed_file.dart';
import 'package:blood_pressure_monitor/models/auto_cleanup_policy.dart';

/// Result of a cleanup operation.
class CleanupResult {
  /// Number of files deleted.
  final int filesDeleted;

  /// Total bytes freed.
  final int bytesFreed;

  /// List of errors encountered (file path and error message).
  final List<MapEntry<String, String>> errors;

  const CleanupResult({
    required this.filesDeleted,
    required this.bytesFreed,
    this.errors = const [],
  });

  /// Returns a human-readable size string for bytes freed.
  String get formattedBytesFreed {
    if (bytesFreed < 1024) {
      return '$bytesFreed B';
    } else if (bytesFreed < 1024 * 1024) {
      return '${(bytesFreed / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytesFreed / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}

/// Service for managing export and report files in the app's documents directory.
class FileManagerService {
  /// Scans the documents directory and returns a list of managed files.
  ///
  /// Looks for files matching the patterns:
  /// - `bp_export_*.json`
  /// - `bp_export_*.csv`
  /// - `bp_report_*.pdf`
  ///
  /// Files that don't match these patterns are ignored.
  Future<List<ManagedFile>> listFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final entities = directory.listSync();
    final files = <ManagedFile>[];

    for (final entity in entities) {
      if (entity is! File) continue;

      final fileName = entity.path.split(Platform.pathSeparator).last;
      final managedFile = _parseFile(entity, fileName);
      if (managedFile != null) {
        files.add(managedFile);
      }
    }

    // Sort by creation date, newest first
    files.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return files;
  }

  /// Parses a file and returns a ManagedFile if it matches expected patterns.
  ManagedFile? _parseFile(File file, String fileName) {
    FileKind? kind;
    String? profileName;

    // Determine file kind based on prefix and extension
    if (fileName.startsWith('bp_export_') && fileName.endsWith('.json')) {
      kind = FileKind.exportJson;
      profileName = _extractProfileName(fileName, 'bp_export_', '.json');
    } else if (fileName.startsWith('bp_export_') && fileName.endsWith('.csv')) {
      kind = FileKind.exportCsv;
      profileName = _extractProfileName(fileName, 'bp_export_', '.csv');
    } else if (fileName.startsWith('bp_report_') && fileName.endsWith('.pdf')) {
      kind = FileKind.reportPdf;
      profileName = _extractProfileName(fileName, 'bp_report_', '.pdf');
    }

    if (kind == null) {
      return null; // Not a recognized file pattern
    }

    try {
      final stat = file.statSync();
      return ManagedFile(
        path: file.path,
        name: fileName,
        sizeBytes: stat.size,
        createdAt: stat.modified,
        kind: kind,
        profileName: profileName,
      );
    } catch (e) {
      // File might have been deleted or inaccessible
      return null;
    }
  }

  /// Extracts profile name from filename.
  ///
  /// Expected format: `{prefix}{profileName}_{timestamp}.{extension}`
  /// Example: `bp_export_John_Doe_20251231_1430.json`
  String? _extractProfileName(String fileName, String prefix, String suffix) {
    try {
      final withoutPrefix = fileName.substring(prefix.length);
      final withoutSuffix =
          withoutPrefix.substring(0, withoutPrefix.length - suffix.length);

      // Find last underscore (before timestamp)
      final lastUnderscore = withoutSuffix.lastIndexOf('_');
      if (lastUnderscore == -1) return null;

      // Find second-to-last underscore
      final secondLastUnderscore =
          withoutSuffix.lastIndexOf('_', lastUnderscore - 1);
      if (secondLastUnderscore == -1) return null;

      // Profile name is everything before the timestamp
      final profileName = withoutSuffix.substring(0, secondLastUnderscore);
      return profileName.replaceAll('_', ' ');
    } catch (e) {
      return null; // Failed to parse, no big deal
    }
  }

  /// Deletes a file at the given path.
  ///
  /// Returns true if successful, false if the file doesn't exist or can't be deleted.
  /// Throws an exception if there's an I/O error other than file not found.
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        return false;
      }
      await file.delete();
      return true;
    } on FileSystemException catch (e) {
      if (e.osError?.errorCode == 2) {
        // File not found (already deleted)
        return false;
      }
      rethrow;
    }
  }

  /// Deletes multiple files.
  ///
  /// Returns the number of files successfully deleted.
  /// Errors are collected but don't stop the operation.
  Future<CleanupResult> deleteFiles(List<String> paths) async {
    int deleted = 0;
    int bytesFreed = 0;
    final errors = <MapEntry<String, String>>[];

    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final size = await file.length();
          await file.delete();
          deleted++;
          bytesFreed += size;
        }
      } catch (e) {
        errors.add(MapEntry(path, e.toString()));
      }
    }

    return CleanupResult(
      filesDeleted: deleted,
      bytesFreed: bytesFreed,
      errors: errors,
    );
  }

  /// Runs automatic cleanup based on the provided policy.
  ///
  /// Returns a [CleanupResult] with the number of files deleted and bytes freed.
  Future<CleanupResult> runAutoCleanup(AutoCleanupPolicy policy) async {
    if (!policy.enabled) {
      return const CleanupResult(filesDeleted: 0, bytesFreed: 0);
    }

    final files = await listFiles();
    final toDelete = <String>[];

    // Group files by type
    final filesByKind = <FileKind, List<ManagedFile>>{};
    for (final file in files) {
      filesByKind.putIfAbsent(file.kind, () => []).add(file);
    }

    // Apply age rule
    if (policy.maxAge != null) {
      final cutoff = DateTime.now().subtract(policy.maxAge!);
      for (final file in files) {
        if (file.createdAt.isBefore(cutoff)) {
          toDelete.add(file.path);
        }
      }
    }

    // Apply count rule per type
    if (policy.maxFilesPerType != null) {
      for (final entry in filesByKind.entries) {
        final filesOfKind = entry.value;
        if (filesOfKind.length > policy.maxFilesPerType!) {
          // Keep the newest N files, delete the rest
          filesOfKind.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          for (int i = policy.maxFilesPerType!; i < filesOfKind.length; i++) {
            if (!toDelete.contains(filesOfKind[i].path)) {
              toDelete.add(filesOfKind[i].path);
            }
          }
        }
      }
    }

    // Apply total size rule (optional, delete oldest first)
    if (policy.maxTotalSizeMB != null) {
      final maxBytes = policy.maxTotalSizeMB! * 1024 * 1024;
      int totalSize = files.fold(0, (sum, file) => sum + file.sizeBytes);

      if (totalSize > maxBytes) {
        // Sort by creation date, oldest first
        final sortedFiles = List<ManagedFile>.from(files)
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

        for (final file in sortedFiles) {
          if (totalSize <= maxBytes) break;
          if (!toDelete.contains(file.path)) {
            toDelete.add(file.path);
            totalSize -= file.sizeBytes;
          }
        }
      }
    }

    return await deleteFiles(toDelete);
  }

  /// Calculates total storage used by managed files.
  Future<int> getTotalStorageBytes() async {
    final files = await listFiles();
    return files.fold<int>(0, (sum, file) => sum + file.sizeBytes);
  }
}

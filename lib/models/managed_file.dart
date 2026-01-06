/// Model for files managed by the file manager.
library;

/// Type of managed file.
enum FileKind {
  /// JSON export file.
  exportJson,

  /// CSV export file.
  exportCsv,

  /// PDF doctor report.
  reportPdf,

  /// Unknown or unrecognized file type.
  unknown;

  /// Returns a user-friendly display name for this file kind.
  String get displayName {
    switch (this) {
      case FileKind.exportJson:
        return 'JSON Export';
      case FileKind.exportCsv:
        return 'CSV Export';
      case FileKind.reportPdf:
        return 'PDF Report';
      case FileKind.unknown:
        return 'Unknown';
    }
  }

  /// Returns the file extension for this kind (without dot).
  String? get extension {
    switch (this) {
      case FileKind.exportJson:
        return 'json';
      case FileKind.exportCsv:
        return 'csv';
      case FileKind.reportPdf:
        return 'pdf';
      case FileKind.unknown:
        return null;
    }
  }
}

/// Represents a file managed by the app (export or report).
class ManagedFile {
  /// Absolute path to the file.
  final String path;

  /// File name (without directory path).
  final String name;

  /// File size in bytes.
  final int sizeBytes;

  /// Creation date of the file.
  final DateTime createdAt;

  /// Type of file.
  final FileKind kind;

  /// Profile name extracted from filename (if available).
  final String? profileName;

  ManagedFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.createdAt,
    required this.kind,
    this.profileName,
  });

  /// Returns a human-readable file size string.
  String get formattedSize {
    if (sizeBytes < 1024) {
      return '$sizeBytes B';
    } else if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  /// Returns sharing text appropriate for this file type.
  String get shareText {
    switch (kind) {
      case FileKind.exportJson:
      case FileKind.exportCsv:
        return 'Sensitive health data – Blood Pressure Export';
      case FileKind.reportPdf:
        return 'Blood Pressure Report';
      case FileKind.unknown:
        return 'HealthLog File';
    }
  }
}

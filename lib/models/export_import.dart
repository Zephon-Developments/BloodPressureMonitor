/// Data Transfer Objects for Export and Import operations.
library;

/// Metadata for an export file.
class ExportMetadata {
  /// Version of the export format.
  final int version;

  /// Timestamp when the export was created.
  final DateTime exportedAt;

  /// Version of the app that created the export.
  final String appVersion;

  /// ID of the profile the data belongs to.
  final int profileId;

  /// Local timezone offset in minutes at time of export.
  final int timezoneOffset;

  ExportMetadata({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.profileId,
    required this.timezoneOffset,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'profileId': profileId,
      'timezoneOffset': timezoneOffset,
    };
  }

  factory ExportMetadata.fromMap(Map<String, dynamic> map) {
    return ExportMetadata(
      version: map['version'] as int,
      exportedAt: DateTime.parse(map['exportedAt'] as String),
      appVersion: map['appVersion'] as String,
      profileId: map['profileId'] as int,
      timezoneOffset: map['timezoneOffset'] as int,
    );
  }
}

/// Result of an import operation.
class ImportResult {
  /// Number of readings successfully imported.
  final int readingsImported;

  /// Number of weight entries successfully imported.
  final int weightsImported;

  /// Number of sleep logs successfully imported.
  final int sleepLogsImported;

  /// Number of medications successfully imported.
  final int medicationsImported;

  /// Number of medication intakes successfully imported.
  final int intakesImported;

  /// Number of records skipped due to duplicates.
  final int duplicatesSkipped;

  /// List of errors encountered during import.
  final List<ImportError> errors;

  ImportResult({
    this.readingsImported = 0,
    this.weightsImported = 0,
    this.sleepLogsImported = 0,
    this.medicationsImported = 0,
    this.intakesImported = 0,
    this.duplicatesSkipped = 0,
    this.errors = const [],
  });

  /// Total number of records successfully imported.
  int get totalImported =>
      readingsImported +
      weightsImported +
      sleepLogsImported +
      medicationsImported +
      intakesImported;

  bool get hasErrors => errors.isNotEmpty;
}

/// Conflict resolution mode for import.
enum ImportConflictMode {
  /// Wipe existing data of the same type before importing.
  overwrite,

  /// Merge with existing data, skipping duplicates.
  append,
}

/// Error encountered during import of a specific row.
class ImportError {
  /// Row number where the error occurred (1-indexed).
  final int row;

  /// Type of data being imported (e.g., "Reading", "Weight").
  final String dataType;

  /// Error message.
  final String message;

  ImportError({
    required this.row,
    required this.dataType,
    required this.message,
  });

  @override
  String toString() => 'Row $row ($dataType): $message';
}

/// Metadata for a generated report.
class ReportMetadata {
  /// Profile name the report is for.
  final String profileName;

  /// Start date of the report range.
  final DateTime startDate;

  /// End date of the report range.
  final DateTime endDate;

  /// Timestamp when the report was generated.
  final DateTime generatedAt;

  ReportMetadata({
    required this.profileName,
    required this.startDate,
    required this.endDate,
    required this.generatedAt,
  });
}

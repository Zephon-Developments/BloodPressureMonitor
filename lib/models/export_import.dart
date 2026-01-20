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

  /// Name of the profile the data belongs to.
  final String? profileName;

  /// Date of birth of the profile owner (PHI - Protected Health Information).
  final DateTime? dateOfBirth;

  /// Patient identifier (e.g., NHS number) (PHI - Protected Health Information).
  final String? patientId;

  /// Primary care doctor's full name (PHI - Protected Health Information).
  final String? doctorName;

  /// Clinic or hospital name (PHI - Protected Health Information).
  final String? clinicName;

  ExportMetadata({
    required this.version,
    required this.exportedAt,
    required this.appVersion,
    required this.profileId,
    required this.timezoneOffset,
    this.profileName,
    this.dateOfBirth,
    this.patientId,
    this.doctorName,
    this.clinicName,
  });

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'exportedAt': exportedAt.toIso8601String(),
      'appVersion': appVersion,
      'profileId': profileId,
      'timezoneOffset': timezoneOffset,
      if (profileName != null) 'profileName': profileName,
      if (dateOfBirth != null) 'dateOfBirth': dateOfBirth!.toIso8601String(),
      if (patientId != null) 'patientId': patientId,
      if (doctorName != null) 'doctorName': doctorName,
      if (clinicName != null) 'clinicName': clinicName,
    };
  }

  factory ExportMetadata.fromMap(Map<String, dynamic> map) {
    return ExportMetadata(
      version: map['version'] as int,
      exportedAt: DateTime.parse(map['exportedAt'] as String),
      appVersion: map['appVersion'] as String,
      profileId: map['profileId'] as int,
      timezoneOffset: map['timezoneOffset'] as int,
      profileName: map['profileName'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      patientId: map['patientId'] as String?,
      doctorName: map['doctorName'] as String?,
      clinicName: map['clinicName'] as String?,
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

  /// Profile information from the import file (if available).
  final ImportProfileInfo? profileInfo;

  ImportResult({
    this.readingsImported = 0,
    this.weightsImported = 0,
    this.sleepLogsImported = 0,
    this.medicationsImported = 0,
    this.intakesImported = 0,
    this.duplicatesSkipped = 0,
    this.errors = const [],
    this.profileInfo,
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

/// Profile information extracted from an import file.
class ImportProfileInfo {
  /// Name of the profile from the import file.
  final String? profileName;

  /// Date of birth from the import file.
  final DateTime? dateOfBirth;

  /// Patient ID from the import file.
  final String? patientId;

  /// Doctor name from the import file.
  final String? doctorName;

  /// Clinic name from the import file.
  final String? clinicName;

  const ImportProfileInfo({
    this.profileName,
    this.dateOfBirth,
    this.patientId,
    this.doctorName,
    this.clinicName,
  });

  /// Creates an [ImportProfileInfo] from export metadata.
  factory ImportProfileInfo.fromMetadata(ExportMetadata metadata) {
    return ImportProfileInfo(
      profileName: metadata.profileName,
      dateOfBirth: metadata.dateOfBirth,
      patientId: metadata.patientId,
      doctorName: metadata.doctorName,
      clinicName: metadata.clinicName,
    );
  }
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

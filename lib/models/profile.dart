/// Profile model representing a user in the HealthLog app.
///
/// Each profile can have multiple readings, medications, and other health data.
/// Profiles are isolated from each other to support multi-user tracking.
class Profile {
  /// Unique identifier for the profile.
  final int? id;

  /// Display name for the profile.
  final String name;

  /// Optional color code for visual identification (hex format).
  final String? colorHex;

  /// Optional avatar/icon identifier.
  final String? avatarIcon;

  /// Optional full date of birth for medical reports and precise age calculation.
  ///
  /// This is Protected Health Information (PHI) and is stored encrypted.
  final DateTime? dateOfBirth;

  /// Optional patient identifier (e.g., NHS number, medical record number).
  ///
  /// This is Protected Health Information (PHI) and is stored encrypted.
  final String? patientId;

  /// Optional primary care doctor's full name for medical reports.
  ///
  /// This is Protected Health Information (PHI) and is stored encrypted.
  final String? doctorName;

  /// Optional clinic or hospital name for medical reports.
  ///
  /// This is Protected Health Information (PHI) and is stored encrypted.
  final String? clinicName;

  /// Preferred units for blood pressure: 'mmHg' or 'kPa'.
  final String preferredUnits;

  /// Preferred units for weight: 'kg' or 'lbs'.
  final String preferredWeightUnit;

  /// Timestamp when the profile was created (UTC).
  final DateTime createdAt;

  /// Creates a new [Profile] instance.
  ///
  /// [name] is required and should be non-empty.
  /// [preferredUnits] defaults to 'mmHg'.
  Profile({
    this.id,
    required this.name,
    this.colorHex,
    this.avatarIcon,
    this.dateOfBirth,
    this.patientId,
    this.doctorName,
    this.clinicName,
    this.preferredUnits = 'mmHg',
    this.preferredWeightUnit = 'kg',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  /// Creates a [Profile] from a database map.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String?,
      avatarIcon: map['avatarIcon'] as String?,
      dateOfBirth: map['dateOfBirth'] != null
          ? _parseDateOnly(map['dateOfBirth'] as String)
          : null,
      patientId: map['patientId'] as String?,
      doctorName: map['doctorName'] as String?,
      clinicName: map['clinicName'] as String?,
      preferredUnits: map['preferredUnits'] as String? ?? 'mmHg',
      preferredWeightUnit: map['preferredWeightUnit'] as String? ?? 'kg',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this [Profile] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'colorHex': colorHex,
      'avatarIcon': avatarIcon,
      'dateOfBirth': dateOfBirth != null ? _formatDateOnly(dateOfBirth!) : null,
      'patientId': patientId,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'preferredUnits': preferredUnits,
      'preferredWeightUnit': preferredWeightUnit,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Profile] with the given fields replaced.
  ///
  /// To explicitly set a nullable field to null, pass the special value
  /// `Object()` is not used. Instead, if a parameter is provided (even if null),
  /// it will be used. Only omitted parameters will preserve existing values.
  ///
  /// For nullable fields that need to be cleared, you can pass `null` directly
  /// when calling this method with named parameters.
  Profile copyWith({
    Object? id = _undefined,
    Object? name = _undefined,
    Object? colorHex = _undefined,
    Object? avatarIcon = _undefined,
    Object? dateOfBirth = _undefined,
    Object? patientId = _undefined,
    Object? doctorName = _undefined,
    Object? clinicName = _undefined,
    Object? preferredUnits = _undefined,
    Object? preferredWeightUnit = _undefined,
    Object? createdAt = _undefined,
  }) {
    return Profile(
      id: identical(id, _undefined) ? this.id : id as int?,
      name: identical(name, _undefined) ? this.name : name as String,
      colorHex:
          identical(colorHex, _undefined) ? this.colorHex : colorHex as String?,
      avatarIcon: identical(avatarIcon, _undefined)
          ? this.avatarIcon
          : avatarIcon as String?,
      dateOfBirth: identical(dateOfBirth, _undefined)
          ? this.dateOfBirth
          : dateOfBirth as DateTime?,
      patientId: identical(patientId, _undefined)
          ? this.patientId
          : patientId as String?,
      doctorName: identical(doctorName, _undefined)
          ? this.doctorName
          : doctorName as String?,
      clinicName: identical(clinicName, _undefined)
          ? this.clinicName
          : clinicName as String?,
      preferredUnits: identical(preferredUnits, _undefined)
          ? this.preferredUnits
          : preferredUnits as String,
      preferredWeightUnit: identical(preferredWeightUnit, _undefined)
          ? this.preferredWeightUnit
          : preferredWeightUnit as String,
      createdAt: identical(createdAt, _undefined)
          ? this.createdAt
          : createdAt as DateTime,
    );
  }

  /// Sentinel value for [copyWith] to distinguish between null and omitted parameters.
  static const _undefined = Object();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        other.avatarIcon == avatarIcon &&
        other.dateOfBirth == dateOfBirth &&
        other.patientId == patientId &&
        other.doctorName == doctorName &&
        other.clinicName == clinicName &&
        other.preferredUnits == preferredUnits &&
        other.preferredWeightUnit == preferredWeightUnit &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      colorHex,
      avatarIcon,
      dateOfBirth,
      patientId,
      doctorName,
      clinicName,
      preferredUnits,
      preferredWeightUnit,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, units: $preferredUnits)';
  }

  /// Parses a date-only string (YYYY-MM-DD) to a DateTime normalized to UTC midnight.
  ///
  /// This ensures timezone-safe handling of dates of birth by always storing
  /// them as UTC midnight, eliminating edge cases where timezone conversions
  /// could shift the date by +/- 1 day.
  static DateTime _parseDateOnly(String dateString) {
    // Parse YYYY-MM-DD format and create UTC midnight DateTime
    final parts = dateString.split('-');
    if (parts.length != 3) {
      throw FormatException(
        'Invalid date format: $dateString. Expected YYYY-MM-DD',
      );
    }
    return DateTime.utc(
      int.parse(parts[0]), // year
      int.parse(parts[1]), // month
      int.parse(parts[2]), // day
    );
  }

  /// Formats a DateTime as a date-only string (YYYY-MM-DD).
  ///
  /// Extracts only the date portion, ignoring time and timezone information.
  static String _formatDateOnly(DateTime date) {
    // Format as YYYY-MM-DD using UTC components to avoid timezone shifts
    final utcDate = date.toUtc();
    return '${utcDate.year.toString().padLeft(4, '0')}-'
        '${utcDate.month.toString().padLeft(2, '0')}-'
        '${utcDate.day.toString().padLeft(2, '0')}';
  }
}

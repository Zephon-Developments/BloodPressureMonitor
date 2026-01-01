/// Profile model representing a user in the HyperTrack app.
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

  /// Optional year of birth for age-related context.
  final int? yearOfBirth;

  /// Optional full date of birth for medical reports and precise age calculation.
  ///
  /// This is Protected Health Information (PHI) and is stored encrypted.
  /// When set, takes precedence over [yearOfBirth] for age calculations.
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

  /// Preferred units: 'mmHg' or 'kPa'.
  final String preferredUnits;

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
    this.yearOfBirth,
    this.dateOfBirth,
    this.patientId,
    this.doctorName,
    this.clinicName,
    this.preferredUnits = 'mmHg',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().toUtc();

  /// Creates a [Profile] from a database map.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorHex: map['colorHex'] as String?,
      avatarIcon: map['avatarIcon'] as String?,
      yearOfBirth: map['yearOfBirth'] as int?,
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.parse(map['dateOfBirth'] as String)
          : null,
      patientId: map['patientId'] as String?,
      doctorName: map['doctorName'] as String?,
      clinicName: map['clinicName'] as String?,
      preferredUnits: map['preferredUnits'] as String? ?? 'mmHg',
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
      'yearOfBirth': yearOfBirth,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'patientId': patientId,
      'doctorName': doctorName,
      'clinicName': clinicName,
      'preferredUnits': preferredUnits,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Profile] with the given fields replaced.
  Profile copyWith({
    int? id,
    String? name,
    String? colorHex,
    String? avatarIcon,
    int? yearOfBirth,
    DateTime? dateOfBirth,
    String? patientId,
    String? doctorName,
    String? clinicName,
    String? preferredUnits,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      yearOfBirth: yearOfBirth ?? this.yearOfBirth,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      patientId: patientId ?? this.patientId,
      doctorName: doctorName ?? this.doctorName,
      clinicName: clinicName ?? this.clinicName,
      preferredUnits: preferredUnits ?? this.preferredUnits,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Profile &&
        other.id == id &&
        other.name == name &&
        other.colorHex == colorHex &&
        other.avatarIcon == avatarIcon &&
        other.yearOfBirth == yearOfBirth &&
        other.dateOfBirth == dateOfBirth &&
        other.patientId == patientId &&
        other.doctorName == doctorName &&
        other.clinicName == clinicName &&
        other.preferredUnits == preferredUnits &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      colorHex,
      avatarIcon,
      yearOfBirth,
      dateOfBirth,
      patientId,
      doctorName,
      clinicName,
      preferredUnits,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, units: $preferredUnits)';
  }
}

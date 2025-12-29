/// Profile model representing a user in the blood pressure monitoring app.
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
    String? preferredUnits,
    DateTime? createdAt,
  }) {
    return Profile(
      id: id ?? this.id,
      name: name ?? this.name,
      colorHex: colorHex ?? this.colorHex,
      avatarIcon: avatarIcon ?? this.avatarIcon,
      yearOfBirth: yearOfBirth ?? this.yearOfBirth,
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
      preferredUnits,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Profile(id: $id, name: $name, units: $preferredUnits)';
  }
}

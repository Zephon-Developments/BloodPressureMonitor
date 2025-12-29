/// Medication model representing a drug that a profile takes.
///
/// Medications can be grouped together and have intake records.
class Medication {
  /// Unique identifier for the medication.
  final int? id;

  /// Profile this medication belongs to.
  final int profileId;

  /// Name of the medication.
  final String name;

  /// Dosage information (e.g., "10mg", "2 tablets").
  final String? dosage;

  /// Optional schedule metadata (e.g., "8:00 AM daily").
  final String? schedule;

  /// Optional notes about the medication.
  final String? notes;

  /// Creates a new [Medication] instance.
  Medication({
    this.id,
    required this.profileId,
    required this.name,
    this.dosage,
    this.schedule,
    this.notes,
  });

  /// Creates a [Medication] from a database map.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      schedule: map['schedule'] as String?,
      notes: map['notes'] as String?,
    );
  }

  /// Converts this [Medication] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'name': name,
      'dosage': dosage,
      'schedule': schedule,
      'notes': notes,
    };
  }

  /// Creates a copy of this [Medication] with the given fields replaced.
  Medication copyWith({
    int? id,
    int? profileId,
    String? name,
    String? dosage,
    String? schedule,
    String? notes,
  }) {
    return Medication(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      schedule: schedule ?? this.schedule,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Medication &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        other.dosage == dosage &&
        other.schedule == schedule &&
        other.notes == notes;
  }

  @override
  int get hashCode {
    return Object.hash(id, profileId, name, dosage, schedule, notes);
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage)';
  }
}

/// Medication group for quick logging of multiple medications together.
///
/// Example: "Morning meds" group containing several medications.
class MedicationGroup {
  /// Unique identifier for the group.
  final int? id;

  /// Profile this group belongs to.
  final int profileId;

  /// Name of the group (e.g., "Morning meds").
  final String name;

  /// IDs of medications in this group.
  final List<int> medicationIds;

  /// Creates a new [MedicationGroup] instance.
  MedicationGroup({
    this.id,
    required this.profileId,
    required this.name,
    required this.medicationIds,
  });

  /// Creates a [MedicationGroup] from a database map.
  ///
  /// The [medicationIds] are stored as a comma-separated string in the database.
  factory MedicationGroup.fromMap(Map<String, dynamic> map) {
    final idsString = map['medicationIds'] as String;
    final ids = idsString.isEmpty
        ? <int>[]
        : idsString.split(',').map((e) => int.parse(e)).toList();

    return MedicationGroup(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      name: map['name'] as String,
      medicationIds: ids,
    );
  }

  /// Converts this [MedicationGroup] to a database map.
  ///
  /// The [medicationIds] are stored as a comma-separated string.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'name': name,
      'medicationIds': medicationIds.join(','),
    };
  }

  /// Creates a copy of this [MedicationGroup] with the given fields replaced.
  MedicationGroup copyWith({
    int? id,
    int? profileId,
    String? name,
    List<int>? medicationIds,
  }) {
    return MedicationGroup(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      medicationIds: medicationIds ?? this.medicationIds,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationGroup &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        _listEquals(other.medicationIds, medicationIds);
  }

  @override
  int get hashCode {
    return Object.hash(id, profileId, name, Object.hashAll(medicationIds));
  }

  @override
  String toString() {
    return 'MedicationGroup(id: $id, name: $name, meds: ${medicationIds.length})';
  }

  bool _listEquals(List a, List b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Record of a medication intake at a specific time.
class MedicationIntake {
  /// Unique identifier for the intake record.
  final int? id;

  /// Profile this intake belongs to.
  final int profileId;

  /// ID of the medication taken.
  final int medicationId;

  /// Timestamp when the medication was taken (UTC).
  final DateTime takenAt;

  /// Optional group ID if this was part of a group intake.
  final int? groupId;

  /// Optional notes about this intake.
  final String? note;

  /// Creates a new [MedicationIntake] instance.
  MedicationIntake({
    this.id,
    required this.profileId,
    required this.medicationId,
    required this.takenAt,
    this.groupId,
    this.note,
  });

  /// Creates a [MedicationIntake] from a database map.
  factory MedicationIntake.fromMap(Map<String, dynamic> map) {
    return MedicationIntake(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      medicationId: map['medicationId'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      groupId: map['groupId'] as int?,
      note: map['note'] as String?,
    );
  }

  /// Converts this [MedicationIntake] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'medicationId': medicationId,
      'takenAt': takenAt.toIso8601String(),
      'groupId': groupId,
      'note': note,
    };
  }

  /// Creates a copy of this [MedicationIntake] with the given fields replaced.
  MedicationIntake copyWith({
    int? id,
    int? profileId,
    int? medicationId,
    DateTime? takenAt,
    int? groupId,
    String? note,
  }) {
    return MedicationIntake(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medicationId: medicationId ?? this.medicationId,
      takenAt: takenAt ?? this.takenAt,
      groupId: groupId ?? this.groupId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationIntake &&
        other.id == id &&
        other.profileId == profileId &&
        other.medicationId == medicationId &&
        other.takenAt == takenAt &&
        other.groupId == groupId &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(id, profileId, medicationId, takenAt, groupId, note);
  }

  @override
  String toString() {
    return 'MedicationIntake(id: $id, medId: $medicationId, at: $takenAt)';
  }
}

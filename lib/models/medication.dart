import 'dart:convert';

/// Medication model representing a drug that a profile takes.
///
/// Medications can be grouped together and have intake records tracked.
/// Schedule metadata is stored as JSON to support flexible scheduling formats.
class Medication {
  /// Unique identifier for the medication.
  final int? id;

  /// Profile this medication belongs to.
  final int profileId;

  /// Name of the medication (required).
  final String name;

  /// Optional dosage information (e.g., "10mg", "2 tablets").
  final String? dosage;

  /// Optional unit for dosage (e.g., "mg", "tablets", "mL").
  final String? unit;

  /// Optional frequency description (e.g., "twice daily", "as needed").
  final String? frequency;

  /// Optional schedule metadata as JSON string.
  ///
  /// Format: `{"v": 1, "frequency": "daily", "times": ["08:00", "20:00"],
  /// "daysOfWeek": [1,2,3,4,5,6,7], "graceMinutesLate": 120,
  /// "graceMinutesMissed": 240}`
  final String? scheduleMetadata;

  /// Timestamp when this medication was created (ISO8601 with offset).
  final DateTime createdAt;

  /// Creates a new [Medication] instance.
  Medication({
    this.id,
    required this.profileId,
    required this.name,
    this.dosage,
    this.unit,
    this.frequency,
    this.scheduleMetadata,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a [Medication] from a database map.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      name: map['name'] as String,
      dosage: map['dosage'] as String?,
      unit: map['unit'] as String?,
      frequency: map['frequency'] as String?,
      scheduleMetadata: map['scheduleMetadata'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this [Medication] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'name': name,
      'dosage': dosage,
      'unit': unit,
      'frequency': frequency,
      'scheduleMetadata': scheduleMetadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [Medication] with the given fields replaced.
  Medication copyWith({
    int? id,
    int? profileId,
    String? name,
    String? dosage,
    String? unit,
    String? frequency,
    String? scheduleMetadata,
    DateTime? createdAt,
  }) {
    return Medication(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      unit: unit ?? this.unit,
      frequency: frequency ?? this.frequency,
      scheduleMetadata: scheduleMetadata ?? this.scheduleMetadata,
      createdAt: createdAt ?? this.createdAt,
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
        other.unit == unit &&
        other.frequency == frequency &&
        other.scheduleMetadata == scheduleMetadata &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      dosage,
      unit,
      frequency,
      scheduleMetadata,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, name: $name, dosage: $dosage, unit: $unit)';
  }
}

/// Medication group for quick logging of multiple medications together.
///
/// Example: "Morning meds" group containing several medications.
/// Member medication IDs are stored as a sorted JSON array for consistency.
class MedicationGroup {
  /// Unique identifier for the group.
  final int? id;

  /// Profile this group belongs to.
  final int profileId;

  /// Name of the group (e.g., "Morning meds").
  final String name;

  /// IDs of medications in this group (sorted and unique).
  final List<int> memberMedicationIds;

  /// Timestamp when this group was created (ISO8601 with offset).
  final DateTime createdAt;

  /// Creates a new [MedicationGroup] instance.
  ///
  /// Automatically sorts and deduplicates [memberMedicationIds].
  MedicationGroup({
    this.id,
    required this.profileId,
    required this.name,
    required List<int> memberMedicationIds,
    DateTime? createdAt,
  })  : memberMedicationIds = _normalizeMemberIds(memberMedicationIds),
        createdAt = createdAt ?? DateTime.now();

  /// Normalizes member IDs by removing duplicates and sorting.
  static List<int> _normalizeMemberIds(List<int> ids) {
    final uniqueIds = ids.toSet().toList();
    uniqueIds.sort();
    return uniqueIds;
  }

  /// Creates a [MedicationGroup] from a database map.
  ///
  /// The [memberMedicationIds] are stored as a JSON array string.
  factory MedicationGroup.fromMap(Map<String, dynamic> map) {
    final idsString = map['memberMedicationIds'] as String;
    final ids = idsString.isEmpty
        ? <int>[]
        : (jsonDecode(idsString) as List).cast<int>();

    return MedicationGroup(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      name: map['name'] as String,
      memberMedicationIds: ids,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this [MedicationGroup] to a database map.
  ///
  /// The [memberMedicationIds] are stored as a JSON array string.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'name': name,
      'memberMedicationIds': jsonEncode(memberMedicationIds),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [MedicationGroup] with the given fields replaced.
  ///
  /// Automatically normalizes [memberMedicationIds] if provided.
  MedicationGroup copyWith({
    int? id,
    int? profileId,
    String? name,
    List<int>? memberMedicationIds,
    DateTime? createdAt,
  }) {
    return MedicationGroup(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      memberMedicationIds: memberMedicationIds ?? this.memberMedicationIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationGroup &&
        other.id == id &&
        other.profileId == profileId &&
        other.name == name &&
        _listEquals(other.memberMedicationIds, memberMedicationIds) &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      name,
      Object.hashAll(memberMedicationIds),
      createdAt,
    );
  }

  @override
  String toString() {
    return 'MedicationGroup(id: $id, name: $name, '
        'meds: ${memberMedicationIds.length})';
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
///
/// Supports tracking both individual and group intakes, with optional
/// scheduling information for late/missed classification.
class MedicationIntake {
  /// Unique identifier for the intake record.
  final int? id;

  /// ID of the medication taken.
  final int medicationId;

  /// Profile this intake belongs to.
  final int profileId;

  /// Timestamp when the medication was taken (ISO8601 with offset).
  final DateTime takenAt;

  /// Local time zone offset in minutes at time of intake.
  final int localOffsetMinutes;

  /// Optional scheduled time for this intake (ISO8601).
  ///
  /// Used to calculate late/missed status relative to schedule.
  final DateTime? scheduledFor;

  /// Optional group ID if this was part of a group intake.
  final int? groupId;

  /// Optional notes about this intake.
  final String? note;

  /// Creates a new [MedicationIntake] instance.
  MedicationIntake({
    this.id,
    required this.medicationId,
    required this.profileId,
    required this.takenAt,
    int? localOffsetMinutes,
    this.scheduledFor,
    this.groupId,
    this.note,
  }) : localOffsetMinutes =
            localOffsetMinutes ?? takenAt.timeZoneOffset.inMinutes;

  /// Creates a [MedicationIntake] from a database map.
  factory MedicationIntake.fromMap(Map<String, dynamic> map) {
    return MedicationIntake(
      id: map['id'] as int?,
      medicationId: map['medicationId'] as int,
      profileId: map['profileId'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      localOffsetMinutes: map['localOffsetMinutes'] as int,
      scheduledFor: map['scheduledFor'] != null
          ? DateTime.parse(map['scheduledFor'] as String)
          : null,
      groupId: map['groupId'] as int?,
      note: map['note'] as String?,
    );
  }

  /// Converts this [MedicationIntake] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'medicationId': medicationId,
      'profileId': profileId,
      'takenAt': takenAt.toIso8601String(),
      'localOffsetMinutes': localOffsetMinutes,
      if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
      'groupId': groupId,
      'note': note,
    };
  }

  /// Creates a copy of this [MedicationIntake] with the given fields replaced.
  MedicationIntake copyWith({
    int? id,
    int? medicationId,
    int? profileId,
    DateTime? takenAt,
    int? localOffsetMinutes,
    DateTime? scheduledFor,
    int? groupId,
    String? note,
  }) {
    return MedicationIntake(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      profileId: profileId ?? this.profileId,
      takenAt: takenAt ?? this.takenAt,
      localOffsetMinutes: localOffsetMinutes ?? this.localOffsetMinutes,
      scheduledFor: scheduledFor ?? this.scheduledFor,
      groupId: groupId ?? this.groupId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MedicationIntake &&
        other.id == id &&
        other.medicationId == medicationId &&
        other.profileId == profileId &&
        other.takenAt == takenAt &&
        other.localOffsetMinutes == localOffsetMinutes &&
        other.scheduledFor == scheduledFor &&
        other.groupId == groupId &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      medicationId,
      profileId,
      takenAt,
      localOffsetMinutes,
      scheduledFor,
      groupId,
      note,
    );
  }

  @override
  String toString() {
    return 'MedicationIntake(id: $id, medId: $medicationId, '
        'at: $takenAt, group: $groupId)';
  }
}

/// Status of a medication intake relative to its schedule.
enum IntakeStatus {
  /// Taken within the scheduled time window.
  onTime,

  /// Taken late but within the grace period.
  late,

  /// Taken after the missed grace period.
  missed,

  /// No schedule information available.
  unscheduled,
}

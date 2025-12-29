/// Blood pressure reading model representing a single measurement.
///
/// Readings are associated with a profile and can be grouped together
/// using a 30-minute rolling window for averaging.
class Reading {
  /// Unique identifier for the reading.
  final int? id;

  /// Profile this reading belongs to.
  final int profileId;

  /// Systolic blood pressure in mmHg (upper number).
  ///
  /// Normal range: 90-120 mmHg. Valid range: 70-250 mmHg.
  final int systolic;

  /// Diastolic blood pressure in mmHg (lower number).
  ///
  /// Normal range: 60-80 mmHg. Valid range: 40-150 mmHg.
  final int diastolic;

  /// Pulse rate in beats per minute.
  ///
  /// Normal range: 60-100 bpm. Valid range: 30-200 bpm.
  final int pulse;

  /// Timestamp when the reading was taken (UTC).
  final DateTime takenAt;

  /// Local UTC offset in minutes at time of reading.
  final int localOffsetMinutes;

  /// Posture when reading was taken (e.g., "sitting", "lying").
  final String? posture;

  /// Arm used for measurement (e.g., "left", "right").
  final String? arm;

  /// References to medication intakes relevant to this reading.
  ///
  /// Stored as comma-separated intake IDs.
  final String? medsContext;

  /// Whether the device detected an irregular heartbeat.
  final bool irregularFlag;

  /// Optional tags (comma-separated: e.g., "fasting,stressed").
  final String? tags;

  /// Optional notes for this reading.
  final String? note;

  /// Creates a new [Reading] instance.
  Reading({
    this.id,
    required this.profileId,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.takenAt,
    required this.localOffsetMinutes,
    this.posture,
    this.arm,
    this.medsContext,
    this.irregularFlag = false,
    this.tags,
    this.note,
  });

  /// Creates a [Reading] from a database map.
  factory Reading.fromMap(Map<String, dynamic> map) {
    final tagsStr = map['tags'] as String?;
    return Reading(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      localOffsetMinutes: map['localOffsetMinutes'] as int,
      posture: map['posture'] as String?,
      arm: map['arm'] as String?,
      medsContext: map['medsContext'] as String?,
      irregularFlag: (map['irregularFlag'] as int) == 1,
      tags: (tagsStr == null || tagsStr.isEmpty) ? null : tagsStr,
      note: map['note'] as String?,
    );
  }

  /// Converts this [Reading] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'takenAt': takenAt.toIso8601String(),
      'localOffsetMinutes': localOffsetMinutes,
      'posture': posture,
      'arm': arm,
      'medsContext': medsContext,
      'irregularFlag': irregularFlag ? 1 : 0,
      'tags': tags,
      'note': note,
    };
  }

  /// Creates a copy of this [Reading] with the given fields replaced.
  Reading copyWith({
    int? id,
    int? profileId,
    int? systolic,
    int? diastolic,
    int? pulse,
    DateTime? takenAt,
    int? localOffsetMinutes,
    String? posture,
    String? arm,
    String? medsContext,
    bool? irregularFlag,
    String? tags,
    String? note,
  }) {
    return Reading(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      systolic: systolic ?? this.systolic,
      diastolic: diastolic ?? this.diastolic,
      pulse: pulse ?? this.pulse,
      takenAt: takenAt ?? this.takenAt,
      localOffsetMinutes: localOffsetMinutes ?? this.localOffsetMinutes,
      posture: posture ?? this.posture,
      arm: arm ?? this.arm,
      medsContext: medsContext ?? this.medsContext,
      irregularFlag: irregularFlag ?? this.irregularFlag,
      tags: tags ?? this.tags,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reading &&
        other.id == id &&
        other.profileId == profileId &&
        other.systolic == systolic &&
        other.diastolic == diastolic &&
        other.pulse == pulse &&
        other.takenAt == takenAt &&
        other.localOffsetMinutes == localOffsetMinutes &&
        other.posture == posture &&
        other.arm == arm &&
        other.medsContext == medsContext &&
        other.irregularFlag == irregularFlag &&
        other.tags == tags &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      systolic,
      diastolic,
      pulse,
      takenAt,
      localOffsetMinutes,
      posture,
      arm,
      medsContext,
      irregularFlag,
      tags,
      note,
    );
  }

  @override
  String toString() {
    return 'Reading(id: $id, $systolic/$diastolic, pulse: $pulse, at: $takenAt)';
  }
}


/// Averaged group of readings within a 30-minute window.
///
/// Multiple readings taken within 30 minutes are grouped together
/// and their average values are calculated.
class ReadingGroup {
  /// Unique identifier for the group.
  final int? id;

  /// Profile this group belongs to.
  final int profileId;

  /// Timestamp of the first reading in the group (UTC).
  final DateTime groupStartAt;

  /// Window size in minutes (default: 30).
  final int windowMinutes;

  /// Averaged systolic value.
  final double avgSystolic;

  /// Averaged diastolic value.
  final double avgDiastolic;

  /// Averaged pulse value.
  final double avgPulse;

  /// IDs of readings in this group (comma-separated).
  final String memberReadingIds;

  /// Optional manual session ID if "start new session" was used.
  final String? sessionId;

  /// Optional note for the entire group.
  final String? note;

  /// Creates a new [ReadingGroup] instance.
  ReadingGroup({
    this.id,
    required this.profileId,
    required this.groupStartAt,
    this.windowMinutes = 30,
    required this.avgSystolic,
    required this.avgDiastolic,
    required this.avgPulse,
    required this.memberReadingIds,
    this.sessionId,
    this.note,
  });

  /// Creates a [ReadingGroup] from a database map.
  factory ReadingGroup.fromMap(Map<String, dynamic> map) {
    return ReadingGroup(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      groupStartAt: DateTime.parse(map['groupStartAt'] as String),
      windowMinutes: map['windowMinutes'] as int? ?? 30,
      avgSystolic: map['avgSystolic'] as double,
      avgDiastolic: map['avgDiastolic'] as double,
      avgPulse: map['avgPulse'] as double,
      memberReadingIds: map['memberReadingIds'] as String,
      sessionId: map['sessionId'] as String?,
      note: map['note'] as String?,
    );
  }

  /// Converts this [ReadingGroup] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'groupStartAt': groupStartAt.toIso8601String(),
      'windowMinutes': windowMinutes,
      'avgSystolic': avgSystolic,
      'avgDiastolic': avgDiastolic,
      'avgPulse': avgPulse,
      'memberReadingIds': memberReadingIds,
      'sessionId': sessionId,
      'note': note,
    };
  }

  /// Creates a copy of this [ReadingGroup] with the given fields replaced.
  ReadingGroup copyWith({
    int? id,
    int? profileId,
    DateTime? groupStartAt,
    int? windowMinutes,
    double? avgSystolic,
    double? avgDiastolic,
    double? avgPulse,
    String? memberReadingIds,
    String? sessionId,
    String? note,
  }) {
    return ReadingGroup(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      groupStartAt: groupStartAt ?? this.groupStartAt,
      windowMinutes: windowMinutes ?? this.windowMinutes,
      avgSystolic: avgSystolic ?? this.avgSystolic,
      avgDiastolic: avgDiastolic ?? this.avgDiastolic,
      avgPulse: avgPulse ?? this.avgPulse,
      memberReadingIds: memberReadingIds ?? this.memberReadingIds,
      sessionId: sessionId ?? this.sessionId,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReadingGroup &&
        other.id == id &&
        other.profileId == profileId &&
        other.groupStartAt == groupStartAt &&
        other.windowMinutes == windowMinutes &&
        other.avgSystolic == avgSystolic &&
        other.avgDiastolic == avgDiastolic &&
        other.avgPulse == avgPulse &&
        other.memberReadingIds == memberReadingIds &&
        other.sessionId == sessionId &&
        other.note == note;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      groupStartAt,
      windowMinutes,
      avgSystolic,
      avgDiastolic,
      avgPulse,
      memberReadingIds,
      sessionId,
      note,
    );
  }

  @override
  String toString() {
    return 'ReadingGroup(id: $id, avg: ${avgSystolic.toStringAsFixed(1)}/${avgDiastolic.toStringAsFixed(1)}, members: $memberReadingIds)';
  }
}

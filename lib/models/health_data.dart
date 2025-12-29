/// Weight entry model for tracking weight and lifestyle factors.
///
/// Supports optional contextual notes about salt intake, exercise,
/// sleep quality, and stress levels.
class WeightEntry {
  /// Unique identifier for the weight entry.
  final int? id;

  /// Profile this entry belongs to.
  final int profileId;

  /// Timestamp when the weight was recorded (UTC).
  final DateTime takenAt;

  /// Weight value in kilograms.
  final double weight;

  /// Optional note about salt intake.
  final String? saltNote;

  /// Optional note about exercise.
  final String? exerciseNote;

  /// Optional sleep quality rating (e.g., "poor", "fair", "good").
  final String? sleepQuality;

  /// Optional stress level rating (e.g., "low", "medium", "high").
  final String? stressLevel;

  /// Creates a new [WeightEntry] instance.
  WeightEntry({
    this.id,
    required this.profileId,
    required this.takenAt,
    required this.weight,
    this.saltNote,
    this.exerciseNote,
    this.sleepQuality,
    this.stressLevel,
  });

  /// Creates a [WeightEntry] from a database map.
  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      weight: map['weight'] as double,
      saltNote: map['saltNote'] as String?,
      exerciseNote: map['exerciseNote'] as String?,
      sleepQuality: map['sleepQuality'] as String?,
      stressLevel: map['stressLevel'] as String?,
    );
  }

  /// Converts this [WeightEntry] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'takenAt': takenAt.toIso8601String(),
      'weight': weight,
      'saltNote': saltNote,
      'exerciseNote': exerciseNote,
      'sleepQuality': sleepQuality,
      'stressLevel': stressLevel,
    };
  }

  /// Creates a copy of this [WeightEntry] with the given fields replaced.
  WeightEntry copyWith({
    int? id,
    int? profileId,
    DateTime? takenAt,
    double? weight,
    String? saltNote,
    String? exerciseNote,
    String? sleepQuality,
    String? stressLevel,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      takenAt: takenAt ?? this.takenAt,
      weight: weight ?? this.weight,
      saltNote: saltNote ?? this.saltNote,
      exerciseNote: exerciseNote ?? this.exerciseNote,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      stressLevel: stressLevel ?? this.stressLevel,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeightEntry &&
        other.id == id &&
        other.profileId == profileId &&
        other.takenAt == takenAt &&
        other.weight == weight &&
        other.saltNote == saltNote &&
        other.exerciseNote == exerciseNote &&
        other.sleepQuality == sleepQuality &&
        other.stressLevel == stressLevel;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      takenAt,
      weight,
      saltNote,
      exerciseNote,
      sleepQuality,
      stressLevel,
    );
  }

  @override
  String toString() {
    return 'WeightEntry(id: $id, weight: ${weight}kg, at: $takenAt)';
  }
}

/// Sleep entry model for tracking sleep data from manual input or device import.
///
/// Stores total sleep time, time in bed, wake count, and optional sleep score.
class SleepEntry {
  /// Unique identifier for the sleep entry.
  final int? id;

  /// Profile this entry belongs to.
  final int profileId;

  /// Date of the night this sleep data represents (e.g., "2025-12-28").
  final String nightOf;

  /// Total sleep time in minutes.
  final int totalSleepMinutes;

  /// Total time in bed in minutes.
  final int timeInBedMinutes;

  /// Number of times woken during the night.
  final int wakeCount;

  /// Optional sleep score or efficiency percentage (0-100).
  final double? sleepScore;

  /// Source of the data (e.g., "manual", "device:FitBit").
  final String source;

  /// Timestamp when this data was imported/entered (UTC).
  final DateTime importedAt;

  /// Creates a new [SleepEntry] instance.
  SleepEntry({
    this.id,
    required this.profileId,
    required this.nightOf,
    required this.totalSleepMinutes,
    required this.timeInBedMinutes,
    required this.wakeCount,
    this.sleepScore,
    required this.source,
    DateTime? importedAt,
  }) : importedAt = importedAt ?? DateTime.now().toUtc();

  /// Creates a [SleepEntry] from a database map.
  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      nightOf: map['nightOf'] as String,
      totalSleepMinutes: map['totalSleepMinutes'] as int,
      timeInBedMinutes: map['timeInBedMinutes'] as int,
      wakeCount: map['wakeCount'] as int,
      sleepScore: map['sleepScore'] as double?,
      source: map['source'] as String,
      importedAt: DateTime.parse(map['importedAt'] as String),
    );
  }

  /// Converts this [SleepEntry] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'nightOf': nightOf,
      'totalSleepMinutes': totalSleepMinutes,
      'timeInBedMinutes': timeInBedMinutes,
      'wakeCount': wakeCount,
      'sleepScore': sleepScore,
      'source': source,
      'importedAt': importedAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [SleepEntry] with the given fields replaced.
  SleepEntry copyWith({
    int? id,
    int? profileId,
    String? nightOf,
    int? totalSleepMinutes,
    int? timeInBedMinutes,
    int? wakeCount,
    double? sleepScore,
    String? source,
    DateTime? importedAt,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      nightOf: nightOf ?? this.nightOf,
      totalSleepMinutes: totalSleepMinutes ?? this.totalSleepMinutes,
      timeInBedMinutes: timeInBedMinutes ?? this.timeInBedMinutes,
      wakeCount: wakeCount ?? this.wakeCount,
      sleepScore: sleepScore ?? this.sleepScore,
      source: source ?? this.source,
      importedAt: importedAt ?? this.importedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepEntry &&
        other.id == id &&
        other.profileId == profileId &&
        other.nightOf == nightOf &&
        other.totalSleepMinutes == totalSleepMinutes &&
        other.timeInBedMinutes == timeInBedMinutes &&
        other.wakeCount == wakeCount &&
        other.sleepScore == sleepScore &&
        other.source == source &&
        other.importedAt == importedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      nightOf,
      totalSleepMinutes,
      timeInBedMinutes,
      wakeCount,
      sleepScore,
      source,
      importedAt,
    );
  }

  @override
  String toString() {
    return 'SleepEntry(id: $id, night: $nightOf, sleep: ${totalSleepMinutes}min)';
  }
}

/// Reminder model for scheduling blood pressure reading reminders.
///
/// Reminders are per-profile and can be active or inactive.
class Reminder {
  /// Unique identifier for the reminder.
  final int? id;

  /// Profile this reminder belongs to.
  final int profileId;

  /// Schedule information (e.g., "daily at 08:00").
  final String schedule;

  /// Whether this reminder is currently active.
  final bool isActive;

  /// Creates a new [Reminder] instance.
  Reminder({
    this.id,
    required this.profileId,
    required this.schedule,
    this.isActive = false,
  });

  /// Creates a [Reminder] from a database map.
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      schedule: map['schedule'] as String,
      isActive: (map['isActive'] as int) == 1,
    );
  }

  /// Converts this [Reminder] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'schedule': schedule,
      'isActive': isActive ? 1 : 0,
    };
  }

  /// Creates a copy of this [Reminder] with the given fields replaced.
  Reminder copyWith({
    int? id,
    int? profileId,
    String? schedule,
    bool? isActive,
  }) {
    return Reminder(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      schedule: schedule ?? this.schedule,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reminder &&
        other.id == id &&
        other.profileId == profileId &&
        other.schedule == schedule &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return Object.hash(id, profileId, schedule, isActive);
  }

  @override
  String toString() {
    return 'Reminder(id: $id, schedule: $schedule, active: $isActive)';
  }
}

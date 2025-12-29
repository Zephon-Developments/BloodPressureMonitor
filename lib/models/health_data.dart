/// Weight unit for measurements.
enum WeightUnit {
  /// Kilograms
  kg,

  /// Pounds
  lbs,
}

/// Extension on WeightUnit for conversion utilities.
extension WeightUnitExtension on WeightUnit {
  /// Converts weight value to kilograms.
  double toKg(double value) {
    switch (this) {
      case WeightUnit.kg:
        return value;
      case WeightUnit.lbs:
        return value * 0.453592;
    }
  }

  /// Converts weight value from kilograms to this unit.
  double fromKg(double kgValue) {
    switch (this) {
      case WeightUnit.kg:
        return kgValue;
      case WeightUnit.lbs:
        return kgValue / 0.453592;
    }
  }

  /// Returns the string representation for database storage.
  String toDbString() {
    switch (this) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
    }
  }

  /// Parses a WeightUnit from database string.
  static WeightUnit fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'kg':
        return WeightUnit.kg;
      case 'lbs':
        return WeightUnit.lbs;
      default:
        return WeightUnit.kg; // Default fallback
    }
  }
}

/// Weight entry model for tracking weight and lifestyle factors.
///
/// Supports optional contextual notes about salt intake, exercise,
/// sleep quality, and stress levels. Stores weight with unit information.
class WeightEntry {
  /// Unique identifier for the weight entry.
  final int? id;

  /// Profile this entry belongs to.
  final int profileId;

  /// Timestamp when the weight was recorded (with timezone).
  final DateTime takenAt;

  /// Local timezone offset in minutes at time of measurement.
  final int localOffsetMinutes;

  /// Weight value (stored as entered, with unit).
  final double weightValue;

  /// Unit of measurement for the weight.
  final WeightUnit unit;

  /// Optional general notes.
  final String? notes;

  /// Optional note about salt intake.
  final String? saltIntake;

  /// Optional note about exercise level.
  final String? exerciseLevel;

  /// Optional stress level rating (e.g., "low", "medium", "high").
  final String? stressLevel;

  /// Optional sleep quality rating (e.g., "poor", "fair", "good").
  final String? sleepQuality;

  /// Source of this entry (manual or import).
  final String source;

  /// Optional source metadata (JSON string for import details).
  final String? sourceMetadata;

  /// Timestamp when this entry was created.
  final DateTime createdAt;

  /// Creates a new [WeightEntry] instance.
  WeightEntry({
    this.id,
    required this.profileId,
    required this.takenAt,
    int? localOffsetMinutes,
    required this.weightValue,
    required this.unit,
    this.notes,
    this.saltIntake,
    this.exerciseLevel,
    this.stressLevel,
    this.sleepQuality,
    this.source = 'manual',
    this.sourceMetadata,
    DateTime? createdAt,
  })  : localOffsetMinutes =
            localOffsetMinutes ?? takenAt.timeZoneOffset.inMinutes,
        createdAt = createdAt ?? DateTime.now();

  /// Creates a [WeightEntry] from a database map.
  factory WeightEntry.fromMap(Map<String, dynamic> map) {
    return WeightEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      takenAt: DateTime.parse(map['takenAt'] as String),
      localOffsetMinutes: map['localOffsetMinutes'] as int,
      weightValue: map['weightValue'] as double,
      unit: WeightUnitExtension.fromDbString(map['unit'] as String),
      notes: map['notes'] as String?,
      saltIntake: map['saltIntake'] as String?,
      exerciseLevel: map['exerciseLevel'] as String?,
      stressLevel: map['stressLevel'] as String?,
      sleepQuality: map['sleepQuality'] as String?,
      source: map['source'] as String? ?? 'manual',
      sourceMetadata: map['sourceMetadata'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this [WeightEntry] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'takenAt': takenAt.toIso8601String(),
      'localOffsetMinutes': localOffsetMinutes,
      'weightValue': weightValue,
      'unit': unit.toDbString(),
      'notes': notes,
      'saltIntake': saltIntake,
      'exerciseLevel': exerciseLevel,
      'stressLevel': stressLevel,
      'sleepQuality': sleepQuality,
      'source': source,
      'sourceMetadata': sourceMetadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Gets weight value in kilograms (converts if needed).
  double get weightInKg => unit.toKg(weightValue);

  /// Gets weight value in pounds (converts if needed).
  double get weightInLbs => WeightUnit.lbs.fromKg(weightInKg);

  /// Creates a copy of this [WeightEntry] with the given fields replaced.
  WeightEntry copyWith({
    int? id,
    int? profileId,
    DateTime? takenAt,
    int? localOffsetMinutes,
    double? weightValue,
    WeightUnit? unit,
    String? notes,
    String? saltIntake,
    String? exerciseLevel,
    String? stressLevel,
    String? sleepQuality,
    String? source,
    String? sourceMetadata,
    DateTime? createdAt,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      takenAt: takenAt ?? this.takenAt,
      localOffsetMinutes: localOffsetMinutes ?? this.localOffsetMinutes,
      weightValue: weightValue ?? this.weightValue,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      saltIntake: saltIntake ?? this.saltIntake,
      exerciseLevel: exerciseLevel ?? this.exerciseLevel,
      stressLevel: stressLevel ?? this.stressLevel,
      sleepQuality: sleepQuality ?? this.sleepQuality,
      source: source ?? this.source,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeightEntry &&
        other.id == id &&
        other.profileId == profileId &&
        other.takenAt == takenAt &&
        other.localOffsetMinutes == localOffsetMinutes &&
        other.weightValue == weightValue &&
        other.unit == unit &&
        other.notes == notes &&
        other.saltIntake == saltIntake &&
        other.exerciseLevel == exerciseLevel &&
        other.stressLevel == stressLevel &&
        other.sleepQuality == sleepQuality &&
        other.source == source &&
        other.sourceMetadata == sourceMetadata &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      takenAt,
      localOffsetMinutes,
      weightValue,
      unit,
      notes,
      saltIntake,
      exerciseLevel,
      stressLevel,
      sleepQuality,
      source,
      sourceMetadata,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'WeightEntry(id: $id, weight: $weightValue${unit.toDbString()}, at: $takenAt)';
  }
}

/// Sleep data source.
enum SleepSource {
  /// Manually entered by user
  manual,

  /// Imported from device/app
  import,
}

/// Extension on SleepSource for database conversion.
extension SleepSourceExtension on SleepSource {
  /// Returns the string representation for database storage.
  String toDbString() {
    switch (this) {
      case SleepSource.manual:
        return 'manual';
      case SleepSource.import:
        return 'import';
    }
  }

  /// Parses a SleepSource from database string.
  static SleepSource fromDbString(String value) {
    switch (value.toLowerCase()) {
      case 'manual':
        return SleepSource.manual;
      case 'import':
        return SleepSource.import;
      default:
        return SleepSource.manual; // Default fallback
    }
  }
}

/// Sleep entry model for tracking sleep data from manual input or device import.
///
/// Stores sleep duration, quality, timing, and source information.
class SleepEntry {
  /// Unique identifier for the sleep entry.
  final int? id;

  /// Profile this entry belongs to.
  final int profileId;

  /// Timestamp when sleep started (with timezone).
  final DateTime startedAt;

  /// Timestamp when sleep ended (with timezone).
  final DateTime? endedAt;

  /// Total sleep duration in minutes.
  ///
  /// Can be explicitly set for imported summaries, or calculated from times.
  final int durationMinutes;

  /// Optional sleep quality rating (1-5 scale).
  final int? quality;

  /// Local timezone offset in minutes at time of sleep end.
  final int localOffsetMinutes;

  /// Source of this entry.
  final SleepSource source;

  /// Optional source metadata (JSON string for import details).
  final String? sourceMetadata;

  /// Optional notes about the sleep.
  final String? notes;

  /// Timestamp when this entry was created.
  final DateTime createdAt;

  /// Creates a new [SleepEntry] instance.
  ///
  /// If [endedAt] is provided and [durationMinutes] is not, duration will be
  /// calculated automatically. For import summaries, duration can be provided
  /// explicitly without [endedAt].
  SleepEntry({
    this.id,
    required this.profileId,
    required this.startedAt,
    this.endedAt,
    int? durationMinutes,
    this.quality,
    int? localOffsetMinutes,
    this.source = SleepSource.manual,
    this.sourceMetadata,
    this.notes,
    DateTime? createdAt,
  })  : durationMinutes = durationMinutes ??
            (endedAt != null ? endedAt.difference(startedAt).inMinutes : 0),
        localOffsetMinutes = localOffsetMinutes ??
            (endedAt ?? startedAt).timeZoneOffset.inMinutes,
        createdAt = createdAt ?? DateTime.now();

  /// Creates a [SleepEntry] from a database map.
  factory SleepEntry.fromMap(Map<String, dynamic> map) {
    return SleepEntry(
      id: map['id'] as int?,
      profileId: map['profileId'] as int,
      startedAt: DateTime.parse(map['startedAt'] as String),
      endedAt: map['endedAt'] != null
          ? DateTime.parse(map['endedAt'] as String)
          : null,
      durationMinutes: map['durationMinutes'] as int,
      quality: map['quality'] as int?,
      localOffsetMinutes: map['localOffsetMinutes'] as int,
      source: SleepSourceExtension.fromDbString(map['source'] as String),
      sourceMetadata: map['sourceMetadata'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Converts this [SleepEntry] to a database map.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'profileId': profileId,
      'startedAt': startedAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
      'durationMinutes': durationMinutes,
      'quality': quality,
      'localOffsetMinutes': localOffsetMinutes,
      'source': source.toDbString(),
      'sourceMetadata': sourceMetadata,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Creates a copy of this [SleepEntry] with the given fields replaced.
  SleepEntry copyWith({
    int? id,
    int? profileId,
    DateTime? startedAt,
    DateTime? endedAt,
    int? durationMinutes,
    int? quality,
    int? localOffsetMinutes,
    SleepSource? source,
    String? sourceMetadata,
    String? notes,
    DateTime? createdAt,
  }) {
    return SleepEntry(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      quality: quality ?? this.quality,
      localOffsetMinutes: localOffsetMinutes ?? this.localOffsetMinutes,
      source: source ?? this.source,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is SleepEntry &&
        other.id == id &&
        other.profileId == profileId &&
        other.startedAt == startedAt &&
        other.endedAt == endedAt &&
        other.durationMinutes == durationMinutes &&
        other.quality == quality &&
        other.localOffsetMinutes == localOffsetMinutes &&
        other.source == source &&
        other.sourceMetadata == sourceMetadata &&
        other.notes == notes &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      profileId,
      startedAt,
      endedAt,
      durationMinutes,
      quality,
      localOffsetMinutes,
      source,
      sourceMetadata,
      notes,
      createdAt,
    );
  }

  @override
  String toString() {
    return 'SleepEntry(id: $id, duration: ${durationMinutes}min, ended: $endedAt)';
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

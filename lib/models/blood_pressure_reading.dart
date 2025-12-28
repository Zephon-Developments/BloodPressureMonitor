class BloodPressureReading {
  final int? id;
  final int systolic;
  final int diastolic;
  final int pulse;
  final DateTime timestamp;
  final String? notes;

  BloodPressureReading({
    this.id,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.timestamp,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'systolic': systolic,
      'diastolic': diastolic,
      'pulse': pulse,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }

  factory BloodPressureReading.fromMap(Map<String, dynamic> map) {
    return BloodPressureReading(
      id: map['id'] as int?,
      systolic: map['systolic'] as int,
      diastolic: map['diastolic'] as int,
      pulse: map['pulse'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      notes: map['notes'] as String?,
    );
  }
}

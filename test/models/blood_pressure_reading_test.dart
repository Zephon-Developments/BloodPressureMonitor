import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/blood_pressure_reading.dart';

void main() {
  group('BloodPressureReading', () {
    test('should create a reading from map', () {
      final map = {
        'id': 1,
        'systolic': 120,
        'diastolic': 80,
        'pulse': 70,
        'timestamp': '2024-01-01T10:00:00.000',
        'notes': 'Test reading',
      };

      final reading = BloodPressureReading.fromMap(map);

      expect(reading.id, 1);
      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.pulse, 70);
      expect(reading.notes, 'Test reading');
    });

    test('should convert a reading to map', () {
      final reading = BloodPressureReading(
        id: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        timestamp: DateTime.parse('2024-01-01T10:00:00.000'),
        notes: 'Test reading',
      );

      final map = reading.toMap();

      expect(map['id'], 1);
      expect(map['systolic'], 120);
      expect(map['diastolic'], 80);
      expect(map['pulse'], 70);
      expect(map['notes'], 'Test reading');
    });
  });
}

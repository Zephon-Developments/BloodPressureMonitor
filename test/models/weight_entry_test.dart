import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightUnit', () {
    test('toKg converts kg correctly', () {
      expect(WeightUnit.kg.toKg(70.0), equals(70.0));
    });

    test('toKg converts lbs to kg correctly', () {
      expect(WeightUnit.lbs.toKg(154.0), closeTo(69.85, 0.01));
    });

    test('fromKg converts kg correctly', () {
      expect(WeightUnit.kg.fromKg(70.0), equals(70.0));
    });

    test('fromKg converts kg to lbs correctly', () {
      expect(WeightUnit.lbs.fromKg(70.0), closeTo(154.32, 0.01));
    });

    test('toDbString returns correct values', () {
      expect(WeightUnit.kg.toDbString(), equals('kg'));
      expect(WeightUnit.lbs.toDbString(), equals('lbs'));
    });

    test('fromDbString parses correctly', () {
      expect(WeightUnitExtension.fromDbString('kg'), equals(WeightUnit.kg));
      expect(WeightUnitExtension.fromDbString('lbs'), equals(WeightUnit.lbs));
      expect(WeightUnitExtension.fromDbString('KG'), equals(WeightUnit.kg));
      expect(WeightUnitExtension.fromDbString('LBS'), equals(WeightUnit.lbs));
    });

    test('fromDbString defaults to kg for unknown values', () {
      expect(
          WeightUnitExtension.fromDbString('unknown'), equals(WeightUnit.kg));
    });
  });

  group('WeightEntry', () {
    final testTime = DateTime(2025, 12, 29, 10, 30);

    test('creates instance with required fields', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.5,
        unit: WeightUnit.kg,
      );

      expect(entry.id, isNull);
      expect(entry.profileId, equals(1));
      expect(entry.takenAt, equals(testTime));
      expect(entry.weightValue, equals(70.5));
      expect(entry.unit, equals(WeightUnit.kg));
      expect(entry.source, equals('manual'));
      expect(
          entry.localOffsetMinutes, equals(testTime.timeZoneOffset.inMinutes));
      expect(entry.createdAt, isNotNull);
    });

    test('creates instance with all optional fields', () {
      final createdAt = DateTime(2025, 12, 29, 9, 0);
      final entry = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        localOffsetMinutes: 120,
        weightValue: 155.0,
        unit: WeightUnit.lbs,
        notes: 'Morning weight',
        saltIntake: 'Low',
        exerciseLevel: 'Moderate',
        stressLevel: 'Low',
        sleepQuality: 'Good',
        source: 'import',
        sourceMetadata: '{"device":"fitbit"}',
        createdAt: createdAt,
      );

      expect(entry.id, equals(42));
      expect(entry.notes, equals('Morning weight'));
      expect(entry.saltIntake, equals('Low'));
      expect(entry.exerciseLevel, equals('Moderate'));
      expect(entry.stressLevel, equals('Low'));
      expect(entry.sleepQuality, equals('Good'));
      expect(entry.source, equals('import'));
      expect(entry.sourceMetadata, equals('{"device":"fitbit"}'));
      expect(entry.localOffsetMinutes, equals(120));
      expect(entry.createdAt, equals(createdAt));
    });

    test('weightInKg returns correct value for kg', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      expect(entry.weightInKg, equals(70.0));
    });

    test('weightInKg converts lbs to kg', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 154.0,
        unit: WeightUnit.lbs,
      );

      expect(entry.weightInKg, closeTo(69.85, 0.01));
    });

    test('weightInLbs returns correct value for lbs', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 154.0,
        unit: WeightUnit.lbs,
      );

      expect(entry.weightInLbs, equals(154.0));
    });

    test('weightInLbs converts kg to lbs', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      expect(entry.weightInLbs, closeTo(154.32, 0.1));
    });

    test('toMap includes all fields', () {
      final createdAt = DateTime(2025, 12, 29, 9, 0);
      final entry = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        localOffsetMinutes: 120,
        weightValue: 70.5,
        unit: WeightUnit.kg,
        notes: 'Test note',
        saltIntake: 'Low',
        exerciseLevel: 'Moderate',
        stressLevel: 'Low',
        sleepQuality: 'Good',
        source: 'manual',
        sourceMetadata: '{"test":true}',
        createdAt: createdAt,
      );

      final map = entry.toMap();

      expect(map['id'], equals(42));
      expect(map['profileId'], equals(1));
      expect(map['takenAt'], equals(testTime.toIso8601String()));
      expect(map['localOffsetMinutes'], equals(120));
      expect(map['weightValue'], equals(70.5));
      expect(map['unit'], equals('kg'));
      expect(map['notes'], equals('Test note'));
      expect(map['saltIntake'], equals('Low'));
      expect(map['exerciseLevel'], equals('Moderate'));
      expect(map['stressLevel'], equals('Low'));
      expect(map['sleepQuality'], equals('Good'));
      expect(map['source'], equals('manual'));
      expect(map['sourceMetadata'], equals('{"test":true}'));
      expect(map['createdAt'], equals(createdAt.toIso8601String()));
    });

    test('toMap excludes null id', () {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final map = entry.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap reconstructs entry correctly', () {
      final createdAt = DateTime(2025, 12, 29, 9, 0);
      final map = {
        'id': 42,
        'profileId': 1,
        'takenAt': testTime.toIso8601String(),
        'localOffsetMinutes': 120,
        'weightValue': 70.5,
        'unit': 'kg',
        'notes': 'Test note',
        'saltIntake': 'Low',
        'exerciseLevel': 'Moderate',
        'stressLevel': 'Low',
        'sleepQuality': 'Good',
        'source': 'import',
        'sourceMetadata': '{"test":true}',
        'createdAt': createdAt.toIso8601String(),
      };

      final entry = WeightEntry.fromMap(map);

      expect(entry.id, equals(42));
      expect(entry.profileId, equals(1));
      expect(entry.takenAt, equals(testTime));
      expect(entry.localOffsetMinutes, equals(120));
      expect(entry.weightValue, equals(70.5));
      expect(entry.unit, equals(WeightUnit.kg));
      expect(entry.notes, equals('Test note'));
      expect(entry.saltIntake, equals('Low'));
      expect(entry.exerciseLevel, equals('Moderate'));
      expect(entry.stressLevel, equals('Low'));
      expect(entry.sleepQuality, equals('Good'));
      expect(entry.source, equals('import'));
      expect(entry.sourceMetadata, equals('{"test":true}'));
      expect(entry.createdAt, equals(createdAt));
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'profileId': 1,
        'takenAt': testTime.toIso8601String(),
        'localOffsetMinutes': 0,
        'weightValue': 70.0,
        'unit': 'kg',
        'source': 'manual',
        'createdAt': testTime.toIso8601String(),
      };

      final entry = WeightEntry.fromMap(map);

      expect(entry.id, isNull);
      expect(entry.notes, isNull);
      expect(entry.saltIntake, isNull);
      expect(entry.exerciseLevel, isNull);
      expect(entry.stressLevel, isNull);
      expect(entry.sleepQuality, isNull);
      expect(entry.sourceMetadata, isNull);
    });

    test('round-trip serialization preserves data', () {
      final original = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        localOffsetMinutes: 120,
        weightValue: 70.5,
        unit: WeightUnit.lbs,
        notes: 'Test',
        saltIntake: 'Low',
        exerciseLevel: 'High',
        stressLevel: 'Medium',
        sleepQuality: 'Good',
        source: 'import',
        sourceMetadata: '{"test":true}',
        createdAt: testTime,
      );

      final map = original.toMap();
      final reconstructed = WeightEntry.fromMap(map);

      expect(reconstructed, equals(original));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final updated = original.copyWith(
        weightValue: 72.0,
        notes: 'Updated note',
      );

      expect(updated.id, equals(42));
      expect(updated.profileId, equals(1));
      expect(updated.weightValue, equals(72.0));
      expect(updated.notes, equals('Updated note'));
      expect(updated.unit, equals(WeightUnit.kg));
    });

    test('copyWith preserves original when no fields specified', () {
      final original = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('equality works correctly', () {
      final entry1 = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
        createdAt: testTime,
      );

      final entry2 = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
        createdAt: testTime,
      );

      final entry3 = WeightEntry(
        id: 43,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
        createdAt: testTime,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('hashCode is consistent', () {
      final entry1 = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
        createdAt: testTime,
      );

      final entry2 = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
        createdAt: testTime,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('toString includes key information', () {
      final entry = WeightEntry(
        id: 42,
        profileId: 1,
        takenAt: testTime,
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final str = entry.toString();
      expect(str, contains('42'));
      expect(str, contains('70.0'));
      expect(str, contains('kg'));
    });
  });
}

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Medication', () {
    test('creates medication with required fields', () {
      final med = Medication(
        profileId: 1,
        name: 'Aspirin',
      );

      expect(med.profileId, 1);
      expect(med.name, 'Aspirin');
      expect(med.id, isNull);
      expect(med.dosage, isNull);
      expect(med.unit, isNull);
      expect(med.frequency, isNull);
      expect(med.scheduleMetadata, isNull);
      expect(med.createdAt, isNotNull);
    });

    test('creates medication with all fields', () {
      final createdAt = DateTime(2025, 12, 29);
      final med = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
        frequency: 'daily',
        scheduleMetadata: '{"v":1}',
        createdAt: createdAt,
      );

      expect(med.id, 1);
      expect(med.profileId, 1);
      expect(med.name, 'Aspirin');
      expect(med.dosage, '100');
      expect(med.unit, 'mg');
      expect(med.frequency, 'daily');
      expect(med.scheduleMetadata, '{"v":1}');
      expect(med.createdAt, createdAt);
    });

    test('toMap converts to database map correctly', () {
      final createdAt = DateTime(2025, 12, 29);
      final med = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
        frequency: 'daily',
        scheduleMetadata: '{"v":1}',
        createdAt: createdAt,
      );

      final map = med.toMap();

      expect(map['id'], 1);
      expect(map['profileId'], 1);
      expect(map['name'], 'Aspirin');
      expect(map['dosage'], '100');
      expect(map['unit'], 'mg');
      expect(map['frequency'], 'daily');
      expect(map['scheduleMetadata'], '{"v":1}');
      expect(map['createdAt'], createdAt.toIso8601String());
    });

    test('fromMap creates medication from database map', () {
      final map = {
        'id': 1,
        'profileId': 1,
        'name': 'Aspirin',
        'dosage': '100',
        'unit': 'mg',
        'frequency': 'daily',
        'scheduleMetadata': '{"v":1}',
        'createdAt': '2025-12-29T00:00:00.000',
      };

      final med = Medication.fromMap(map);

      expect(med.id, 1);
      expect(med.profileId, 1);
      expect(med.name, 'Aspirin');
      expect(med.dosage, '100');
      expect(med.unit, 'mg');
      expect(med.frequency, 'daily');
      expect(med.scheduleMetadata, '{"v":1}');
      expect(med.createdAt, DateTime(2025, 12, 29));
    });

    test('round-trip serialization preserves data', () {
      final original = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
        frequency: 'daily',
        scheduleMetadata: '{"v":1}',
        createdAt: DateTime(2025, 12, 29),
      );

      final map = original.toMap();
      final restored = Medication.fromMap(map);

      expect(restored, original);
    });

    test('copyWith creates new instance with updated fields', () {
      final med = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
      );

      final updated = med.copyWith(dosage: '200', unit: 'tablets');

      expect(updated.id, 1);
      expect(updated.profileId, 1);
      expect(updated.name, 'Aspirin');
      expect(updated.dosage, '200');
      expect(updated.unit, 'tablets');
    });

    test('equality compares all fields', () {
      final createdAt = DateTime(2025, 12, 29);
      final med1 = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        createdAt: createdAt,
      );
      final med2 = Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        createdAt: createdAt,
      );
      final med3 = Medication(
        id: 2,
        profileId: 1,
        name: 'Aspirin',
        createdAt: createdAt,
      );

      expect(med1, med2);
      expect(med1, isNot(med3));
    });
  });

  group('MedicationGroup', () {
    test('creates group with required fields', () {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2, 3],
      );

      expect(group.profileId, 1);
      expect(group.name, 'Morning Meds');
      expect(group.memberMedicationIds, [1, 2, 3]);
      expect(group.id, isNull);
      expect(group.createdAt, isNotNull);
    });

    test('normalizes member IDs by sorting and deduplicating', () {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Meds',
        memberMedicationIds: [3, 1, 2, 1, 3],
      );

      expect(group.memberMedicationIds, [1, 2, 3]);
    });

    test('toMap converts to database map with JSON array', () {
      final createdAt = DateTime(2025, 12, 29);
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2, 3],
        createdAt: createdAt,
      );

      final map = group.toMap();

      expect(map['id'], 1);
      expect(map['profileId'], 1);
      expect(map['name'], 'Morning Meds');
      expect(map['memberMedicationIds'], '[1,2,3]');
      expect(map['createdAt'], createdAt.toIso8601String());
    });

    test('fromMap creates group from database map', () {
      final map = {
        'id': 1,
        'profileId': 1,
        'name': 'Morning Meds',
        'memberMedicationIds': '[1,2,3]',
        'createdAt': '2025-12-29T00:00:00.000',
      };

      final group = MedicationGroup.fromMap(map);

      expect(group.id, 1);
      expect(group.profileId, 1);
      expect(group.name, 'Morning Meds');
      expect(group.memberMedicationIds, [1, 2, 3]);
      expect(group.createdAt, DateTime(2025, 12, 29));
    });

    test('fromMap handles empty member list', () {
      final map = {
        'id': 1,
        'profileId': 1,
        'name': 'Empty Group',
        'memberMedicationIds': '',
        'createdAt': '2025-12-29T00:00:00.000',
      };

      final group = MedicationGroup.fromMap(map);

      expect(group.memberMedicationIds, isEmpty);
    });

    test('round-trip serialization preserves data', () {
      final original = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [3, 1, 2],
        createdAt: DateTime(2025, 12, 29),
      );

      final map = original.toMap();
      final restored = MedicationGroup.fromMap(map);

      expect(restored, original);
    });

    test('copyWith creates new instance with updated fields', () {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2],
      );

      final updated = group.copyWith(
        name: 'Evening Meds',
        memberMedicationIds: [3, 4],
      );

      expect(updated.id, 1);
      expect(updated.profileId, 1);
      expect(updated.name, 'Evening Meds');
      expect(updated.memberMedicationIds, [3, 4]);
    });

    test('equality compares all fields including member list', () {
      final createdAt = DateTime(2025, 12, 29);
      final group1 = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Meds',
        memberMedicationIds: [1, 2],
        createdAt: createdAt,
      );
      final group2 = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Meds',
        memberMedicationIds: [1, 2],
        createdAt: createdAt,
      );
      final group3 = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Meds',
        memberMedicationIds: [1, 3],
        createdAt: createdAt,
      );

      expect(group1, group2);
      expect(group1, isNot(group3));
    });
  });

  group('MedicationIntake', () {
    test('creates intake with required fields', () {
      final takenAt = DateTime(2025, 12, 29, 8, 0);
      final intake = MedicationIntake(
        medicationId: 1,
        profileId: 1,
        takenAt: takenAt,
      );

      expect(intake.medicationId, 1);
      expect(intake.profileId, 1);
      expect(intake.takenAt, takenAt);
      expect(intake.localOffsetMinutes, takenAt.timeZoneOffset.inMinutes);
      expect(intake.id, isNull);
      expect(intake.scheduledFor, isNull);
      expect(intake.groupId, isNull);
      expect(intake.note, isNull);
    });

    test('creates intake with all fields', () {
      final takenAt = DateTime(2025, 12, 29, 8, 30);
      final scheduledFor = DateTime(2025, 12, 29, 8, 0);
      final intake = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: takenAt,
        localOffsetMinutes: -300,
        scheduledFor: scheduledFor,
        groupId: 5,
        note: 'Took with food',
      );

      expect(intake.id, 1);
      expect(intake.medicationId, 1);
      expect(intake.profileId, 1);
      expect(intake.takenAt, takenAt);
      expect(intake.localOffsetMinutes, -300);
      expect(intake.scheduledFor, scheduledFor);
      expect(intake.groupId, 5);
      expect(intake.note, 'Took with food');
    });

    test('toMap converts to database map correctly', () {
      final takenAt = DateTime(2025, 12, 29, 8, 30);
      final scheduledFor = DateTime(2025, 12, 29, 8, 0);
      final intake = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: takenAt,
        localOffsetMinutes: -300,
        scheduledFor: scheduledFor,
        groupId: 5,
        note: 'Took with food',
      );

      final map = intake.toMap();

      expect(map['id'], 1);
      expect(map['medicationId'], 1);
      expect(map['profileId'], 1);
      expect(map['takenAt'], takenAt.toIso8601String());
      expect(map['localOffsetMinutes'], -300);
      expect(map['scheduledFor'], scheduledFor.toIso8601String());
      expect(map['groupId'], 5);
      expect(map['note'], 'Took with food');
    });

    test('fromMap creates intake from database map', () {
      final map = {
        'id': 1,
        'medicationId': 1,
        'profileId': 1,
        'takenAt': '2025-12-29T08:30:00.000',
        'localOffsetMinutes': -300,
        'scheduledFor': '2025-12-29T08:00:00.000',
        'groupId': 5,
        'note': 'Took with food',
      };

      final intake = MedicationIntake.fromMap(map);

      expect(intake.id, 1);
      expect(intake.medicationId, 1);
      expect(intake.profileId, 1);
      expect(intake.takenAt, DateTime(2025, 12, 29, 8, 30));
      expect(intake.localOffsetMinutes, -300);
      expect(intake.scheduledFor, DateTime(2025, 12, 29, 8, 0));
      expect(intake.groupId, 5);
      expect(intake.note, 'Took with food');
    });

    test('round-trip serialization preserves data', () {
      final original = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 30),
        localOffsetMinutes: -300,
        scheduledFor: DateTime(2025, 12, 29, 8, 0),
        groupId: 5,
        note: 'Took with food',
      );

      final map = original.toMap();
      final restored = MedicationIntake.fromMap(map);

      expect(restored, original);
    });

    test('copyWith creates new instance with updated fields', () {
      final intake = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
      );

      final updated = intake.copyWith(
        note: 'Forgot to take earlier',
        groupId: 10,
      );

      expect(updated.id, 1);
      expect(updated.medicationId, 1);
      expect(updated.note, 'Forgot to take earlier');
      expect(updated.groupId, 10);
    });

    test('equality compares all fields', () {
      final takenAt = DateTime(2025, 12, 29, 8, 0);
      final intake1 = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: takenAt,
        localOffsetMinutes: -300,
      );
      final intake2 = MedicationIntake(
        id: 1,
        medicationId: 1,
        profileId: 1,
        takenAt: takenAt,
        localOffsetMinutes: -300,
      );
      final intake3 = MedicationIntake(
        id: 1,
        medicationId: 2,
        profileId: 1,
        takenAt: takenAt,
        localOffsetMinutes: -300,
      );

      expect(intake1, intake2);
      expect(intake1, isNot(intake3));
    });
  });
}

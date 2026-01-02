import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/profile.dart';

void main() {
  group('Profile Model Tests', () {
    final DateTime testDate = DateTime(2025, 1, 1, 12, 0, 0);

    test('Profile creation with all fields', () {
      final profile = Profile(
        id: 1,
        name: 'John Doe',
        colorHex: '#FF5733',
        avatarIcon: '👤',
        yearOfBirth: 1980,
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      expect(profile.id, 1);
      expect(profile.name, 'John Doe');
      expect(profile.colorHex, '#FF5733');
      expect(profile.avatarIcon, '👤');
      expect(profile.yearOfBirth, 1980);
      expect(profile.preferredUnits, 'mmHg');
      expect(profile.createdAt, testDate);
    });

    test('Profile creation with minimum required fields', () {
      final profile = Profile(
        name: 'Jane Doe',
        preferredUnits: 'kPa',
        createdAt: testDate,
      );

      expect(profile.id, isNull);
      expect(profile.name, 'Jane Doe');
      expect(profile.colorHex, isNull);
      expect(profile.avatarIcon, isNull);
      expect(profile.yearOfBirth, isNull);
      expect(profile.preferredUnits, 'kPa');
      expect(profile.createdAt, testDate);
    });

    test('toMap serialization includes all fields', () {
      final profile = Profile(
        id: 2,
        name: 'Test User',
        colorHex: '#00FF00',
        avatarIcon: '🏃',
        yearOfBirth: 1995,
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final map = profile.toMap();

      expect(map['id'], 2);
      expect(map['name'], 'Test User');
      expect(map['colorHex'], '#00FF00');
      expect(map['avatarIcon'], '🏃');
      expect(map['yearOfBirth'], 1995);
      expect(map['preferredUnits'], 'mmHg');
      expect(map['createdAt'], testDate.toIso8601String());
    });

    test('toMap serialization excludes null id', () {
      final profile = Profile(
        name: 'New User',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final map = profile.toMap();

      expect(map.containsKey('id'), false);
    });

    test('fromMap deserialization with all fields', () {
      final map = {
        'id': 3,
        'name': 'Alice',
        'colorHex': '#0000FF',
        'avatarIcon': '💪',
        'yearOfBirth': 1988,
        'preferredUnits': 'kPa',
        'createdAt': testDate.toIso8601String(),
      };

      final profile = Profile.fromMap(map);

      expect(profile.id, 3);
      expect(profile.name, 'Alice');
      expect(profile.colorHex, '#0000FF');
      expect(profile.avatarIcon, '💪');
      expect(profile.yearOfBirth, 1988);
      expect(profile.preferredUnits, 'kPa');
      expect(profile.createdAt, testDate);
    });

    test('fromMap deserialization with null optional fields', () {
      final map = {
        'id': 4,
        'name': 'Bob',
        'colorHex': null,
        'avatarIcon': null,
        'yearOfBirth': null,
        'preferredUnits': 'mmHg',
        'createdAt': testDate.toIso8601String(),
      };

      final profile = Profile.fromMap(map);

      expect(profile.id, 4);
      expect(profile.name, 'Bob');
      expect(profile.colorHex, isNull);
      expect(profile.avatarIcon, isNull);
      expect(profile.yearOfBirth, isNull);
      expect(profile.preferredUnits, 'mmHg');
      expect(profile.createdAt, testDate);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Profile(
        id: 5,
        name: 'Original',
        colorHex: '#FFFFFF',
        avatarIcon: '🎯',
        yearOfBirth: 1990,
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final updated = original.copyWith(
        name: 'Updated',
        yearOfBirth: 1991,
      );

      expect(updated.id, 5);
      expect(updated.name, 'Updated');
      expect(updated.colorHex, '#FFFFFF');
      expect(updated.avatarIcon, '🎯');
      expect(updated.yearOfBirth, 1991);
      expect(updated.preferredUnits, 'mmHg');
      expect(updated.createdAt, testDate);
    });

    test('copyWith with no changes returns equivalent instance', () {
      final original = Profile(
        id: 6,
        name: 'Same',
        preferredUnits: 'kPa',
        createdAt: testDate,
      );

      final copy = original.copyWith();

      expect(copy.id, original.id);
      expect(copy.name, original.name);
      expect(copy.preferredUnits, original.preferredUnits);
      expect(copy.createdAt, original.createdAt);
    });

    test('equality operator works correctly for identical profiles', () {
      final profile1 = Profile(
        id: 7,
        name: 'Equal Test',
        colorHex: '#123456',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final profile2 = Profile(
        id: 7,
        name: 'Equal Test',
        colorHex: '#123456',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      expect(profile1, equals(profile2));
      expect(profile1.hashCode, equals(profile2.hashCode));
    });

    test('equality operator returns false for different profiles', () {
      final profile1 = Profile(
        id: 8,
        name: 'User A',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final profile2 = Profile(
        id: 9,
        name: 'User B',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      expect(profile1, isNot(equals(profile2)));
    });

    test('equality considers all fields', () {
      final base = Profile(
        id: 10,
        name: 'Base',
        colorHex: '#000000',
        avatarIcon: '⭐',
        yearOfBirth: 2000,
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      final diffName = base.copyWith(name: 'Different');
      final diffColor = base.copyWith(colorHex: '#111111');
      final diffIcon = base.copyWith(avatarIcon: '🌟');
      final diffYear = base.copyWith(yearOfBirth: 2001);
      final diffUnits = base.copyWith(preferredUnits: 'kPa');
      final diffDate =
          base.copyWith(createdAt: testDate.add(const Duration(days: 1)));

      expect(base, isNot(equals(diffName)));
      expect(base, isNot(equals(diffColor)));
      expect(base, isNot(equals(diffIcon)));
      expect(base, isNot(equals(diffYear)));
      expect(base, isNot(equals(diffUnits)));
      expect(base, isNot(equals(diffDate)));
    });

    test('round-trip serialization preserves data', () {
      final original = Profile(
        id: 11,
        name: 'Round Trip',
        colorHex: '#ABCDEF',
        avatarIcon: '🔄',
        yearOfBirth: 1985,
        preferredUnits: 'kPa',
        createdAt: testDate,
      );

      final map = original.toMap();
      final restored = Profile.fromMap(map);

      expect(restored, equals(original));
    });

    test('preferredUnits defaults to mmHg', () {
      final profile = Profile(
        name: 'Default Units',
        preferredUnits: 'mmHg',
        createdAt: testDate,
      );

      expect(profile.preferredUnits, 'mmHg');
    });

    test('supports kPa units', () {
      final profile = Profile(
        name: 'Metric User',
        preferredUnits: 'kPa',
        createdAt: testDate,
      );

      expect(profile.preferredUnits, 'kPa');
    });

    group('Medical Metadata Tests', () {
      final testDateOfBirth = DateTime.utc(1990, 5, 15);

      test('Profile creation with all medical metadata fields', () {
        final profile = Profile(
          id: 12,
          name: 'Medical User',
          dateOfBirth: testDateOfBirth,
          patientId: 'NHS-123456789',
          doctorName: 'Dr. Jane Smith',
          clinicName: 'City General Hospital',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        expect(profile.dateOfBirth, testDateOfBirth);
        expect(profile.patientId, 'NHS-123456789');
        expect(profile.doctorName, 'Dr. Jane Smith');
        expect(profile.clinicName, 'City General Hospital');
      });

      test('Profile creation with null medical metadata fields', () {
        final profile = Profile(
          name: 'Basic User',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        expect(profile.dateOfBirth, isNull);
        expect(profile.patientId, isNull);
        expect(profile.doctorName, isNull);
        expect(profile.clinicName, isNull);
      });

      test('toMap serialization includes medical metadata', () {
        final profile = Profile(
          id: 13,
          name: 'Test Patient',
          dateOfBirth: testDateOfBirth,
          patientId: 'MRN-987654',
          doctorName: 'Dr. John Doe',
          clinicName: 'Memorial Hospital',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        final map = profile.toMap();

        expect(map['dateOfBirth'], '1990-05-15');
        expect(map['patientId'], 'MRN-987654');
        expect(map['doctorName'], 'Dr. John Doe');
        expect(map['clinicName'], 'Memorial Hospital');
      });

      test('toMap serialization handles null medical metadata', () {
        final profile = Profile(
          name: 'Null Fields',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        final map = profile.toMap();

        expect(map['dateOfBirth'], isNull);
        expect(map['patientId'], isNull);
        expect(map['doctorName'], isNull);
        expect(map['clinicName'], isNull);
      });

      test('fromMap deserialization with medical metadata', () {
        final map = {
          'id': 14,
          'name': 'Patient From Map',
          'dateOfBirth': '1990-05-15',
          'patientId': 'PAT-456',
          'doctorName': 'Dr. Sarah Wilson',
          'clinicName': 'St. Mary\'s Clinic',
          'preferredUnits': 'mmHg',
          'createdAt': testDate.toIso8601String(),
        };

        final profile = Profile.fromMap(map);

        expect(profile.dateOfBirth, testDateOfBirth);
        expect(profile.patientId, 'PAT-456');
        expect(profile.doctorName, 'Dr. Sarah Wilson');
        expect(profile.clinicName, 'St. Mary\'s Clinic');
      });

      test('fromMap deserialization with null medical metadata', () {
        final map = {
          'id': 15,
          'name': 'No Medical Data',
          'dateOfBirth': null,
          'patientId': null,
          'doctorName': null,
          'clinicName': null,
          'preferredUnits': 'mmHg',
          'createdAt': testDate.toIso8601String(),
        };

        final profile = Profile.fromMap(map);

        expect(profile.dateOfBirth, isNull);
        expect(profile.patientId, isNull);
        expect(profile.doctorName, isNull);
        expect(profile.clinicName, isNull);
      });

      test('copyWith updates medical metadata fields', () {
        final original = Profile(
          id: 16,
          name: 'Original Patient',
          dateOfBirth: testDateOfBirth,
          patientId: 'OLD-123',
          doctorName: 'Dr. Old',
          clinicName: 'Old Clinic',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        final newDate = DateTime(1985, 10, 20);
        final updated = original.copyWith(
          dateOfBirth: newDate,
          patientId: 'NEW-456',
          doctorName: 'Dr. New',
          clinicName: 'New Hospital',
        );

        expect(updated.dateOfBirth, newDate);
        expect(updated.patientId, 'NEW-456');
        expect(updated.doctorName, 'Dr. New');
        expect(updated.clinicName, 'New Hospital');
        // Verify other fields remain unchanged
        expect(updated.id, original.id);
        expect(updated.name, original.name);
      });

      test('equality considers medical metadata fields', () {
        final profile1 = Profile(
          id: 17,
          name: 'Equal Medical',
          dateOfBirth: testDateOfBirth,
          patientId: 'PAT-123',
          doctorName: 'Dr. Smith',
          clinicName: 'Clinic A',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        final profile2 = Profile(
          id: 17,
          name: 'Equal Medical',
          dateOfBirth: testDateOfBirth,
          patientId: 'PAT-123',
          doctorName: 'Dr. Smith',
          clinicName: 'Clinic A',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        expect(profile1, equals(profile2));
        expect(profile1.hashCode, equals(profile2.hashCode));
      });

      test('inequality when medical metadata differs', () {
        final base = Profile(
          id: 18,
          name: 'Base',
          dateOfBirth: testDateOfBirth,
          patientId: 'PAT-100',
          doctorName: 'Dr. Base',
          clinicName: 'Base Clinic',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        final diffDob = base.copyWith(dateOfBirth: DateTime(1991, 1, 1));
        final diffPatientId = base.copyWith(patientId: 'PAT-999');
        final diffDoctor = base.copyWith(doctorName: 'Dr. Different');
        final diffClinic = base.copyWith(clinicName: 'Different Clinic');

        expect(base, isNot(equals(diffDob)));
        expect(base, isNot(equals(diffPatientId)));
        expect(base, isNot(equals(diffDoctor)));
        expect(base, isNot(equals(diffClinic)));
      });

      test('round-trip serialization preserves medical metadata', () {
        final original = Profile(
          id: 19,
          name: 'Round Trip Medical',
          dateOfBirth: testDateOfBirth,
          patientId: 'RT-456',
          doctorName: 'Dr. Round',
          clinicName: 'Trip Hospital',
          yearOfBirth: 1990,
          preferredUnits: 'kPa',
          createdAt: testDate,
        );

        final map = original.toMap();
        final restored = Profile.fromMap(map);

        expect(restored, equals(original));
        expect(restored.dateOfBirth, original.dateOfBirth);
        expect(restored.patientId, original.patientId);
        expect(restored.doctorName, original.doctorName);
        expect(restored.clinicName, original.clinicName);
      });

      test('copyWith can explicitly set medical metadata to null', () {
        final original = Profile(
          id: 20,
          name: 'Clear Medical Data',
          dateOfBirth: testDateOfBirth,
          patientId: 'PAT-999',
          doctorName: 'Dr. Original',
          clinicName: 'Original Clinic',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        // Clear all medical metadata fields
        final cleared = original.copyWith(
          dateOfBirth: null,
          patientId: null,
          doctorName: null,
          clinicName: null,
        );

        expect(cleared.id, original.id);
        expect(cleared.name, original.name);
        expect(cleared.dateOfBirth, isNull);
        expect(cleared.patientId, isNull);
        expect(cleared.doctorName, isNull);
        expect(cleared.clinicName, isNull);
        expect(cleared.preferredUnits, original.preferredUnits);
        expect(cleared.createdAt, original.createdAt);
      });

      test('copyWith preserves unspecified medical metadata', () {
        final original = Profile(
          id: 21,
          name: 'Partial Update',
          dateOfBirth: testDateOfBirth,
          patientId: 'PAT-123',
          doctorName: 'Dr. Keep',
          clinicName: 'Keep Clinic',
          preferredUnits: 'mmHg',
          createdAt: testDate,
        );

        // Update only one field, others should remain
        final updated = original.copyWith(
          patientId: 'PAT-NEW',
        );

        expect(updated.dateOfBirth, original.dateOfBirth);
        expect(updated.patientId, 'PAT-NEW');
        expect(updated.doctorName, original.doctorName);
        expect(updated.clinicName, original.clinicName);
      });
    });
  });
}

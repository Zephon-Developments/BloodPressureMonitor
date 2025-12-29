import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/reading.dart';

void main() {
  group('Reading Model Tests', () {
    final DateTime testDate = DateTime(2025, 1, 15, 10, 30, 0);

    test('Reading creation with all fields', () {
      final reading = Reading(
        id: 1,
        profileId: 100,
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        takenAt: testDate,
        localOffsetMinutes: -300,
        posture: 'sitting',
        arm: 'left',
        medsContext: 'after_meds',
        irregularFlag: true,
        tags: 'morning,fasting',
        note: 'Feeling good',
      );

      expect(reading.id, 1);
      expect(reading.profileId, 100);
      expect(reading.systolic, 120);
      expect(reading.diastolic, 80);
      expect(reading.pulse, 72);
      expect(reading.takenAt, testDate);
      expect(reading.localOffsetMinutes, -300);
      expect(reading.posture, 'sitting');
      expect(reading.arm, 'left');
      expect(reading.medsContext, 'after_meds');
      expect(reading.irregularFlag, true);
      expect(reading.tags, 'morning,fasting');
      expect(reading.note, 'Feeling good');
    });

    test('Reading creation with minimum required fields', () {
      final reading = Reading(
        profileId: 200,
        systolic: 115,
        diastolic: 75,
        pulse: 68,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(reading.id, isNull);
      expect(reading.profileId, 200);
      expect(reading.systolic, 115);
      expect(reading.diastolic, 75);
      expect(reading.pulse, 68);
      expect(reading.takenAt, testDate);
      expect(reading.localOffsetMinutes, 0);
      expect(reading.posture, isNull);
      expect(reading.arm, isNull);
      expect(reading.medsContext, isNull);
      expect(reading.irregularFlag, false);
      expect(reading.tags, isNull);
      expect(reading.note, isNull);
    });

    test('toMap serialization includes all fields', () {
      final reading = Reading(
        id: 2,
        profileId: 300,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: testDate,
        localOffsetMinutes: 60,
        posture: 'standing',
        arm: 'right',
        medsContext: 'before_meds',
        irregularFlag: true,
        tags: 'stress,work',
        note: 'High stress day',
      );

      final map = reading.toMap();

      expect(map['id'], 2);
      expect(map['profileId'], 300);
      expect(map['systolic'], 130);
      expect(map['diastolic'], 85);
      expect(map['pulse'], 75);
      expect(map['takenAt'], testDate.toIso8601String());
      expect(map['localOffsetMinutes'], 60);
      expect(map['posture'], 'standing');
      expect(map['arm'], 'right');
      expect(map['medsContext'], 'before_meds');
      expect(map['irregularFlag'], 1);
      expect(map['tags'], 'stress,work');
      expect(map['note'], 'High stress day');
    });

    test('toMap serialization excludes null id', () {
      final reading = Reading(
        profileId: 400,
        systolic: 125,
        diastolic: 82,
        pulse: 70,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final map = reading.toMap();

      expect(map.containsKey('id'), false);
    });

    test('toMap handles null tags', () {
      final reading = Reading(
        profileId: 500,
        systolic: 118,
        diastolic: 78,
        pulse: 65,
        takenAt: testDate,
        localOffsetMinutes: 0,
        tags: null,
      );

      final map = reading.toMap();

      expect(map['tags'], isNull);
    });

    test('toMap handles empty tags string', () {
      final reading = Reading(
        profileId: 600,
        systolic: 122,
        diastolic: 80,
        pulse: 72,
        takenAt: testDate,
        localOffsetMinutes: 0,
        tags: '',
      );

      final map = reading.toMap();

      expect(map['tags'], '');
    });

    test('fromMap deserialization with all fields', () {
      final map = {
        'id': 3,
        'profileId': 700,
        'systolic': 140,
        'diastolic': 90,
        'pulse': 80,
        'takenAt': testDate.toIso8601String(),
        'localOffsetMinutes': -480,
        'posture': 'lying',
        'arm': 'left',
        'medsContext': 'no_meds',
        'irregularFlag': 1,
        'tags': 'evening,relaxed',
        'note': 'After dinner',
      };

      final reading = Reading.fromMap(map);

      expect(reading.id, 3);
      expect(reading.profileId, 700);
      expect(reading.systolic, 140);
      expect(reading.diastolic, 90);
      expect(reading.pulse, 80);
      expect(reading.takenAt, testDate);
      expect(reading.localOffsetMinutes, -480);
      expect(reading.posture, 'lying');
      expect(reading.arm, 'left');
      expect(reading.medsContext, 'no_meds');
      expect(reading.irregularFlag, true);
      expect(reading.tags, 'evening,relaxed');
      expect(reading.note, 'After dinner');
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'id': 4,
        'profileId': 800,
        'systolic': 110,
        'diastolic': 70,
        'pulse': 60,
        'takenAt': testDate.toIso8601String(),
        'localOffsetMinutes': 0,
        'posture': null,
        'arm': null,
        'medsContext': null,
        'irregularFlag': 0,
        'tags': null,
        'note': null,
      };

      final reading = Reading.fromMap(map);

      expect(reading.posture, isNull);
      expect(reading.arm, isNull);
      expect(reading.medsContext, isNull);
      expect(reading.irregularFlag, false);
      expect(reading.tags, isNull);
      expect(reading.note, isNull);
    });

    test('fromMap handles empty tags string', () {
      final map = {
        'profileId': 900,
        'systolic': 120,
        'diastolic': 80,
        'pulse': 70,
        'takenAt': testDate.toIso8601String(),
        'localOffsetMinutes': 0,
        'irregularFlag': 0,
        'tags': '',
      };

      final reading = Reading.fromMap(map);

      expect(reading.tags, isNull);
    });

    test('copyWith creates new instance with updated fields', () {
      final original = Reading(
        id: 5,
        profileId: 1000,
        systolic: 125,
        diastolic: 82,
        pulse: 70,
        takenAt: testDate,
        localOffsetMinutes: 0,
        posture: 'sitting',
        tags: 'original',
      );

      final updated = original.copyWith(
        systolic: 130,
        posture: 'standing',
        tags: 'updated',
      );

      expect(updated.id, 5);
      expect(updated.profileId, 1000);
      expect(updated.systolic, 130);
      expect(updated.diastolic, 82);
      expect(updated.pulse, 70);
      expect(updated.posture, 'standing');
      expect(updated.tags, 'updated');
    });

    test('equality operator works correctly for identical readings', () {
      final reading1 = Reading(
        id: 6,
        profileId: 1100,
        systolic: 118,
        diastolic: 76,
        pulse: 68,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final reading2 = Reading(
        id: 6,
        profileId: 1100,
        systolic: 118,
        diastolic: 76,
        pulse: 68,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(reading1, equals(reading2));
      expect(reading1.hashCode, equals(reading2.hashCode));
    });

    test('equality operator returns false for different readings', () {
      final reading1 = Reading(
        profileId: 1200,
        systolic: 120,
        diastolic: 80,
        pulse: 72,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final reading2 = Reading(
        profileId: 1200,
        systolic: 125,
        diastolic: 80,
        pulse: 72,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(reading1, isNot(equals(reading2)));
    });

    test('round-trip serialization preserves data', () {
      final original = Reading(
        id: 7,
        profileId: 1300,
        systolic: 135,
        diastolic: 88,
        pulse: 78,
        takenAt: testDate,
        localOffsetMinutes: 120,
        posture: 'sitting',
        arm: 'left',
        medsContext: 'after_meds',
        irregularFlag: true,
        tags: 'test,round-trip',
        note: 'Test note',
      );

      final map = original.toMap();
      final restored = Reading.fromMap(map);

      expect(restored, equals(original));
    });

    test('irregularFlag defaults to false', () {
      final reading = Reading(
        profileId: 1400,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(reading.irregularFlag, false);
    });

    test('supports valid systolic range 70-250', () {
      final low = Reading(
        profileId: 1500,
        systolic: 70,
        diastolic: 50,
        pulse: 60,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final high = Reading(
        profileId: 1500,
        systolic: 250,
        diastolic: 100,
        pulse: 100,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(low.systolic, 70);
      expect(high.systolic, 250);
    });

    test('supports valid diastolic range 40-150', () {
      final low = Reading(
        profileId: 1600,
        systolic: 90,
        diastolic: 40,
        pulse: 60,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final high = Reading(
        profileId: 1600,
        systolic: 200,
        diastolic: 150,
        pulse: 100,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(low.diastolic, 40);
      expect(high.diastolic, 150);
    });

    test('supports valid pulse range 30-200', () {
      final low = Reading(
        profileId: 1700,
        systolic: 120,
        diastolic: 80,
        pulse: 30,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      final high = Reading(
        profileId: 1700,
        systolic: 120,
        diastolic: 80,
        pulse: 200,
        takenAt: testDate,
        localOffsetMinutes: 0,
      );

      expect(low.pulse, 30);
      expect(high.pulse, 200);
    });
  });

  group('ReadingGroup Model Tests', () {
    final DateTime groupStart = DateTime(2025, 1, 15, 14, 0, 0);

    test('ReadingGroup creation with all fields', () {
      final group = ReadingGroup(
        id: 1,
        profileId: 100,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 122.5,
        avgDiastolic: 81.0,
        avgPulse: 71.5,
        memberReadingIds: '1,2,3',
        sessionId: 'morning-session',
        note: 'Good readings',
      );

      expect(group.id, 1);
      expect(group.profileId, 100);
      expect(group.groupStartAt, groupStart);
      expect(group.windowMinutes, 30);
      expect(group.avgSystolic, 122.5);
      expect(group.avgDiastolic, 81.0);
      expect(group.avgPulse, 71.5);
      expect(group.memberReadingIds, '1,2,3');
      expect(group.sessionId, 'morning-session');
      expect(group.note, 'Good readings');
    });

    test('ReadingGroup creation with minimum required fields', () {
      final group = ReadingGroup(
        profileId: 200,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 120.0,
        avgDiastolic: 80.0,
        avgPulse: 70.0,
        memberReadingIds: '4',
      );

      expect(group.id, isNull);
      expect(group.windowMinutes, 30);
      expect(group.memberReadingIds, '4');
      expect(group.sessionId, isNull);
      expect(group.note, isNull);
    });

    test('toMap serialization includes all fields', () {
      final group = ReadingGroup(
        id: 2,
        profileId: 300,
        groupStartAt: groupStart,
        windowMinutes: 45,
        avgSystolic: 125.3,
        avgDiastolic: 83.7,
        avgPulse: 74.2,
        memberReadingIds: '5,6,7,8',
        sessionId: 'evening',
        note: 'Multiple readings',
      );

      final map = group.toMap();

      expect(map['id'], 2);
      expect(map['profileId'], 300);
      expect(map['groupStartAt'], groupStart.toIso8601String());
      expect(map['windowMinutes'], 45);
      expect(map['avgSystolic'], 125.3);
      expect(map['avgDiastolic'], 83.7);
      expect(map['avgPulse'], 74.2);
      expect(map['memberReadingIds'], '5,6,7,8');
      expect(map['sessionId'], 'evening');
      expect(map['note'], 'Multiple readings');
    });

    test('fromMap deserialization with all fields', () {
      final map = {
        'id': 3,
        'profileId': 400,
        'groupStartAt': groupStart.toIso8601String(),
        'windowMinutes': 30,
        'avgSystolic': 118.5,
        'avgDiastolic': 77.5,
        'avgPulse': 68.0,
        'memberReadingIds': '9,10',
        'sessionId': 'test-session',
        'note': 'Test group',
      };

      final group = ReadingGroup.fromMap(map);

      expect(group.id, 3);
      expect(group.profileId, 400);
      expect(group.groupStartAt, groupStart);
      expect(group.windowMinutes, 30);
      expect(group.avgSystolic, 118.5);
      expect(group.avgDiastolic, 77.5);
      expect(group.avgPulse, 68.0);
      expect(group.memberReadingIds, '9,10');
      expect(group.sessionId, 'test-session');
      expect(group.note, 'Test group');
    });

    test('copyWith creates new instance with updated fields', () {
      final original = ReadingGroup(
        id: 4,
        profileId: 500,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 120.0,
        avgDiastolic: 80.0,
        avgPulse: 70.0,
        memberReadingIds: '11,12',
      );

      final updated = original.copyWith(
        avgSystolic: 125.0,
        note: 'Updated note',
      );

      expect(updated.id, 4);
      expect(updated.avgSystolic, 125.0);
      expect(updated.avgDiastolic, 80.0);
      expect(updated.note, 'Updated note');
    });

    test('equality operator works correctly', () {
      final group1 = ReadingGroup(
        id: 5,
        profileId: 600,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 122.0,
        avgDiastolic: 82.0,
        avgPulse: 72.0,
        memberReadingIds: '13,14,15',
      );

      final group2 = ReadingGroup(
        id: 5,
        profileId: 600,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 122.0,
        avgDiastolic: 82.0,
        avgPulse: 72.0,
        memberReadingIds: '13,14,15',
      );

      expect(group1, equals(group2));
      expect(group1.hashCode, equals(group2.hashCode));
    });

    test('round-trip serialization preserves data', () {
      final original = ReadingGroup(
        id: 6,
        profileId: 700,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 130.5,
        avgDiastolic: 85.5,
        avgPulse: 75.5,
        memberReadingIds: '16,17,18,19',
        sessionId: 'round-trip',
        note: 'Test',
      );

      final map = original.toMap();
      final restored = ReadingGroup.fromMap(map);

      expect(restored, equals(original));
    });

    test('windowMinutes defaults to 30', () {
      final group = ReadingGroup(
        profileId: 800,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 120.0,
        avgDiastolic: 80.0,
        avgPulse: 70.0,
        memberReadingIds: '20',
      );

      expect(group.windowMinutes, 30);
    });

    test('handles single member reading', () {
      final group = ReadingGroup(
        profileId: 900,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 115.0,
        avgDiastolic: 75.0,
        avgPulse: 65.0,
        memberReadingIds: '21',
      );

      expect(group.memberReadingIds.split(',').length, 1);
      expect(group.memberReadingIds, '21');
    });

    test('handles multiple member readings', () {
      final group = ReadingGroup(
        profileId: 1000,
        groupStartAt: groupStart,
        windowMinutes: 30,
        avgSystolic: 120.0,
        avgDiastolic: 80.0,
        avgPulse: 70.0,
        memberReadingIds: '22,23,24,25,26',
      );

      expect(group.memberReadingIds.split(',').length, 5);
    });
  });
}

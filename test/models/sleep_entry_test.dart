import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SleepSource', () {
    test('toDbString returns correct values', () {
      expect(SleepSource.manual.toDbString(), equals('manual'));
      expect(SleepSource.import.toDbString(), equals('import'));
    });

    test('fromDbString parses correctly', () {
      expect(SleepSourceExtension.fromDbString('manual'),
          equals(SleepSource.manual));
      expect(SleepSourceExtension.fromDbString('import'),
          equals(SleepSource.import));
      expect(SleepSourceExtension.fromDbString('MANUAL'),
          equals(SleepSource.manual));
      expect(SleepSourceExtension.fromDbString('IMPORT'),
          equals(SleepSource.import));
    });

    test('fromDbString defaults to manual for unknown values', () {
      expect(SleepSourceExtension.fromDbString('unknown'),
          equals(SleepSource.manual));
    });
  });

  group('SleepEntry', () {
    final testStart = DateTime(2025, 12, 28, 22, 0);
    final testEnd = DateTime(2025, 12, 29, 6, 30);

    test('creates instance with required fields and auto-calculates duration',
        () {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
      );

      expect(entry.id, isNull);
      expect(entry.profileId, equals(1));
      expect(entry.startedAt, equals(testStart));
      expect(entry.endedAt, equals(testEnd));
      expect(entry.durationMinutes, equals(510)); // 8.5 hours
      expect(entry.source, equals(SleepSource.manual));
      expect(
          entry.localOffsetMinutes, equals(testEnd.timeZoneOffset.inMinutes));
      expect(entry.createdAt, isNotNull);
    });

    test('creates instance with explicit duration (no endedAt)', () {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
        durationMinutes: 480,
      );

      expect(entry.startedAt, equals(testStart));
      expect(entry.endedAt, isNull);
      expect(entry.durationMinutes, equals(480));
    });

    test('creates instance with all optional fields', () {
      final createdAt = DateTime(2025, 12, 29, 7, 0);
      final entry = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        quality: 4,
        localOffsetMinutes: 120,
        source: SleepSource.import,
        sourceMetadata: '{"device":"fitbit"}',
        notes: 'Good night sleep',
        createdAt: createdAt,
      );

      expect(entry.id, equals(42));
      expect(entry.quality, equals(4));
      expect(entry.localOffsetMinutes, equals(120));
      expect(entry.source, equals(SleepSource.import));
      expect(entry.sourceMetadata, equals('{"device":"fitbit"}'));
      expect(entry.notes, equals('Good night sleep'));
      expect(entry.createdAt, equals(createdAt));
    });

    test('explicit duration overrides auto-calculation', () {
      // endedAt would suggest 510 minutes, but we explicitly set 480
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 480,
      );

      expect(entry.durationMinutes, equals(480));
    });

    test('duration defaults to 0 when neither endedAt nor duration provided',
        () {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
      );

      expect(entry.durationMinutes, equals(0));
    });

    test('toMap includes all fields', () {
      final createdAt = DateTime(2025, 12, 29, 7, 0);
      final entry = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        quality: 4,
        localOffsetMinutes: 120,
        source: SleepSource.import,
        sourceMetadata: '{"device":"fitbit"}',
        notes: 'Good sleep',
        createdAt: createdAt,
      );

      final map = entry.toMap();

      expect(map['id'], equals(42));
      expect(map['profileId'], equals(1));
      expect(map['startedAt'], equals(testStart.toIso8601String()));
      expect(map['endedAt'], equals(testEnd.toIso8601String()));
      expect(map['durationMinutes'], equals(510));
      expect(map['quality'], equals(4));
      expect(map['localOffsetMinutes'], equals(120));
      expect(map['source'], equals('import'));
      expect(map['sourceMetadata'], equals('{"device":"fitbit"}'));
      expect(map['notes'], equals('Good sleep'));
      expect(map['createdAt'], equals(createdAt.toIso8601String()));
    });

    test('toMap excludes null id', () {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
        durationMinutes: 480,
      );

      final map = entry.toMap();
      expect(map.containsKey('id'), isFalse);
    });

    test('toMap handles null endedAt', () {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: testStart,
        durationMinutes: 480,
      );

      final map = entry.toMap();
      expect(map['endedAt'], isNull);
    });

    test('fromMap reconstructs entry correctly', () {
      final createdAt = DateTime(2025, 12, 29, 7, 0);
      final map = {
        'id': 42,
        'profileId': 1,
        'startedAt': testStart.toIso8601String(),
        'endedAt': testEnd.toIso8601String(),
        'durationMinutes': 510,
        'quality': 4,
        'localOffsetMinutes': 120,
        'source': 'import',
        'sourceMetadata': '{"device":"fitbit"}',
        'notes': 'Good sleep',
        'createdAt': createdAt.toIso8601String(),
      };

      final entry = SleepEntry.fromMap(map);

      expect(entry.id, equals(42));
      expect(entry.profileId, equals(1));
      expect(entry.startedAt, equals(testStart));
      expect(entry.endedAt, equals(testEnd));
      expect(entry.durationMinutes, equals(510));
      expect(entry.quality, equals(4));
      expect(entry.localOffsetMinutes, equals(120));
      expect(entry.source, equals(SleepSource.import));
      expect(entry.sourceMetadata, equals('{"device":"fitbit"}'));
      expect(entry.notes, equals('Good sleep'));
      expect(entry.createdAt, equals(createdAt));
    });

    test('fromMap handles null optional fields', () {
      final map = {
        'profileId': 1,
        'startedAt': testStart.toIso8601String(),
        'durationMinutes': 480,
        'localOffsetMinutes': 0,
        'source': 'manual',
        'createdAt': testStart.toIso8601String(),
      };

      final entry = SleepEntry.fromMap(map);

      expect(entry.id, isNull);
      expect(entry.endedAt, isNull);
      expect(entry.quality, isNull);
      expect(entry.sourceMetadata, isNull);
      expect(entry.notes, isNull);
    });

    test('round-trip serialization preserves data', () {
      final original = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        quality: 4,
        localOffsetMinutes: 120,
        source: SleepSource.import,
        sourceMetadata: '{"device":"fitbit"}',
        notes: 'Test',
        createdAt: testEnd,
      );

      final map = original.toMap();
      final reconstructed = SleepEntry.fromMap(map);

      expect(reconstructed, equals(original));
    });

    test('copyWith creates new instance with updated fields', () {
      final original = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        quality: 3,
      );

      final updated = original.copyWith(
        quality: 5,
        notes: 'Updated note',
      );

      expect(updated.id, equals(42));
      expect(updated.profileId, equals(1));
      expect(updated.quality, equals(5));
      expect(updated.notes, equals('Updated note'));
      expect(updated.startedAt, equals(testStart));
      expect(updated.endedAt, equals(testEnd));
    });

    test('copyWith preserves original when no fields specified', () {
      final original = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        durationMinutes: 480,
      );

      final copy = original.copyWith();
      expect(copy, equals(original));
    });

    test('equality works correctly', () {
      final entry1 = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        createdAt: testEnd,
      );

      final entry2 = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        createdAt: testEnd,
      );

      final entry3 = SleepEntry(
        id: 43,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        createdAt: testEnd,
      );

      expect(entry1, equals(entry2));
      expect(entry1, isNot(equals(entry3)));
    });

    test('hashCode is consistent', () {
      final entry1 = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        createdAt: testEnd,
      );

      final entry2 = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
        createdAt: testEnd,
      );

      expect(entry1.hashCode, equals(entry2.hashCode));
    });

    test('toString includes key information', () {
      final entry = SleepEntry(
        id: 42,
        profileId: 1,
        startedAt: testStart,
        endedAt: testEnd,
        durationMinutes: 510,
      );

      final str = entry.toString();
      expect(str, contains('42'));
      expect(str, contains('510'));
      expect(str, contains(testEnd.toString()));
    });
  });
}

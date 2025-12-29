import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService dbService;
  late SleepService sleepService;

  setUpAll(() {
    // Initialize FFI for in-memory database testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    // Create in-memory database for each test
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          // Use same schema as production
          await db.execute('''
            CREATE TABLE Profile (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
              colorHex TEXT,
              avatarIcon TEXT,
              yearOfBirth INTEGER,
              preferredUnits TEXT NOT NULL DEFAULT 'mmHg',
              createdAt TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE SleepEntry (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              startedAt TEXT NOT NULL,
              endedAt TEXT,
              durationMinutes INTEGER NOT NULL,
              quality INTEGER,
              localOffsetMinutes INTEGER NOT NULL,
              source TEXT NOT NULL DEFAULT 'manual',
              sourceMetadata TEXT,
              notes TEXT,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_sleepentry_profile_time 
            ON SleepEntry(profileId, endedAt DESC)
          ''');

          await db.execute('''
            CREATE INDEX idx_sleepentry_profile_started 
            ON SleepEntry(profileId, startedAt)
          ''');

          // Create test profile
          await db.insert('Profile', {
            'name': 'Test Profile',
            'createdAt': DateTime.now().toIso8601String(),
          });
        },
      ),
    );

    dbService = DatabaseService(testDatabase: db);
    sleepService = SleepService(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('SleepService - Create', () {
    test('creates sleep entry with all fields', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        endedAt: DateTime(2025, 12, 29, 6, 30),
        quality: 4,
        notes: 'Good sleep',
      );

      final created = await sleepService.createSleepEntry(entry);

      expect(created.id, isNotNull);
      expect(created.durationMinutes, equals(510));
      expect(created.quality, equals(4));
      expect(created.notes, equals('Good sleep'));
    });

    test('creates sleep entry with minimal fields', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      final created = await sleepService.createSleepEntry(entry);

      expect(created.id, isNotNull);
      expect(created.durationMinutes, equals(480));
      expect(created.endedAt, isNull);
      expect(created.quality, isNull);
    });

    test('accepts duration less than 60 (warning only)', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 30,
      );

      // Should succeed - validation only warns, doesn't block
      final created = await sleepService.createSleepEntry(entry);
      expect(created.id, isNotNull);
      expect(created.durationMinutes, equals(30));
    });

    test('throws on invalid duration (too long)', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 1500,
      );

      expect(
        () => sleepService.createSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid quality (too low)', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
        quality: 0,
      );

      expect(
        () => sleepService.createSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid quality (too high)', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
        quality: 6,
      );

      expect(
        () => sleepService.createSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid times (end before start)', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 29, 6, 0),
        endedAt: DateTime(2025, 12, 29, 5, 0),
      );

      expect(
        () => sleepService.createSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SleepService - Read', () {
    test('getSleepEntry retrieves existing entry', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      final created = await sleepService.createSleepEntry(entry);
      final retrieved = await sleepService.getSleepEntry(created.id!);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(created.id));
      expect(retrieved.durationMinutes, equals(480));
    });

    test('getSleepEntry returns null for non-existent entry', () async {
      final retrieved = await sleepService.getSleepEntry(9999);
      expect(retrieved, isNull);
    });

    test('listSleepEntries returns all entries for profile', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 26, 22, 0),
          endedAt: DateTime(2025, 12, 27, 6, 0),
        ),
      );

      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 27, 22, 0),
          endedAt: DateTime(2025, 12, 28, 6, 0),
        ),
      );

      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          endedAt: DateTime(2025, 12, 29, 6, 0),
        ),
      );

      final entries = await sleepService.listSleepEntries(profileId: 1);

      expect(entries.length, equals(3));
      // Should be ordered by endedAt DESC
      expect(entries[0].endedAt, equals(DateTime(2025, 12, 29, 6, 0)));
      expect(entries[1].endedAt, equals(DateTime(2025, 12, 28, 6, 0)));
      expect(entries[2].endedAt, equals(DateTime(2025, 12, 27, 6, 0)));
    });

    test('listSleepEntries filters by date range', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 26, 22, 0),
          endedAt: DateTime(2025, 12, 27, 6, 0),
        ),
      );

      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 27, 22, 0),
          endedAt: DateTime(2025, 12, 28, 6, 0),
        ),
      );

      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          endedAt: DateTime(2025, 12, 29, 6, 0),
        ),
      );

      final entries = await sleepService.listSleepEntries(
        profileId: 1,
        from: DateTime(2025, 12, 28),
        to: DateTime(2025, 12, 29, 23, 59),
      );

      expect(entries.length, equals(2));
    });
  });

  group('SleepService - Update', () {
    test('updates existing sleep entry', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
        quality: 3,
      );

      final created = await sleepService.createSleepEntry(entry);
      final updated = await sleepService.updateSleepEntry(
        created.copyWith(quality: 5, notes: 'Updated'),
      );

      expect(updated.quality, equals(5));
      expect(updated.notes, equals('Updated'));

      final retrieved = await sleepService.getSleepEntry(created.id!);
      expect(retrieved!.quality, equals(5));
    });

    test('throws when updating entry without ID', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      expect(
        () => sleepService.updateSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating non-existent entry', () async {
      final entry = SleepEntry(
        id: 9999,
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      expect(
        () => sleepService.updateSleepEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating to invalid duration', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      final created = await sleepService.createSleepEntry(entry);

      expect(
        () => sleepService.updateSleepEntry(
          created.copyWith(durationMinutes: 2000),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('SleepService - Delete', () {
    test('deletes existing sleep entry', () async {
      final entry = SleepEntry(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        durationMinutes: 480,
      );

      final created = await sleepService.createSleepEntry(entry);
      final deleted = await sleepService.deleteSleepEntry(created.id!);

      expect(deleted, isTrue);

      final retrieved = await sleepService.getSleepEntry(created.id!);
      expect(retrieved, isNull);
    });

    test('returns false when deleting non-existent entry', () async {
      final deleted = await sleepService.deleteSleepEntry(9999);
      expect(deleted, isFalse);
    });
  });

  group('SleepService - Correlation', () {
    test('findSleepForMorningReading finds recent sleep', () async {
      final readingTime = DateTime(2025, 12, 29, 8, 0);

      // Sleep ending at 6:30 AM (1.5 hours before reading)
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          endedAt: DateTime(2025, 12, 29, 6, 30),
        ),
      );

      final found = await sleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: readingTime,
      );

      expect(found, isNotNull);
      expect(found!.endedAt, equals(DateTime(2025, 12, 29, 6, 30)));
    });

    test('findSleepForMorningReading respects lookback window', () async {
      final readingTime = DateTime(2025, 12, 29, 8, 0);

      // Sleep ending at 12:00 PM previous day (20 hours before, outside 18h window)
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 4, 0),
          endedAt: DateTime(2025, 12, 28, 12, 0),
        ),
      );

      final found = await sleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: readingTime,
        lookbackHours: 18,
      );

      expect(found, isNull);
    });

    test('findSleepForMorningReading uses custom lookback', () async {
      final readingTime = DateTime(2025, 12, 29, 8, 0);

      // Sleep ending at 12:00 PM previous day (20 hours before)
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 4, 0),
          endedAt: DateTime(2025, 12, 28, 12, 0),
        ),
      );

      final found = await sleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: readingTime,
        lookbackHours: 24,
      );

      expect(found, isNotNull);
    });

    test('findSleepForMorningReading ignores sleep without endedAt', () async {
      final readingTime = DateTime(2025, 12, 29, 8, 0);

      // Ongoing sleep (no endedAt)
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          durationMinutes: 480,
        ),
      );

      final found = await sleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: readingTime,
      );

      expect(found, isNull);
    });

    test('findSleepForMorningReading returns most recent when multiple match',
        () async {
      final readingTime = DateTime(2025, 12, 29, 8, 0);

      // Earlier sleep
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 14, 0),
          endedAt: DateTime(2025, 12, 28, 16, 0),
        ),
      );

      // Later sleep (should be returned)
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          endedAt: DateTime(2025, 12, 29, 6, 30),
        ),
      );

      final found = await sleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: readingTime,
      );

      expect(found, isNotNull);
      expect(found!.endedAt, equals(DateTime(2025, 12, 29, 6, 30)));
    });
  });

  group('SleepService - Duplicate Detection', () {
    test('isDuplicate returns false when no duplicate exists', () async {
      final isDupe = await sleepService.isDuplicate(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        source: SleepSource.import,
        sourceMetadata: '{"device":"fitbit"}',
      );

      expect(isDupe, isFalse);
    });

    test('isDuplicate returns true when duplicate exists', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          durationMinutes: 480,
          source: SleepSource.import,
          sourceMetadata: '{"device":"fitbit"}',
        ),
      );

      final isDupe = await sleepService.isDuplicate(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        source: SleepSource.import,
        sourceMetadata: '{"device":"fitbit"}',
      );

      expect(isDupe, isTrue);
    });

    test('isDuplicate checks sourceMetadata when provided', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          durationMinutes: 480,
          source: SleepSource.import,
          sourceMetadata: '{"device":"fitbit"}',
        ),
      );

      // Different metadata - not a duplicate
      final isDupe = await sleepService.isDuplicate(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        source: SleepSource.import,
        sourceMetadata: '{"device":"garmin"}',
      );

      expect(isDupe, isFalse);
    });

    test('isDuplicate works without sourceMetadata', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          durationMinutes: 480,
          source: SleepSource.manual,
        ),
      );

      final isDupe = await sleepService.isDuplicate(
        profileId: 1,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        source: SleepSource.manual,
      );

      expect(isDupe, isTrue);
    });

    test('isDuplicate distinguishes between profiles', () async {
      await sleepService.createSleepEntry(
        SleepEntry(
          profileId: 1,
          startedAt: DateTime(2025, 12, 28, 22, 0),
          durationMinutes: 480,
          source: SleepSource.manual,
        ),
      );

      // Different profile - not a duplicate
      final isDupe = await sleepService.isDuplicate(
        profileId: 2,
        startedAt: DateTime(2025, 12, 28, 22, 0),
        source: SleepSource.manual,
      );

      expect(isDupe, isFalse);
    });
  });
}

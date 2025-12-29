import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database testDb;
  late DatabaseService databaseService;
  late ReadingService readingService;
  late AveragingService averagingService;

  setUp(() async {
    // Create in-memory unencrypted database for testing
    testDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          // Create schema matching production
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
            CREATE TABLE Reading (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              systolic INTEGER NOT NULL,
              diastolic INTEGER NOT NULL,
              pulse INTEGER NOT NULL,
              takenAt TEXT NOT NULL,
              localOffsetMinutes INTEGER NOT NULL,
              posture TEXT,
              arm TEXT,
              medsContext TEXT,
              irregularFlag INTEGER NOT NULL DEFAULT 0,
              tags TEXT,
              note TEXT,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_reading_profile_time 
            ON Reading(profileId, takenAt DESC)
          ''');

          await db.execute('''
            CREATE TABLE ReadingGroup (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              groupStartAt TEXT NOT NULL,
              windowMinutes INTEGER NOT NULL DEFAULT 30,
              avgSystolic REAL NOT NULL,
              avgDiastolic REAL NOT NULL,
              avgPulse REAL NOT NULL,
              memberReadingIds TEXT NOT NULL,
              sessionId TEXT,
              note TEXT,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');
        },
      ),
    );

    // Inject test database into services
    databaseService = DatabaseService(testDatabase: testDb);
    readingService = ReadingService(databaseService: databaseService);
    averagingService = AveragingService(
      databaseService: databaseService,
      readingService: readingService,
    );

    // Create test profile
    await testDb.insert('Profile', {
      'id': 1,
      'name': 'Test User',
      'preferredUnits': 'mmHg',
      'createdAt': DateTime.now().toIso8601String(),
    });
  });

  tearDown(() async {
    await testDb.close();
  });

  group('createOrUpdateGroupsForReading', () {
    test('single reading creates group of 1', () async {
      final reading = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId = await readingService.createReading(reading);
      final persistedReading = await readingService.getReading(readingId);

      await averagingService.createOrUpdateGroupsForReading(persistedReading!);

      final groups = await testDb.query('ReadingGroup');

      expect(groups.length, 1);
      expect(groups.first['memberReadingIds'], '$readingId');
      expect(groups.first['avgSystolic'], 120.0);
      expect(groups.first['avgDiastolic'], 80.0);
      expect(groups.first['avgPulse'], 70.0);
    });

    test('two readings within 30 minutes form one group', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 20),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      final groups = await testDb.query('ReadingGroup');

      expect(groups.length, 1);
      expect(groups.first['memberReadingIds'], '$readingId1,$readingId2');
      expect(groups.first['avgSystolic'], 125.0);
      expect(groups.first['avgDiastolic'], 82.5);
      expect(groups.first['avgPulse'], 72.5);
    });

    test('reading outside 30-minute window creates new group', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 35),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      final groups =
          await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');

      expect(groups.length, 2);
      expect(groups[0]['memberReadingIds'], '$readingId1');
      expect(groups[1]['memberReadingIds'], '$readingId2');
    });

    test('back-dated reading recomputes groups correctly', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      final reading2 = Reading(
        profileId: 1,
        systolic: 140,
        diastolic: 90,
        pulse: 80,
        takenAt: DateTime(2024, 1, 1, 11, 0),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      // Verify two separate groups exist
      var groups =
          await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');
      expect(groups.length, 2);

      // Add back-dated reading between the two
      final reading3 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 15),
        localOffsetMinutes: -300,
      );

      final readingId3 = await readingService.createReading(reading3);
      final persistedReading3 = await readingService.getReading(readingId3);
      await averagingService.createOrUpdateGroupsForReading(persistedReading3!);

      // Verify first group now has two readings
      groups = await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');
      expect(groups.length, 2);
      expect(groups[0]['memberReadingIds'], '$readingId1,$readingId3');
      expect(groups[0]['avgSystolic'], 125.0);
      expect(groups[1]['memberReadingIds'], '$readingId2');
    });

    test('manual session ID forces new group', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
        medsContext: 'session-1',
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 15),
        localOffsetMinutes: -300,
        medsContext: 'session-2',
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      final groups =
          await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');

      expect(groups.length, 2);
      expect(groups[0]['memberReadingIds'], '$readingId1');
      expect(groups[0]['sessionId'], 'session-1');
      expect(groups[1]['memberReadingIds'], '$readingId2');
      expect(groups[1]['sessionId'], 'session-2');
    });

    test('does not delete unrelated groups outside time window', () async {
      // Create reading at 10:00
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      // Create reading at 14:00 (4 hours later, well outside window)
      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 14, 0),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      // Verify both groups still exist
      final groups = await testDb.query('ReadingGroup');
      expect(groups.length, 2);

      // Now add a reading at 10:15 (within first group's window)
      final reading3 = Reading(
        profileId: 1,
        systolic: 125,
        diastolic: 82,
        pulse: 72,
        takenAt: DateTime(2024, 1, 1, 10, 15),
        localOffsetMinutes: -300,
      );

      final readingId3 = await readingService.createReading(reading3);
      final persistedReading3 = await readingService.getReading(readingId3);
      await averagingService.createOrUpdateGroupsForReading(persistedReading3!);

      // Verify second group at 14:00 is still intact
      final groupsAfter =
          await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');
      expect(groupsAfter.length, 2);
      expect(groupsAfter[0]['memberReadingIds'], '$readingId1,$readingId3');
      expect(groupsAfter[1]['memberReadingIds'], '$readingId2'); // Unchanged
    });

    test('throws StateError if reading has no ID', () async {
      final reading = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      expect(
        () => averagingService.createOrUpdateGroupsForReading(reading),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('recomputeGroupsForProfile', () {
    test('recomputes all groups from scratch', () async {
      final readings = [
        Reading(
          profileId: 1,
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          takenAt: DateTime(2024, 1, 1, 10, 0),
          localOffsetMinutes: -300,
        ),
        Reading(
          profileId: 1,
          systolic: 125,
          diastolic: 82,
          pulse: 72,
          takenAt: DateTime(2024, 1, 1, 10, 15),
          localOffsetMinutes: -300,
        ),
        Reading(
          profileId: 1,
          systolic: 135,
          diastolic: 88,
          pulse: 78,
          takenAt: DateTime(2024, 1, 1, 11, 0),
          localOffsetMinutes: -300,
        ),
      ];

      for (final reading in readings) {
        await readingService.createReading(reading);
      }

      await averagingService.recomputeGroupsForProfile(1);

      final groups =
          await testDb.query('ReadingGroup', orderBy: 'groupStartAt ASC');

      expect(groups.length, 2);
      expect(groups[0]['avgSystolic'], 122.5);
      expect(groups[1]['avgSystolic'], 135.0);
    });

    test('handles empty profile gracefully', () async {
      await averagingService.recomputeGroupsForProfile(999);

      final groups =
          await testDb.query('ReadingGroup', where: 'profileId = 999');
      expect(groups.length, 0);
    });
  });

  group('deleteGroupsForReading', () {
    test('deletes groups containing the reading with exact ID match', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      final persistedReading1 = await readingService.getReading(readingId1);
      await averagingService.createOrUpdateGroupsForReading(persistedReading1!);

      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 15),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      final persistedReading2 = await readingService.getReading(readingId2);
      await averagingService.createOrUpdateGroupsForReading(persistedReading2!);

      var groups = await testDb.query('ReadingGroup');
      expect(groups.length, 1);

      await averagingService.deleteGroupsForReading(readingId1);

      groups = await testDb.query('ReadingGroup');
      expect(groups.length, 0);
    });

    test('does not match partial ID (e.g., 1 does not match 10)', () async {
      // Create reading with ID 1
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId1))!,
      );

      // Create 9 more readings to ensure we get ID 10
      for (int i = 0; i < 9; i++) {
        await readingService.createReading(
          Reading(
            profileId: 1,
            systolic: 120 + i,
            diastolic: 80,
            pulse: 70,
            takenAt: DateTime(2024, 1, 1, 12, i),
            localOffsetMinutes: -300,
          ),
        );
      }

      // Create reading with ID 10 (in different time window)
      final reading10 = Reading(
        profileId: 1,
        systolic: 140,
        diastolic: 90,
        pulse: 80,
        takenAt: DateTime(2024, 1, 1, 14, 0),
        localOffsetMinutes: -300,
      );

      final readingId10 = await readingService.createReading(reading10);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId10))!,
      );

      // Verify we have at least 2 groups
      var groups = await testDb.query('ReadingGroup');
      final initialGroupCount = groups.length;
      expect(initialGroupCount, greaterThanOrEqualTo(2));

      // Delete groups containing reading ID 1
      await averagingService.deleteGroupsForReading(readingId1);

      // Verify group with ID 10 still exists
      groups = await testDb.query('ReadingGroup');
      final remaining = groups.where(
        (g) => (g['memberReadingIds'] as String).contains('$readingId10'),
      );
      expect(
        remaining.length,
        1,
        reason: 'Group containing ID 10 should still exist',
      );
    });
  });

  group('edge cases', () {
    test('handles readings at exact 30-minute boundary', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId1))!,
      );

      // Exactly 30 minutes later
      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 30),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId2))!,
      );

      final groups = await testDb.query('ReadingGroup');
      expect(
        groups.length,
        1,
        reason: 'Readings exactly 30 min apart should group',
      );
    });

    test('handles readings just beyond 30-minute boundary', () async {
      final reading1 = Reading(
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2024, 1, 1, 10, 0),
        localOffsetMinutes: -300,
      );

      final readingId1 = await readingService.createReading(reading1);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId1))!,
      );

      // 31 minutes later
      final reading2 = Reading(
        profileId: 1,
        systolic: 130,
        diastolic: 85,
        pulse: 75,
        takenAt: DateTime(2024, 1, 1, 10, 31),
        localOffsetMinutes: -300,
      );

      final readingId2 = await readingService.createReading(reading2);
      await averagingService.createOrUpdateGroupsForReading(
        (await readingService.getReading(readingId2))!,
      );

      final groups = await testDb.query('ReadingGroup');
      expect(
        groups.length,
        2,
        reason: 'Readings > 30 min apart should not group',
      );
    });
  });
}

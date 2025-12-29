import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService dbService;
  late WeightService weightService;

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
            CREATE TABLE WeightEntry (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              takenAt TEXT NOT NULL,
              localOffsetMinutes INTEGER NOT NULL,
              weightValue REAL NOT NULL,
              unit TEXT NOT NULL,
              notes TEXT,
              saltIntake TEXT,
              exerciseLevel TEXT,
              stressLevel TEXT,
              sleepQuality TEXT,
              source TEXT NOT NULL DEFAULT 'manual',
              sourceMetadata TEXT,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE INDEX idx_weightentry_profile_time 
            ON WeightEntry(profileId, takenAt DESC)
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
    weightService = WeightService(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('WeightService - Create', () {
    test('creates weight entry with all fields', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.5,
        unit: WeightUnit.kg,
        notes: 'Morning weight',
        saltIntake: 'Low',
        exerciseLevel: 'Moderate',
        stressLevel: 'Low',
        sleepQuality: 'Good',
      );

      final created = await weightService.createWeightEntry(entry);

      expect(created.id, isNotNull);
      expect(created.weightValue, equals(70.5));
      expect(created.unit, equals(WeightUnit.kg));
      expect(created.notes, equals('Morning weight'));
      expect(created.saltIntake, equals('Low'));
    });

    test('creates weight entry with minimal fields', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 155.0,
        unit: WeightUnit.lbs,
      );

      final created = await weightService.createWeightEntry(entry);

      expect(created.id, isNotNull);
      expect(created.weightValue, equals(155.0));
      expect(created.unit, equals(WeightUnit.lbs));
      expect(created.notes, isNull);
    });

    test('throws on invalid weight (too low)', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 0,
        unit: WeightUnit.kg,
      );

      expect(
        () => weightService.createWeightEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid weight (too high for kg)', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 350,
        unit: WeightUnit.kg,
      );

      expect(
        () => weightService.createWeightEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws on invalid weight (too high for lbs)', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 700,
        unit: WeightUnit.lbs,
      );

      expect(
        () => weightService.createWeightEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('WeightService - Read', () {
    test('getWeightEntry retrieves existing entry', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final created = await weightService.createWeightEntry(entry);
      final retrieved = await weightService.getWeightEntry(created.id!);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, equals(created.id));
      expect(retrieved.weightValue, equals(70.0));
    });

    test('getWeightEntry returns null for non-existent entry', () async {
      final retrieved = await weightService.getWeightEntry(9999);
      expect(retrieved, isNull);
    });

    test('listWeightEntries returns all entries for profile', () async {
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 27, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 28, 8, 0),
        weightValue: 70.5,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 71.0,
        unit: WeightUnit.kg,
      ),);

      final entries = await weightService.listWeightEntries(profileId: 1);

      expect(entries.length, equals(3));
      // Should be ordered by takenAt DESC
      expect(entries[0].weightValue, equals(71.0));
      expect(entries[1].weightValue, equals(70.5));
      expect(entries[2].weightValue, equals(70.0));
    });

    test('listWeightEntries filters by date range', () async {
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 27, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 28, 8, 0),
        weightValue: 70.5,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 71.0,
        unit: WeightUnit.kg,
      ),);

      final entries = await weightService.listWeightEntries(
        profileId: 1,
        from: DateTime(2025, 12, 28),
        to: DateTime(2025, 12, 29, 23, 59),
      );

      expect(entries.length, equals(2));
      expect(entries[0].weightValue, equals(71.0));
      expect(entries[1].weightValue, equals(70.5));
    });

    test('getLatestWeightEntry returns most recent entry', () async {
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 27, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 71.0,
        unit: WeightUnit.kg,
      ),);

      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 28, 8, 0),
        weightValue: 70.5,
        unit: WeightUnit.kg,
      ),);

      final latest = await weightService.getLatestWeightEntry(1);

      expect(latest, isNotNull);
      expect(latest!.weightValue, equals(71.0));
    });

    test('getLatestWeightEntry returns null when no entries exist', () async {
      final latest = await weightService.getLatestWeightEntry(1);
      expect(latest, isNull);
    });
  });

  group('WeightService - Update', () {
    test('updates existing weight entry', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final created = await weightService.createWeightEntry(entry);
      final updated = await weightService.updateWeightEntry(
        created.copyWith(weightValue: 71.0, notes: 'Updated'),
      );

      expect(updated.weightValue, equals(71.0));
      expect(updated.notes, equals('Updated'));

      final retrieved = await weightService.getWeightEntry(created.id!);
      expect(retrieved!.weightValue, equals(71.0));
    });

    test('throws when updating entry without ID', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      expect(
        () => weightService.updateWeightEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating non-existent entry', () async {
      final entry = WeightEntry(
        id: 9999,
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      expect(
        () => weightService.updateWeightEntry(entry),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('throws when updating to invalid weight', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final created = await weightService.createWeightEntry(entry);

      expect(
        () => weightService.updateWeightEntry(
          created.copyWith(weightValue: 0),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('WeightService - Delete', () {
    test('deletes existing weight entry', () async {
      final entry = WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      );

      final created = await weightService.createWeightEntry(entry);
      final deleted = await weightService.deleteWeightEntry(created.id!);

      expect(deleted, isTrue);

      final retrieved = await weightService.getWeightEntry(created.id!);
      expect(retrieved, isNull);
    });

    test('returns false when deleting non-existent entry', () async {
      final deleted = await weightService.deleteWeightEntry(9999);
      expect(deleted, isFalse);
    });
  });

  group('WeightService - Correlation', () {
    test('findWeightForReading finds nearest weight within same day', () async {
      final readingTime = DateTime(2025, 12, 29, 10, 0);

      // Weight at 9:45 (15 mins before - nearer)
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 9, 45),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      // Weight at 10:30 (30 mins after - further)
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 10, 30),
        weightValue: 70.5,
        unit: WeightUnit.kg,
      ),);

      final found = await weightService.findWeightForReading(
        profileId: 1,
        readingTime: readingTime,
      );

      expect(found, isNotNull);
      expect(found!.weightValue, equals(70.0)); // Nearest by time
    });

    test('findWeightForReading respects time window', () async {
      final readingTime = DateTime(2025, 12, 29, 10, 0);

      // Weight at 8:00 (2 hours before, outside 1h window)
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 0),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      final found = await weightService.findWeightForReading(
        profileId: 1,
        readingTime: readingTime,
        window: const Duration(hours: 1),
      );

      expect(found, isNull);
    });

    test('findWeightForReading does not cross day boundary', () async {
      final readingTime = DateTime(2025, 12, 29, 0, 30);

      // Weight on previous day at 23:45 (45 mins before, within 1h window)
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 28, 23, 45),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      final found = await weightService.findWeightForReading(
        profileId: 1,
        readingTime: readingTime,
      );

      // Should not find it because it's on a different day
      expect(found, isNull);
    });

    test('findWeightForReading uses custom window duration', () async {
      final readingTime = DateTime(2025, 12, 29, 10, 0);

      // Weight at 8:30 (1.5 hours before)
      await weightService.createWeightEntry(WeightEntry(
        profileId: 1,
        takenAt: DateTime(2025, 12, 29, 8, 30),
        weightValue: 70.0,
        unit: WeightUnit.kg,
      ),);

      final found = await weightService.findWeightForReading(
        profileId: 1,
        readingTime: readingTime,
        window: const Duration(hours: 2),
      );

      expect(found, isNotNull);
      expect(found!.weightValue, equals(70.0));
    });

    test('findWeightForReading returns null when no entries in range',
        () async {
      final readingTime = DateTime(2025, 12, 29, 10, 0);

      final found = await weightService.findWeightForReading(
        profileId: 1,
        readingTime: readingTime,
      );

      expect(found, isNull);
    });
  });
}

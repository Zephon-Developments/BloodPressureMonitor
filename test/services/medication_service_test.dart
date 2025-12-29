import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService dbService;
  late MedicationService medService;

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
        version: 2,
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
            CREATE TABLE Medication (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              name TEXT NOT NULL,
              dosage TEXT,
              unit TEXT,
              frequency TEXT,
              scheduleMetadata TEXT,
              isActive INTEGER NOT NULL DEFAULT 1,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
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
    medService = MedicationService(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('MedicationService - Create', () {
    test('creates medication with all fields', () async {
      final med = Medication(
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
        frequency: 'daily',
        scheduleMetadata: '{"v":1}',
      );

      final created = await medService.createMedication(med);

      expect(created.id, isNotNull);
      expect(created.name, 'Aspirin');
      expect(created.dosage, '100');
      expect(created.unit, 'mg');
      expect(created.frequency, 'daily');
      expect(created.scheduleMetadata, '{"v":1}');
    });

    test('creates medication with minimal fields', () async {
      final med = Medication(
        profileId: 1,
        name: 'Ibuprofen',
      );

      final created = await medService.createMedication(med);

      expect(created.id, isNotNull);
      expect(created.name, 'Ibuprofen');
      expect(created.dosage, isNull);
      expect(created.unit, isNull);
      expect(created.frequency, isNull);
    });

    test('rejects medication with empty name', () async {
      final med = Medication(
        profileId: 1,
        name: '',
      );

      expect(
        () => medService.createMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects medication with name exceeding 120 chars', () async {
      final med = Medication(
        profileId: 1,
        name: 'A' * 121,
      );

      expect(
        () => medService.createMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects medication with dosage exceeding 120 chars', () async {
      final med = Medication(
        profileId: 1,
        name: 'Aspirin',
        dosage: 'A' * 121,
      );

      expect(
        () => medService.createMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects medication with unit exceeding 50 chars', () async {
      final med = Medication(
        profileId: 1,
        name: 'Aspirin',
        unit: 'A' * 51,
      );

      expect(
        () => medService.createMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects medication with frequency exceeding 120 chars', () async {
      final med = Medication(
        profileId: 1,
        name: 'Aspirin',
        frequency: 'A' * 121,
      );

      expect(
        () => medService.createMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MedicationService - Read', () {
    test('retrieves medication by id', () async {
      final created = await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );

      final retrieved = await medService.getMedication(created.id!);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.name, 'Aspirin');
    });

    test('returns null for non-existent medication', () async {
      final retrieved = await medService.getMedication(999);
      expect(retrieved, isNull);
    });

    test('lists medications by profile', () async {
      await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );
      await medService.createMedication(
        Medication(profileId: 1, name: 'Ibuprofen'),
      );

      final meds = await medService.listMedicationsByProfile(1);

      expect(meds.length, 2);
      expect(meds[0].name, 'Aspirin'); // Alphabetically first
      expect(meds[1].name, 'Ibuprofen');
    });

    test('lists are isolated by profile', () async {
      // Create second profile
      final db = await dbService.database;
      await db.insert('Profile', {
        'name': 'Profile 2',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await medService.createMedication(
        Medication(profileId: 1, name: 'Med1'),
      );
      await medService.createMedication(
        Medication(profileId: 2, name: 'Med2'),
      );

      final profile1Meds = await medService.listMedicationsByProfile(1);
      final profile2Meds = await medService.listMedicationsByProfile(2);

      expect(profile1Meds.length, 1);
      expect(profile1Meds[0].name, 'Med1');
      expect(profile2Meds.length, 1);
      expect(profile2Meds[0].name, 'Med2');
    });

    test('searches medications by name substring', () async {
      await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );
      await medService.createMedication(
        Medication(profileId: 1, name: 'Ibuprofen'),
      );
      await medService.createMedication(
        Medication(profileId: 1, name: 'Paracetamol'),
      );

      final results = await medService.searchMedicationsByName(
        profileId: 1,
        searchTerm: 'pro',
      );

      expect(results.length, 1);
      expect(results[0].name, 'Ibuprofen');
    });

    test('search is case-insensitive', () async {
      await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );

      final results = await medService.searchMedicationsByName(
        profileId: 1,
        searchTerm: 'ASPIRIN',
      );

      expect(results.length, 1);
      expect(results[0].name, 'Aspirin');
    });
  });

  group('MedicationService - Update', () {
    test('updates medication fields', () async {
      final created = await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin', dosage: '100'),
      );

      final updated = await medService.updateMedication(
        created.copyWith(dosage: '200', unit: 'mg'),
      );

      expect(updated.id, created.id);
      expect(updated.dosage, '200');
      expect(updated.unit, 'mg');
    });

    test('rejects update without id', () async {
      final med = Medication(profileId: 1, name: 'Aspirin');

      expect(
        () => medService.updateMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects update with invalid name', () async {
      final created = await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );

      expect(
        () => medService.updateMedication(created.copyWith(name: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects update for non-existent medication', () async {
      final med = Medication(id: 999, profileId: 1, name: 'Aspirin');

      expect(
        () => medService.updateMedication(med),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MedicationService - Delete', () {
    test('soft-deletes medication by setting isActive to false', () async {
      final created = await medService.createMedication(
        Medication(profileId: 1, name: 'Aspirin'),
      );

      final deleted = await medService.deleteMedication(created.id!);

      expect(deleted, isTrue);

      // Medication should still exist but be inactive
      final retrieved = await medService.getMedication(created.id!);
      expect(retrieved, isNotNull);
      expect(retrieved!.isActive, isFalse);

      // Should not appear in default active list
      final activeList = await medService.listMedicationsByProfile(1);
      expect(activeList.any((m) => m.id == created.id), isFalse);

      // Should appear in list with includeInactive
      final fullList = await medService.listMedicationsByProfile(
        1,
        includeInactive: true,
      );
      expect(fullList.any((m) => m.id == created.id), isTrue);
    });

    test('returns false when deleting non-existent medication', () async {
      final deleted = await medService.deleteMedication(999);
      expect(deleted, isFalse);
    });
  });
}

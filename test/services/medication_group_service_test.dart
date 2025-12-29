import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService dbService;
  late MedicationGroupService groupService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) async {
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
              createdAt TEXT NOT NULL,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');

          await db.execute('''
            CREATE TABLE MedicationGroup (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              name TEXT NOT NULL,
              memberMedicationIds TEXT NOT NULL,
              createdAt TEXT NOT NULL,
              FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
            )
          ''');

          // Create test profile
          await db.insert('Profile', {
            'name': 'Test Profile',
            'createdAt': DateTime.now().toIso8601String(),
          });

          // Create test medications
          await db.insert('Medication', {
            'profileId': 1,
            'name': 'Med1',
            'createdAt': DateTime.now().toIso8601String(),
          });
          await db.insert('Medication', {
            'profileId': 1,
            'name': 'Med2',
            'createdAt': DateTime.now().toIso8601String(),
          });
          await db.insert('Medication', {
            'profileId': 1,
            'name': 'Med3',
            'createdAt': DateTime.now().toIso8601String(),
          });
        },
      ),
    );

    dbService = DatabaseService(testDatabase: db);
    groupService = MedicationGroupService(dbService);
  });

  tearDown(() async {
    await dbService.close();
  });

  group('MedicationGroupService - Create', () {
    test('creates group with member medications', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2],
      );

      final created = await groupService.createGroup(group);

      expect(created.id, isNotNull);
      expect(created.name, 'Morning Meds');
      expect(created.memberMedicationIds, [1, 2]);
    });

    test('normalizes member IDs (sorts and deduplicates)', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Group',
        memberMedicationIds: [3, 1, 2, 1],
      );

      final created = await groupService.createGroup(group);

      expect(created.memberMedicationIds, [1, 2, 3]);
    });

    test('rejects group with empty name', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: '',
        memberMedicationIds: [1],
      );

      expect(
        () => groupService.createGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects group with name exceeding 120 chars', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'A' * 121,
        memberMedicationIds: [1],
      );

      expect(
        () => groupService.createGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects group with non-existent medication', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Invalid Group',
        memberMedicationIds: [1, 999],
      );

      expect(
        () => groupService.createGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects group with medications from different profile', () async {
      // Create second profile with medication
      final db = await dbService.database;
      await db.insert('Profile', {
        'name': 'Profile 2',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await db.insert('Medication', {
        'profileId': 2,
        'name': 'Med4',
        'createdAt': DateTime.now().toIso8601String(),
      });

      final group = MedicationGroup(
        profileId: 1,
        name: 'Cross-profile Group',
        memberMedicationIds: [1, 4], // 4 belongs to profile 2
      );

      expect(
        () => groupService.createGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('allows empty member list', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Empty Group',
        memberMedicationIds: [],
      );

      final created = await groupService.createGroup(group);

      expect(created.id, isNotNull);
      expect(created.memberMedicationIds, isEmpty);
    });
  });

  group('MedicationGroupService - Read', () {
    test('retrieves group by id', () async {
      final created = await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Morning Meds',
          memberMedicationIds: [1, 2],
        ),
      );

      final retrieved = await groupService.getGroup(created.id!);

      expect(retrieved, isNotNull);
      expect(retrieved!.id, created.id);
      expect(retrieved.name, 'Morning Meds');
      expect(retrieved.memberMedicationIds, [1, 2]);
    });

    test('returns null for non-existent group', () async {
      final retrieved = await groupService.getGroup(999);
      expect(retrieved, isNull);
    });

    test('lists groups by profile', () async {
      await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Morning Meds',
          memberMedicationIds: [1],
        ),
      );
      await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Evening Meds',
          memberMedicationIds: [2],
        ),
      );

      final groups = await groupService.listGroupsByProfile(1);

      expect(groups.length, 2);
      expect(groups[0].name, 'Evening Meds'); // Alphabetically first
      expect(groups[1].name, 'Morning Meds');
    });

    test('groups are isolated by profile', () async {
      final db = await dbService.database;
      await db.insert('Profile', {
        'name': 'Profile 2',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await db.insert('Medication', {
        'profileId': 2,
        'name': 'Med4',
        'createdAt': DateTime.now().toIso8601String(),
      });

      await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Group1',
          memberMedicationIds: [1],
        ),
      );
      await groupService.createGroup(
        MedicationGroup(
          profileId: 2,
          name: 'Group2',
          memberMedicationIds: [4],
        ),
      );

      final profile1Groups = await groupService.listGroupsByProfile(1);
      final profile2Groups = await groupService.listGroupsByProfile(2);

      expect(profile1Groups.length, 1);
      expect(profile1Groups[0].name, 'Group1');
      expect(profile2Groups.length, 1);
      expect(profile2Groups[0].name, 'Group2');
    });
  });

  group('MedicationGroupService - Update', () {
    test('updates group name and members', () async {
      final created = await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Morning Meds',
          memberMedicationIds: [1],
        ),
      );

      final updated = await groupService.updateGroup(
        created.copyWith(
          name: 'Evening Meds',
          memberMedicationIds: [2, 3],
        ),
      );

      expect(updated.id, created.id);
      expect(updated.name, 'Evening Meds');
      expect(updated.memberMedicationIds, [2, 3]);
    });

    test('rejects update without id', () async {
      final group = MedicationGroup(
        profileId: 1,
        name: 'Group',
        memberMedicationIds: [1],
      );

      expect(
        () => groupService.updateGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects update with invalid name', () async {
      final created = await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Group',
          memberMedicationIds: [1],
        ),
      );

      expect(
        () => groupService.updateGroup(created.copyWith(name: '')),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects update with cross-profile medications', () async {
      final db = await dbService.database;
      await db.insert('Profile', {
        'name': 'Profile 2',
        'createdAt': DateTime.now().toIso8601String(),
      });
      await db.insert('Medication', {
        'profileId': 2,
        'name': 'Med4',
        'createdAt': DateTime.now().toIso8601String(),
      });

      final created = await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Group',
          memberMedicationIds: [1],
        ),
      );

      expect(
        () => groupService.updateGroup(
          created.copyWith(memberMedicationIds: [1, 4]),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects update for non-existent group', () async {
      final group = MedicationGroup(
        id: 999,
        profileId: 1,
        name: 'Group',
        memberMedicationIds: [1],
      );

      expect(
        () => groupService.updateGroup(group),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('MedicationGroupService - Delete', () {
    test('deletes group by id', () async {
      final created = await groupService.createGroup(
        MedicationGroup(
          profileId: 1,
          name: 'Morning Meds',
          memberMedicationIds: [1],
        ),
      );

      final deleted = await groupService.deleteGroup(created.id!);

      expect(deleted, isTrue);

      final retrieved = await groupService.getGroup(created.id!);
      expect(retrieved, isNull);
    });

    test('returns false when deleting non-existent group', () async {
      final deleted = await groupService.deleteGroup(999);
      expect(deleted, isFalse);
    });
  });
}

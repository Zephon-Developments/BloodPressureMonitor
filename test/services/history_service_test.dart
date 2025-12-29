import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/history_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late DatabaseService dbService;
  late HistoryService historyService;
  late ReadingService readingService;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    final db = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE Profile (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              name TEXT NOT NULL,
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
              note TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE ReadingGroup (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              profileId INTEGER NOT NULL,
              groupStartAt TEXT NOT NULL,
              windowMinutes INTEGER NOT NULL,
              avgSystolic REAL NOT NULL,
              avgDiastolic REAL NOT NULL,
              avgPulse REAL NOT NULL,
              memberReadingIds TEXT NOT NULL,
              sessionId TEXT,
              note TEXT
            )
          ''');

          await db.insert('Profile', {
            'id': 1,
            'name': 'Test',
            'createdAt': DateTime.now().toIso8601String(),
          });
        },
      ),
    );

    dbService = DatabaseService(testDatabase: db);
    readingService = ReadingService(databaseService: dbService);
    historyService = HistoryService(
      databaseService: dbService,
      readingService: readingService,
    );

    await _seedReadings(db);
  });

  tearDown(() async {
    await dbService.close();
  });

  test('fetchGroupedHistory supports keyset pagination', () async {
    final firstPage = await historyService.fetchGroupedHistory(
      profileId: 1,
      limit: 1,
    );

    expect(firstPage, hasLength(1));
    expect(firstPage.first.memberReadingIds, equals('6,5'));

    final cursor = firstPage.last.groupStartAt;
    final secondPage = await historyService.fetchGroupedHistory(
      profileId: 1,
      before: cursor,
      limit: 1,
    );

    expect(secondPage, hasLength(1));
    expect(secondPage.first.memberReadingIds, equals('4,3,2,1'));
  });

  test('fetchGroupedHistory fills page when tag filter skips rows', () async {
    final groups = await historyService.fetchGroupedHistory(
      profileId: 1,
      limit: 1,
      tags: const ['fasting'],
    );

    expect(groups, hasLength(1));
    expect(groups.first.memberReadingIds, equals('4,3,2,1'));
  });

  test('fetchGroupedHistory returns empty when no tags match', () async {
    final groups = await historyService.fetchGroupedHistory(
      profileId: 1,
      limit: 2,
      tags: const ['nonexistent'],
    );

    expect(groups, isEmpty);
  });

  test('fetchRawHistory filters by tags across pages', () async {
    final readings = await historyService.fetchRawHistory(
      profileId: 1,
      limit: 1,
      tags: const ['fasting'],
    );

    expect(readings, hasLength(1));
    expect(readings.first.tags, contains('fasting'));
    expect(
      readings.first.takenAt.isBefore(DateTime.utc(2025, 1, 3, 9, 20)),
      isTrue,
    );
  });

  test('fetchRawHistory returns empty when tags miss', () async {
    final readings = await historyService.fetchRawHistory(
      profileId: 1,
      tags: const ['bedtime'],
    );

    expect(readings, isEmpty);
  });

  test('fetchGroupMembers returns members sorted by time desc', () async {
    final groups = await historyService.fetchGroupedHistory(profileId: 1);
    final group = groups.last;

    final members = await historyService.fetchGroupMembers(group);
    expect(members.length, equals(4));
    expect(members.first.takenAt.isAfter(members.last.takenAt), isTrue);
  });
}

Future<void> _seedReadings(Database db) async {
  final timestamps = <DateTime>[
    DateTime.utc(2025, 1, 1, 8),
    DateTime.utc(2025, 1, 1, 8, 20),
    DateTime.utc(2025, 1, 2, 7, 55),
    DateTime.utc(2025, 1, 3, 9),
    DateTime.utc(2025, 1, 3, 9, 20),
    DateTime.utc(2025, 1, 4, 7, 30),
  ];

  final tagSets = <String?>[
    'fasting,morning',
    null,
    null,
    'fasting',
    null,
    'recovery',
  ];

  for (var i = 0; i < timestamps.length; i++) {
    await db.insert('Reading', {
      'id': i + 1,
      'profileId': 1,
      'systolic': 120 + i,
      'diastolic': 80 + i,
      'pulse': 70 + i,
      'takenAt': timestamps[i].toIso8601String(),
      'localOffsetMinutes': 0,
      'tags': tagSets[i],
    });
  }

  await db.insert('ReadingGroup', {
    'id': 1,
    'profileId': 1,
    'groupStartAt': DateTime.utc(2025, 1, 4, 7, 30).toIso8601String(),
    'windowMinutes': 30,
    'avgSystolic': 122,
    'avgDiastolic': 82,
    'avgPulse': 72,
    'memberReadingIds': '6,5',
  });

  await db.insert('ReadingGroup', {
    'id': 2,
    'profileId': 1,
    'groupStartAt': DateTime.utc(2025, 1, 2, 7, 55).toIso8601String(),
    'windowMinutes': 30,
    'avgSystolic': 121,
    'avgDiastolic': 81,
    'avgPulse': 71,
    'memberReadingIds': '4,3,2,1',
    'sessionId': 'manual',
  });
}

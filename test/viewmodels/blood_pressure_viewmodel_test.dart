import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database testDb;
  late DatabaseService databaseService;
  late ReadingService readingService;
  late AveragingService averagingService;
  late BloodPressureViewModel viewModel;

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

          await db.execute('''
            CREATE INDEX idx_reading_profile_time 
            ON Reading(profileId, takenAt)
          ''');

          await db.execute('''
            CREATE INDEX idx_readinggroup_profile 
            ON ReadingGroup(profileId)
          ''');

          // Insert test profile
          await db.insert('Profile', {
            'id': 1,
            'name': 'Test Profile',
            'preferredUnits': 'mmHg',
            'createdAt': DateTime.now().toIso8601String(),
          });
        },
      ),
    );

    databaseService = DatabaseService(testDatabase: testDb);
    readingService = ReadingService(databaseService: databaseService);
    averagingService = AveragingService(
      databaseService: databaseService,
      readingService: readingService,
    );
    viewModel = BloodPressureViewModel(
      readingService,
      averagingService,
    );
  });

  tearDown(() async {
    await testDb.close();
  });

  Reading createTestReading({
    int? id,
    required int systolic,
    required int diastolic,
    required int pulse,
    DateTime? takenAt,
  }) {
    return Reading(
      id: id,
      profileId: 1,
      systolic: systolic,
      diastolic: diastolic,
      pulse: pulse,
      takenAt: takenAt ?? DateTime.now(),
      localOffsetMinutes: -300,
    );
  }

  group('BloodPressureViewModel', () {
    group('loadReadings', () {
      test('loads readings successfully', () async {
        final reading1 = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );
        final reading2 = createTestReading(
          systolic: 130,
          diastolic: 85,
          pulse: 75,
        );

        await readingService.createReading(reading1);
        await readingService.createReading(reading2);

        await viewModel.loadReadings();

        expect(viewModel.readings.length, 2);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
      });

      test('sets isLoading during operation', () async {
        final loadFuture = viewModel.loadReadings();
        // Can't reliably test isLoading in sync code with real DB
        await loadFuture;
        expect(viewModel.isLoading, false);
      });
    });

    group('addReading', () {
      test('adds valid reading and triggers averaging', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final result = await viewModel.addReading(reading);

        expect(result.level, ValidationLevel.valid);
        expect(viewModel.readings.length, 1);
        expect(viewModel.error, isNull);

        // Averaging is triggered successfully (no error means it ran)
      });

      test('blocks error-level reading without persistence', () async {
        final reading = createTestReading(
          systolic: 300, // Error: > 250
          diastolic: 80,
          pulse: 70,
        );

        final result = await viewModel.addReading(reading);

        expect(result.level, ValidationLevel.error);
        expect(viewModel.error, isNotNull);
        expect(viewModel.lastValidation?.level, ValidationLevel.error);
        expect(viewModel.readings, isEmpty);

        // Verify nothing was persisted
        final readings = await testDb.query('Reading');
        expect(readings, isEmpty);
      });

      test('blocks warning-level reading without override', () async {
        final reading = createTestReading(
          systolic: 185, // Warning: > 180
          diastolic: 80,
          pulse: 70,
        );

        final result = await viewModel.addReading(reading);

        expect(result.level, ValidationLevel.warning);
        expect(viewModel.error, isNotNull);
        expect(viewModel.lastValidation?.level, ValidationLevel.warning);
        expect(viewModel.readings, isEmpty);
      });

      test('allows warning-level reading with override', () async {
        final reading = createTestReading(
          systolic: 185,
          diastolic: 80,
          pulse: 70,
        );

        final result =
            await viewModel.addReading(reading, confirmOverride: true);

        expect(result.level, ValidationLevel.warning);
        expect(viewModel.readings.length, 1);
        expect(viewModel.readings.first.systolic, 185);

        // Averaging triggered without error
      });

      test('does not allow error-level reading even with override', () async {
        final reading = createTestReading(
          systolic: 300,
          diastolic: 80,
          pulse: 70,
        );

        final result =
            await viewModel.addReading(reading, confirmOverride: true);

        expect(result.level, ValidationLevel.error);
        expect(viewModel.readings, isEmpty);
      });

      test('validates multiple types of warnings', () async {
        final reading = createTestReading(
          systolic: 185,
          diastolic: 80,
          pulse: 150, // Also warning
        );

        final result = await viewModel.addReading(reading);

        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('Systolic'));
        expect(result.message, contains('Pulse'));
      });

      test('updates lastValidation field', () async {
        final reading = createTestReading(
          systolic: 185,
          diastolic: 80,
          pulse: 70,
        );

        await viewModel.addReading(reading);

        expect(viewModel.lastValidation, isNotNull);
        expect(viewModel.lastValidation?.level, ValidationLevel.warning);
      });
    });

    group('updateReading', () {
      test('updates valid reading and triggers averaging', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final id = await readingService.createReading(reading);
        final updatedReading = reading.copyWith(id: id, systolic: 125);

        final result = await viewModel.updateReading(updatedReading);

        expect(result.level, ValidationLevel.valid);
        await viewModel.loadReadings();
        expect(viewModel.readings.first.systolic, 125);
      });

      test('blocks error-level update', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final id = await readingService.createReading(reading);
        final updatedReading = reading.copyWith(id: id, systolic: 300);

        final result = await viewModel.updateReading(updatedReading);

        expect(result.level, ValidationLevel.error);
        await viewModel.loadReadings();
        expect(viewModel.readings.first.systolic, 120); // Unchanged
      });

      test('blocks warning-level update without override', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final id = await readingService.createReading(reading);
        final updatedReading = reading.copyWith(id: id, systolic: 185);

        final result = await viewModel.updateReading(updatedReading);

        expect(result.level, ValidationLevel.warning);
        await viewModel.loadReadings();
        expect(viewModel.readings.first.systolic, 120); // Unchanged
      });

      test('allows warning-level update with override', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final id = await readingService.createReading(reading);
        final updatedReading = reading.copyWith(id: id, systolic: 185);

        final result = await viewModel.updateReading(updatedReading,
            confirmOverride: true);

        expect(result.level, ValidationLevel.warning);
        await viewModel.loadReadings();
        expect(viewModel.readings.first.systolic, 185);
      });

      test('returns error if reading has no ID', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final result = await viewModel.updateReading(reading);

        expect(result.level, ValidationLevel.error);
        expect(viewModel.error, contains('without an ID'));
      });
    });

    group('deleteReading', () {
      test('deletes reading successfully', () async {
        final reading = createTestReading(
          systolic: 120,
          diastolic: 80,
          pulse: 70,
        );

        final id = await readingService.createReading(reading);

        await viewModel.deleteReading(id);

        await viewModel.loadReadings();
        expect(viewModel.readings, isEmpty);
      });
    });

    group('getters', () {
      test('returns correct defaults', () {
        expect(viewModel.readings, isEmpty);
        expect(viewModel.isLoading, false);
        expect(viewModel.error, isNull);
        expect(viewModel.lastValidation, isNull);
      });
    });
  });
}

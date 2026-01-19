import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/services/import_service.dart';
import '../helpers/service_mocks.dart';

class _ReadingServiceStub extends MockReadingService {
  int createCallCount = 0;
  Future<List<Reading>> Function(
    int profileId,
    DateTime startTime,
    DateTime endTime,
  )? rangeResponder;

  @override
  Future<List<Reading>> getReadingsInTimeRange(
    int profileId,
    DateTime startTime,
    DateTime endTime,
  ) {
    if (rangeResponder != null) {
      return rangeResponder!(profileId, startTime, endTime);
    }
    return super.getReadingsInTimeRange(profileId, startTime, endTime);
  }

  @override
  Future<int> createReading(Reading reading) {
    createCallCount++;
    return super.createReading(reading);
  }
}

void main() {
  late _ReadingServiceStub readingService;
  late MockWeightService weightService;
  late MockSleepService sleepService;
  late MockMedicationService medicationService;
  late MockMedicationIntakeService intakeService;
  late MockAveragingService averagingService;
  late ImportService importService;
  late Directory tempDir;

  setUp(() {
    readingService = _ReadingServiceStub();
    weightService = MockWeightService();
    sleepService = MockSleepService();
    medicationService = MockMedicationService();
    intakeService = MockMedicationIntakeService();
    averagingService = MockAveragingService();
    importService = ImportService(
      readingService: readingService,
      weightService: weightService,
      sleepService: sleepService,
      medicationService: medicationService,
      intakeService: intakeService,
      averagingService: averagingService,
    );
    tempDir = Directory.systemTemp.createTempSync('import_service_test');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  File writeJson(Map<String, dynamic> content) {
    final file = File('${tempDir.path}/data.json');
    file.writeAsStringSync(jsonEncode(content));
    return file;
  }

  const profileId = 42;
  final reading = Reading(
    profileId: profileId,
    systolic: 120,
    diastolic: 80,
    pulse: 70,
    takenAt: DateTime.utc(2024, 1, 1, 12),
    localOffsetMinutes: 0,
  );
  final weightEntry = WeightEntry(
    profileId: profileId,
    takenAt: DateTime.utc(2024, 1, 2),
    weightValue: 80.0,
    unit: WeightUnit.kg,
  );
  final sleepEntry = SleepEntry(
    profileId: profileId,
    startedAt: DateTime.utc(2024, 1, 1, 22),
    endedAt: DateTime.utc(2024, 1, 2, 6),
  );
  final medication = Medication(
    profileId: profileId,
    name: 'Losartan',
    dosage: '25mg',
  );
  final intake = MedicationIntake(
    medicationId: 1,
    profileId: profileId,
    takenAt: DateTime.utc(2024, 1, 1, 8),
  );

  group('importFromJson', () {
    test('overwrite clears existing data per dataset', () async {
      when(readingService.deleteAllByProfile(profileId))
          .thenAnswer((_) async => 5);
      when(weightService.deleteAllByProfile(profileId))
          .thenAnswer((_) async => 2);
      when(sleepService.deleteAllByProfile(profileId))
          .thenAnswer((_) async => 2);
      when(medicationService.deleteAllByProfile(profileId))
          .thenAnswer((_) async => 1);
      when(intakeService.deleteAllByProfile(profileId))
          .thenAnswer((_) async => 3);

      final file = writeJson({
        'readings': [reading.toMap()],
        'weight': [weightEntry.toMap()],
        'sleep': [sleepEntry.toMap()],
        'medications': [medication.toMap()],
        'medicationIntakes': [intake.toMap()],
      });

      final result = await importService.importFromJson(
        file: file,
        profileId: profileId,
        conflictMode: ImportConflictMode.overwrite,
      );

      verify(readingService.deleteAllByProfile(profileId)).called(1);
      verify(weightService.deleteAllByProfile(profileId)).called(1);
      verify(sleepService.deleteAllByProfile(profileId)).called(1);
      verify(medicationService.deleteAllByProfile(profileId)).called(1);
      verify(intakeService.deleteAllByProfile(profileId)).called(1);

      expect(result, isA<Success<ImportResult>>());
      final importResult = (result as Success<ImportResult>).value;
      expect(importResult.errors, isEmpty);
      expect(importResult.readingsImported, 1);
      expect(importResult.weightsImported, 1);
      expect(importResult.sleepLogsImported, 1);
      expect(importResult.medicationsImported, 1);
      expect(importResult.intakesImported, 1);
    });

    test('append skips duplicate readings', () async {
      readingService.rangeResponder = (profileArg, start, rangeEnd) async {
        if (start == reading.takenAt) {
          return [reading.copyWith(profileId: profileId)];
        }
        return <Reading>[];
      };

      final file = writeJson({
        'readings': [
          reading.toMap(), // Duplicate
          reading.copyWith(systolic: 140).toMap(), // New
        ],
      });

      final result = await importService.importFromJson(
        file: file,
        profileId: profileId,
        conflictMode: ImportConflictMode.append,
      );

      expect(result, isA<Success<ImportResult>>());
      final importResult = (result as Success<ImportResult>).value;
      expect(importResult.readingsImported, 1);
      expect(importResult.duplicatesSkipped, 1);
      expect(readingService.createCallCount, 1);
    });

    test('returns Failure on invalid JSON', () async {
      final file = File('${tempDir.path}/invalid.json');
      file.writeAsStringSync('{ invalid json }');

      final result = await importService.importFromJson(
        file: file,
        profileId: profileId,
        conflictMode: ImportConflictMode.append,
      );

      expect(result, isA<Failure<ImportResult>>());
      final failure = result as Failure<ImportResult>;
      expect(failure.error.type, AppErrorType.validation);
    });
  });
}

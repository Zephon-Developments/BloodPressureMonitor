import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
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

  File writeCsv(List<String> lines) {
    final file = File('${tempDir.path}/data.csv');
    file.writeAsStringSync('${lines.join('\r\n')}\r\n');
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

      expect(result.errors, isEmpty);
      expect(result.readingsImported, 1);
      expect(result.weightsImported, 1);
      expect(result.sleepLogsImported, 1);
      expect(result.medicationsImported, 1);
      expect(result.intakesImported, 1);
    });
  });

  group('importFromCsv', () {
    test('append skips duplicate readings and preserves existing data',
        () async {
      readingService.rangeResponder = (
        profileArg,
        start,
        rangeEnd,
      ) async {
        final isSameInstant =
            start == reading.takenAt && rangeEnd == reading.takenAt;
        if (profileArg == profileId && isSameInstant) {
          return [reading.copyWith(profileId: profileId)];
        }
        return <Reading>[];
      };

      final file = writeCsv([
        '# READINGS',
        'systolic,diastolic,pulse,takenAt,localOffsetMinutes,posture,arm,medsContext,irregularFlag,tags,note',
        '120,80,70,2024-01-01T12:00:00.000Z,0,,,,0,,',
        '130,85,72,2024-01-02T12:00:00.000Z,0,,,,0,,',
      ]);

      final result = await importService.importFromCsv(
        file: file,
        profileId: profileId,
        conflictMode: ImportConflictMode.append,
      );

      verifyNever(readingService.deleteAllByProfile(profileId));
      expect(result.errors, isEmpty);
      expect(
        result.duplicatesSkipped,
        1,
        reason:
            'duplicates:${result.duplicatesSkipped} imported:${result.readingsImported} created:${readingService.createCallCount}',
      );
      expect(readingService.createCallCount, 1);
      expect(result.readingsImported, 1);
    });
  });
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/export_service.dart';
import '../helpers/service_mocks.dart';
import '../helpers/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockReadingService readingService;
  late MockWeightService weightService;
  late MockSleepService sleepService;
  late MockMedicationService medicationService;
  late MockMedicationIntakeService intakeService;
  late MockAppInfoService appInfoService;
  late ExportService exportService;
  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUp(() {
    readingService = MockReadingService();
    weightService = MockWeightService();
    sleepService = MockSleepService();
    medicationService = MockMedicationService();
    intakeService = MockMedicationIntakeService();
    appInfoService = MockAppInfoService();
    tempDir = Directory.systemTemp.createTempSync('export_service_test');
    originalPlatform = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);

    exportService = ExportService(
      readingService: readingService,
      weightService: weightService,
      sleepService: sleepService,
      medicationService: medicationService,
      intakeService: intakeService,
      appInfoService: appInfoService,
    );
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPlatform;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final reading = Reading(
    id: 1,
    profileId: 1,
    systolic: 120,
    diastolic: 75,
    pulse: 70,
    takenAt: DateTime.utc(2024, 1, 1, 12),
    localOffsetMinutes: 0,
  );
  final weightEntry = WeightEntry(
    id: 2,
    profileId: 1,
    takenAt: DateTime.utc(2024, 1, 2),
    weightValue: 80,
    unit: WeightUnit.kg,
  );
  final sleepEntry = SleepEntry(
    id: 3,
    profileId: 1,
    startedAt: DateTime.utc(2024, 1, 1, 22),
    endedAt: DateTime.utc(2024, 1, 2, 6),
  );
  final medication = Medication(
    id: 4,
    profileId: 1,
    name: 'Amlodipine',
    dosage: '10mg',
  );
  final intake = MedicationIntake(
    id: 5,
    medicationId: 4,
    profileId: 1,
    takenAt: DateTime.utc(2024, 1, 1, 8),
  );

  void stubServices() {
    when(appInfoService.getAppVersion()).thenAnswer((_) async => '9.9.9');
    when(
      readingService.getReadingsByProfile(
        1,
        limit: anyNamed('limit'),
      ),
    ).thenAnswer((_) async => [reading]);
    when(
      weightService.listWeightEntries(
        profileId: 1,
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => [weightEntry]);
    when(
      sleepService.listSleepEntries(
        profileId: 1,
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => [sleepEntry]);
    when(
      medicationService.listMedicationsByProfile(
        1,
        includeInactive: true,
      ),
    ).thenAnswer((_) async => [medication]);
    when(
      intakeService.listIntakes(
        profileId: 1,
        from: anyNamed('from'),
        to: anyNamed('to'),
        medicationId: anyNamed('medicationId'),
        groupId: anyNamed('groupId'),
      ),
    ).thenAnswer((_) async => [intake]);
  }

  group('ExportService', () {
    test('exportToJson writes metadata and data sections', () async {
      stubServices();

      final file = await exportService.exportToJson(
        profileId: 1,
        profileName: 'Primary User',
      );

      final jsonContent =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final metadata = jsonContent['metadata'] as Map<String, dynamic>;

      expect(metadata['appVersion'], '9.9.9');
      expect(metadata['profileId'], 1);
      expect((jsonContent['readings'] as List).length, 1);
      expect((jsonContent['weight'] as List).length, 1);
      expect((jsonContent['sleep'] as List).length, 1);
      expect((jsonContent['medications'] as List).length, 1);
      expect((jsonContent['medicationIntakes'] as List).length, 1);
    });

    test('exportToCsv emits section headers', () async {
      stubServices();

      final file = await exportService.exportToCsv(
        profileId: 1,
        profileName: 'Primary User',
      );

      final contents = await file.readAsString();
      expect(contents.contains('# READINGS'), isTrue);
      expect(contents.contains('# WEIGHT'), isTrue);
      expect(contents.contains('# SLEEP'), isTrue);
      expect(contents.contains('# MEDICATIONS'), isTrue);
      expect(contents.contains('# MEDICATION_INTAKES'), isTrue);
    });

    test('exportToCsv sanitizes formula injection attempts', () async {
      // Create readings with malicious formula-like content
      final maliciousReading = Reading(
        id: 1,
        profileId: 1,
        systolic: 120,
        diastolic: 75,
        pulse: 70,
        takenAt: DateTime.utc(2024, 1, 1, 12),
        localOffsetMinutes: 0,
        note: '=SUM(A1:A10)',
        tags: '+HYPERLINK("evil.com","click")',
      );

      final maliciousMedication = Medication(
        id: 4,
        profileId: 1,
        name: '@cmd|calc',
        dosage: '-2+2',
      );

      when(appInfoService.getAppVersion()).thenAnswer((_) async => '9.9.9');
      when(
        readingService.getReadingsByProfile(
          1,
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => [maliciousReading]);
      when(
        medicationService.listMedicationsByProfile(
          1,
          includeInactive: true,
        ),
      ).thenAnswer((_) async => [maliciousMedication]);
      when(
        weightService.listWeightEntries(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
        ),
      ).thenAnswer((_) async => []);
      when(
        sleepService.listSleepEntries(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
        ),
      ).thenAnswer((_) async => []);
      when(
        intakeService.listIntakes(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
          medicationId: anyNamed('medicationId'),
          groupId: anyNamed('groupId'),
        ),
      ).thenAnswer((_) async => []);

      final file = await exportService.exportToCsv(
        profileId: 1,
        profileName: 'TestUser',
      );

      final contents = await file.readAsString();

      // Verify that formula characters are escaped with single quote prefix
      expect(contents.contains("'=SUM(A1:A10)"), isTrue);
      expect(contents.contains("'+HYPERLINK"), isTrue);
      expect(contents.contains("'@cmd|calc"), isTrue);
      expect(contents.contains("'-2+2"), isTrue);
    });

    test('exportToCsv preserves normal text without sanitization', () async {
      final normalReading = Reading(
        id: 1,
        profileId: 1,
        systolic: 120,
        diastolic: 75,
        pulse: 70,
        takenAt: DateTime.utc(2024, 1, 1, 12),
        localOffsetMinutes: 0,
        note: 'Normal note with numbers 123',
        tags: 'tag1,tag2',
      );

      when(appInfoService.getAppVersion()).thenAnswer((_) async => '9.9.9');
      when(
        readingService.getReadingsByProfile(
          1,
          limit: anyNamed('limit'),
        ),
      ).thenAnswer((_) async => [normalReading]);
      when(
        weightService.listWeightEntries(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
        ),
      ).thenAnswer((_) async => []);
      when(
        sleepService.listSleepEntries(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
        ),
      ).thenAnswer((_) async => []);
      when(
        medicationService.listMedicationsByProfile(
          1,
          includeInactive: true,
        ),
      ).thenAnswer((_) async => []);
      when(
        intakeService.listIntakes(
          profileId: 1,
          from: anyNamed('from'),
          to: anyNamed('to'),
          medicationId: anyNamed('medicationId'),
          groupId: anyNamed('groupId'),
        ),
      ).thenAnswer((_) async => []);

      final file = await exportService.exportToCsv(
        profileId: 1,
        profileName: 'TestUser',
      );

      final contents = await file.readAsString();

      // Normal content should not be prefixed with quotes
      expect(contents.contains('Normal note with numbers 123'), isTrue);
      expect(contents.contains('tag1,tag2'), isTrue);
      // Should not have quotes added to normal text
      expect(contents.contains("'Normal note"), isFalse);
      expect(contents.contains("'tag1"), isFalse);
    });
  });
}

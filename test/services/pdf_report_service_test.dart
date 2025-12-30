import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/pdf_report_service.dart';
import '../helpers/test_path_provider.dart';

import '../helpers/service_mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAnalyticsService analyticsService;
  late MockReadingService readingService;
  late MockMedicationService medicationService;
  late PdfReportService pdfReportService;
  late Directory tempDir;
  late PathProviderPlatform originalPlatform;

  setUp(() {
    analyticsService = MockAnalyticsService();
    readingService = MockReadingService();
    medicationService = MockMedicationService();
    pdfReportService = PdfReportService(
      analyticsService: analyticsService,
      readingService: readingService,
      medicationService: medicationService,
    );

    tempDir = Directory.systemTemp.createTempSync('pdf_report_test');
    originalPlatform = PathProviderPlatform.instance;
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);
  });

  tearDown(() {
    PathProviderPlatform.instance = originalPlatform;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  final stats = HealthStats(
    minSystolic: 110,
    avgSystolic: 120,
    maxSystolic: 130,
    minDiastolic: 70,
    avgDiastolic: 80,
    maxDiastolic: 90,
    minPulse: 60,
    avgPulse: 65,
    maxPulse: 70,
    systolicStdDev: 5,
    systolicCv: 4,
    diastolicStdDev: 4,
    diastolicCv: 3,
    pulseStdDev: 2,
    pulseCv: 1.5,
    split: const MorningEveningSplit(
      morning: ReadingBucketStats(
        count: 2,
        minSystolic: 110,
        avgSystolic: 115,
        maxSystolic: 120,
        minDiastolic: 70,
        avgDiastolic: 75,
        maxDiastolic: 80,
        minPulse: 60,
        avgPulse: 62,
        maxPulse: 64,
      ),
      evening: ReadingBucketStats(
        count: 2,
        minSystolic: 118,
        avgSystolic: 122,
        maxSystolic: 128,
        minDiastolic: 74,
        avgDiastolic: 78,
        maxDiastolic: 82,
        minPulse: 63,
        avgPulse: 65,
        maxPulse: 67,
      ),
      morningCount: 2,
      eveningCount: 2,
    ),
    totalReadings: 4,
    periodStart: DateTime.utc(2024, 1, 1),
    periodEnd: DateTime.utc(2024, 1, 31),
  );

  final readings = [
    Reading(
      id: 1,
      profileId: 1,
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      takenAt: DateTime.utc(2024, 1, 5),
      localOffsetMinutes: 0,
    ),
  ];

  final medications = [
    Medication(
      id: 1,
      profileId: 1,
      name: 'Lisinopril',
      dosage: '10mg',
    ),
  ];

  test('generateReport fetches data and creates pdf file', () async {
    when(
      analyticsService.calculateStats(
        profileId: 1,
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 1, 31),
        cutoff: anyNamed('cutoff'),
      ),
    ).thenAnswer((_) async => stats);
    when(
      readingService.getReadingsInTimeRange(
        1,
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 31),
      ),
    ).thenAnswer((_) async => readings);
    when(
      medicationService.listMedicationsByProfile(
        1,
        includeInactive: false,
      ),
    ).thenAnswer((_) async => medications);

    final file = await pdfReportService.generateReport(
      profileId: 1,
      profileName: 'Primary User',
      startDate: DateTime.utc(2024, 1, 1),
      endDate: DateTime.utc(2024, 1, 31),
      chartImages: const [],
    );

    expect(await file.exists(), isTrue);
    expect(await file.length(), greaterThan(0));

    verify(
      analyticsService.calculateStats(
        profileId: 1,
        startDate: DateTime.utc(2024, 1, 1),
        endDate: DateTime.utc(2024, 1, 31),
        cutoff: null,
      ),
    ).called(1);
    verify(
      readingService.getReadingsInTimeRange(
        1,
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 31),
      ),
    ).called(1);
    verify(
      medicationService.listMedicationsByProfile(
        1,
        includeInactive: false,
      ),
    ).called(1);
  });
}

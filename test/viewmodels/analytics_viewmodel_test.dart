import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_viewmodel_test.mocks.dart';

@GenerateMocks([AnalyticsService, ActiveProfileViewModel])
void main() {
  late AnalyticsViewModel viewModel;
  late MockAnalyticsService mockService;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  void stubBaseFetches() {
    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
    when(mockActiveProfileViewModel.addListener(any)).thenReturn(null);
    when(mockActiveProfileViewModel.removeListener(any)).thenReturn(null);

    when(
      mockService.calculateStats(
        profileId: anyNamed('profileId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ),
    ).thenAnswer((_) async => _stats());

    when(
      mockService.getChartData(
        profileId: anyNamed('profileId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
        range: anyNamed('range'),
      ),
    ).thenAnswer((_) async => _chart());
  }

  setUp(() {
    mockService = MockAnalyticsService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
    stubBaseFetches();

    viewModel = AnalyticsViewModel(
      analyticsService: mockService,
      activeProfileViewModel: mockActiveProfileViewModel,
      clock: () => DateTime.utc(2025, 1, 10),
    );
  });

  test('loadData populates stats and chart data', () async {
    await viewModel.loadData();

    expect(viewModel.stats, isNotNull);
    expect(viewModel.chartData, isNotNull);
    expect(viewModel.hasData, isTrue);
  });

  test('loadData reuses cache without hitting service', () async {
    await viewModel.loadData();

    when(
      mockService.calculateStats(
        profileId: anyNamed('profileId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ),
    ).thenThrow(Exception('Should not refetch'));

    await viewModel.loadData();

    expect(viewModel.error, isNull);
  });

  test('toggleSleepOverlay fetches correlation data', () async {
    await viewModel.loadData();

    when(
      mockService.getSleepCorrelation(
        profileId: anyNamed('profileId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ),
    ).thenAnswer((_) async => _sleepCorrelation());
    when(
      mockService.getSleepStageSeries(
        profileId: anyNamed('profileId'),
        startDate: anyNamed('startDate'),
        endDate: anyNamed('endDate'),
      ),
    ).thenAnswer(
      (_) async => const SleepStageSeries(
        stages: [],
        hasIncompleteSessions: false,
      ),
    );

    await viewModel.toggleSleepOverlay();

    expect(viewModel.showSleepOverlay, isTrue);
    expect(viewModel.sleepCorrelation, isNotNull);
  });
}

HealthStats _stats() {
  return HealthStats(
    minSystolic: 120,
    avgSystolic: 125,
    maxSystolic: 130,
    minDiastolic: 80,
    avgDiastolic: 82,
    maxDiastolic: 85,
    minPulse: 65,
    avgPulse: 68,
    maxPulse: 72,
    systolicStdDev: 2,
    systolicCv: 1.5,
    diastolicStdDev: 1,
    diastolicCv: 1.2,
    pulseStdDev: 1.5,
    pulseCv: 2,
    split: const MorningEveningSplit(
      morning: ReadingBucketStats(
        count: 1,
        minSystolic: 120,
        avgSystolic: 122,
        maxSystolic: 125,
        minDiastolic: 80,
        avgDiastolic: 82,
        maxDiastolic: 84,
        minPulse: 65,
        avgPulse: 67,
        maxPulse: 70,
      ),
      evening: ReadingBucketStats(
        count: 1,
        minSystolic: 126,
        avgSystolic: 128,
        maxSystolic: 130,
        minDiastolic: 83,
        avgDiastolic: 84,
        maxDiastolic: 85,
        minPulse: 70,
        avgPulse: 71,
        maxPulse: 72,
      ),
      morningCount: 1,
      eveningCount: 1,
    ),
    totalReadings: 2,
    periodStart: DateTime.utc(2025, 1, 1),
    periodEnd: DateTime.utc(2025, 1, 7),
  );
}

ChartDataSet _chart() {
  final now = DateTime.utc(2025, 1, 1);
  return ChartDataSet(
    systolicPoints: [
      ChartPoint(timestamp: now, value: 120),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 125),
    ],
    diastolicPoints: [
      ChartPoint(timestamp: now, value: 80),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 82),
    ],
    pulsePoints: [
      ChartPoint(timestamp: now, value: 68),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 70),
    ],
    minDate: now,
    maxDate: now.add(const Duration(days: 1)),
  );
}

SleepCorrelationData _sleepCorrelation() {
  final date = DateTime(2025, 1, 2);
  final reading = ReadingGroup(
    id: 1,
    profileId: 1,
    groupStartAt: date,
    avgSystolic: 125,
    avgDiastolic: 82,
    avgPulse: 68,
    memberReadingIds: '1',
  );
  final sleep = SleepEntry(
    id: 1,
    profileId: 1,
    startedAt: date.subtract(const Duration(hours: 7)),
    endedAt: date,
    durationMinutes: 420,
    deepMinutes: 100,
    lightMinutes: 200,
    remMinutes: 80,
    awakeMinutes: 40,
    quality: 4,
  );

  return SleepCorrelationData(
    sleepByDate: {date: SleepQualityLevel.good},
    morningReadings: {date: reading},
    correlationPoints: [
      CorrelationPoint(date: date, sleepEntry: sleep, reading: reading),
    ],
  );
}

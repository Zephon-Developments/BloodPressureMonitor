import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/correlation_service.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockReadingService mockReadingService;
  late MockWeightService mockWeightService;
  late MockSleepService mockSleepService;
  late CorrelationService correlationService;

  setUp(() {
    mockReadingService = MockReadingService();
    mockWeightService = MockWeightService();
    mockSleepService = MockSleepService();
    correlationService = CorrelationService(
      readingService: mockReadingService,
      weightService: mockWeightService,
      sleepService: mockSleepService,
    );
  });

  Reading createReading(DateTime timestamp) {
    return Reading(
      id: null,
      profileId: 1,
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      takenAt: timestamp,
      localOffsetMinutes: 0,
    );
  }

  test('fetchMorningReadingsWithSleep pairs only morning readings', () async {
    final morning = createReading(DateTime(2025, 1, 2, 8));
    final afternoon = createReading(DateTime(2025, 1, 2, 14));
    final sleepEntry = SleepEntry(
      profileId: 1,
      startedAt: DateTime(2025, 1, 1, 22),
      endedAt: DateTime(2025, 1, 2, 6),
    );

    when(
      mockReadingService.getReadingsInTimeRange(any, any, any),
    ).thenAnswer((_) async => <Reading>[morning, afternoon]);
    when(
      mockSleepService.findSleepForMorningReading(
        profileId: anyNamed('profileId'),
        readingTime: anyNamed('readingTime'),
        lookbackHours: anyNamed('lookbackHours'),
      ),
    ).thenAnswer((_) async => sleepEntry);

    final correlations = await correlationService.fetchMorningReadingsWithSleep(
      profileId: 1,
      start: DateTime(2025, 1, 1),
      end: DateTime(2025, 1, 3),
      morningCutoffHour: 12,
    );

    expect(correlations.length, 1);
    expect(correlations.first.reading, morning);
    expect(correlations.first.sleepEntry, sleepEntry);
    verify(
      mockSleepService.findSleepForMorningReading(
        profileId: 1,
        readingTime: morning.takenAt,
        lookbackHours: 18,
      ),
    ).called(1);
  });

  test('fetchWeightsForRange delegates to WeightService', () async {
    final weightEntry = WeightEntry(
      profileId: 1,
      takenAt: DateTime(2025, 1, 4, 7),
      weightValue: 75,
      unit: WeightUnit.kg,
    );
    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <WeightEntry>[weightEntry]);

    final weights = await correlationService.fetchWeightsForRange(
      profileId: 1,
      from: DateTime(2025, 1, 1),
      to: DateTime(2025, 1, 10),
    );

    expect(weights, [weightEntry]);
    verify(
      mockWeightService.listWeightEntries(
        profileId: 1,
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).called(1);
  });

  test('getLatestWeight delegates to WeightService', () async {
    final latest = WeightEntry(
      profileId: 1,
      takenAt: DateTime(2025, 1, 5, 9),
      weightValue: 74,
      unit: WeightUnit.kg,
    );
    when(mockWeightService.getLatestWeightEntry(1))
        .thenAnswer((_) async => latest);

    final result = await correlationService.getLatestWeight(1);

    expect(result, latest);
    verify(mockWeightService.getLatestWeightEntry(1)).called(1);
  });
}

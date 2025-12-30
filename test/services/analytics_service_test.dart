import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/utils/time_range.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'analytics_service_test.mocks.dart';

@GenerateMocks([ReadingService, SleepService])
void main() {
  late AnalyticsService service;
  late MockReadingService mockReadingService;
  late MockSleepService mockSleepService;

  setUp(() {
    mockReadingService = MockReadingService();
    mockSleepService = MockSleepService();
    service = AnalyticsService(
      readingService: mockReadingService,
      sleepService: mockSleepService,
      clock: () => DateTime.utc(2025, 1, 10),
    );
  });

  group('calculateStats', () {
    test('aggregates min/avg/max and variability', () async {
      when(
        mockReadingService.getGroupsInRange(
          profileId: anyNamed('profileId'),
          start: anyNamed('start'),
          end: anyNamed('end'),
        ),
      ).thenAnswer(
        (_) async => [
          _group(
            id: 1,
            at: DateTime.utc(2025, 1, 1, 8),
            systolic: 120,
            diastolic: 80,
            pulse: 70,
          ),
          _group(
            id: 2,
            at: DateTime.utc(2025, 1, 1, 20),
            systolic: 140,
            diastolic: 90,
            pulse: 75,
          ),
        ],
      );

      final stats = await service.calculateStats(
        profileId: 1,
        startDate: DateTime.utc(2025, 1, 1),
        endDate: DateTime.utc(2025, 1, 5),
      );

      expect(stats.minSystolic, 120);
      expect(stats.maxSystolic, 140);
      expect(stats.avgDiastolic, closeTo(85, 0.01));
      expect(stats.totalReadings, 2);
      expect(stats.split.morningCount, 1);
      expect(stats.split.eveningCount, 1);
    });

    test('returns zeros for empty dataset', () async {
      when(
        mockReadingService.getGroupsInRange(
          profileId: anyNamed('profileId'),
          start: anyNamed('start'),
          end: anyNamed('end'),
        ),
      ).thenAnswer((_) async => <ReadingGroup>[]);

      final stats = await service.calculateStats(
        profileId: 1,
        startDate: DateTime.utc(2025, 1, 1),
        endDate: DateTime.utc(2025, 1, 5),
      );

      expect(stats.totalReadings, 0);
      expect(stats.minPulse, 0);
    });
  });

  test('classifyByTimeOfDay splits by cutoff', () {
    final groups = [
      _group(
        id: 1,
        at: DateTime(2025, 1, 1, 9),
        systolic: 120,
        diastolic: 80,
        pulse: 70,
      ),
      _group(
        id: 2,
        at: DateTime(2025, 1, 1, 14),
        systolic: 135,
        diastolic: 85,
        pulse: 72,
      ),
    ];

    final buckets = service.classifyByTimeOfDay(
      groups,
      const TimeOfDay(hour: 12, minute: 0),
    );

    expect(buckets.morning, hasLength(1));
    expect(buckets.evening, hasLength(1));
  });

  test('getChartData downsamples when range is long', () async {
    final data = List.generate(
      120,
      (index) => _group(
        id: index,
        at: DateTime.utc(2024, 1, 1).add(Duration(days: index)),
        systolic: 120 + (index % 5),
        diastolic: 80,
        pulse: 70,
      ),
    );

    when(
      mockReadingService.getGroupsInRange(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
      ),
    ).thenAnswer((_) async => data);

    final chart = await service.getChartData(
      profileId: 1,
      startDate: DateTime.utc(2024, 1, 1),
      endDate: DateTime.utc(2025, 1, 1),
      range: TimeRange.oneYear,
    );

    expect(chart.isSampled, isTrue);
    expect(chart.systolicPoints.length, lessThan(data.length));
  });

  test('getSleepStageSeries flags incomplete entries', () async {
    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer(
      (_) async => [
        _sleepEntry(
          id: 1,
          endedAt: DateTime(2025, 1, 2, 6, 30),
          deep: 120,
          light: 200,
          rem: 60,
          awake: 30,
        ),
        _sleepEntry(
          id: 2,
          endedAt: DateTime(2025, 1, 3, 7),
        ),
      ],
    );

    final series = await service.getSleepStageSeries(
      profileId: 1,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 5),
    );

    expect(series.stages, hasLength(1));
    expect(series.hasIncompleteSessions, isTrue);
  });

  test('getSleepCorrelation aligns sleep with morning readings', () async {
    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer(
      (_) async => [
        _sleepEntry(
          id: 1,
          endedAt: DateTime(2025, 1, 2, 6, 0),
          deep: 100,
          light: 180,
          rem: 50,
          awake: 20,
          quality: 4,
        ),
      ],
    );

    when(
      mockReadingService.getGroupsInRange(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
      ),
    ).thenAnswer(
      (_) async => [
        _group(
          id: 1,
          at: DateTime(2025, 1, 2, 8),
          systolic: 125,
          diastolic: 82,
          pulse: 68,
        ),
      ],
    );

    final correlation = await service.getSleepCorrelation(
      profileId: 1,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 1, 3),
    );

    expect(correlation.sleepByDate.length, 1);
    expect(correlation.morningReadings.length, 1);
    expect(correlation.correlationPoints.single.reading, isNotNull);
  });
}

ReadingGroup _group({
  required int id,
  required DateTime at,
  required double systolic,
  required double diastolic,
  required double pulse,
}) {
  return ReadingGroup(
    id: id,
    profileId: 1,
    groupStartAt: at,
    avgSystolic: systolic,
    avgDiastolic: diastolic,
    avgPulse: pulse,
    memberReadingIds: '1',
    sessionId: null,
    note: null,
  );
}

SleepEntry _sleepEntry({
  required int id,
  DateTime? endedAt,
  int? deep,
  int? light,
  int? rem,
  int? awake,
  int? quality,
}) {
  return SleepEntry(
    id: id,
    profileId: 1,
    startedAt:
        (endedAt ?? DateTime(2025, 1, 1)).subtract(const Duration(hours: 8)),
    endedAt: endedAt,
    durationMinutes: 480,
    deepMinutes: deep,
    lightMinutes: light,
    remMinutes: rem,
    awakeMinutes: awake,
    quality: quality,
  );
}

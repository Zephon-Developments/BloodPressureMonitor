import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/stats_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'stats_service_test.mocks.dart';

@GenerateMocks([
  ReadingService,
  WeightService,
  SleepService,
  MedicationIntakeService,
])
void main() {
  late StatsService statsService;
  late MockReadingService mockReadingService;
  late MockWeightService mockWeightService;
  late MockSleepService mockSleepService;
  late MockMedicationIntakeService mockMedicationIntakeService;

  setUp(() {
    mockReadingService = MockReadingService();
    mockWeightService = MockWeightService();
    mockSleepService = MockSleepService();
    mockMedicationIntakeService = MockMedicationIntakeService();

    statsService = StatsService(
      readingService: mockReadingService,
      weightService: mockWeightService,
      sleepService: mockSleepService,
      medicationIntakeService: mockMedicationIntakeService,
    );
  });

  group('getBloodPressureStats', () {
    test('returns null when no readings available', () async {
      when(mockReadingService.getReadingsInTimeRange(
        any,
        any,
        any,
      )).thenAnswer((_) async => []);

      final result = await statsService.getBloodPressureStats(profileId: 1);

      expect(result, isNull);
    });

    test('returns stats with stable trend when only one reading', () async {
      final now = DateTime.now();
      final reading = Reading(
        id: 1,
        profileId: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: now,
        localOffsetMinutes: 0,
      );

      when(mockReadingService.getReadingsInTimeRange(
        any,
        any,
        any,
      )).thenAnswer((_) async => [reading]);

      final result = await statsService.getBloodPressureStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.latestValue, contains('120/80'));
      expect(result.weekAverage, contains('Avg: 120/80'));
      expect(result.trend,
          TrendDirection.stable); // No previous week data for comparison
    });

    test('calculates correct average from multiple readings', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      final readings = [
        Reading(
          id: 3,
          profileId: 1,
          systolic: 122,
          diastolic: 82,
          pulse: 72,
          takenAt: weekStart.add(const Duration(days: 2)),
          localOffsetMinutes: 0,
        ),
        Reading(
          id: 2,
          profileId: 1,
          systolic: 118,
          diastolic: 78,
          pulse: 68,
          takenAt: weekStart.add(const Duration(days: 4)),
          localOffsetMinutes: 0,
        ),
        Reading(
          id: 1,
          profileId: 1,
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          takenAt: now.subtract(const Duration(hours: 1)),
          localOffsetMinutes: 0,
        ),
      ];

      when(mockReadingService.getReadingsInTimeRange(
        any,
        any,
        any,
      )).thenAnswer((_) async => readings);

      final result = await statsService.getBloodPressureStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.weekAverage,
          'Avg: 120/80'); // (120+118+122)/3 = 120, (80+78+82)/3 = 80
      expect(result.trend, TrendDirection.stable); // No previous week data
    });

    test('detects upward trend (improvement - BP decreasing)', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));

      final readings = [
        Reading(
          id: 2,
          profileId: 1,
          systolic: 130,
          diastolic: 85,
          pulse: 75,
          takenAt: previousWeekStart.add(const Duration(days: 3)),
          localOffsetMinutes: 0,
        ),
        Reading(
          id: 1,
          profileId: 1,
          systolic: 110,
          diastolic: 70,
          pulse: 70,
          takenAt: now.subtract(const Duration(hours: 1)),
          localOffsetMinutes: 0,
        ),
      ];

      when(mockReadingService.getReadingsInTimeRange(
        any,
        any,
        any,
      )).thenAnswer((_) async => readings);

      final result = await statsService.getBloodPressureStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.trend,
          TrendDirection.up); // BP decreased by ~15%, improvement
    });
  });

  group('getWeightStats', () {
    test('returns null when no weight entries available', () async {
      when(mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => []);

      final result = await statsService.getWeightStats(profileId: 1);

      expect(result, isNull);
    });

    test('calculates correct weight average', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      final weights = [
        WeightEntry(
          id: 3,
          profileId: 1,
          weightValue: 69.0,
          unit: WeightUnit.kg,
          takenAt: weekStart.add(const Duration(days: 2)),
        ),
        WeightEntry(
          id: 2,
          profileId: 1,
          weightValue: 71.0,
          unit: WeightUnit.kg,
          takenAt: weekStart.add(const Duration(days: 4)),
        ),
        WeightEntry(
          id: 1,
          profileId: 1,
          weightValue: 70.0,
          unit: WeightUnit.kg,
          takenAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      when(mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => weights);

      final result = await statsService.getWeightStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.weekAverage, 'Avg: 70.0 kg'); // (70+71+69)/3 = 70
    });

    test('detects upward trend (weight loss - improvement)', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));

      final weights = [
        WeightEntry(
          id: 2,
          profileId: 1,
          weightValue: 70.0,
          unit: WeightUnit.kg,
          takenAt: previousWeekStart.add(const Duration(days: 3)),
        ),
        WeightEntry(
          id: 1,
          profileId: 1,
          weightValue: 65.0,
          unit: WeightUnit.kg,
          takenAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      when(mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => weights);

      final result = await statsService.getWeightStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.trend, TrendDirection.up); // Weight decreased, improvement
    });
  });

  group('getSleepStats', () {
    test('returns null when no sleep entries available', () async {
      when(mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => []);

      final result = await statsService.getSleepStats(profileId: 1);

      expect(result, isNull);
    });

    test('calculates correct sleep average in hours and minutes', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      final sleepEntries = [
        SleepEntry(
          id: 3,
          profileId: 1,
          startedAt: weekStart.add(const Duration(days: 2)),
          endedAt: weekStart.add(const Duration(days: 2, hours: 9)),
          durationMinutes: 540, // 9 hours
        ),
        SleepEntry(
          id: 2,
          profileId: 1,
          startedAt: weekStart.add(const Duration(days: 4)),
          endedAt: weekStart.add(const Duration(days: 4, hours: 7)),
          durationMinutes: 420, // 7 hours
        ),
        SleepEntry(
          id: 1,
          profileId: 1,
          startedAt: now.subtract(const Duration(hours: 8)),
          endedAt: now.subtract(const Duration(minutes: 10)),
          durationMinutes: 470, // ~7h 50m, but we use exact
        ),
      ];

      when(mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => sleepEntries);

      final result = await statsService.getSleepStats(profileId: 1);

      expect(result, isNotNull);
      // (540+420+470)/3 = 476.67 = 476 minutes = 7h 56m
      expect(result!.weekAverage, contains('7h'));
    });

    test('detects upward trend (more sleep - improvement)', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));

      final sleepEntries = [
        SleepEntry(
          id: 2,
          profileId: 1,
          startedAt: previousWeekStart.add(const Duration(days: 3)),
          endedAt: previousWeekStart.add(const Duration(days: 3, hours: 6)),
          durationMinutes: 360, // 6 hours
        ),
        SleepEntry(
          id: 1,
          profileId: 1,
          startedAt: now.subtract(const Duration(hours: 8)),
          endedAt: now.subtract(const Duration(minutes: 10)),
          durationMinutes: 470, // ~7.8 hours
        ),
      ];

      when(mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => sleepEntries);

      final result = await statsService.getSleepStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.trend, TrendDirection.up); // More sleep, improvement
    });
  });

  group('getMedicationStats', () {
    test('returns null when no medication intakes available', () async {
      when(mockMedicationIntakeService.listIntakes(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => []);

      final result = await statsService.getMedicationStats(profileId: 1);

      expect(result, isNull);
    });

    test('calculates adherence percentage correctly', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));

      // 5 days with doses = ~71% adherence
      final intakes = [
        MedicationIntake(
          id: 5,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 1)),
        ),
        MedicationIntake(
          id: 4,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 2)),
        ),
        MedicationIntake(
          id: 3,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 3)),
        ),
        MedicationIntake(
          id: 2,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 4)),
        ),
        MedicationIntake(
          id: 1,
          profileId: 1,
          medicationId: 1,
          takenAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      when(mockMedicationIntakeService.listIntakes(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => intakes);

      final result = await statsService.getMedicationStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.weekAverage, contains('Adherence: 71%'));
    });

    test('shows time since last dose in minutes if less than 1 hour', () async {
      final now = DateTime.now();
      final recentIntake = [
        MedicationIntake(
          id: 1,
          profileId: 1,
          medicationId: 1,
          takenAt: now.subtract(const Duration(minutes: 30)),
        ),
      ];

      when(mockMedicationIntakeService.listIntakes(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => recentIntake);

      final result = await statsService.getMedicationStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.latestValue, contains('min ago'));
    });

    test('detects upward trend (better adherence - improvement)', () async {
      final now = DateTime.now();
      final weekStart = now.subtract(const Duration(days: 7));
      final previousWeekStart = weekStart.subtract(const Duration(days: 7));

      // Current week: 6 days with doses = 86% adherence
      // Previous week: 4 days with doses = 57% adherence
      final allIntakes = [
        // Previous week (4 days)
        MedicationIntake(
          id: 10,
          profileId: 1,
          medicationId: 1,
          takenAt: previousWeekStart.add(const Duration(days: 1)),
        ),
        MedicationIntake(
          id: 9,
          profileId: 1,
          medicationId: 1,
          takenAt: previousWeekStart.add(const Duration(days: 2)),
        ),
        MedicationIntake(
          id: 8,
          profileId: 1,
          medicationId: 1,
          takenAt: previousWeekStart.add(const Duration(days: 3)),
        ),
        MedicationIntake(
          id: 7,
          profileId: 1,
          medicationId: 1,
          takenAt: previousWeekStart.add(const Duration(days: 4)),
        ),
        // Current week (6 days)
        MedicationIntake(
          id: 6,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 1)),
        ),
        MedicationIntake(
          id: 5,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 2)),
        ),
        MedicationIntake(
          id: 4,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 3)),
        ),
        MedicationIntake(
          id: 3,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 4)),
        ),
        MedicationIntake(
          id: 2,
          profileId: 1,
          medicationId: 1,
          takenAt: weekStart.add(const Duration(days: 5)),
        ),
        MedicationIntake(
          id: 1,
          profileId: 1,
          medicationId: 1,
          takenAt: now.subtract(const Duration(hours: 1)),
        ),
      ];

      when(mockMedicationIntakeService.listIntakes(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      )).thenAnswer((_) async => allIntakes);

      final result = await statsService.getMedicationStats(profileId: 1);

      expect(result, isNotNull);
      expect(result!.trend, TrendDirection.up); // Better adherence, improvement
    });
  });
}

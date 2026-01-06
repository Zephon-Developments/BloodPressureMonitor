import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';

class MockReadingService extends Mock implements ReadingService {
  @override
  Future<int> createReading(Reading reading) => (super.noSuchMethod(
        Invocation.method(#createReading, [reading]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);

  @override
  Future<List<Reading>> getReadingsByProfile(int profileId, {int? limit}) =>
      (super.noSuchMethod(
        Invocation.method(
          #getReadingsByProfile,
          [profileId],
          {#limit: limit},
        ),
        returnValue: Future.value(<Reading>[]),
        returnValueForMissingStub: Future.value(<Reading>[]),
      ) as Future<List<Reading>>);

  @override
  Future<List<Reading>> getReadingsInTimeRange(
    int profileId,
    DateTime startTime,
    DateTime endTime,
  ) =>
      (super.noSuchMethod(
        Invocation.method(
          #getReadingsInTimeRange,
          [profileId, startTime, endTime],
        ),
        returnValue: Future.value(<Reading>[]),
        returnValueForMissingStub: Future.value(<Reading>[]),
      ) as Future<List<Reading>>);

  @override
  Future<int> deleteAllByProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#deleteAllByProfile, [profileId]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);
}

class MockWeightService extends Mock implements WeightService {
  @override
  Future<WeightEntry> createWeightEntry(WeightEntry entry) =>
      (super.noSuchMethod(
        Invocation.method(#createWeightEntry, [entry]),
        returnValue: Future.value(entry),
        returnValueForMissingStub: Future.value(entry),
      ) as Future<WeightEntry>);

  @override
  Future<List<WeightEntry>> listWeightEntries({
    required int profileId,
    DateTime? from,
    DateTime? to,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listWeightEntries,
          [],
          {#profileId: profileId, #from: from, #to: to},
        ),
        returnValue: Future.value(<WeightEntry>[]),
        returnValueForMissingStub: Future.value(<WeightEntry>[]),
      ) as Future<List<WeightEntry>>);

  @override
  Future<int> deleteAllByProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#deleteAllByProfile, [profileId]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);
}

class MockSleepService extends Mock implements SleepService {
  @override
  Future<SleepEntry> createSleepEntry(SleepEntry entry) => (super.noSuchMethod(
        Invocation.method(#createSleepEntry, [entry]),
        returnValue: Future.value(entry),
        returnValueForMissingStub: Future.value(entry),
      ) as Future<SleepEntry>);

  @override
  Future<List<SleepEntry>> listSleepEntries({
    required int profileId,
    DateTime? from,
    DateTime? to,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listSleepEntries,
          [],
          {#profileId: profileId, #from: from, #to: to},
        ),
        returnValue: Future.value(<SleepEntry>[]),
        returnValueForMissingStub: Future.value(<SleepEntry>[]),
      ) as Future<List<SleepEntry>>);

  @override
  Future<int> deleteAllByProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#deleteAllByProfile, [profileId]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);
}

class MockMedicationService extends Mock implements MedicationService {
  @override
  Future<Medication> createMedication(Medication medication) =>
      (super.noSuchMethod(
        Invocation.method(#createMedication, [medication]),
        returnValue: Future.value(medication),
        returnValueForMissingStub: Future.value(medication),
      ) as Future<Medication>);

  @override
  Future<List<Medication>> listMedicationsByProfile(
    int profileId, {
    bool includeInactive = false,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listMedicationsByProfile,
          [profileId],
          {#includeInactive: includeInactive},
        ),
        returnValue: Future.value(<Medication>[]),
        returnValueForMissingStub: Future.value(<Medication>[]),
      ) as Future<List<Medication>>);

  @override
  Future<int> deleteAllByProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#deleteAllByProfile, [profileId]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);
}

class MockMedicationIntakeService extends Mock
    implements MedicationIntakeService {
  @override
  Future<MedicationIntake> logIntake(MedicationIntake intake) =>
      (super.noSuchMethod(
        Invocation.method(#logIntake, [intake]),
        returnValue: Future.value(intake),
        returnValueForMissingStub: Future.value(intake),
      ) as Future<MedicationIntake>);

  @override
  Future<List<MedicationIntake>> listIntakes({
    required int profileId,
    DateTime? from,
    DateTime? to,
    int? medicationId,
    int? groupId,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #listIntakes,
          [],
          {
            #profileId: profileId,
            #from: from,
            #to: to,
            #medicationId: medicationId,
            #groupId: groupId,
          },
        ),
        returnValue: Future.value(<MedicationIntake>[]),
        returnValueForMissingStub: Future.value(<MedicationIntake>[]),
      ) as Future<List<MedicationIntake>>);

  @override
  Future<int> deleteAllByProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#deleteAllByProfile, [profileId]),
        returnValue: Future.value(0),
        returnValueForMissingStub: Future.value(0),
      ) as Future<int>);
}

class MockAppInfoService extends Mock implements AppInfoService {
  @override
  Future<String> getAppVersion() => (super.noSuchMethod(
        Invocation.method(#getAppVersion, []),
        returnValue: Future.value('1.0.0'),
        returnValueForMissingStub: Future.value('1.0.0'),
      ) as Future<String>);
}

class MockAnalyticsService extends Mock implements AnalyticsService {
  @override
  Future<HealthStats> calculateStats({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
    TimeOfDay? cutoff,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #calculateStats,
          [],
          {
            #profileId: profileId,
            #startDate: startDate,
            #endDate: endDate,
            #cutoff: cutoff,
          },
        ),
        returnValue: Future.value(
          HealthStats(
            minSystolic: 0,
            avgSystolic: 0,
            maxSystolic: 0,
            minDiastolic: 0,
            avgDiastolic: 0,
            maxDiastolic: 0,
            minPulse: 0,
            avgPulse: 0,
            maxPulse: 0,
            systolicStdDev: 0,
            systolicCv: 0,
            diastolicStdDev: 0,
            diastolicCv: 0,
            pulseStdDev: 0,
            pulseCv: 0,
            split: const MorningEveningSplit(
              morning: ReadingBucketStats(
                count: 0,
                minSystolic: 0,
                avgSystolic: 0,
                maxSystolic: 0,
                minDiastolic: 0,
                avgDiastolic: 0,
                maxDiastolic: 0,
                minPulse: 0,
                avgPulse: 0,
                maxPulse: 0,
              ),
              evening: ReadingBucketStats(
                count: 0,
                minSystolic: 0,
                avgSystolic: 0,
                maxSystolic: 0,
                minDiastolic: 0,
                avgDiastolic: 0,
                maxDiastolic: 0,
                minPulse: 0,
                avgPulse: 0,
                maxPulse: 0,
              ),
              morningCount: 0,
              eveningCount: 0,
            ),
            totalReadings: 0,
            periodStart: DateTime.fromMillisecondsSinceEpoch(0),
            periodEnd: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ),
        returnValueForMissingStub: Future.value(
          HealthStats(
            minSystolic: 0,
            avgSystolic: 0,
            maxSystolic: 0,
            minDiastolic: 0,
            avgDiastolic: 0,
            maxDiastolic: 0,
            minPulse: 0,
            avgPulse: 0,
            maxPulse: 0,
            systolicStdDev: 0,
            systolicCv: 0,
            diastolicStdDev: 0,
            diastolicCv: 0,
            pulseStdDev: 0,
            pulseCv: 0,
            split: const MorningEveningSplit(
              morning: ReadingBucketStats(
                count: 0,
                minSystolic: 0,
                avgSystolic: 0,
                maxSystolic: 0,
                minDiastolic: 0,
                avgDiastolic: 0,
                maxDiastolic: 0,
                minPulse: 0,
                avgPulse: 0,
                maxPulse: 0,
              ),
              evening: ReadingBucketStats(
                count: 0,
                minSystolic: 0,
                avgSystolic: 0,
                maxSystolic: 0,
                minDiastolic: 0,
                avgDiastolic: 0,
                maxDiastolic: 0,
                minPulse: 0,
                avgPulse: 0,
                maxPulse: 0,
              ),
              morningCount: 0,
              eveningCount: 0,
            ),
            totalReadings: 0,
            periodStart: DateTime.fromMillisecondsSinceEpoch(0),
            periodEnd: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        ),
      ) as Future<HealthStats>);
}

class MockAveragingService extends Mock implements AveragingService {
  @override
  Future<void> createOrUpdateGroupsForReading(Reading reading) =>
      (super.noSuchMethod(
        Invocation.method(#createOrUpdateGroupsForReading, [reading]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<void> recomputeGroupsForProfile(int profileId) => (super.noSuchMethod(
        Invocation.method(#recomputeGroupsForProfile, [profileId]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<void> deleteGroupsForReading(int readingId) => (super.noSuchMethod(
        Invocation.method(#deleteGroupsForReading, [readingId]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);
}

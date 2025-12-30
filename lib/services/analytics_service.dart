import 'dart:collection';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/utils/time_range.dart';

/// Service responsible for preparing analytics data for the UI.
///
/// Aggregates blood pressure statistics, prepares chart datasets with
/// range-aware sampling, and correlates sleep data with morning readings.
class AnalyticsService {
  AnalyticsService({
    required ReadingService readingService,
    required SleepService sleepService,
    DateTime Function()? clock,
  })  : _readingService = readingService,
        _sleepService = sleepService;

  static const int _stdDevComputeThreshold = 500;

  final ReadingService _readingService;
  final SleepService _sleepService;

  /// Calculates aggregated statistics for the provided range.
  Future<HealthStats> calculateStats({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
    TimeOfDay? cutoff,
  }) async {
    final groups = await _readingService.getGroupsInRange(
      profileId: profileId,
      start: startDate,
      end: endDate,
    );

    if (groups.isEmpty) {
      return HealthStats(
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
          morning: _emptyBucket,
          evening: _emptyBucket,
          morningCount: 0,
          eveningCount: 0,
        ),
        totalReadings: 0,
        periodStart: startDate,
        periodEnd: endDate,
      );
    }

    final systolicValues = groups.map((group) => group.avgSystolic).toList();
    final diastolicValues = groups.map((group) => group.avgDiastolic).toList();
    final pulseValues = groups.map((group) => group.avgPulse).toList();

    final systolicAvg = _average(systolicValues);
    final diastolicAvg = _average(diastolicValues);
    final pulseAvg = _average(pulseValues);

    final stdDevs = await Future.wait<double>([
      _stdDev(systolicValues, systolicAvg),
      _stdDev(diastolicValues, diastolicAvg),
      _stdDev(pulseValues, pulseAvg),
    ]);

    final totalReadings = groups.fold<int>(
      0,
      (sum, group) => sum + _countMembers(group.memberReadingIds),
    );

    final classification = classifyByTimeOfDay(
      groups,
      cutoff ?? TimeRange.thirtyDays.defaultCutoff,
    );

    final split = MorningEveningSplit(
      morning: _buildBucketStats(classification.morning),
      evening: _buildBucketStats(classification.evening),
      morningCount: classification.morning.length,
      eveningCount: classification.evening.length,
    );

    return HealthStats(
      minSystolic: systolicValues.reduce(min),
      avgSystolic: systolicAvg,
      maxSystolic: systolicValues.reduce(max),
      minDiastolic: diastolicValues.reduce(min),
      avgDiastolic: diastolicAvg,
      maxDiastolic: diastolicValues.reduce(max),
      minPulse: pulseValues.reduce(min),
      avgPulse: pulseAvg,
      maxPulse: pulseValues.reduce(max),
      systolicStdDev: stdDevs[0],
      systolicCv: _coefficientOfVariation(stdDevs[0], systolicAvg),
      diastolicStdDev: stdDevs[1],
      diastolicCv: _coefficientOfVariation(stdDevs[1], diastolicAvg),
      pulseStdDev: stdDevs[2],
      pulseCv: _coefficientOfVariation(stdDevs[2], pulseAvg),
      split: split,
      totalReadings: totalReadings,
      periodStart: startDate,
      periodEnd: endDate,
    );
  }

  /// Prepares chart data for the given range with smart downsampling.
  Future<ChartDataSet> getChartData({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
    required TimeRange range,
    int maxPoints = 90,
  }) async {
    final groups = await _readingService.getGroupsInRange(
      profileId: profileId,
      start: startDate,
      end: endDate,
    );

    if (groups.isEmpty) {
      return ChartDataSet(
        systolicPoints: const <ChartPoint>[],
        diastolicPoints: const <ChartPoint>[],
        pulsePoints: const <ChartPoint>[],
        minDate: startDate,
        maxDate: endDate,
        isSampled: false,
      );
    }

    final shouldSample = _shouldSample(range, groups.length, maxPoints);
    final aggregates = shouldSample
        ? _downsample(groups, range, maxPoints)
        : groups
            .map(
              (group) => _BucketAggregate(
                timestamp: group.groupStartAt,
                systolic: group.avgSystolic,
                diastolic: group.avgDiastolic,
                pulse: group.avgPulse,
                isSampled: false,
                groupId: group.id,
              ),
            )
            .toList();

    final systolicPoints = aggregates
        .map(
          (aggregate) => ChartPoint(
            timestamp: aggregate.timestamp,
            value: aggregate.systolic,
            isSampled: aggregate.isSampled,
            groupId: aggregate.groupId,
          ),
        )
        .toList();
    final diastolicPoints = aggregates
        .map(
          (aggregate) => ChartPoint(
            timestamp: aggregate.timestamp,
            value: aggregate.diastolic,
            isSampled: aggregate.isSampled,
            groupId: aggregate.groupId,
          ),
        )
        .toList();
    final pulsePoints = aggregates
        .map(
          (aggregate) => ChartPoint(
            timestamp: aggregate.timestamp,
            value: aggregate.pulse,
            isSampled: aggregate.isSampled,
            groupId: aggregate.groupId,
          ),
        )
        .toList();

    return ChartDataSet(
      systolicPoints: systolicPoints,
      diastolicPoints: diastolicPoints,
      pulsePoints: pulsePoints,
      minDate: aggregates.first.timestamp,
      maxDate: aggregates.last.timestamp,
      isSampled: shouldSample,
    );
  }

  /// Correlates sleep sessions with morning readings in the range.
  Future<SleepCorrelationData> getSleepCorrelation({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
    TimeOfDay? cutoff,
  }) async {
    final groups = await _readingService.getGroupsInRange(
      profileId: profileId,
      start: startDate,
      end: endDate,
    );

    final classification = classifyByTimeOfDay(
      groups,
      cutoff ?? TimeRange.thirtyDays.defaultCutoff,
    );

    final sleepEntries = await _sleepService.listSleepEntries(
      profileId: profileId,
      from: startDate.subtract(const Duration(days: 1)),
      to: endDate.add(const Duration(days: 1)),
    );

    final sleepByDate = SplayTreeMap<DateTime, SleepQualityLevel?>();
    final entriesByDate = <DateTime, SleepEntry>{};

    for (final entry in sleepEntries) {
      if (entry.endedAt == null) {
        continue;
      }
      final sessionDate = _toLocalDate(entry.sessionDateLocal);
      entriesByDate[sessionDate] = entry;
      sleepByDate[sessionDate] = SleepQualityParsing.fromScore(entry.quality);
    }

    final morningMap = <DateTime, ReadingGroup>{};
    for (final group in classification.morning) {
      final local = _toLocalDate(group.groupStartAt.toLocal());
      morningMap.putIfAbsent(local, () => group);
    }

    final correlationPoints = <CorrelationPoint>[];
    final orderedDates = entriesByDate.keys.toList()..sort();
    for (final date in orderedDates) {
      correlationPoints.add(
        CorrelationPoint(
          date: date,
          sleepEntry: entriesByDate[date]!,
          reading: morningMap[date],
        ),
      );
    }

    return SleepCorrelationData(
      sleepByDate: sleepByDate,
      morningReadings: morningMap,
      correlationPoints: correlationPoints,
    );
  }

  /// Builds stacked sleep stage series for the requested window.
  Future<SleepStageSeries> getSleepStageSeries({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final entries = await _sleepService.listSleepEntries(
      profileId: profileId,
      from: startDate.subtract(const Duration(days: 1)),
      to: endDate.add(const Duration(days: 1)),
    );

    final stages = <SleepStageBreakdown>[];
    bool hasIncomplete = false;

    for (final entry in entries) {
      if (!entry.hasStageData) {
        hasIncomplete = true;
        continue;
      }
      stages.add(
        SleepStageBreakdown(
          sessionDate: _toLocalDate(entry.sessionDateLocal),
          getUpTime: entry.endedAt?.toLocal(),
          deepMinutes: entry.deepMinutes!,
          lightMinutes: entry.lightMinutes!,
          remMinutes: entry.remMinutes!,
          awakeMinutes: entry.awakeMinutes!,
        ),
      );
    }

    stages.sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    return SleepStageSeries(
      stages: stages,
      hasIncompleteSessions: hasIncomplete,
    );
  }

  /// Splits readings into morning and evening buckets using [cutoff].
  @visibleForTesting
  TimeOfDayClassification classifyByTimeOfDay(
    List<ReadingGroup> groups,
    TimeOfDay cutoff,
  ) {
    final cutoffMinutes = cutoff.hour * 60 + cutoff.minute;
    final morning = <ReadingGroup>[];
    final evening = <ReadingGroup>[];

    for (final group in groups) {
      final local = group.groupStartAt.toLocal();
      final minutes = local.hour * 60 + local.minute;
      if (minutes < cutoffMinutes) {
        morning.add(group);
      } else {
        evening.add(group);
      }
    }

    return TimeOfDayClassification(morning: morning, evening: evening);
  }

  static bool _shouldSample(TimeRange range, int groups, int maxPoints) {
    if (groups <= maxPoints && range == TimeRange.sevenDays) {
      return false;
    }

    switch (range) {
      case TimeRange.sevenDays:
        return groups > maxPoints;
      case TimeRange.thirtyDays:
        return groups > 100 || groups > maxPoints;
      case TimeRange.ninetyDays:
      case TimeRange.oneYear:
      case TimeRange.allTime:
        return true;
    }
  }

  List<_BucketAggregate> _downsample(
    List<ReadingGroup> groups,
    TimeRange range,
    int maxPoints,
  ) {
    final buckets = SplayTreeMap<DateTime, List<ReadingGroup>>();

    for (final group in groups) {
      final key = range.useWeeklyBuckets
          ? _weekStart(group.groupStartAt)
          : _dayStart(group.groupStartAt);
      buckets.putIfAbsent(key, () => <ReadingGroup>[]).add(group);
    }

    final aggregates = buckets.entries
        .map(
          (entry) => _BucketAggregate(
            timestamp: entry.key,
            systolic: _average(entry.value.map((g) => g.avgSystolic)),
            diastolic: _average(entry.value.map((g) => g.avgDiastolic)),
            pulse: _average(entry.value.map((g) => g.avgPulse)),
            isSampled: true,
          ),
        )
        .toList();

    if (aggregates.length <= maxPoints) {
      return aggregates;
    }

    final step = (aggregates.length / maxPoints).ceil();
    final reduced = <_BucketAggregate>[];
    for (var index = 0; index < aggregates.length; index += step) {
      reduced.add(aggregates[index]);
    }

    if (reduced.last.timestamp != aggregates.last.timestamp) {
      reduced.add(aggregates.last);
    }

    return reduced;
  }

  static ReadingBucketStats _buildBucketStats(List<ReadingGroup> groups) {
    if (groups.isEmpty) {
      return _emptyBucket;
    }

    final systolicValues = groups.map((group) => group.avgSystolic).toList();
    final diastolicValues = groups.map((group) => group.avgDiastolic).toList();
    final pulseValues = groups.map((group) => group.avgPulse).toList();

    return ReadingBucketStats(
      count: groups.length,
      minSystolic: systolicValues.reduce(min),
      avgSystolic: _average(systolicValues),
      maxSystolic: systolicValues.reduce(max),
      minDiastolic: diastolicValues.reduce(min),
      avgDiastolic: _average(diastolicValues),
      maxDiastolic: diastolicValues.reduce(max),
      minPulse: pulseValues.reduce(min),
      avgPulse: _average(pulseValues),
      maxPulse: pulseValues.reduce(max),
    );
  }

  Future<double> _stdDev(List<double> values, double mean) async {
    if (values.isEmpty || mean == 0) {
      return 0;
    }
    if (values.length <= _stdDevComputeThreshold) {
      return _stdDevSync(values, mean);
    }

    final payload = <String, dynamic>{
      'values': List<double>.from(values),
      'mean': mean,
    };
    return compute(_stdDevWorker, payload);
  }

  static double _stdDevSync(List<double> values, double mean) {
    if (values.isEmpty) {
      return 0;
    }
    final variance = values.fold<double>(
          0,
          (sum, value) => sum + pow(value - mean, 2),
        ) /
        values.length;
    return sqrt(variance);
  }

  static double _coefficientOfVariation(double stdDev, double mean) {
    if (mean == 0) {
      return 0;
    }
    return (stdDev / mean) * 100;
  }

  static double _average(Iterable<double> values) {
    if (values.isEmpty) {
      return 0;
    }
    return values.reduce((a, b) => a + b) / values.length;
  }

  static int _countMembers(String memberIds) {
    if (memberIds.trim().isEmpty) {
      return 0;
    }
    return memberIds
        .split(',')
        .map((id) => id.trim())
        .where((value) => value.isNotEmpty)
        .length;
  }

  static DateTime _dayStart(DateTime timestamp) {
    final utc = timestamp.toUtc();
    return DateTime.utc(utc.year, utc.month, utc.day);
  }

  static DateTime _weekStart(DateTime timestamp) {
    final day = _dayStart(timestamp);
    final delta = day.weekday - DateTime.monday;
    return day.subtract(Duration(days: max(delta, 0)));
  }

  static DateTime _toLocalDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

/// Result of splitting readings by time of day.
class TimeOfDayClassification {
  const TimeOfDayClassification({
    required this.morning,
    required this.evening,
  });

  /// Readings captured before the cutoff.
  final List<ReadingGroup> morning;

  /// Readings captured at or after the cutoff.
  final List<ReadingGroup> evening;
}

class _BucketAggregate {
  const _BucketAggregate({
    required this.timestamp,
    required this.systolic,
    required this.diastolic,
    required this.pulse,
    required this.isSampled,
    this.groupId,
  });

  final DateTime timestamp;
  final double systolic;
  final double diastolic;
  final double pulse;
  final bool isSampled;
  final int? groupId;
}

const ReadingBucketStats _emptyBucket = ReadingBucketStats(
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
);

double _stdDevWorker(Map<String, dynamic> payload) {
  final values = (payload['values'] as List<dynamic>).cast<double>();
  final mean = payload['mean'] as double;
  return AnalyticsService._stdDevSync(values, mean);
}

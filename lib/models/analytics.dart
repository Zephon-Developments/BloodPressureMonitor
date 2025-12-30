import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';

/// Represents a chartable value at a point in time.
class ChartPoint {
  const ChartPoint({
    required this.timestamp,
    required this.value,
    this.isSampled = false,
    this.groupId,
  });

  final DateTime timestamp;
  final double value;
  final bool isSampled;
  final int? groupId;
}

/// Combined dataset for the systolic, diastolic, and pulse series.
class ChartDataSet {
  const ChartDataSet({
    required this.systolicPoints,
    required this.diastolicPoints,
    required this.pulsePoints,
    required this.minDate,
    required this.maxDate,
    this.isSampled = false,
  });

  final List<ChartPoint> systolicPoints;
  final List<ChartPoint> diastolicPoints;
  final List<ChartPoint> pulsePoints;
  final DateTime minDate;
  final DateTime maxDate;
  final bool isSampled;

  bool get hasPoints =>
      systolicPoints.isNotEmpty ||
      diastolicPoints.isNotEmpty ||
      pulsePoints.isNotEmpty;
}

/// Snapshot of aggregate metrics for a bucket of readings.
class ReadingBucketStats {
  const ReadingBucketStats({
    required this.count,
    required this.minSystolic,
    required this.avgSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.avgDiastolic,
    required this.maxDiastolic,
    required this.minPulse,
    required this.avgPulse,
    required this.maxPulse,
  });

  final int count;
  final double minSystolic;
  final double avgSystolic;
  final double maxSystolic;
  final double minDiastolic;
  final double avgDiastolic;
  final double maxDiastolic;
  final double minPulse;
  final double avgPulse;
  final double maxPulse;
}

/// Morning vs evening comparison bucket.
class MorningEveningSplit {
  const MorningEveningSplit({
    required this.morning,
    required this.evening,
    required this.morningCount,
    required this.eveningCount,
  });

  final ReadingBucketStats morning;
  final ReadingBucketStats evening;
  final int morningCount;
  final int eveningCount;
}

/// Aggregated health statistics across the selected range.
class HealthStats {
  const HealthStats({
    required this.minSystolic,
    required this.avgSystolic,
    required this.maxSystolic,
    required this.minDiastolic,
    required this.avgDiastolic,
    required this.maxDiastolic,
    required this.minPulse,
    required this.avgPulse,
    required this.maxPulse,
    required this.systolicStdDev,
    required this.systolicCv,
    required this.diastolicStdDev,
    required this.diastolicCv,
    required this.pulseStdDev,
    required this.pulseCv,
    required this.split,
    required this.totalReadings,
    required this.periodStart,
    required this.periodEnd,
  });

  final double minSystolic;
  final double avgSystolic;
  final double maxSystolic;
  final double minDiastolic;
  final double avgDiastolic;
  final double maxDiastolic;
  final double minPulse;
  final double avgPulse;
  final double maxPulse;
  final double systolicStdDev;
  final double systolicCv;
  final double diastolicStdDev;
  final double diastolicCv;
  final double pulseStdDev;
  final double pulseCv;
  final MorningEveningSplit split;
  final int totalReadings;
  final DateTime periodStart;
  final DateTime periodEnd;

  bool get hasData => totalReadings > 0;
}

/// Sleep stage breakdown prepared for stacked area display.
class SleepStageBreakdown {
  const SleepStageBreakdown({
    required this.sessionDate,
    required this.getUpTime,
    required this.deepMinutes,
    required this.lightMinutes,
    required this.remMinutes,
    required this.awakeMinutes,
  });

  final DateTime sessionDate;
  final DateTime? getUpTime;
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;

  int get totalMinutes =>
      deepMinutes + lightMinutes + remMinutes + awakeMinutes;
}

/// Collection of sleep stage series metadata.
class SleepStageSeries {
  const SleepStageSeries({
    required this.stages,
    required this.hasIncompleteSessions,
  });

  final List<SleepStageBreakdown> stages;
  final bool hasIncompleteSessions;

  bool get isEmpty => stages.isEmpty;
}

/// Correlation between sleep quality and morning readings.
class SleepCorrelationData {
  const SleepCorrelationData({
    required this.sleepByDate,
    required this.morningReadings,
    required this.correlationPoints,
  });

  final Map<DateTime, SleepQualityLevel?> sleepByDate;
  final Map<DateTime, ReadingGroup> morningReadings;
  final List<CorrelationPoint> correlationPoints;
}

/// Represents a single overlay annotation point.
class CorrelationPoint {
  const CorrelationPoint({
    required this.date,
    required this.sleepEntry,
    required this.reading,
  });

  final DateTime date;
  final SleepEntry sleepEntry;
  final ReadingGroup? reading;
}

/// Enumeration of qualitative sleep levels derived from a 1-5 score.
enum SleepQualityLevel {
  veryPoor,
  poor,
  fair,
  good,
  excellent,
}

/// Helpers for parsing qualitative sleep scores.
extension SleepQualityParsing on SleepQualityLevel {
  static SleepQualityLevel? fromScore(int? value) {
    if (value == null) {
      return null;
    }
    final index = value.clamp(1, 5) - 1;
    return SleepQualityLevel.values[index];
  }

  int get score => index + 1;
}

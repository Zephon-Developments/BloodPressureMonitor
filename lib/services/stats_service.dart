import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';

/// Service for calculating mini-statistics for health data categories.
///
/// Provides summary statistics including latest values, 7-day averages,
/// and trend indicators for use in collapsible history sections.
class StatsService {
  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;
  final MedicationIntakeService _medicationIntakeService;

  /// Creates a [StatsService] with required dependencies.
  StatsService({
    ReadingService? readingService,
    WeightService? weightService,
    SleepService? sleepService,
    MedicationIntakeService? medicationIntakeService,
  })  : _readingService = readingService ?? ReadingService(),
        _weightService = weightService ?? WeightService(DatabaseService()),
        _sleepService = sleepService ?? SleepService(DatabaseService()),
        _medicationIntakeService = medicationIntakeService ??
            MedicationIntakeService(DatabaseService());

  /// Calculates mini-stats for blood pressure readings.
  ///
  /// Returns null if no readings are available.
  Future<MiniStats?> getBloodPressureStats({
    required int profileId,
    int daysBack = 7,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: daysBack));
    final previousWeekStart = weekStart.subtract(Duration(days: daysBack));

    // Get all readings from previous two weeks
    final allReadings = await _readingService.getReadingsInTimeRange(
      profileId,
      previousWeekStart,
      now,
    );

    if (allReadings.isEmpty) {
      return null;
    }

    final latest = allReadings.last; // Most recent
    final latestValue =
        '${latest.systolic}/${latest.diastolic} mmHg @ ${DateFormats.timeOnly.format(latest.takenAt)}';

    // Calculate current week average
    final currentWeekReadings =
        allReadings.where((r) => r.takenAt.isAfter(weekStart)).toList();

    if (currentWeekReadings.isEmpty) {
      return MiniStats(
        latestValue: latestValue,
        weekAverage: 'Insufficient data',
        trend: TrendDirection.stable,
        lastUpdate: latest.takenAt,
      );
    }

    final currentAvgSystolic =
        currentWeekReadings.map((r) => r.systolic).reduce((a, b) => a + b) ~/
            currentWeekReadings.length;
    final currentAvgDiastolic =
        currentWeekReadings.map((r) => r.diastolic).reduce((a, b) => a + b) ~/
            currentWeekReadings.length;

    // Calculate previous week average for trend
    final previousWeekReadings = allReadings
        .where((r) =>
            r.takenAt.isAfter(previousWeekStart) &&
            r.takenAt.isBefore(weekStart))
        .toList();

    TrendDirection trend = TrendDirection.stable;
    if (previousWeekReadings.isNotEmpty) {
      final prevAvgSystolic =
          previousWeekReadings.map((r) => r.systolic).reduce((a, b) => a + b) ~/
              previousWeekReadings.length;

      final diff = currentAvgSystolic - prevAvgSystolic;
      final changePercent = (diff.abs() / prevAvgSystolic) * 100;

      if (changePercent >= 5) {
        // Lower BP is better
        trend = diff < 0 ? TrendDirection.up : TrendDirection.down;
      }
    }

    return MiniStats(
      latestValue: latestValue,
      weekAverage: 'Avg: $currentAvgSystolic/$currentAvgDiastolic',
      trend: trend,
      lastUpdate: latest.takenAt,
    );
  }

  /// Calculates mini-stats for weight entries.
  ///
  /// Returns null if no weight entries are available.
  Future<MiniStats?> getWeightStats({
    required int profileId,
    int daysBack = 7,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: daysBack));
    final previousWeekStart = weekStart.subtract(Duration(days: daysBack));

    // Get all weights from previous two weeks
    final allWeights = await _weightService.listWeightEntries(
      profileId: profileId,
      from: previousWeekStart,
      to: now,
    );

    if (allWeights.isEmpty) {
      return null;
    }

    final latest = allWeights.last; // Most recent
    final latestValue =
        '${latest.weightValue.toStringAsFixed(1)} ${latest.unit.toDbString()} @ ${DateFormats.dateOnly.format(latest.takenAt)}';

    // Calculate current week average
    final currentWeekWeights =
        allWeights.where((w) => w.takenAt.isAfter(weekStart)).toList();

    if (currentWeekWeights.isEmpty) {
      return MiniStats(
        latestValue: latestValue,
        weekAverage: 'Insufficient data',
        trend: TrendDirection.stable,
        lastUpdate: latest.takenAt,
      );
    }

    final currentAvg =
        currentWeekWeights.map((w) => w.weightValue).reduce((a, b) => a + b) /
            currentWeekWeights.length;

    // Calculate previous week average for trend
    final previousWeekWeights = allWeights
        .where((w) =>
            w.takenAt.isAfter(previousWeekStart) &&
            w.takenAt.isBefore(weekStart))
        .toList();

    TrendDirection trend = TrendDirection.stable;
    if (previousWeekWeights.isNotEmpty) {
      final prevAvg = previousWeekWeights
              .map((w) => w.weightValue)
              .reduce((a, b) => a + b) /
          previousWeekWeights.length;

      final diff = currentAvg - prevAvg;
      final changePercent = (diff.abs() / prevAvg) * 100;

      if (changePercent >= 5) {
        // Weight loss is improvement (down = good)
        trend = diff < 0 ? TrendDirection.up : TrendDirection.down;
      }
    }

    return MiniStats(
      latestValue: latestValue,
      weekAverage:
          'Avg: ${currentAvg.toStringAsFixed(1)} ${latest.unit.toDbString()}',
      trend: trend,
      lastUpdate: latest.takenAt,
    );
  }

  /// Calculates mini-stats for sleep entries.
  ///
  /// Returns null if no sleep entries are available.
  Future<MiniStats?> getSleepStats({
    required int profileId,
    int daysBack = 7,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: daysBack));
    final previousWeekStart = weekStart.subtract(Duration(days: daysBack));

    // Get all sleep entries from previous two weeks
    final allSleep = await _sleepService.listSleepEntries(
      profileId: profileId,
      from: previousWeekStart,
      to: now,
    );

    if (allSleep.isEmpty) {
      return null;
    }

    final latest = allSleep.last; // Most recent
    final latestHours = latest.durationMinutes ~/ 60;
    final latestMinutes = latest.durationMinutes % 60;
    final latestValue =
        '${latestHours}h ${latestMinutes}m @ ${DateFormats.dateOnly.format(latest.endedAt ?? latest.startedAt)}';

    // Calculate current week average
    final currentWeekSleep = allSleep
        .where((s) => (s.endedAt ?? s.startedAt).isAfter(weekStart))
        .toList();

    if (currentWeekSleep.isEmpty) {
      return MiniStats(
        latestValue: latestValue,
        weekAverage: 'Insufficient data',
        trend: TrendDirection.stable,
        lastUpdate: latest.endedAt ?? latest.startedAt,
      );
    }

    final currentAvgMinutes = currentWeekSleep
            .map((s) => s.durationMinutes)
            .reduce((a, b) => a + b) ~/
        currentWeekSleep.length;
    final avgHours = currentAvgMinutes ~/ 60;
    final avgMinutes = currentAvgMinutes % 60;

    // Calculate previous week average for trend
    final previousWeekSleep = allSleep.where((s) {
      final sleepEnd = s.endedAt ?? s.startedAt;
      return sleepEnd.isAfter(previousWeekStart) &&
          sleepEnd.isBefore(weekStart);
    }).toList();

    TrendDirection trend = TrendDirection.stable;
    if (previousWeekSleep.isNotEmpty) {
      final prevAvgMinutes = previousWeekSleep
              .map((s) => s.durationMinutes)
              .reduce((a, b) => a + b) ~/
          previousWeekSleep.length;

      final diff = currentAvgMinutes - prevAvgMinutes;
      final changePercent = (diff.abs() / prevAvgMinutes) * 100;

      if (changePercent >= 5) {
        // More sleep is better
        trend = diff > 0 ? TrendDirection.up : TrendDirection.down;
      }
    }

    return MiniStats(
      latestValue: latestValue,
      weekAverage: 'Avg: ${avgHours}h ${avgMinutes}m',
      trend: trend,
      lastUpdate: latest.endedAt ?? latest.startedAt,
    );
  }

  /// Calculates mini-stats for medication adherence.
  ///
  /// Returns null if no medication intake data is available.
  Future<MiniStats?> getMedicationStats({
    required int profileId,
    int daysBack = 7,
  }) async {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: daysBack));
    final previousWeekStart = weekStart.subtract(Duration(days: daysBack));

    // Get all intakes from previous two weeks
    final allIntakes = await _medicationIntakeService.listIntakes(
      profileId: profileId,
      from: previousWeekStart,
      to: now,
    );

    if (allIntakes.isEmpty) {
      return null;
    }

    final latest = allIntakes.last; // Most recent
    final timeSince = now.difference(latest.takenAt);
    final hoursSince = timeSince.inHours;
    final latestValue = hoursSince < 1
        ? 'Last dose: ${timeSince.inMinutes} min ago'
        : 'Last dose: ${hoursSince}h ago';

    // Calculate adherence for current week
    final currentWeekIntakes =
        allIntakes.where((i) => i.takenAt.isAfter(weekStart)).toList();

    if (currentWeekIntakes.isEmpty) {
      return MiniStats(
        latestValue: latestValue,
        weekAverage: 'No data',
        trend: TrendDirection.stable,
        lastUpdate: latest.takenAt,
      );
    }

    // For simplicity, calculate adherence as percentage of days with at least one dose
    final daysWithDoses = currentWeekIntakes
        .map((i) => DateTime(i.takenAt.year, i.takenAt.month, i.takenAt.day))
        .toSet()
        .length;
    final adherencePercent = (daysWithDoses / daysBack * 100).round();

    // Calculate previous week for trend
    final previousIntakes = allIntakes
        .where((i) =>
            i.takenAt.isAfter(previousWeekStart) &&
            i.takenAt.isBefore(weekStart))
        .toList();

    TrendDirection trend = TrendDirection.stable;
    if (previousIntakes.isNotEmpty) {
      final prevDaysWithDoses = previousIntakes
          .map((i) => DateTime(i.takenAt.year, i.takenAt.month, i.takenAt.day))
          .toSet()
          .length;
      final prevAdherence = prevDaysWithDoses / daysBack * 100;

      final diff = adherencePercent - prevAdherence;
      if (diff.abs() >= 5) {
        // Better adherence is improvement
        trend = diff > 0 ? TrendDirection.up : TrendDirection.down;
      }
    }

    return MiniStats(
      latestValue: latestValue,
      weekAverage: 'Adherence: $adherencePercent%',
      trend: trend,
      lastUpdate: latest.takenAt,
    );
  }
}

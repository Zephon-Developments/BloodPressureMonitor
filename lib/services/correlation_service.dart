import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';

/// Lightweight tuple carrying a blood pressure reading alongside the
/// sleep session that likely preceded it.
class ReadingSleepCorrelation {
  /// Creates a [ReadingSleepCorrelation].
  const ReadingSleepCorrelation({
    required this.reading,
    this.sleepEntry,
  });

  /// The blood pressure reading captured in the morning window.
  final Reading reading;

  /// The sleep session that ended before the reading (if any).
  final SleepEntry? sleepEntry;
}

/// Service that aggregates readings, weight, and sleep data for analytics.
class CorrelationService {
  CorrelationService({
    required ReadingService readingService,
    required WeightService weightService,
    required SleepService sleepService,
  })  : _readingService = readingService,
        _weightService = weightService,
        _sleepService = sleepService;

  final ReadingService _readingService;
  final WeightService _weightService;
  final SleepService _sleepService;

  /// Fetches morning readings and pairs each with the most recent sleep entry.
  Future<List<ReadingSleepCorrelation>> fetchMorningReadingsWithSleep({
    required int profileId,
    required DateTime start,
    required DateTime end,
    int morningCutoffHour = 12,
  }) async {
    final readings = await _readingService.getReadingsInTimeRange(
      profileId,
      start,
      end,
    );

    final List<ReadingSleepCorrelation> pairs = <ReadingSleepCorrelation>[];
    for (final reading in readings) {
      if (reading.takenAt.hour >= morningCutoffHour) {
        continue;
      }
      final sleep = await _sleepService.findSleepForMorningReading(
        profileId: profileId,
        readingTime: reading.takenAt,
      );
      pairs.add(ReadingSleepCorrelation(reading: reading, sleepEntry: sleep));
    }
    return pairs;
  }

  /// Fetches normalized weight entries for the provided date range.
  Future<List<WeightEntry>> fetchWeightsForRange({
    required int profileId,
    DateTime? from,
    DateTime? to,
  }) {
    return _weightService.listWeightEntries(
      profileId: profileId,
      from: from,
      to: to,
    );
  }

  /// Convenience helper to retrieve the latest recorded weight.
  Future<WeightEntry?> getLatestWeight(int profileId) {
    return _weightService.getLatestWeightEntry(profileId);
  }
}

/// Represents mini-statistics for a health data category.
///
/// Used to display summary information in collapsed sections of the history page.
class MiniStats {
  /// The most recent value as a formatted string.
  final String latestValue;

  /// The 7-day average as a formatted string.
  final String weekAverage;

  /// The trend direction compared to the previous week.
  final TrendDirection trend;

  /// When the latest value was recorded.
  final DateTime? lastUpdate;

  /// Creates a [MiniStats] instance.
  const MiniStats({
    required this.latestValue,
    required this.weekAverage,
    required this.trend,
    this.lastUpdate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MiniStats &&
        other.latestValue == latestValue &&
        other.weekAverage == weekAverage &&
        other.trend == trend &&
        other.lastUpdate == lastUpdate;
  }

  @override
  int get hashCode {
    return Object.hash(
      latestValue,
      weekAverage,
      trend,
      lastUpdate,
    );
  }

  @override
  String toString() {
    return 'MiniStats(latest: $latestValue, avg: $weekAverage, trend: $trend)';
  }
}

/// Direction of trend compared to previous period.
enum TrendDirection {
  /// Improvement (BP lower, more sleep, better adherence, etc.)
  up,

  /// Decline (BP higher, less sleep, worse adherence, etc.)
  down,

  /// No significant change (<5% difference)
  stable,
}

import 'package:flutter/material.dart';

/// Time range selections for analytics views.
enum TimeRange {
  sevenDays,
  thirtyDays,
  ninetyDays,
  oneYear,
  allTime,
}

extension TimeRangeExtension on TimeRange {
  /// Resolves the time range into a start/end tuple using [anchor] as "now".
  (DateTime start, DateTime end) toDateRange({DateTime? anchor}) {
    final now = (anchor ?? DateTime.now()).toUtc();
    switch (this) {
      case TimeRange.sevenDays:
        return (now.subtract(const Duration(days: 7)), now);
      case TimeRange.thirtyDays:
        return (now.subtract(const Duration(days: 30)), now);
      case TimeRange.ninetyDays:
        return (now.subtract(const Duration(days: 90)), now);
      case TimeRange.oneYear:
        return (now.subtract(const Duration(days: 365)), now);
      case TimeRange.allTime:
        return (DateTime.utc(2000, 1, 1), now);
    }
  }

  /// Human-readable label for chips and analytics subtitles.
  String get label {
    switch (this) {
      case TimeRange.sevenDays:
        return '7d';
      case TimeRange.thirtyDays:
        return '30d';
      case TimeRange.ninetyDays:
        return '90d';
      case TimeRange.oneYear:
        return '1y';
      case TimeRange.allTime:
        return 'All';
    }
  }

  /// Whether this range should prefer weekly aggregation.
  bool get useWeeklyBuckets =>
      this == TimeRange.oneYear || this == TimeRange.allTime;

  /// Maximum number of raw points to plot before sampling is required.
  int get maxRawPoints {
    switch (this) {
      case TimeRange.sevenDays:
        return 120;
      case TimeRange.thirtyDays:
        return 100;
      case TimeRange.ninetyDays:
        return 90;
      case TimeRange.oneYear:
        return 90;
      case TimeRange.allTime:
        return 90;
    }
  }

  /// Default cutoff separating morning and evening buckets.
  TimeOfDay get defaultCutoff => const TimeOfDay(hour: 12, minute: 0);
}

import 'package:blood_pressure_monitor/models/reading.dart';

/// Display mode for the history screen.
enum HistoryViewMode { averaged, raw }

/// Preset date ranges available on the history filter bar.
enum HistoryRangePreset { sevenDays, thirtyDays, ninetyDays, all, custom }

/// Filter state applied to the history query.
class HistoryFilters {
  HistoryFilters({
    this.startDate,
    this.endDate,
    Set<String> tags = const <String>{},
    this.viewMode = HistoryViewMode.averaged,
  }) : tags = Set<String>.unmodifiable(
          tags.map((tag) => tag.trim().toLowerCase()).where(
                (tag) => tag.isNotEmpty,
              ),
        );

  /// Builds an initial filter window using the provided clock.
  factory HistoryFilters.initial(DateTime nowUtc) {
    final DateTime end = nowUtc;
    final DateTime start = end.subtract(const Duration(days: 30));
    return HistoryFilters(startDate: start, endDate: end);
  }

  /// Inclusive UTC start date filter.
  final DateTime? startDate;

  /// Inclusive UTC end date filter.
  final DateTime? endDate;

  /// Case-insensitive tags to match.
  final Set<String> tags;

  /// Current history view mode.
  final HistoryViewMode viewMode;

  HistoryFilters copyWith({
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    Set<String>? tags,
    HistoryViewMode? viewMode,
  }) {
    return HistoryFilters(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      tags: tags ?? this.tags,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  int get hashCode => Object.hash(startDate, endDate, tags, viewMode);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryFilters &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.viewMode == viewMode &&
        _setEquals(other.tags, tags);
  }

  bool _setEquals(Set<String> a, Set<String> b) {
    if (a.length != b.length) return false;
    for (final value in a) {
      if (!b.contains(value)) return false;
    }
    return true;
  }
}

/// UI model describing an averaged reading group row.
class HistoryGroupItem {
  const HistoryGroupItem({
    required this.group,
    this.readings,
    this.isExpanded = false,
    this.isLoadingChildren = false,
    this.childError,
  });

  /// Underlying reading group summary.
  final ReadingGroup group;

  /// Raw readings contained in this group (lazy loaded).
  final List<Reading>? readings;

  /// Whether the tile is currently expanded.
  final bool isExpanded;

  /// Whether raw readings are being fetched.
  final bool isLoadingChildren;

  /// Optional load error scoped to this group.
  final String? childError;

  /// Number of readings contained in the group.
  int get memberCount {
    return group.memberReadingIds
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .length;
  }

  /// Returns reading list as unmodifiable view when present.
  List<Reading>? get children =>
      readings == null ? null : List<Reading>.unmodifiable(readings!);

  HistoryGroupItem copyWith({
    List<Reading>? readings,
    bool replaceReadings = false,
    bool? isExpanded,
    bool? isLoadingChildren,
    String? childError,
    bool clearError = false,
  }) {
    return HistoryGroupItem(
      group: group,
      readings: replaceReadings ? readings : (readings ?? this.readings),
      isExpanded: isExpanded ?? this.isExpanded,
      isLoadingChildren: isLoadingChildren ?? this.isLoadingChildren,
      childError: clearError ? null : (childError ?? this.childError),
    );
  }
}

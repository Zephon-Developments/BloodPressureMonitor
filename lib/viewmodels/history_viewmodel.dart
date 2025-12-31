import 'package:flutter/foundation.dart';

import 'package:blood_pressure_monitor/models/history.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/history_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel coordinating history retrieval, filtering, and pagination.
///
/// Automatically reloads data when the active profile changes.
class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(
    this._historyService,
    this._activeProfileViewModel, {
    DateTime Function()? clock,
  })  : _clock = clock ?? DateTime.now,
        _filters = HistoryFilters.initial((clock ?? DateTime.now)().toUtc()) {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  static const int _pageSize = 20;

  final HistoryService _historyService;
  final ActiveProfileViewModel _activeProfileViewModel;
  final DateTime Function() _clock;

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  void _onProfileChanged() {
    _groups = [];
    _rawReadings = [];
    _error = null;
    notifyListeners();
    loadInitial();
  }

  HistoryFilters _filters;
  HistoryRangePreset _activePreset = HistoryRangePreset.thirtyDays;
  List<HistoryGroupItem> _groups = <HistoryGroupItem>[];
  List<Reading> _rawReadings = <Reading>[];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;
  DateTime? _groupCursor;
  DateTime? _rawCursor;

  /// Current filters applied to the query.
  HistoryFilters get filters => _filters;

  /// Currently selected preset.
  HistoryRangePreset get activePreset => _activePreset;

  /// Whether new data is loading for initial fetch.
  bool get isLoading => _isLoading;

  /// Whether pagination request is running.
  bool get isLoadingMore => _isLoadingMore;

  /// Whether additional pages are available.
  bool get hasMore => _hasMore;

  /// Latest user-facing error.
  String? get error => _error;

  /// Averaged history groups.
  List<HistoryGroupItem> get groups =>
      List<HistoryGroupItem>.unmodifiable(_groups);

  /// Flat list of raw readings when view mode is raw.
  List<Reading> get rawReadings => List<Reading>.unmodifiable(_rawReadings);

  /// True when no data is available for the current filters.
  bool get isEmpty => _filters.viewMode == HistoryViewMode.averaged
      ? _groups.isEmpty
      : _rawReadings.isEmpty;

  /// Loads the first page for the current filters.
  ///
  /// Resets cursors, clears errors, and re-fetches either averaged or
  /// raw data depending on the active view mode.
  Future<void> loadInitial() async {
    _isLoading = true;
    _error = null;
    _groupCursor = null;
    _rawCursor = null;
    _hasMore = true;
    notifyListeners();

    try {
      if (_filters.viewMode == HistoryViewMode.averaged) {
        await _loadGroups(reset: true);
      } else {
        await _loadRawReadings(reset: true);
      }
    } catch (e) {
      _error = 'Failed to load history: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetches the next page if available.
  ///
  /// Uses keyset pagination via the latest cursor and appends the
  /// resulting records to the current collection. Calls are ignored if
  /// another load is in-flight or no more pages are available.
  Future<void> loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) {
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      if (_filters.viewMode == HistoryViewMode.averaged) {
        await _loadGroups(reset: false);
      } else {
        await _loadRawReadings(reset: false);
      }
    } catch (e) {
      _error = 'Failed to load more history: $e';
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refreshes the current view by reloading from the first page.
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Updates the active preset range (e.g., 7/30/90 days).
  ///
  /// Also triggers a full reload so the UI reflects the new time window.
  Future<void> applyPreset(HistoryRangePreset preset) async {
    final now = _clock().toUtc();
    DateTime? start;
    DateTime? end = now;

    switch (preset) {
      case HistoryRangePreset.sevenDays:
        start = now.subtract(const Duration(days: 7));
        break;
      case HistoryRangePreset.thirtyDays:
        start = now.subtract(const Duration(days: 30));
        break;
      case HistoryRangePreset.ninetyDays:
        start = now.subtract(const Duration(days: 90));
        break;
      case HistoryRangePreset.all:
        start = null;
        end = null;
        break;
      case HistoryRangePreset.custom:
        // Custom is handled via setCustomRange, ignore here.
        return;
    }

    _filters = _filters.copyWith(
      startDate: start,
      clearStartDate: start == null,
      endDate: end,
      clearEndDate: end == null,
    );
    _activePreset =
        preset == HistoryRangePreset.all ? HistoryRangePreset.all : preset;
    await loadInitial();
  }

  /// Applies a custom date range.
  ///
  /// The provided dates are normalized to cover whole days in UTC before
  /// reloading the data set.
  Future<void> setCustomRange(DateTime start, DateTime end) async {
    final normalizedStart = DateTime.utc(start.year, start.month, start.day);
    final normalizedEnd = DateTime.utc(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
    );
    _filters = _filters.copyWith(
      startDate: normalizedStart,
      endDate: normalizedEnd,
    );
    _activePreset = HistoryRangePreset.custom;
    await loadInitial();
  }

  /// Updates the active tag filters.
  ///
  /// Tags are normalized to lowercase before being persisted to the
  /// filter set and triggering a reload.
  Future<void> updateTags(Set<String> tags) async {
    _filters = _filters.copyWith(tags: tags);
    await loadInitial();
  }

  /// Switches between averaged and raw view modes.
  ///
  /// Reloads the backing data to ensure the list contents match the new
  /// mode immediately.
  Future<void> setViewMode(HistoryViewMode mode) async {
    if (_filters.viewMode == mode) {
      return;
    }
    _filters = _filters.copyWith(viewMode: mode);
    await loadInitial();
  }

  /// Toggles expansion state for a single group, lazily loading as needed.
  ///
  /// On first expansion, raw readings are fetched and cached. Subsequent
  /// expansions reuse the cached children unless an error occurred.
  Future<void> toggleGroupExpansion(int groupId) async {
    final index = _groups.indexWhere((item) => item.group.id == groupId);
    if (index == -1) {
      return;
    }

    final item = _groups[index];
    final shouldExpand = !item.isExpanded;

    if (!shouldExpand) {
      _groups[index] = item.copyWith(isExpanded: false);
      notifyListeners();
      return;
    }

    // Optimistically expand and start loading children if necessary.
    if (item.children != null && item.children!.isNotEmpty) {
      _groups[index] = item.copyWith(isExpanded: true, clearError: true);
      notifyListeners();
      return;
    }

    _groups[index] = item.copyWith(
      isExpanded: true,
      isLoadingChildren: true,
      clearError: true,
    );
    notifyListeners();

    try {
      final readings = await _historyService.fetchGroupMembers(item.group);
      _groups[index] = item.copyWith(
        isExpanded: true,
        isLoadingChildren: false,
        readings: readings,
        replaceReadings: true,
        clearError: true,
      );
    } catch (e) {
      _groups[index] = item.copyWith(
        isExpanded: true,
        isLoadingChildren: false,
        childError: 'Failed to load readings: $e',
      );
    }

    notifyListeners();
  }

  Future<void> _loadGroups({required bool reset}) async {
    final groups = await _historyService.fetchGroupedHistory(
      profileId: _activeProfileViewModel.activeProfileId,
      start: _filters.startDate,
      end: _filters.endDate,
      before: reset ? null : _groupCursor,
      limit: _pageSize,
      tags: _filters.tags.toList(),
    );

    if (reset) {
      _groups = groups.map((group) => HistoryGroupItem(group: group)).toList();
    } else {
      _groups.addAll(groups.map((group) => HistoryGroupItem(group: group)));
    }

    _groupCursor = groups.isEmpty ? _groupCursor : groups.last.groupStartAt;
    _hasMore = groups.length == _pageSize;
    _rawReadings = <Reading>[];
  }

  Future<void> _loadRawReadings({required bool reset}) async {
    final readings = await _historyService.fetchRawHistory(
      profileId: _activeProfileViewModel.activeProfileId,
      start: _filters.startDate,
      end: _filters.endDate,
      before: reset ? null : _rawCursor,
      limit: _pageSize,
      tags: _filters.tags.toList(),
    );

    if (reset) {
      _rawReadings = readings;
    } else {
      _rawReadings.addAll(readings);
    }

    _rawCursor = readings.isEmpty ? _rawCursor : readings.last.takenAt;
    _hasMore = readings.length == _pageSize;
    _groups = <HistoryGroupItem>[];
  }
}

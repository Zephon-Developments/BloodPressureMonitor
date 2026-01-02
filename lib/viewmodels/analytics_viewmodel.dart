import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/utils/time_range.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel coordinating analytics range selection, caching, and overlay state.
class AnalyticsViewModel extends ChangeNotifier {
  AnalyticsViewModel({
    required AnalyticsService analyticsService,
    required ActiveProfileViewModel activeProfileViewModel,
    Duration cacheTtl = const Duration(minutes: 5),
    DateTime Function()? clock,
  })  : _analyticsService = analyticsService,
        _activeProfileViewModel = activeProfileViewModel,
        _cacheTtl = cacheTtl,
        _clock = clock ?? DateTime.now {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  final AnalyticsService _analyticsService;
  final ActiveProfileViewModel _activeProfileViewModel;
  final Duration _cacheTtl;
  final DateTime Function() _clock;

  final Map<TimeRange, _RangeCacheEntry> _rangeCache =
      <TimeRange, _RangeCacheEntry>{};

  TimeRange _selectedRange = TimeRange.thirtyDays;
  HealthStats? _stats;
  ChartDataSet? _chartData;
  ChartDataSet? _chartDataSmoothed;
  DualAxisBpData? _dualAxisBpData;
  DualAxisBpData? _dualAxisBpDataSmoothed;
  SleepCorrelationData? _sleepCorrelation;
  SleepStageSeries? _sleepStages;
  bool _isLoading = false;
  bool _showSleepOverlay = false;
  bool _smoothBpChart = false;
  bool _smoothPulseChart = false;
  String? _error;
  DateTime? _lastUpdated;

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  void _onProfileChanged() {
    invalidateCache();
    _analyticsService.invalidateSmoothedCache(
      _activeProfileViewModel.activeProfileId,
    );
    _stats = null;
    _chartData = null;
    _chartDataSmoothed = null;
    _dualAxisBpData = null;
    _dualAxisBpDataSmoothed = null;
    _sleepCorrelation = null;
    _sleepStages = null;
    _error = null;
    notifyListeners();
    loadData();
  }

  /// Currently selected time range.
  TimeRange get selectedRange => _selectedRange;

  /// Latest aggregate statistics.
  HealthStats? get stats => _stats;

  /// Chart dataset for the selected range.
  ChartDataSet? get chartData => _chartData;

  /// Smoothed chart dataset for the selected range.
  ChartDataSet? get chartDataSmoothed => _chartDataSmoothed;

  /// Dual-axis BP data for the selected range.
  DualAxisBpData? get dualAxisBpData => _dualAxisBpData;

  /// Smoothed dual-axis BP data for the selected range.
  DualAxisBpData? get dualAxisBpDataSmoothed => _dualAxisBpDataSmoothed;

  /// Sleep correlation metadata when overlay is enabled.
  SleepCorrelationData? get sleepCorrelation => _sleepCorrelation;

  /// Sleep stage stackable data when overlay is enabled.
  SleepStageSeries? get sleepStages => _sleepStages;

  /// Whether background work is running.
  bool get isLoading => _isLoading;

  /// Most recent user-facing error.
  String? get error => _error;

  /// Indicates if any chart points are available.
  bool get hasData => _chartData?.hasPoints ?? false;

  /// Whether the sleep overlay is visible.
  bool get showSleepOverlay => _showSleepOverlay;

  /// Whether BP chart smoothing is enabled.
  bool get smoothBpChart => _smoothBpChart;

  /// Whether pulse chart smoothing is enabled.
  bool get smoothPulseChart => _smoothPulseChart;

  /// Timestamp for the last successful refresh.
  DateTime? get lastUpdated => _lastUpdated;

  /// Updates the selected range and clears transient UI state.
  void setTimeRange(TimeRange range) {
    if (_selectedRange == range) {
      return;
    }
    _selectedRange = range;
    _error = null;
    notifyListeners();
  }

  /// Forces cached data to be cleared for all ranges.
  void invalidateCache() {
    _rangeCache.clear();
  }

  /// Toggles BP chart smoothing and reloads dual-axis data if needed.
  Future<void> toggleBpSmoothing() async {
    _smoothBpChart = !_smoothBpChart;
    notifyListeners();

    // Reload dual-axis BP data with new smoothing state
    if (_dualAxisBpData != null) {
      await _loadDualAxisBpData();
    }
  }

  /// Toggles pulse chart smoothing.
  void togglePulseSmoothing() {
    _smoothPulseChart = !_smoothPulseChart;
    notifyListeners();
  }

  /// Toggles the sleep overlay, fetching correlation data when necessary.
  Future<void> toggleSleepOverlay() async {
    _showSleepOverlay = !_showSleepOverlay;
    if (!_showSleepOverlay) {
      _sleepCorrelation = null;
      _sleepStages = null;
      notifyListeners();
      return;
    }

    notifyListeners();
    await loadData(forceOverlayRefresh: true);
  }

  /// Loads analytics for the selected range, leveraging cache where possible.
  Future<void> loadData({
    bool forceRefresh = false,
    bool forceOverlayRefresh = false,
  }) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    final range = _selectedRange;
    final DateTime anchor = _clock().toUtc();
    final (start, end) = range.toDateRange(anchor: anchor);

    try {
      final cache = _rangeCache[range];
      final now = DateTime.now().toUtc();
      final cacheFresh = !forceRefresh &&
          cache != null &&
          now.difference(cache.timestamp) < _cacheTtl;
      final overlaySatisfied = !_showSleepOverlay ||
          (cacheFresh &&
              !forceOverlayRefresh &&
              cache.sleepCorrelation != null &&
              cache.sleepStages != null);

      if (cacheFresh && overlaySatisfied) {
        _applyCache(cache);
        _isLoading = false;
        notifyListeners();
        return;
      }

      final fetches = <Future<dynamic>>[
        _analyticsService.calculateStats(
          profileId: _activeProfileViewModel.activeProfileId,
          startDate: start,
          endDate: end,
        ),
        _analyticsService.getChartData(
          profileId: _activeProfileViewModel.activeProfileId,
          startDate: start,
          endDate: end,
          range: range,
        ),
        _analyticsService.getChartDataSmoothed(
          profileId: _activeProfileViewModel.activeProfileId,
          startDate: start,
          endDate: end,
          range: range,
        ),
        _analyticsService.getDualAxisBpData(
          profileId: _activeProfileViewModel.activeProfileId,
          startDate: start,
          endDate: end,
          range: range,
          smoothed: false,
        ),
        _analyticsService.getDualAxisBpData(
          profileId: _activeProfileViewModel.activeProfileId,
          startDate: start,
          endDate: end,
          range: range,
          smoothed: true,
        ),
      ];

      if (_showSleepOverlay) {
        fetches
          ..add(
            _analyticsService.getSleepCorrelation(
              profileId: _activeProfileViewModel.activeProfileId,
              startDate: start,
              endDate: end,
            ),
          )
          ..add(
            _analyticsService.getSleepStageSeries(
              profileId: _activeProfileViewModel.activeProfileId,
              startDate: start,
              endDate: end,
            ),
          );
      }

      final results = await Future.wait(fetches);
      final stats = results[0] as HealthStats;
      final chart = results[1] as ChartDataSet;
      final chartSmoothed = results[2] as ChartDataSet;
      final dualAxisBp = results[3] as DualAxisBpData;
      final dualAxisBpSmoothed = results[4] as DualAxisBpData;
      final sleepCorrelation =
          _showSleepOverlay ? results[5] as SleepCorrelationData : null;
      final sleepStages =
          _showSleepOverlay ? results[6] as SleepStageSeries : null;

      _stats = stats;
      _chartData = chart;
      _chartDataSmoothed = chartSmoothed;
      _dualAxisBpData = dualAxisBp;
      _dualAxisBpDataSmoothed = dualAxisBpSmoothed;
      _sleepCorrelation = sleepCorrelation;
      _sleepStages = sleepStages;
      _lastUpdated = now;

      _rangeCache[range] = _RangeCacheEntry(
        timestamp: now,
        stats: stats,
        chartData: chart,
        chartDataSmoothed: chartSmoothed,
        dualAxisBpData: dualAxisBp,
        dualAxisBpDataSmoothed: dualAxisBpSmoothed,
        sleepCorrelation: sleepCorrelation,
        sleepStages: sleepStages,
      );
    } catch (error) {
      _error = 'Failed to load analytics data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyCache(_RangeCacheEntry cache) {
    _stats = cache.stats;
    _chartData = cache.chartData;
    _chartDataSmoothed = cache.chartDataSmoothed;
    _dualAxisBpData = cache.dualAxisBpData;
    _dualAxisBpDataSmoothed = cache.dualAxisBpDataSmoothed;
    _sleepCorrelation = _showSleepOverlay ? cache.sleepCorrelation : null;
    _sleepStages = _showSleepOverlay ? cache.sleepStages : null;
    _lastUpdated = cache.timestamp;
  }

  Future<void> _loadDualAxisBpData() async {
    final range = _selectedRange;
    final DateTime anchor = _clock().toUtc();
    final (start, end) = range.toDateRange(anchor: anchor);

    try {
      _dualAxisBpData = await _analyticsService.getDualAxisBpData(
        profileId: _activeProfileViewModel.activeProfileId,
        startDate: start,
        endDate: end,
        range: range,
        smoothed: false,
      );
      _dualAxisBpDataSmoothed = await _analyticsService.getDualAxisBpData(
        profileId: _activeProfileViewModel.activeProfileId,
        startDate: start,
        endDate: end,
        range: range,
        smoothed: true,
      );
      notifyListeners();
    } catch (error) {
      _error = 'Failed to load dual-axis BP data';
      notifyListeners();
    }
  }
}

class _RangeCacheEntry {
  const _RangeCacheEntry({
    required this.timestamp,
    required this.stats,
    required this.chartData,
    required this.chartDataSmoothed,
    required this.dualAxisBpData,
    required this.dualAxisBpDataSmoothed,
    this.sleepCorrelation,
    this.sleepStages,
  });

  final DateTime timestamp;
  final HealthStats stats;
  final ChartDataSet chartData;
  final ChartDataSet chartDataSmoothed;
  final DualAxisBpData dualAxisBpData;
  final DualAxisBpData dualAxisBpDataSmoothed;
  final SleepCorrelationData? sleepCorrelation;
  final SleepStageSeries? sleepStages;
}

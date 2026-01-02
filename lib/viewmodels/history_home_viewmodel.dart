import 'package:flutter/foundation.dart';

import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/services/stats_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for the unified History Home page.
///
/// Manages state for mini-statistics across all health metric categories
/// (Blood Pressure, Weight, Sleep, Medication). Each category has independent
/// loading and error states to allow for graceful degradation.
///
/// Automatically reloads all stats when the active profile changes.
class HistoryHomeViewModel extends ChangeNotifier {
  /// Creates a HistoryHomeViewModel.
  ///
  /// Parameters:
  /// - [statsService]: Service for calculating mini-statistics
  /// - [activeProfileViewModel]: ViewModel managing the active profile
  HistoryHomeViewModel(
    this._statsService,
    this._activeProfileViewModel,
  ) {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  final StatsService _statsService;
  final ActiveProfileViewModel _activeProfileViewModel;

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  ///
  /// Clears all stats immediately to prevent ghosting, then reloads.
  void _onProfileChanged() {
    _bloodPressureStats = null;
    _weightStats = null;
    _sleepStats = null;
    _medicationStats = null;
    _errorBP = null;
    _errorWeight = null;
    _errorSleep = null;
    _errorMedication = null;
    notifyListeners();
    loadAllStats();
  }

  // Stats
  MiniStats? _bloodPressureStats;
  MiniStats? _weightStats;
  MiniStats? _sleepStats;
  MiniStats? _medicationStats;

  // Loading states
  bool _isLoadingBP = false;
  bool _isLoadingWeight = false;
  bool _isLoadingSleep = false;
  bool _isLoadingMedication = false;

  // Error states
  String? _errorBP;
  String? _errorWeight;
  String? _errorSleep;
  String? _errorMedication;

  /// Blood pressure mini-statistics.
  MiniStats? get bloodPressureStats => _bloodPressureStats;

  /// Weight mini-statistics.
  MiniStats? get weightStats => _weightStats;

  /// Sleep mini-statistics.
  MiniStats? get sleepStats => _sleepStats;

  /// Medication adherence mini-statistics.
  MiniStats? get medicationStats => _medicationStats;

  /// Whether blood pressure stats are currently loading.
  bool get isLoadingBP => _isLoadingBP;

  /// Whether weight stats are currently loading.
  bool get isLoadingWeight => _isLoadingWeight;

  /// Whether sleep stats are currently loading.
  bool get isLoadingSleep => _isLoadingSleep;

  /// Whether medication stats are currently loading.
  bool get isLoadingMedication => _isLoadingMedication;

  /// Whether any category is currently loading.
  bool get isLoading =>
      _isLoadingBP ||
      _isLoadingWeight ||
      _isLoadingSleep ||
      _isLoadingMedication;

  /// Error message for blood pressure stats, if any.
  String? get errorBP => _errorBP;

  /// Error message for weight stats, if any.
  String? get errorWeight => _errorWeight;

  /// Error message for sleep stats, if any.
  String? get errorSleep => _errorSleep;

  /// Error message for medication stats, if any.
  String? get errorMedication => _errorMedication;

  /// Loads mini-statistics for all health categories.
  ///
  /// This method loads stats in parallel for better performance.
  /// Individual errors are captured per-category and don't prevent
  /// other categories from loading successfully.
  Future<void> loadAllStats() async {
    await Future.wait([
      loadBPStats(),
      loadWeightStats(),
      loadSleepStats(),
      loadMedicationStats(),
    ]);
  }

  /// Loads blood pressure mini-statistics.
  Future<void> loadBPStats() async {
    final profileId = _activeProfileViewModel.activeProfileId;

    _isLoadingBP = true;
    _errorBP = null;
    notifyListeners();

    try {
      _bloodPressureStats = await _statsService.getBloodPressureStats(
        profileId: profileId,
      );
      _errorBP = null;
    } catch (e) {
      _errorBP = 'Failed to load blood pressure stats';
      debugPrint('Error loading BP stats: $e');
    } finally {
      _isLoadingBP = false;
      notifyListeners();
    }
  }

  /// Loads weight mini-statistics.
  Future<void> loadWeightStats() async {
    final profileId = _activeProfileViewModel.activeProfileId;

    _isLoadingWeight = true;
    _errorWeight = null;
    notifyListeners();

    try {
      _weightStats = await _statsService.getWeightStats(profileId: profileId);
      _errorWeight = null;
    } catch (e) {
      _errorWeight = 'Failed to load weight stats';
      debugPrint('Error loading weight stats: $e');
    } finally {
      _isLoadingWeight = false;
      notifyListeners();
    }
  }

  /// Loads sleep mini-statistics.
  Future<void> loadSleepStats() async {
    final profileId = _activeProfileViewModel.activeProfileId;

    _isLoadingSleep = true;
    _errorSleep = null;
    notifyListeners();

    try {
      _sleepStats = await _statsService.getSleepStats(profileId: profileId);
      _errorSleep = null;
    } catch (e) {
      _errorSleep = 'Failed to load sleep stats';
      debugPrint('Error loading sleep stats: $e');
    } finally {
      _isLoadingSleep = false;
      notifyListeners();
    }
  }

  /// Loads medication adherence mini-statistics.
  Future<void> loadMedicationStats() async {
    final profileId = _activeProfileViewModel.activeProfileId;

    _isLoadingMedication = true;
    _errorMedication = null;
    notifyListeners();

    try {
      _medicationStats = await _statsService.getMedicationStats(
        profileId: profileId,
      );
      _errorMedication = null;
    } catch (e) {
      _errorMedication = 'Failed to load medication stats';
      debugPrint('Error loading medication stats: $e');
    } finally {
      _isLoadingMedication = false;
      notifyListeners();
    }
  }

  /// Refreshes all mini-statistics.
  ///
  /// Clears existing stats and reloads from the service.
  /// Useful for pull-to-refresh functionality.
  Future<void> refresh() async {
    _bloodPressureStats = null;
    _weightStats = null;
    _sleepStats = null;
    _medicationStats = null;
    notifyListeners();
    await loadAllStats();
  }
}

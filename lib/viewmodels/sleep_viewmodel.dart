import 'package:flutter/foundation.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for manual sleep tracking workflows.
///
/// Provides CRUD helpers with loading/submission state, allowing UI widgets
/// to bind to reactive sleep data.
///
/// Automatically reloads data when the active profile changes.
class SleepViewModel extends ChangeNotifier {
  /// Creates a [SleepViewModel].
  SleepViewModel(
    this._sleepService,
    this._activeProfileViewModel,
  ) {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  final SleepService _sleepService;
  final ActiveProfileViewModel _activeProfileViewModel;

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  void _onProfileChanged() {
    _entries = [];
    _error = null;
    notifyListeners();
    loadEntries();
  }

  List<SleepEntry> _entries = <SleepEntry>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Current sleep sessions sorted by most recent end time.
  List<SleepEntry> get entries => List<SleepEntry>.unmodifiable(_entries);

  /// Whether entries are being loaded.
  bool get isLoading => _isLoading;

  /// Whether a mutation is running.
  bool get isSubmitting => _isSubmitting;

  /// Latest error suitable for user display.
  String? get error => _error;

  /// Loads sleep entries for the configured profile.
  Future<void> loadEntries({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _sleepService.listSleepEntries(
        profileId: _activeProfileViewModel.activeProfileId,
        from: from,
        to: to,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load sleep entries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a sleep entry and refreshes the list.
  ///
  /// Returns `null` on success or an error message on failure.
  Future<String?> saveSleepEntry({
    int? id,
    required DateTime start,
    required DateTime end,
    int? quality,
    int? deepMinutes,
    int? lightMinutes,
    int? remMinutes,
    int? awakeMinutes,
    String? notes,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final entry = SleepEntry(
        id: id,
        profileId: _activeProfileViewModel.activeProfileId,
        startedAt: start,
        endedAt: end,
        quality: quality,
        deepMinutes: deepMinutes,
        lightMinutes: lightMinutes,
        remMinutes: remMinutes,
        awakeMinutes: awakeMinutes,
        notes: _normalize(notes),
      );

      if (id == null) {
        await _sleepService.createSleepEntry(entry);
      } else {
        await _sleepService.updateSleepEntry(entry);
      }

      await loadEntries();
      return null;
    } on ArgumentError catch (e) {
      _error = e.message?.toString() ?? 'Invalid sleep entry';
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Failed to save sleep entry: $e';
      notifyListeners();
      return _error;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Deletes a sleep entry.
  Future<String?> deleteSleepEntry(int id) async {
    try {
      final deleted = await _sleepService.deleteSleepEntry(id);
      if (!deleted) {
        _error = 'Sleep entry not found';
        notifyListeners();
        return _error;
      }
      await loadEntries();
      return null;
    } catch (e) {
      _error = 'Failed to delete sleep entry: $e';
      notifyListeners();
      return _error;
    }
  }

  /// Clears the current error after it has been displayed.
  void clearError() {
    if (_error == null) {
      return;
    }
    _error = null;
    notifyListeners();
  }

  String? _normalize(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

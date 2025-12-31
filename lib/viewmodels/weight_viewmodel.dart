import 'package:flutter/foundation.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel that coordinates weight tracking workflows.
///
/// Exposes a list of weight entries, loading/submission state, and provides
/// helpers for CRUD operations with appropriate user-facing error handling.
///
/// Automatically reloads data when the active profile changes.
class WeightViewModel extends ChangeNotifier {
  /// Creates a [WeightViewModel].
  WeightViewModel(
    this._weightService,
    this._activeProfileViewModel,
  ) {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  final WeightService _weightService;
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

  List<WeightEntry> _entries = <WeightEntry>[];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _error;

  /// Current weight entries sorted by recorded time (newest first).
  List<WeightEntry> get entries => List<WeightEntry>.unmodifiable(_entries);

  /// Whether entries are currently being loaded.
  bool get isLoading => _isLoading;

  /// Whether a save/delete mutation is in progress.
  bool get isSubmitting => _isSubmitting;

  /// Latest user-facing error message, if any.
  String? get error => _error;

  /// Loads weight entries for the configured profile.
  Future<void> loadEntries({DateTime? from, DateTime? to}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _entries = await _weightService.listWeightEntries(
        profileId: _activeProfileViewModel.activeProfileId,
        from: from,
        to: to,
      );
      _error = null;
    } catch (e) {
      _error = 'Failed to load weight entries: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Persists a weight entry (create or update) and refreshes the list.
  ///
  /// Returns `null` on success or a localized error message on failure.
  Future<String?> saveWeightEntry({
    int? id,
    required double weightValue,
    required WeightUnit unit,
    required DateTime recordedAt,
    String? notes,
    String? saltIntake,
    String? exerciseLevel,
    String? stressLevel,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    try {
      final entry = WeightEntry(
        id: id,
        profileId: _activeProfileViewModel.activeProfileId,
        takenAt: recordedAt,
        weightValue: weightValue,
        unit: unit,
        notes: _normalize(notes),
        saltIntake: _normalize(saltIntake),
        exerciseLevel: _normalize(exerciseLevel),
        stressLevel: _normalize(stressLevel),
      );

      if (id == null) {
        await _weightService.createWeightEntry(entry);
      } else {
        await _weightService.updateWeightEntry(entry);
      }

      await loadEntries();
      return null;
    } on ArgumentError catch (e) {
      _error = e.message?.toString() ?? 'Invalid weight entry';
      notifyListeners();
      return _error;
    } catch (e) {
      _error = 'Failed to save weight entry: $e';
      notifyListeners();
      return _error;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }

  /// Deletes a weight entry by id, reloading on success.
  Future<String?> deleteWeightEntry(int id) async {
    try {
      final deleted = await _weightService.deleteWeightEntry(id);
      if (!deleted) {
        _error = 'Weight entry not found';
        notifyListeners();
        return _error;
      }

      await loadEntries();
      return null;
    } catch (e) {
      _error = 'Failed to delete weight entry: $e';
      notifyListeners();
      return _error;
    }
  }

  /// Clears the current error (useful after showing a snackbar/dialog).
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

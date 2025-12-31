import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for managing blood pressure readings with validation and averaging.
///
/// This ViewModel handles CRUD operations for blood pressure readings,
/// enforces medical validation rules, and automatically triggers averaging
/// group recomputation after data changes.
///
/// Automatically reloads data when the active profile changes.
class BloodPressureViewModel extends ChangeNotifier {
  final ReadingService _readingService;
  final AveragingService _averagingService;
  final ActiveProfileViewModel _activeProfileViewModel;
  List<Reading> _readings = [];
  bool _isLoading = false;
  String? _error;
  ValidationResult? _lastValidation;

  /// Creates a BloodPressureViewModel.
  ///
  /// Parameters:
  /// - [readingService]: Service for reading CRUD operations
  /// - [averagingService]: Service for computing reading group averages
  /// - [activeProfileViewModel]: ViewModel managing the active profile
  BloodPressureViewModel(
    this._readingService,
    this._averagingService,
    this._activeProfileViewModel,
  ) {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  ///
  /// Clears current data immediately to prevent ghosting, then reloads.
  void _onProfileChanged() {
    _readings = [];
    _error = null;
    notifyListeners();
    loadReadings();
  }

  List<Reading> get readings => _readings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// The most recent validation result from an add/update operation.
  ///
  /// The UI can check this to determine if a confirmation dialog should be shown.
  ValidationResult? get lastValidation => _lastValidation;

  /// Loads all readings for the current profile.
  ///
  /// Parameters:
  /// - [clearError]: Whether to clear existing error messages (defaults to true).
  ///   Set to false to preserve averaging-related errors.
  Future<void> loadReadings({bool clearError = true}) async {
    _isLoading = true;
    if (clearError) {
      _error = null;
    }
    notifyListeners();

    try {
      _readings = await _readingService.getReadingsByProfile(
        _activeProfileViewModel.activeProfileId,
      );
    } catch (e) {
      _error = 'Failed to load readings: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds a new reading with validation.
  ///
  /// Validates the reading before persistence. Returns a [ValidationResult]:
  /// - [ValidationLevel.error]: Hard block, reading not saved
  /// - [ValidationLevel.warning]: Soft block, requires [confirmOverride] = true
  /// - [ValidationLevel.valid]: Proceeds normally
  ///
  /// After successful persistence, automatically triggers averaging recomputation.
  ///
  /// Parameters:
  /// - [reading]: The reading to add
  /// - [confirmOverride]: Set to true to override warning-level validations
  ///
  /// Returns the validation result for UI handling.
  Future<ValidationResult> addReading(
    Reading reading, {
    bool confirmOverride = false,
  }) async {
    final validation = validateReading(reading);
    _lastValidation = validation;

    // Hard block on error
    if (validation.level == ValidationLevel.error) {
      _error = validation.message;
      notifyListeners();
      return validation;
    }

    // Soft block on warning without override
    if (validation.level == ValidationLevel.warning && !confirmOverride) {
      _error = validation.message;
      notifyListeners();
      return validation;
    }

    try {
      final id = await _readingService.createReading(reading);
      final persistedReading = await _readingService.getReading(id);

      // Trigger averaging recomputation (best-effort)
      if (persistedReading != null) {
        try {
          await _averagingService.createOrUpdateGroupsForReading(
            persistedReading,
          );
          await loadReadings();
        } catch (e) {
          // Log averaging failure but don't rollback the reading
          _error = 'Reading saved, but averaging failed: $e';
          await loadReadings(clearError: false);
        }
      } else {
        await loadReadings();
      }
      return validation;
    } catch (e) {
      _error = 'Failed to add reading: $e';
      notifyListeners();
      return ValidationResult.error(_error!);
    }
  }

  /// Updates an existing reading with validation.
  ///
  /// Validates the reading before persistence. After successful update,
  /// triggers averaging recomputation for affected groups.
  ///
  /// Parameters:
  /// - [reading]: The reading to update (must have an ID)
  /// - [confirmOverride]: Set to true to override warning-level validations
  ///
  /// Returns the validation result for UI handling.
  Future<ValidationResult> updateReading(
    Reading reading, {
    bool confirmOverride = false,
  }) async {
    if (reading.id == null) {
      _error = 'Cannot update reading without an ID';
      notifyListeners();
      return ValidationResult.error(_error!);
    }

    final validation = validateReading(reading);
    _lastValidation = validation;

    // Hard block on error
    if (validation.level == ValidationLevel.error) {
      _error = validation.message;
      notifyListeners();
      return validation;
    }

    // Soft block on warning without override
    if (validation.level == ValidationLevel.warning && !confirmOverride) {
      _error = validation.message;
      notifyListeners();
      return validation;
    }

    try {
      await _readingService.updateReading(reading);

      // Trigger averaging recomputation (best-effort)
      try {
        await _averagingService.createOrUpdateGroupsForReading(reading);
        await loadReadings();
      } catch (e) {
        _error = 'Reading updated, but averaging failed: $e';
        await loadReadings(clearError: false);
      }

      return validation;
    } catch (e) {
      _error = 'Failed to update reading: $e';
      notifyListeners();
      return ValidationResult.error(_error!);
    }
  }

  /// Deletes a reading and cleans up related averaging groups.
  ///
  /// Parameters:
  /// - [id]: The ID of the reading to delete
  Future<void> deleteReading(int id) async {
    try {
      await _readingService.deleteReading(id);

      // Clean up averaging groups (best-effort)
      try {
        await _averagingService.deleteGroupsForReading(id);
        await loadReadings();
      } catch (e) {
        _error = 'Reading deleted, but group cleanup failed: $e';
        await loadReadings(clearError: false);
      }
    } catch (e) {
      _error = 'Failed to delete reading: $e';
      notifyListeners();
    }
  }
}

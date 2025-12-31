import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for managing medication intake logging and history.
///
/// Provides state management for intake logging (single and group),
/// history browsing with filters, and intake status calculation.
class MedicationIntakeViewModel extends ChangeNotifier {
  final MedicationIntakeService _intakeService;
  final MedicationService _medicationService;
  final ActiveProfileViewModel _activeProfileViewModel;

  List<MedicationIntake> _intakes = [];
  Map<int, Medication> _medicationCache = {};
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int? _filterMedicationId;
  int? _filterGroupId;

  MedicationIntakeViewModel({
    required MedicationIntakeService intakeService,
    required MedicationService medicationService,
    required ActiveProfileViewModel activeProfileViewModel,
  })  : _intakeService = intakeService,
        _medicationService = medicationService,
        _activeProfileViewModel = activeProfileViewModel {
    _activeProfileViewModel.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _activeProfileViewModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  /// Callback invoked when the active profile changes.
  void _onProfileChanged() {
    _intakes = [];
    _medicationCache = {};
    _errorMessage = null;
    notifyListeners();
    loadIntakes();
  }

  /// List of medication intakes filtered by current criteria.
  List<MedicationIntake> get intakes => _intakes;

  /// Map of medication IDs to medication objects for lookup.
  Map<int, Medication> get medicationCache => _medicationCache;

  /// Whether intakes are currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if the last operation failed.
  String? get errorMessage => _errorMessage;

  /// Start date/time filter for intake history.
  DateTime? get filterFrom => _filterFrom;

  /// End date/time filter for intake history.
  DateTime? get filterTo => _filterTo;

  /// Medication ID filter for intake history.
  int? get filterMedicationId => _filterMedicationId;

  /// Group ID filter for intake history.
  int? get filterGroupId => _filterGroupId;

  /// Loads intakes for the active profile with current filters applied.
  Future<void> loadIntakes() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileId = _activeProfileViewModel.activeProfileId;

      // Load medications first to populate cache
      final medications = await _medicationService.listMedicationsByProfile(
        profileId,
        includeInactive: true,
      );
      _medicationCache = {for (var m in medications) m.id!: m};

      _intakes = await _intakeService.listIntakes(
        profileId: profileId,
        from: _filterFrom,
        to: _filterTo,
        medicationId: _filterMedicationId,
        groupId: _filterGroupId,
      );
    } catch (e) {
      _errorMessage = 'Failed to load intake history: $e';
      debugPrint('Error loading intakes: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the date range filter and reloads intakes.
  Future<void> setDateRange(DateTime? from, DateTime? to) async {
    _filterFrom = from;
    _filterTo = to;
    await loadIntakes();
  }

  /// Sets the medication filter and reloads intakes.
  Future<void> setMedicationFilter(int? medicationId) async {
    _filterMedicationId = medicationId;
    await loadIntakes();
  }

  /// Sets the group filter and reloads intakes.
  Future<void> setGroupFilter(int? groupId) async {
    _filterGroupId = groupId;
    await loadIntakes();
  }

  /// Logs a single medication intake and refreshes the list.
  Future<void> logIntake(MedicationIntake intake) async {
    try {
      _errorMessage = null;
      await _intakeService.logIntake(intake);
      await loadIntakes();
    } catch (e) {
      _errorMessage = 'Failed to log intake: $e';
      debugPrint('Error logging intake: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Logs multiple medications as a group intake and refreshes the list.
  Future<void> logGroupIntake({
    int? groupId,
    required List<int> medicationIds,
    required DateTime takenAt,
    DateTime? scheduledFor,
    String? note,
  }) async {
    try {
      _errorMessage = null;
      final profileId = _activeProfileViewModel.activeProfileId;

      await _intakeService.logGroupIntake(
        groupId: groupId,
        medicationIds: medicationIds,
        profileId: profileId,
        takenAt: takenAt,
        scheduledFor: scheduledFor,
        note: note,
      );

      await loadIntakes();
    } catch (e) {
      _errorMessage = 'Failed to log group intake: $e';
      debugPrint('Error logging group intake: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Calculates the intake status for display.
  ///
  /// Returns the status (on-time, late, missed, unscheduled) based on the
  /// medication's schedule metadata and the intake's scheduled time.
  IntakeStatus calculateStatusSync(MedicationIntake intake) {
    final medication = _medicationCache[intake.medicationId];

    if (medication == null) {
      return IntakeStatus.unscheduled;
    }

    return _intakeService.calculateStatus(
      intake: intake,
      scheduleMetadata: medication.scheduleMetadata,
    );
  }

  /// Calculates the intake status for display.
  ///
  /// Returns the status (on-time, late, missed, unscheduled) based on the
  /// medication's schedule metadata and the intake's scheduled time.
  Future<IntakeStatus> calculateStatus(MedicationIntake intake) async {
    try {
      // Check cache first
      if (_medicationCache.containsKey(intake.medicationId)) {
        return calculateStatusSync(intake);
      }

      // Fetch the medication to get schedule metadata
      final medication = await _medicationService.getMedication(
        intake.medicationId,
      );

      if (medication == null) {
        return IntakeStatus.unscheduled;
      }

      // Update cache
      _medicationCache[medication.id!] = medication;

      return _intakeService.calculateStatus(
        intake: intake,
        scheduleMetadata: medication.scheduleMetadata,
      );
    } catch (e) {
      debugPrint('Error calculating intake status: $e');
      return IntakeStatus.unscheduled;
    }
  }

  /// Clears all filters and reloads intakes.
  Future<void> clearFilters() async {
    _filterFrom = null;
    _filterTo = null;
    _filterMedicationId = null;
    _filterGroupId = null;
    await loadIntakes();
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

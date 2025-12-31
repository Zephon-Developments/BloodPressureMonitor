import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for managing medication CRUD operations and filtering.
///
/// Provides state management for the medication list view with search,
/// active/inactive filtering, and group filtering capabilities.
class MedicationViewModel extends ChangeNotifier {
  final MedicationService _medicationService;
  final MedicationGroupService _medicationGroupService;
  final ActiveProfileViewModel _activeProfileViewModel;

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _searchTerm = '';
  bool _showInactive = false;
  int? _selectedGroupId;

  MedicationViewModel({
    required MedicationService medicationService,
    required MedicationGroupService medicationGroupService,
    required ActiveProfileViewModel activeProfileViewModel,
  })  : _medicationService = medicationService,
        _medicationGroupService = medicationGroupService,
        _activeProfileViewModel = activeProfileViewModel;

  /// List of medications filtered by search term, active status, and group.
  List<Medication> get medications => _medications;

  /// Whether medications are currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if the last operation failed.
  String? get errorMessage => _errorMessage;

  /// Current search term for filtering medications.
  String get searchTerm => _searchTerm;

  /// Whether inactive medications are shown in the list.
  bool get showInactive => _showInactive;

  /// Currently selected group ID for filtering, or null for all groups.
  int? get selectedGroupId => _selectedGroupId;

  /// Loads medications for the active profile with current filters applied.
  Future<void> loadMedications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileId = _activeProfileViewModel.activeProfileId;

      if (_searchTerm.isNotEmpty) {
        // Use search API if search term is present
        _medications = await _medicationService.searchMedicationsByName(
          profileId: profileId,
          searchTerm: _searchTerm,
        );

        // When searching, respect the showInactive filter by removing inactive
        // medications from the results if _showInactive is false.
        if (!_showInactive) {
          _medications =
              _medications.where((medication) => medication.isActive).toList();
        }
      } else {
        // Load all medications for profile
        _medications = await _medicationService.listMedicationsByProfile(
          profileId,
          includeInactive: _showInactive,
        );
      }

      // Apply group filter if selected
      if (_selectedGroupId != null) {
        final group = await _medicationGroupService.getGroup(_selectedGroupId!);
        if (group != null) {
          final memberIds = group.memberMedicationIds.toSet();
          _medications = _medications
              .where((med) => med.id != null && memberIds.contains(med.id))
              .toList();
        }
      }
    } catch (e) {
      _errorMessage = 'Failed to load medications: $e';
      debugPrint('Error loading medications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Updates the search term and reloads medications.
  Future<void> search(String term) async {
    _searchTerm = term.trim();
    await loadMedications();
  }

  /// Toggles the display of inactive medications and reloads.
  Future<void> toggleShowInactive() async {
    _showInactive = !_showInactive;
    await loadMedications();
  }

  /// Sets the selected group filter and reloads medications.
  Future<void> setGroupFilter(int? groupId) async {
    _selectedGroupId = groupId;
    await loadMedications();
  }

  /// Creates a new medication and refreshes the list.
  Future<void> createMedication(Medication medication) async {
    try {
      _errorMessage = null;
      await _medicationService.createMedication(medication);
      await loadMedications();
    } catch (e) {
      _errorMessage = 'Failed to create medication: $e';
      debugPrint('Error creating medication: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing medication and refreshes the list.
  Future<void> updateMedication(Medication medication) async {
    try {
      _errorMessage = null;
      await _medicationService.updateMedication(medication);
      await loadMedications();
    } catch (e) {
      _errorMessage = 'Failed to update medication: $e';
      debugPrint('Error updating medication: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Soft-deletes a medication and refreshes the list.
  Future<void> deleteMedication(int id) async {
    try {
      _errorMessage = null;
      final success = await _medicationService.deleteMedication(id);
      if (!success) {
        throw Exception('Medication not found');
      }
      await loadMedications();
    } catch (e) {
      _errorMessage = 'Failed to delete medication: $e';
      debugPrint('Error deleting medication: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Clears any error message.
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}

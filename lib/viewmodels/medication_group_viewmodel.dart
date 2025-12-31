import 'package:flutter/foundation.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// ViewModel for managing medication group operations.
///
/// Provides state management for medication groups with CRUD operations.
class MedicationGroupViewModel extends ChangeNotifier {
  final MedicationGroupService _groupService;
  final ActiveProfileViewModel _activeProfileViewModel;

  List<MedicationGroup> _groups = [];
  bool _isLoading = false;
  String? _errorMessage;

  MedicationGroupViewModel({
    required MedicationGroupService groupService,
    required ActiveProfileViewModel activeProfileViewModel,
  })  : _groupService = groupService,
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
    _groups = [];
    _errorMessage = null;
    notifyListeners();
    loadGroups();
  }

  /// List of medication groups for the active profile.
  List<MedicationGroup> get groups => _groups;

  /// Whether groups are currently being loaded.
  bool get isLoading => _isLoading;

  /// Error message if the last operation failed.
  String? get errorMessage => _errorMessage;

  /// Loads medication groups for the active profile.
  Future<void> loadGroups() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final profileId = _activeProfileViewModel.activeProfileId;
      _groups = await _groupService.listGroupsByProfile(profileId);
    } catch (e) {
      _errorMessage = 'Failed to load medication groups: $e';
      debugPrint('Error loading medication groups: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates a new medication group and refreshes the list.
  Future<void> createGroup(MedicationGroup group) async {
    try {
      _errorMessage = null;
      await _groupService.createGroup(group);
      await loadGroups();
    } catch (e) {
      _errorMessage = 'Failed to create medication group: $e';
      debugPrint('Error creating medication group: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Updates an existing medication group and refreshes the list.
  Future<void> updateGroup(MedicationGroup group) async {
    try {
      _errorMessage = null;
      await _groupService.updateGroup(group);
      await loadGroups();
    } catch (e) {
      _errorMessage = 'Failed to update medication group: $e';
      debugPrint('Error updating medication group: $e');
      notifyListeners();
      rethrow;
    }
  }

  /// Deletes a medication group and refreshes the list.
  Future<void> deleteGroup(int id) async {
    try {
      _errorMessage = null;
      final success = await _groupService.deleteGroup(id);
      if (!success) {
        throw Exception('Medication group not found');
      }
      await loadGroups();
    } catch (e) {
      _errorMessage = 'Failed to delete medication group: $e';
      debugPrint('Error deleting medication group: $e');
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

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';

/// ViewModel for managing the currently active profile.
///
/// Tracks the active profile ID and name, persists the selection in
/// SharedPreferences, and provides methods for switching profiles.
class ActiveProfileViewModel extends ChangeNotifier {
  final ProfileService _profileService;
  final SharedPreferences _prefs;

  static const String _activeProfileIdKey = 'active_profile_id';
  static const String _activeProfileNameKey = 'active_profile_name';

  int _activeProfileId = 1;
  String _activeProfileName = 'User';
  bool _isLoading = false;

  ActiveProfileViewModel({
    required ProfileService profileService,
    required SharedPreferences prefs,
  })  : _profileService = profileService,
        _prefs = prefs;

  int get activeProfileId => _activeProfileId;
  String get activeProfileName => _activeProfileName;
  bool get isLoading => _isLoading;

  /// Loads the active profile from SharedPreferences or initializes a default.
  ///
  /// If no profile exists in the database, creates a default "User" profile.
  /// This method should be called during app initialization.
  Future<void> loadInitial() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Try to load from SharedPreferences
      final savedId = _prefs.getInt(_activeProfileIdKey);
      final savedName = _prefs.getString(_activeProfileNameKey);

      if (savedId != null && savedName != null) {
        // Verify the profile still exists
        final profile = await _profileService.getProfile(savedId);
        if (profile != null) {
          _activeProfileId = savedId;
          _activeProfileName = savedName;
          _isLoading = false;
          notifyListeners();
          return;
        }
      }

      // No saved profile or profile no longer exists, load from database
      final profiles = await _profileService.getAllProfiles();

      if (profiles.isNotEmpty) {
        // Use the first available profile
        _activeProfileId = profiles.first.id!;
        _activeProfileName = profiles.first.name;
        await _persistActiveProfile();
      } else {
        // No profiles exist, create a default one
        final defaultProfile = Profile(
          id: null,
          name: 'User',
          createdAt: DateTime.now(),
        );
        final newId = await _profileService.createProfile(defaultProfile);
        _activeProfileId = newId;
        _activeProfileName = 'User';
        await _persistActiveProfile();
      }
    } catch (e) {
      debugPrint('Error loading active profile: $e');
      // Fall back to defaults
      _activeProfileId = 1;
      _activeProfileName = 'User';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the active profile.
  ///
  /// Updates the active profile and persists the selection to SharedPreferences.
  Future<void> setActive(Profile profile) async {
    if (profile.id == null) {
      throw ArgumentError('Profile must have a valid ID');
    }

    _activeProfileId = profile.id!;
    _activeProfileName = profile.name;
    await _persistActiveProfile();
    notifyListeners();
  }

  /// Creates a new profile and optionally sets it as active.
  Future<int> createProfile(Profile profile, {bool setAsActive = false}) async {
    final id = await _profileService.createProfile(profile);
    if (setAsActive) {
      final newProfile = profile.copyWith(id: id);
      await setActive(newProfile);
    } else {
      notifyListeners();
    }
    return id;
  }

  /// Updates an existing profile.
  ///
  /// If the updated profile is the active one, updates the local state.
  Future<void> updateProfile(Profile profile) async {
    await _profileService.updateProfile(profile);
    if (profile.id == _activeProfileId) {
      _activeProfileName = profile.name;
      await _persistActiveProfile();
    }
    notifyListeners();
  }

  /// Deletes a profile.
  ///
  /// If the deleted profile is the active one, switches to another profile
  /// or creates a default one if none remain.
  Future<void> deleteProfile(int id) async {
    await _profileService.deleteProfile(id);

    if (id == _activeProfileId) {
      // Need to find a new active profile
      final profiles = await _profileService.getAllProfiles();
      if (profiles.isNotEmpty) {
        await setActive(profiles.first);
      } else {
        // No profiles left, create a default one
        await loadInitial();
      }
    } else {
      notifyListeners();
    }
  }

  /// Persists the active profile selection to SharedPreferences.
  Future<void> _persistActiveProfile() async {
    await _prefs.setInt(_activeProfileIdKey, _activeProfileId);
    await _prefs.setString(_activeProfileNameKey, _activeProfileName);
  }
}

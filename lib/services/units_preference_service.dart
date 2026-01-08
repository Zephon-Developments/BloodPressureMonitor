import 'dart:convert';
import 'package:blood_pressure_monitor/models/units_preference.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for persisting and retrieving user unit preferences.
///
/// Uses SharedPreferences for storage with graceful fallback to defaults
/// if data is corrupted or missing.
class UnitsPreferenceService {
  static const String _prefsKey = 'units_preference';
  final SharedPreferences _prefs;

  /// Creates a [UnitsPreferenceService] with the given SharedPreferences instance.
  UnitsPreferenceService(this._prefs);

  /// Retrieves the saved units preference.
  ///
  /// Returns default preferences (kg, Celsius) if:
  /// - No saved preference exists
  /// - Saved data is corrupted or invalid
  ///
  /// Example:
  /// ```dart
  /// final service = UnitsPreferenceService(prefs);
  /// final units = await service.getUnitsPreference();
  /// print(units.weightUnit); // WeightUnit.kg (default)
  /// ```
  Future<UnitsPreference> getUnitsPreference() async {
    try {
      final jsonString = _prefs.getString(_prefsKey);
      if (jsonString == null) {
        return const UnitsPreference(); // Return defaults
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return UnitsPreference.fromJson(json);
    } catch (e) {
      // Log error but don't throw - gracefully degrade to defaults
      // In production, would use proper logging
      return const UnitsPreference();
    }
  }

  /// Saves the units preference.
  ///
  /// Persists the preference to SharedPreferences as a JSON string.
  ///
  /// Throws an exception if saving fails (e.g., storage full).
  ///
  /// Example:
  /// ```dart
  /// final service = UnitsPreferenceService(prefs);
  /// await service.saveUnitsPreference(
  ///   UnitsPreference(weightUnit: WeightUnit.lbs),
  /// );
  /// ```
  Future<void> saveUnitsPreference(UnitsPreference preference) async {
    final jsonString = jsonEncode(preference.toJson());
    final success = await _prefs.setString(_prefsKey, jsonString);

    if (!success) {
      throw Exception('Failed to save units preference');
    }
  }

  /// Clears the saved units preference.
  ///
  /// After clearing, [getUnitsPreference] will return defaults.
  ///
  /// Useful for testing or resetting to defaults.
  Future<void> clearUnitsPreference() async {
    await _prefs.remove(_prefsKey);
  }
}

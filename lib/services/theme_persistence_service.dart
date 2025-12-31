import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';

/// Service responsible for persisting and loading theme settings.
///
/// Uses SharedPreferences to store theme configuration as a JSON string.
class ThemePersistenceService {
  static const String _themeSettingsKey = 'theme_settings';

  final SharedPreferences _prefs;

  /// Creates a [ThemePersistenceService] with the provided [SharedPreferences] instance.
  ThemePersistenceService(this._prefs);

  /// Saves the given [ThemeSettings] to persistent storage.
  ///
  /// Returns `true` if the save was successful, `false` otherwise.
  Future<bool> saveThemeSettings(ThemeSettings settings) async {
    try {
      final json = jsonEncode(settings.toJson());
      return await _prefs.setString(_themeSettingsKey, json);
    } catch (e) {
      return false;
    }
  }

  /// Loads [ThemeSettings] from persistent storage.
  ///
  /// Returns `null` if no settings are saved or if loading fails.
  ThemeSettings? loadThemeSettings() {
    try {
      final jsonString = _prefs.getString(_themeSettingsKey);
      if (jsonString == null) {
        return null;
      }
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ThemeSettings.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Clears all saved theme settings.
  ///
  /// Returns `true` if the clear was successful, `false` otherwise.
  Future<bool> clearThemeSettings() async {
    try {
      return await _prefs.remove(_themeSettingsKey);
    } catch (e) {
      return false;
    }
  }
}

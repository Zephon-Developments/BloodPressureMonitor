import 'package:flutter/material.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/services/theme_persistence_service.dart';

/// ViewModel managing theme state and appearance preferences for the application.
///
/// Provides Material 3 ThemeData generation based on user preferences including
/// theme mode, accent color, font scaling, and high-contrast mode. Persists
/// settings using [ThemePersistenceService].
class ThemeViewModel extends ChangeNotifier {
  final ThemePersistenceService _persistenceService;
  ThemeSettings _settings;

  /// Creates a [ThemeViewModel] with the provided persistence service.
  ///
  /// Initializes with default settings or loads from persistence.
  ThemeViewModel(this._persistenceService) : _settings = const ThemeSettings() {
    _loadSettings();
  }

  /// The current theme settings.
  ThemeSettings get settings => _settings;

  /// The current theme mode.
  AppThemeMode get themeMode => _settings.themeMode;

  /// The current accent color.
  AccentColor get accentColor => _settings.accentColor;

  /// The current font scale option.
  FontScaleOption get fontScale => _settings.fontScale;

  /// Whether high-contrast mode is enabled.
  bool get highContrastMode => _settings.highContrastMode;

  /// Converts [AppThemeMode] to Material [ThemeMode].
  ThemeMode get materialThemeMode {
    switch (_settings.themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Generates the light theme based on current settings.
  ThemeData get lightTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: _settings.accentColor.toColor(),
      brightness: Brightness.light,
    );

    final colorScheme = _settings.highContrastMode
        ? _applyHighContrast(baseColorScheme, Brightness.light)
        : baseColorScheme;

    return _buildThemeData(colorScheme, Brightness.light);
  }

  /// Generates the dark theme based on current settings.
  ThemeData get darkTheme {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: _settings.accentColor.toColor(),
      brightness: Brightness.dark,
    );

    final colorScheme = _settings.highContrastMode
        ? _applyHighContrast(baseColorScheme, Brightness.dark)
        : baseColorScheme;

    return _buildThemeData(colorScheme, Brightness.dark);
  }

  /// Updates the theme mode and persists the change.
  Future<void> setThemeMode(AppThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _saveSettings();
    notifyListeners();
  }

  /// Updates the accent color and persists the change.
  Future<void> setAccentColor(AccentColor color) async {
    _settings = _settings.copyWith(accentColor: color);
    await _saveSettings();
    notifyListeners();
  }

  /// Updates the font scale and persists the change.
  Future<void> setFontScale(FontScaleOption scale) async {
    _settings = _settings.copyWith(fontScale: scale);
    await _saveSettings();
    notifyListeners();
  }

  /// Toggles high-contrast mode and persists the change.
  Future<void> toggleHighContrastMode() async {
    _settings =
        _settings.copyWith(highContrastMode: !_settings.highContrastMode);
    await _saveSettings();
    notifyListeners();
  }

  /// Resets all theme settings to defaults and persists the change.
  Future<void> resetToDefaults() async {
    _settings = const ThemeSettings();
    await _saveSettings();
    notifyListeners();
  }

  /// Loads settings from persistence.
  Future<void> _loadSettings() async {
    final loaded = _persistenceService.loadThemeSettings();
    if (loaded != null) {
      _settings = loaded;
      notifyListeners();
    }
  }

  /// Saves current settings to persistence.
  Future<void> _saveSettings() async {
    await _persistenceService.saveThemeSettings(_settings);
  }

  /// Builds a [ThemeData] from the given [ColorScheme] and brightness.
  ThemeData _buildThemeData(ColorScheme colorScheme, Brightness brightness) {
    final textTheme = _buildTextTheme(brightness);

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
      ),
    );
  }

  /// Builds a [TextTheme] with the current font scale applied.
  TextTheme _buildTextTheme(Brightness brightness) {
    final baseTheme = brightness == Brightness.light
        ? ThemeData.light().textTheme
        : ThemeData.dark().textTheme;

    final scaleFactor = _settings.fontScale.scaleFactor;

    return TextTheme(
      displayLarge: baseTheme.displayLarge?.copyWith(
        fontSize: (baseTheme.displayLarge?.fontSize ?? 57) * scaleFactor,
      ),
      displayMedium: baseTheme.displayMedium?.copyWith(
        fontSize: (baseTheme.displayMedium?.fontSize ?? 45) * scaleFactor,
      ),
      displaySmall: baseTheme.displaySmall?.copyWith(
        fontSize: (baseTheme.displaySmall?.fontSize ?? 36) * scaleFactor,
      ),
      headlineLarge: baseTheme.headlineLarge?.copyWith(
        fontSize: (baseTheme.headlineLarge?.fontSize ?? 32) * scaleFactor,
      ),
      headlineMedium: baseTheme.headlineMedium?.copyWith(
        fontSize: (baseTheme.headlineMedium?.fontSize ?? 28) * scaleFactor,
      ),
      headlineSmall: baseTheme.headlineSmall?.copyWith(
        fontSize: (baseTheme.headlineSmall?.fontSize ?? 24) * scaleFactor,
      ),
      titleLarge: baseTheme.titleLarge?.copyWith(
        fontSize: (baseTheme.titleLarge?.fontSize ?? 22) * scaleFactor,
      ),
      titleMedium: baseTheme.titleMedium?.copyWith(
        fontSize: (baseTheme.titleMedium?.fontSize ?? 16) * scaleFactor,
      ),
      titleSmall: baseTheme.titleSmall?.copyWith(
        fontSize: (baseTheme.titleSmall?.fontSize ?? 14) * scaleFactor,
      ),
      bodyLarge: baseTheme.bodyLarge?.copyWith(
        fontSize: (baseTheme.bodyLarge?.fontSize ?? 16) * scaleFactor,
      ),
      bodyMedium: baseTheme.bodyMedium?.copyWith(
        fontSize: (baseTheme.bodyMedium?.fontSize ?? 14) * scaleFactor,
      ),
      bodySmall: baseTheme.bodySmall?.copyWith(
        fontSize: (baseTheme.bodySmall?.fontSize ?? 12) * scaleFactor,
      ),
      labelLarge: baseTheme.labelLarge?.copyWith(
        fontSize: (baseTheme.labelLarge?.fontSize ?? 14) * scaleFactor,
      ),
      labelMedium: baseTheme.labelMedium?.copyWith(
        fontSize: (baseTheme.labelMedium?.fontSize ?? 12) * scaleFactor,
      ),
      labelSmall: baseTheme.labelSmall?.copyWith(
        fontSize: (baseTheme.labelSmall?.fontSize ?? 11) * scaleFactor,
      ),
    );
  }

  /// Applies high-contrast adjustments to the given [ColorScheme].
  ColorScheme _applyHighContrast(ColorScheme scheme, Brightness brightness) {
    if (brightness == Brightness.light) {
      return scheme.copyWith(
        primary: _darkenColor(scheme.primary, 0.2),
        onPrimary: Colors.white,
        secondary: _darkenColor(scheme.secondary, 0.2),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Colors.black,
      );
    } else {
      return scheme.copyWith(
        primary: _lightenColor(scheme.primary, 0.2),
        onPrimary: Colors.black,
        secondary: _lightenColor(scheme.secondary, 0.2),
        onSecondary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white,
      );
    }
  }

  /// Darkens the given [color] by the specified [amount] (0.0 to 1.0).
  Color _darkenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final darkened =
        hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return darkened.toColor();
  }

  /// Lightens the given [color] by the specified [amount] (0.0 to 1.0).
  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened =
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0));
    return lightened.toColor();
  }
}

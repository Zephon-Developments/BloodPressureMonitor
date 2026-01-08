import 'package:flutter/material.dart';

/// Defines the supported theme modes.
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Defines the available accent color options for the app theme.
enum AccentColor {
  teal,
  blue,
  green,
  cyan,
  indigo,
  blueGrey,
  emerald,
  turquoise,
}

/// Defines font scaling options for accessibility.
enum FontScaleOption {
  normal,
  large,
  extraLarge,
}

/// Model representing user preferences for app theme and appearance.
///
/// Immutable data class that stores all theme-related settings including
/// theme mode, accent color, font scaling, and high-contrast mode.
@immutable
class ThemeSettings {
  /// The current theme mode (light, dark, or system).
  final AppThemeMode themeMode;

  /// The selected accent color for the theme.
  final AccentColor accentColor;

  /// The font scaling option for accessibility.
  final FontScaleOption fontScale;

  /// Whether high-contrast mode is enabled for better accessibility.
  final bool highContrastMode;

  const ThemeSettings({
    this.themeMode = AppThemeMode.system,
    this.accentColor = AccentColor.teal,
    this.fontScale = FontScaleOption.normal,
    this.highContrastMode = false,
  });

  /// Creates a copy of this [ThemeSettings] with the given fields replaced.
  ThemeSettings copyWith({
    AppThemeMode? themeMode,
    AccentColor? accentColor,
    FontScaleOption? fontScale,
    bool? highContrastMode,
  }) {
    return ThemeSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColor: accentColor ?? this.accentColor,
      fontScale: fontScale ?? this.fontScale,
      highContrastMode: highContrastMode ?? this.highContrastMode,
    );
  }

  /// Converts this [ThemeSettings] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'themeMode': themeMode.name,
      'accentColor': accentColor.name,
      'fontScale': fontScale.name,
      'highContrastMode': highContrastMode,
    };
  }

  /// Creates a [ThemeSettings] from a JSON map.
  factory ThemeSettings.fromJson(Map<String, dynamic> json) {
    return ThemeSettings(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == json['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      accentColor: AccentColor.values.firstWhere(
        (e) => e.name == json['accentColor'],
        orElse: () => AccentColor.teal,
      ),
      fontScale: FontScaleOption.values.firstWhere(
        (e) => e.name == json['fontScale'],
        orElse: () => FontScaleOption.normal,
      ),
      highContrastMode: json['highContrastMode'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ThemeSettings &&
        other.themeMode == themeMode &&
        other.accentColor == accentColor &&
        other.fontScale == fontScale &&
        other.highContrastMode == highContrastMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      themeMode,
      accentColor,
      fontScale,
      highContrastMode,
    );
  }

  @override
  String toString() {
    return 'ThemeSettings(themeMode: $themeMode, accentColor: $accentColor, '
        'fontScale: $fontScale, highContrastMode: $highContrastMode)';
  }
}

/// Extension to convert [AccentColor] to Material [Color].
extension AccentColorExtension on AccentColor {
  /// Returns the Material [Color] for this accent color.
  Color toColor() {
    switch (this) {
      case AccentColor.teal:
        return Colors.teal;
      case AccentColor.blue:
        return Colors.blue;
      case AccentColor.green:
        return Colors.green;
      case AccentColor.cyan:
        return Colors.cyan;
      case AccentColor.indigo:
        return Colors.indigo;
      case AccentColor.blueGrey:
        return Colors.blueGrey;
      case AccentColor.emerald:
        return const Color(0xFF50C878);
      case AccentColor.turquoise:
        return const Color(0xFF40E0D0);
    }
  }

  /// Returns a human-readable display name for this accent color.
  String get displayName {
    switch (this) {
      case AccentColor.teal:
        return 'Teal';
      case AccentColor.blue:
        return 'Blue';
      case AccentColor.green:
        return 'Green';
      case AccentColor.cyan:
        return 'Cyan';
      case AccentColor.indigo:
        return 'Indigo';
      case AccentColor.blueGrey:
        return 'Blue Grey';
      case AccentColor.emerald:
        return 'Emerald';
      case AccentColor.turquoise:
        return 'Turquoise';
    }
  }
}

/// Extension to convert [FontScaleOption] to scale factor.
extension FontScaleOptionExtension on FontScaleOption {
  /// Returns the text scale factor for this font scale option.
  double get scaleFactor {
    switch (this) {
      case FontScaleOption.normal:
        return 1.0;
      case FontScaleOption.large:
        return 1.15;
      case FontScaleOption.extraLarge:
        return 1.3;
    }
  }

  /// Returns a human-readable display name for this font scale option.
  String get displayName {
    switch (this) {
      case FontScaleOption.normal:
        return 'Normal';
      case FontScaleOption.large:
        return 'Large';
      case FontScaleOption.extraLarge:
        return 'Extra Large';
    }
  }
}

/// Extension to convert [AppThemeMode] to display name.
extension AppThemeModeExtension on AppThemeMode {
  /// Returns a human-readable display name for this theme mode.
  String get displayName {
    switch (this) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}

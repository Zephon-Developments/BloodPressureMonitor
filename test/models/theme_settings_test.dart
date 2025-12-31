import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:flutter/material.dart';

void main() {
  group('ThemeSettings', () {
    test('creates with default values', () {
      const settings = ThemeSettings();

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.accentColor, AccentColor.teal);
      expect(settings.fontScale, FontScaleOption.normal);
      expect(settings.highContrastMode, false);
    });

    test('creates with custom values', () {
      const settings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
        fontScale: FontScaleOption.large,
        highContrastMode: true,
      );

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.accentColor, AccentColor.blue);
      expect(settings.fontScale, FontScaleOption.large);
      expect(settings.highContrastMode, true);
    });

    test('copyWith creates new instance with modified values', () {
      const original = ThemeSettings();
      final modified = original.copyWith(
        themeMode: AppThemeMode.light,
        highContrastMode: true,
      );

      expect(modified.themeMode, AppThemeMode.light);
      expect(modified.accentColor, AccentColor.teal); // unchanged
      expect(modified.fontScale, FontScaleOption.normal); // unchanged
      expect(modified.highContrastMode, true);
      expect(original.themeMode, AppThemeMode.system); // original unchanged
    });

    test('toJson serializes correctly', () {
      const settings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
        fontScale: FontScaleOption.extraLarge,
        highContrastMode: true,
      );

      final json = settings.toJson();

      expect(json['themeMode'], 'dark');
      expect(json['accentColor'], 'blue');
      expect(json['fontScale'], 'extraLarge');
      expect(json['highContrastMode'], true);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'themeMode': 'dark',
        'accentColor': 'blue',
        'fontScale': 'large',
        'highContrastMode': true,
      };

      final settings = ThemeSettings.fromJson(json);

      expect(settings.themeMode, AppThemeMode.dark);
      expect(settings.accentColor, AccentColor.blue);
      expect(settings.fontScale, FontScaleOption.large);
      expect(settings.highContrastMode, true);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{};

      final settings = ThemeSettings.fromJson(json);

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.accentColor, AccentColor.teal);
      expect(settings.fontScale, FontScaleOption.normal);
      expect(settings.highContrastMode, false);
    });

    test('fromJson handles invalid enum values with defaults', () {
      final json = {
        'themeMode': 'invalid',
        'accentColor': 'invalid',
        'fontScale': 'invalid',
        'highContrastMode': false,
      };

      final settings = ThemeSettings.fromJson(json);

      expect(settings.themeMode, AppThemeMode.system);
      expect(settings.accentColor, AccentColor.teal);
      expect(settings.fontScale, FontScaleOption.normal);
    });

    test('equality works correctly', () {
      const settings1 = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
      );
      const settings2 = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
      );
      const settings3 = ThemeSettings(
        themeMode: AppThemeMode.light,
        accentColor: AccentColor.blue,
      );

      expect(settings1, settings2);
      expect(settings1, isNot(settings3));
    });

    test('hashCode works correctly', () {
      const settings1 = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
      );
      const settings2 = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
      );

      expect(settings1.hashCode, settings2.hashCode);
    });

    test('toString returns formatted string', () {
      const settings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
        fontScale: FontScaleOption.large,
        highContrastMode: true,
      );

      final str = settings.toString();

      expect(str, contains('ThemeSettings'));
      expect(str, contains('dark'));
      expect(str, contains('blue'));
      expect(str, contains('large'));
      expect(str, contains('true'));
    });
  });

  group('AccentColorExtension', () {
    test('toColor returns correct Material colors', () {
      expect(AccentColor.teal.toColor(), Colors.teal);
      expect(AccentColor.blue.toColor(), Colors.blue);
      expect(AccentColor.green.toColor(), Colors.green);
      expect(AccentColor.cyan.toColor(), Colors.cyan);
      expect(AccentColor.indigo.toColor(), Colors.indigo);
      expect(AccentColor.blueGrey.toColor(), Colors.blueGrey);
    });

    test('toColor returns custom colors for emerald and turquoise', () {
      expect(AccentColor.emerald.toColor(), const Color(0xFF50C878));
      expect(AccentColor.turquoise.toColor(), const Color(0xFF40E0D0));
    });

    test('displayName returns correct names', () {
      expect(AccentColor.teal.displayName, 'Teal');
      expect(AccentColor.blue.displayName, 'Blue');
      expect(AccentColor.green.displayName, 'Green');
      expect(AccentColor.cyan.displayName, 'Cyan');
      expect(AccentColor.indigo.displayName, 'Indigo');
      expect(AccentColor.blueGrey.displayName, 'Blue Grey');
      expect(AccentColor.emerald.displayName, 'Emerald');
      expect(AccentColor.turquoise.displayName, 'Turquoise');
    });
  });

  group('FontScaleOptionExtension', () {
    test('scaleFactor returns correct values', () {
      expect(FontScaleOption.normal.scaleFactor, 1.0);
      expect(FontScaleOption.large.scaleFactor, 1.15);
      expect(FontScaleOption.extraLarge.scaleFactor, 1.3);
    });

    test('displayName returns correct names', () {
      expect(FontScaleOption.normal.displayName, 'Normal');
      expect(FontScaleOption.large.displayName, 'Large');
      expect(FontScaleOption.extraLarge.displayName, 'Extra Large');
    });
  });

  group('AppThemeModeExtension', () {
    test('displayName returns correct names', () {
      expect(AppThemeMode.light.displayName, 'Light');
      expect(AppThemeMode.dark.displayName, 'Dark');
      expect(AppThemeMode.system.displayName, 'System');
    });
  });
}

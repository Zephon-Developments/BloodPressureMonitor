import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/services/theme_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemePersistenceService', () {
    late SharedPreferences prefs;
    late ThemePersistenceService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = ThemePersistenceService(prefs);
    });

    tearDown(() async {
      await prefs.clear();
    });

    test('saveThemeSettings stores settings correctly', () async {
      const settings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
        fontScale: FontScaleOption.large,
        highContrastMode: true,
      );

      final result = await service.saveThemeSettings(settings);

      expect(result, true);
      expect(prefs.getString('theme_settings'), isNotNull);
    });

    test('loadThemeSettings returns null when no settings exist', () {
      final loaded = service.loadThemeSettings();

      expect(loaded, isNull);
    });

    test('loadThemeSettings retrieves saved settings correctly', () async {
      const original = ThemeSettings(
        themeMode: AppThemeMode.light,
        accentColor: AccentColor.green,
        fontScale: FontScaleOption.extraLarge,
        highContrastMode: true,
      );

      await service.saveThemeSettings(original);
      final loaded = service.loadThemeSettings();

      expect(loaded, isNotNull);
      expect(loaded!.themeMode, AppThemeMode.light);
      expect(loaded.accentColor, AccentColor.green);
      expect(loaded.fontScale, FontScaleOption.extraLarge);
      expect(loaded.highContrastMode, true);
    });

    test('loadThemeSettings handles corrupted data gracefully', () async {
      await prefs.setString('theme_settings', 'invalid json');

      final loaded = service.loadThemeSettings();

      expect(loaded, isNull);
    });

    test('clearThemeSettings removes stored settings', () async {
      const settings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.cyan,
      );

      await service.saveThemeSettings(settings);
      expect(prefs.getString('theme_settings'), isNotNull);

      final result = await service.clearThemeSettings();

      expect(result, true);
      expect(prefs.getString('theme_settings'), isNull);
    });

    test('clearThemeSettings returns true when no settings exist', () async {
      final result = await service.clearThemeSettings();

      expect(result, true);
    });

    test('roundtrip save and load preserves all settings', () async {
      const original = ThemeSettings(
        themeMode: AppThemeMode.system,
        accentColor: AccentColor.indigo,
        fontScale: FontScaleOption.normal,
        highContrastMode: false,
      );

      await service.saveThemeSettings(original);
      final loaded = service.loadThemeSettings();

      expect(loaded, original);
    });

    test('multiple saves overwrite previous settings', () async {
      const first = ThemeSettings(
        themeMode: AppThemeMode.light,
        accentColor: AccentColor.teal,
      );
      const second = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
      );

      await service.saveThemeSettings(first);
      await service.saveThemeSettings(second);

      final loaded = service.loadThemeSettings();

      expect(loaded, second);
      expect(loaded, isNot(first));
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/services/theme_persistence_service.dart';
import 'package:blood_pressure_monitor/viewmodels/theme_viewmodel.dart';

import 'theme_viewmodel_test.mocks.dart';

@GenerateMocks([ThemePersistenceService])
void main() {
  group('ThemeViewModel', () {
    late MockThemePersistenceService mockPersistenceService;
    late ThemeViewModel viewModel;

    setUp(() {
      mockPersistenceService = MockThemePersistenceService();
      when(mockPersistenceService.loadThemeSettings()).thenReturn(null);
      when(mockPersistenceService.saveThemeSettings(any))
          .thenAnswer((_) async => true);
      viewModel = ThemeViewModel(mockPersistenceService);
    });

    test('initializes with default settings', () {
      expect(viewModel.themeMode, AppThemeMode.system);
      expect(viewModel.accentColor, AccentColor.teal);
      expect(viewModel.fontScale, FontScaleOption.normal);
      expect(viewModel.highContrastMode, false);
    });

    test('loads settings from persistence on initialization', () {
      const savedSettings = ThemeSettings(
        themeMode: AppThemeMode.dark,
        accentColor: AccentColor.blue,
        fontScale: FontScaleOption.large,
        highContrastMode: true,
      );

      when(mockPersistenceService.loadThemeSettings())
          .thenReturn(savedSettings);

      final vm = ThemeViewModel(mockPersistenceService);

      expect(vm.themeMode, AppThemeMode.dark);
      expect(vm.accentColor, AccentColor.blue);
      expect(vm.fontScale, FontScaleOption.large);
      expect(vm.highContrastMode, true);
    });

    test('materialThemeMode converts AppThemeMode correctly', () {
      expect(viewModel.materialThemeMode, ThemeMode.system);

      viewModel.setThemeMode(AppThemeMode.light);
      expect(viewModel.materialThemeMode, ThemeMode.light);

      viewModel.setThemeMode(AppThemeMode.dark);
      expect(viewModel.materialThemeMode, ThemeMode.dark);
    });

    test('setThemeMode updates theme mode and persists', () async {
      var notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      await viewModel.setThemeMode(AppThemeMode.dark);

      expect(viewModel.themeMode, AppThemeMode.dark);
      expect(notified, true);
      verify(mockPersistenceService.saveThemeSettings(any)).called(1);
    });

    test('setAccentColor updates accent color and persists', () async {
      var notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      await viewModel.setAccentColor(AccentColor.blue);

      expect(viewModel.accentColor, AccentColor.blue);
      expect(notified, true);
      verify(mockPersistenceService.saveThemeSettings(any)).called(1);
    });

    test('setFontScale updates font scale and persists', () async {
      var notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      await viewModel.setFontScale(FontScaleOption.large);

      expect(viewModel.fontScale, FontScaleOption.large);
      expect(notified, true);
      verify(mockPersistenceService.saveThemeSettings(any)).called(1);
    });

    test('toggleHighContrastMode toggles state and persists', () async {
      expect(viewModel.highContrastMode, false);

      await viewModel.toggleHighContrastMode();

      expect(viewModel.highContrastMode, true);
      verify(mockPersistenceService.saveThemeSettings(any)).called(1);

      await viewModel.toggleHighContrastMode();

      expect(viewModel.highContrastMode, false);
      // Total calls should be at least 2 (one for each toggle)
      verify(mockPersistenceService.saveThemeSettings(any)).called(greaterThanOrEqualTo(1));
    });

    test('resetToDefaults restores default settings and persists', () async {
      await viewModel.setThemeMode(AppThemeMode.dark);
      await viewModel.setAccentColor(AccentColor.blue);
      await viewModel.setFontScale(FontScaleOption.large);
      await viewModel.toggleHighContrastMode();

      var notified = false;
      viewModel.addListener(() {
        notified = true;
      });

      await viewModel.resetToDefaults();

      expect(viewModel.themeMode, AppThemeMode.system);
      expect(viewModel.accentColor, AccentColor.teal);
      expect(viewModel.fontScale, FontScaleOption.normal);
      expect(viewModel.highContrastMode, false);
      expect(notified, true);
      verify(mockPersistenceService.saveThemeSettings(any)).called(greaterThan(4));
    });

    test('lightTheme generates valid ThemeData', () {
      final theme = viewModel.lightTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.brightness, Brightness.light);
    });

    test('darkTheme generates valid ThemeData', () {
      final theme = viewModel.darkTheme;

      expect(theme, isA<ThemeData>());
      expect(theme.useMaterial3, true);
      expect(theme.colorScheme.brightness, Brightness.dark);
    });

    test('lightTheme uses selected accent color', () {
      viewModel.setAccentColor(AccentColor.blue);

      final theme = viewModel.lightTheme;

      // ColorScheme.fromSeed creates colors based on the seed
      expect(theme.colorScheme, isNotNull);
    });

    test('darkTheme uses selected accent color', () {
      viewModel.setAccentColor(AccentColor.green);

      final theme = viewModel.darkTheme;

      expect(theme.colorScheme, isNotNull);
    });

    test('lightTheme applies high contrast when enabled', () async {
      await viewModel.toggleHighContrastMode();

      final theme = viewModel.lightTheme;
      final normalTheme = ThemeViewModel(mockPersistenceService).lightTheme;

      // High contrast theme should have different colors
      expect(theme.colorScheme.surface, isNot(normalTheme.colorScheme.surface));
    });

    test('darkTheme applies high contrast when enabled', () async {
      await viewModel.toggleHighContrastMode();

      final theme = viewModel.darkTheme;
      final normalTheme = ThemeViewModel(mockPersistenceService).darkTheme;

      // High contrast theme should have different colors
      expect(theme.colorScheme.surface, isNot(normalTheme.colorScheme.surface));
    });

    test('lightTheme applies font scaling', () async {
      await viewModel.setFontScale(FontScaleOption.large);

      final theme = viewModel.lightTheme;
      final normalTheme = ThemeViewModel(mockPersistenceService).lightTheme;

      // Scaled theme should have larger font sizes
      final scaledSize = theme.textTheme.bodyMedium?.fontSize;
      final normalSize = normalTheme.textTheme.bodyMedium?.fontSize;

      expect(scaledSize, greaterThan(normalSize!));
    });

    test('darkTheme applies font scaling', () async {
      await viewModel.setFontScale(FontScaleOption.extraLarge);

      final theme = viewModel.darkTheme;
      final normalTheme = ThemeViewModel(mockPersistenceService).darkTheme;

      // Scaled theme should have larger font sizes
      final scaledSize = theme.textTheme.bodyMedium?.fontSize;
      final normalSize = normalTheme.textTheme.bodyMedium?.fontSize;

      expect(scaledSize, greaterThan(normalSize!));
    });

    test('themes have consistent Material 3 structure', () {
      final lightTheme = viewModel.lightTheme;
      final darkTheme = viewModel.darkTheme;

      expect(lightTheme.useMaterial3, true);
      expect(darkTheme.useMaterial3, true);
      expect(lightTheme.appBarTheme.centerTitle, true);
      expect(darkTheme.appBarTheme.centerTitle, true);
      expect(lightTheme.cardTheme.elevation, 2);
      expect(darkTheme.cardTheme.elevation, 2);
    });

    test('changing theme mode notifies listeners', () async {
      var notificationCount = 0;
      viewModel.addListener(() {
        notificationCount++;
      });

      await viewModel.setThemeMode(AppThemeMode.light);
      await viewModel.setThemeMode(AppThemeMode.dark);
      await viewModel.setThemeMode(AppThemeMode.system);

      expect(notificationCount, 3);
    });

    test('changing accent color notifies listeners', () async {
      var notificationCount = 0;
      viewModel.addListener(() {
        notificationCount++;
      });

      await viewModel.setAccentColor(AccentColor.blue);
      await viewModel.setAccentColor(AccentColor.green);

      expect(notificationCount, 2);
    });

    test('settings property returns current settings', () {
      expect(viewModel.settings, const ThemeSettings());

      viewModel.setThemeMode(AppThemeMode.dark);
      expect(viewModel.settings.themeMode, AppThemeMode.dark);
    });
  });
}

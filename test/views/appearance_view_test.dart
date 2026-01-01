import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/viewmodels/theme_viewmodel.dart';
import 'package:blood_pressure_monitor/views/appearance_view.dart';

import 'appearance_view_test.mocks.dart';

@GenerateMocks([ThemeViewModel])
void main() {
  group('AppearanceView', () {
    late MockThemeViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockThemeViewModel();
      when(mockViewModel.themeMode).thenReturn(AppThemeMode.system);
      when(mockViewModel.accentColor).thenReturn(AccentColor.teal);
      when(mockViewModel.fontScale).thenReturn(FontScaleOption.normal);
      when(mockViewModel.highContrastMode).thenReturn(false);
      when(mockViewModel.setThemeMode(any)).thenAnswer((_) async {});
      when(mockViewModel.setAccentColor(any)).thenAnswer((_) async {});
      when(mockViewModel.setFontScale(any)).thenAnswer((_) async {});
      when(mockViewModel.toggleHighContrastMode()).thenAnswer((_) async {});
      when(mockViewModel.resetToDefaults()).thenAnswer((_) async {});
    });

    Widget buildTestWidget() {
      return ChangeNotifierProvider<ThemeViewModel>.value(
        value: mockViewModel,
        child: const MaterialApp(
          home: AppearanceView(),
        ),
      );
    }

    testWidgets('displays title and reset button', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.byIcon(Icons.restore), findsOneWidget);
    });

    testWidgets('displays theme mode section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Theme Mode'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);
    });

    testWidgets('displays accent color picker', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Accent Color'), findsOneWidget);
      // Should display all accent color options
      expect(find.text('Teal'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
    });

    testWidgets('displays font scale selector', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Text Size'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Extra Large'), findsOneWidget);
    });

    testWidgets('displays high contrast toggle', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(
        find.textContaining('Increases contrast'),
        findsOneWidget,
      );
    });

    testWidgets('displays preview section', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Preview'), findsOneWidget);
      expect(find.text('Headline Text'), findsOneWidget);
      expect(find.text('Sample Button'), findsOneWidget);
    });

    testWidgets('selecting theme mode calls viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();

      verify(mockViewModel.setThemeMode(AppThemeMode.light)).called(1);
    });

    testWidgets('selecting accent color calls viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Find and tap the Blue color option
      final blueColorOption = find.ancestor(
        of: find.text('Blue'),
        matching: find.byType(InkWell),
      );

      await tester.tap(blueColorOption.first);
      await tester.pumpAndSettle();

      verify(mockViewModel.setAccentColor(AccentColor.blue)).called(1);
    });

    testWidgets('selecting font scale calls viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Scroll to make Large option visible
      await tester.ensureVisible(find.text('Large'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();

      verify(mockViewModel.setFontScale(FontScaleOption.large)).called(1);
    });

    testWidgets('toggling high contrast calls viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Scroll to make Switch visible
      final switchWidget = find.byType(Switch);
      await tester.ensureVisible(switchWidget);
      await tester.pumpAndSettle();

      await tester.tap(switchWidget);
      await tester.pumpAndSettle();

      verify(mockViewModel.toggleHighContrastMode()).called(1);
    });

    testWidgets('reset button shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();

      expect(find.text('Reset to Defaults'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to reset'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('confirming reset calls viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap reset button
      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();

      // Tap Reset in dialog
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      verify(mockViewModel.resetToDefaults()).called(1);
    });

    testWidgets('canceling reset does not call viewmodel', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Tap reset button
      await tester.tap(find.byIcon(Icons.restore));
      await tester.pumpAndSettle();

      // Tap Cancel in dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(mockViewModel.resetToDefaults());
    });

    testWidgets('has scrollable content', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('all cards are present', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Should have cards for: Theme Mode, Accent Color, Text Size,
      // High Contrast, and Preview
      expect(find.byType(Card), findsAtLeastNWidgets(5));
    });

    testWidgets('shows all theme mode descriptions', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      expect(find.text('Always use light theme'), findsOneWidget);
      expect(find.text('Always use dark theme'), findsOneWidget);
      expect(find.text('Follow system theme setting'), findsOneWidget);
    });

    testWidgets('reflects current theme mode selection', (tester) async {
      when(mockViewModel.themeMode).thenReturn(AppThemeMode.dark);

      await tester.pumpWidget(buildTestWidget());

      final darkRadio = find.ancestor(
        of: find.text('Dark'),
        matching: find.byType(RadioListTile<AppThemeMode>),
      );

      final radioTile = tester.widget<RadioListTile<AppThemeMode>>(darkRadio);
      // ignore: deprecated_member_use
      expect(radioTile.groupValue, AppThemeMode.dark);
    });

    testWidgets('reflects current font scale selection', (tester) async {
      when(mockViewModel.fontScale).thenReturn(FontScaleOption.large);

      await tester.pumpWidget(buildTestWidget());

      final largeRadio = find.ancestor(
        of: find.text('Large'),
        matching: find.byType(RadioListTile<FontScaleOption>),
      );

      final radioTile =
          tester.widget<RadioListTile<FontScaleOption>>(largeRadio);
      // ignore: deprecated_member_use
      expect(radioTile.groupValue, FontScaleOption.large);
    });

    testWidgets('reflects high contrast mode state', (tester) async {
      when(mockViewModel.highContrastMode).thenReturn(true);

      await tester.pumpWidget(buildTestWidget());

      final switchListTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switchListTile.value, true);
    });
  });
}

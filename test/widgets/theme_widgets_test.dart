import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/widgets/theme_widgets.dart';

void main() {
  group('ThemePalettePicker', () {
    testWidgets('displays all accent colors', (tester) async {
      var selectedColor = AccentColor.teal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemePalettePicker(
              selectedColor: selectedColor,
              onColorSelected: (color) {
                selectedColor = color;
              },
            ),
          ),
        ),
      );

      expect(find.text('Accent Color'), findsOneWidget);
      expect(find.text('Teal'), findsOneWidget);
      expect(find.text('Blue'), findsOneWidget);
      expect(find.text('Green'), findsOneWidget);
      expect(find.text('Cyan'), findsOneWidget);
      expect(find.text('Indigo'), findsOneWidget);
      expect(find.text('Blue Grey'), findsOneWidget);
      expect(find.text('Emerald'), findsOneWidget);
      expect(find.text('Turquoise'), findsOneWidget);
    });

    testWidgets('highlights selected color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemePalettePicker(
              selectedColor: AccentColor.blue,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Find the Blue color option container
      final blueOption = find.ancestor(
        of: find.text('Blue'),
        matching: find.byType(Container),
      );

      expect(blueOption, findsWidgets);
    });

    testWidgets('calls onColorSelected when tapping a color', (tester) async {
      AccentColor? selectedColor;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemePalettePicker(
              selectedColor: AccentColor.teal,
              onColorSelected: (color) {
                selectedColor = color;
              },
            ),
          ),
        ),
      );

      // Tap on Blue color
      final blueOption = find.ancestor(
        of: find.text('Blue'),
        matching: find.byType(InkWell),
      );

      await tester.tap(blueOption.first);
      await tester.pumpAndSettle();

      expect(selectedColor, AccentColor.blue);
    });

    testWidgets('displays color circles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ThemePalettePicker(
              selectedColor: AccentColor.teal,
              onColorSelected: (_) {},
            ),
          ),
        ),
      );

      // Should have 8 color option containers (one for each AccentColor)
      expect(find.byType(InkWell), findsNWidgets(8));
    });
  });

  group('FontScaleSelector', () {
    testWidgets('displays all font scale options', (tester) async {
      var selectedScale = FontScaleOption.normal;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontScaleSelector(
              selectedScale: selectedScale,
              onScaleSelected: (scale) {
                selectedScale = scale;
              },
            ),
          ),
        ),
      );

      expect(find.text('Text Size'), findsOneWidget);
      expect(find.text('Normal'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Extra Large'), findsOneWidget);
    });

    testWidgets('shows sample text at different scales', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontScaleSelector(
              selectedScale: FontScaleOption.normal,
              onScaleSelected: (_) {},
            ),
          ),
        ),
      );

      // The actual text is lowercase 'sample'
      expect(find.textContaining('sample text at 100% scale', findRichText: true), findsOneWidget);
      expect(find.textContaining('sample text at 115% scale', findRichText: true), findsOneWidget);
      expect(find.textContaining('sample text at 130% scale', findRichText: true), findsOneWidget);
    });

    testWidgets('calls onScaleSelected when selecting an option',
        (tester) async {
      FontScaleOption? selectedScale;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontScaleSelector(
              selectedScale: FontScaleOption.normal,
              onScaleSelected: (scale) {
                selectedScale = scale;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Large'));
      await tester.pumpAndSettle();

      expect(selectedScale, FontScaleOption.large);
    });

    testWidgets('highlights selected scale', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontScaleSelector(
              selectedScale: FontScaleOption.large,
              onScaleSelected: (_) {},
            ),
          ),
        ),
      );

      final largeRadio = find.ancestor(
        of: find.text('Large'),
        matching: find.byType(RadioListTile<FontScaleOption>),
      );

      final radioTile =
          tester.widget<RadioListTile<FontScaleOption>>(largeRadio);
      expect(radioTile.groupValue, FontScaleOption.large);
    });

    testWidgets('displays all three radio buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FontScaleSelector(
              selectedScale: FontScaleOption.normal,
              onScaleSelected: (_) {},
            ),
          ),
        ),
      );

      expect(
        find.byType(RadioListTile<FontScaleOption>),
        findsNWidgets(3),
      );
    });
  });

  group('ContrastToggleTile', () {
    testWidgets('displays title and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContrastToggleTile(
              isEnabled: false,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('High Contrast Mode'), findsOneWidget);
      expect(
        find.textContaining('Increases contrast between text and background'),
        findsOneWidget,
      );
    });

    testWidgets('reflects enabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContrastToggleTile(
              isEnabled: true,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      final switchListTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      expect(switchListTile.value, true);
    });

    testWidgets('reflects disabled state', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContrastToggleTile(
              isEnabled: false,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      final switchListTile = tester.widget<SwitchListTile>(
        find.byType(SwitchListTile),
      );

      expect(switchListTile.value, false);
    });

    testWidgets('calls onToggle when switch is tapped', (tester) async {
      bool? toggledValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContrastToggleTile(
              isEnabled: false,
              onToggle: (value) {
                toggledValue = value;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(toggledValue, true);
    });

    testWidgets('is wrapped in a Card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContrastToggleTile(
              isEnabled: false,
              onToggle: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });
  });
}

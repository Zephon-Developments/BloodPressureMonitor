import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/widgets/medication/unit_combo_box.dart';

void main() {
  group('UnitComboBox Widget Tests', () {
    testWidgets('should display initial value if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              initialValue: 'mg',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('mg'), findsOneWidget);
    });

    testWidgets('should display default placeholder when no initial value',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
    });

    testWidgets('should show all predefined units in dropdown', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap the dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Verify common units are present
      expect(find.text('mg').hitTestable(), findsOneWidget);
      expect(find.text('ml').hitTestable(), findsOneWidget);
      expect(find.text('IU').hitTestable(), findsOneWidget);
      expect(find.text('mcg').hitTestable(), findsOneWidget);
      expect(find.text('units').hitTestable(), findsOneWidget);
      expect(find.text('tablets').hitTestable(), findsOneWidget);
      expect(find.text('capsules').hitTestable(), findsOneWidget);
      expect(find.text('drops').hitTestable(), findsOneWidget);
      expect(find.text('puffs').hitTestable(), findsOneWidget);
      expect(find.text('Custom...').hitTestable(), findsOneWidget);
    });

    testWidgets('should call onChanged when unit is selected', (tester) async {
      String? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (unit) {
                selectedUnit = unit;
              },
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'mg'
      await tester.tap(find.text('mg').last);
      await tester.pumpAndSettle();

      expect(selectedUnit, 'mg');
    });

    testWidgets('should show custom text field when Custom is selected',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();

      // Select 'Custom'
      await tester.tap(find.text('Custom...').last);
      await tester.pumpAndSettle();

      // Should now see a TextField for custom input
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Enter custom unit'), findsOneWidget);
    });

    testWidgets('should call onChanged with custom unit text', (tester) async {
      String? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (unit) {
                selectedUnit = unit;
              },
            ),
          ),
        ),
      );

      // Select Custom
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom...').last);
      await tester.pumpAndSettle();

      // Enter custom text
      await tester.enterText(find.byType(TextField), 'spray');
      await tester.pumpAndSettle();

      expect(selectedUnit, 'spray');
    });

    testWidgets('should respect enabled parameter', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              enabled: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final dropdown = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );

      // When disabled, onChanged should be null
      expect(dropdown.onChanged, isNull);
    });

    testWidgets('should clear custom text when switching back to preset',
        (tester) async {
      String? selectedUnit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              onChanged: (unit) {
                selectedUnit = unit;
              },
            ),
          ),
        ),
      );

      // Select Custom and enter text
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom...').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'spray');
      await tester.pumpAndSettle();

      expect(selectedUnit, 'spray');

      // Switch back to a preset unit
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mg').last);
      await tester.pumpAndSettle();

      expect(selectedUnit, 'mg');
      expect(find.byType(TextField), findsNothing);
    });

    testWidgets('should show initial custom value if not in preset list',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: UnitComboBox(
              initialValue: 'spray',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show Custom with the text field populated
      expect(find.text('Custom...'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('spray'), findsOneWidget);
    });
  });
}

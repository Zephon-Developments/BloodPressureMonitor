import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/widgets/medication/multi_select_medication_picker.dart';

void main() {
  late List<Medication> testMedications;

  setUp(() {
    testMedications = [
      Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        dosage: '100',
        unit: 'mg',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Medication(
        id: 2,
        profileId: 1,
        name: 'Lisinopril',
        dosage: '10',
        unit: 'mg',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Medication(
        id: 3,
        profileId: 1,
        name: 'Metformin',
        dosage: '500',
        unit: 'mg',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
  });

  group('MultiSelectMedicationPicker Widget Tests', () {
    testWidgets('should display title and action buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      expect(find.text('Select Medications'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
    });

    testWidgets('should display all medications in the list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('100 mg'), findsOneWidget);
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('10 mg'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);
      expect(find.text('500 mg'), findsOneWidget);
    });

    testWidgets('should show checkboxes for each medication', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      expect(find.byType(CheckboxListTile), findsNWidgets(3));
    });

    testWidgets('should pre-select initially selected medications',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
              initiallySelected: const [1, 2], // Aspirin and Lisinopril
            ),
          ),
        ),
      );

      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );

      expect(checkboxes.elementAt(0).value, true); // Aspirin
      expect(checkboxes.elementAt(1).value, true); // Lisinopril
      expect(checkboxes.elementAt(2).value, false); // Metformin
    });

    testWidgets('should toggle selection when checkbox is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // Initially all unchecked
      var checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxes.first.value, false);

      // Tap first medication
      await tester.tap(find.text('Aspirin'));
      await tester.pump();

      // Should now be checked
      checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxes.first.value, true);

      // Tap again to uncheck
      await tester.tap(find.text('Aspirin'));
      await tester.pump();

      checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      expect(checkboxes.first.value, false);
    });

    testWidgets('should show search bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search medications...'), findsOneWidget);
    });

    testWidgets('should filter medications based on search text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // Initially all visible
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);

      // Search for "Asp"
      await tester.enterText(find.byType(TextField), 'Asp');
      await tester.pump();

      // Only Aspirin should be visible
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Lisinopril'), findsNothing);
      expect(find.text('Metformin'), findsNothing);
    });

    testWidgets('should show clear button when search has text',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // No clear button initially
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Aspirin');
      await tester.pump();

      // Clear button should appear
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear search when clear button is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // Enter search text
      await tester.enterText(find.byType(TextField), 'Aspirin');
      await tester.pump();

      expect(find.text('Lisinopril'), findsNothing);

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      // All medications should be visible again
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Lisinopril'), findsOneWidget);
      expect(find.text('Metformin'), findsOneWidget);
    });

    testWidgets('should show empty state when no medications', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: [],
            ),
          ),
        ),
      );

      expect(find.text('No medications available'), findsOneWidget);
    });

    testWidgets('should show empty state when search has no results',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // Search for something that doesn't exist
      await tester.enterText(find.byType(TextField), 'XYZ');
      await tester.pump();

      expect(find.text('No medications match your search'), findsOneWidget);
    });

    testWidgets('should return selected IDs when Done is tapped',
        (tester) async {
      List<int>? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MultiSelectMedicationPicker.show(
                    context,
                    medications: testMedications,
                  );
                },
                child: const Text('Show Picker'),
              ),
            ),
          ),
        ),
      );

      // Show picker
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Select first and third medications
      await tester.tap(find.text('Aspirin'));
      await tester.pump();
      await tester.tap(find.text('Metformin'));
      await tester.pump();

      // Tap Confirm
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(result, [1, 3]);
    });

    testWidgets('should return null when Cancel is tapped', (tester) async {
      List<int>? result = [999]; // Set non-null initial value

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await MultiSelectMedicationPicker.show(
                    context,
                    medications: testMedications,
                  );
                },
                child: const Text('Show Picker'),
              ),
            ),
          ),
        ),
      );

      // Show picker
      await tester.tap(find.text('Show Picker'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(result, null);
    });

    testWidgets('should maintain selection count display', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiSelectMedicationPicker(
              medications: testMedications,
            ),
          ),
        ),
      );

      // Select two medications
      await tester.tap(find.text('Aspirin'));
      await tester.pump();
      await tester.tap(find.text('Lisinopril'));
      await tester.pump();

      // Should show count in header
      expect(find.text('2 selected'), findsOneWidget);
    });
  });
}

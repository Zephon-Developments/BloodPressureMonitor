import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/views/home/widgets/quick_actions.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/medication/medication_picker_dialog.dart';

import '../../../test_mocks.mocks.dart';

void main() {
  late MockMedicationViewModel mockMedicationViewModel;

  setUp(() {
    mockMedicationViewModel = MockMedicationViewModel();
    when(mockMedicationViewModel.isLoading).thenReturn(false);
    when(mockMedicationViewModel.errorMessage).thenReturn(null);
    when(mockMedicationViewModel.medications).thenReturn([]);
    when(mockMedicationViewModel.loadMedications()).thenAnswer((_) async {});
    when(mockMedicationViewModel.search(any)).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<MedicationViewModel>.value(
      value: mockMedicationViewModel,
      child: const MaterialApp(
        home: Scaffold(
          body: QuickActions(),
        ),
      ),
    );
  }

  group('QuickActions Widget Tests', () {
    testWidgets('renders quick actions title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('renders add reading button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Add Blood Pressure Reading'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('navigates to AddReadingView when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the add reading button
      await tester.tap(find.text('Add Blood Pressure Reading'));
      await tester.pumpAndSettle();

      // Should navigate to AddReadingView
      expect(find.byType(AddReadingView), findsOneWidget);
    });

    testWidgets('renders log medication intake button',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Log Medication Intake'), findsOneWidget);
      expect(find.byIcon(Icons.medication), findsOneWidget);
    });

    testWidgets('medication intake button opens picker dialog',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Tap the medication intake button
      await tester.tap(find.text('Log Medication Intake'));
      await tester.pumpAndSettle();

      // Should open the medication picker dialog
      expect(find.byType(MedicationPickerDialog), findsOneWidget);
      expect(find.text('Select Medication'), findsOneWidget);
    });

    testWidgets('button spans full width', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final sizedBoxFinder = find.descendant(
        of: find.byType(QuickActions),
        matching: find.byType(SizedBox),
      );

      expect(sizedBoxFinder, findsWidgets);
    });
  });
}

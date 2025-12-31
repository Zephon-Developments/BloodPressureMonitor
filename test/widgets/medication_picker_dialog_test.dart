import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/medication/medication_picker_dialog.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockMedicationViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockMedicationViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.errorMessage).thenReturn(null);
    when(mockViewModel.medications).thenReturn([]);
    when(mockViewModel.loadMedications()).thenAnswer((_) async {});
    when(mockViewModel.search(any)).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<MedicationViewModel>.value(
      value: mockViewModel,
      child: const MaterialApp(
        home: Scaffold(
          body: MedicationPickerDialog(),
        ),
      ),
    );
  }

  testWidgets('should display title and search bar', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Select Medication'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Search medications...'), findsOneWidget);
  });

  testWidgets('should display loading indicator when loading', (tester) async {
    when(mockViewModel.isLoading).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('should display error message on error', (tester) async {
    when(mockViewModel.errorMessage).thenReturn('Test error');

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Test error'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('should display empty state when no medications', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('No active medications'), findsOneWidget);
  });

  testWidgets('should display active medications only', (tester) async {
    final medications = <Medication>[
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
        isActive: false,
        createdAt: DateTime.now(),
      ),
    ];
    when(mockViewModel.medications).thenReturn(medications);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Aspirin'), findsOneWidget);
    expect(find.text('100 mg'), findsOneWidget);
    expect(find.text('Lisinopril'), findsNothing);
  });

  testWidgets('should call search when search text changes', (tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Aspirin');
    await tester.pump(const Duration(milliseconds: 300));

    verify(mockViewModel.search('Aspirin')).called(1);
  });

  testWidgets('should return selected medication on tap', (tester) async {
    final medication = Medication(
      id: 1,
      profileId: 1,
      name: 'Aspirin',
      dosage: '100',
      unit: 'mg',
      isActive: true,
      createdAt: DateTime.now(),
    );
    when(mockViewModel.medications).thenReturn([medication]);

    Medication? selectedMedication;
    await tester.pumpWidget(
      ChangeNotifierProvider<MedicationViewModel>.value(
        value: mockViewModel,
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedMedication = await showMedicationPicker(context);
                },
                child: const Text('Show Picker'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Picker'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Aspirin'));
    await tester.pumpAndSettle();

    expect(selectedMedication, medication);
  });
}

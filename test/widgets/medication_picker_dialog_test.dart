import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/medication/medication_picker_dialog.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockMedicationViewModel mockViewModel;
  late MockMedicationGroupViewModel mockGroupViewModel;

  setUp(() {
    mockViewModel = MockMedicationViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.errorMessage).thenReturn(null);
    when(mockViewModel.medications).thenReturn([]);
    when(mockViewModel.loadMedications()).thenAnswer((_) async {});
    when(mockViewModel.search(any)).thenAnswer((_) async {});

    mockGroupViewModel = MockMedicationGroupViewModel();
    when(mockGroupViewModel.isLoading).thenReturn(false);
    when(mockGroupViewModel.errorMessage).thenReturn(null);
    when(mockGroupViewModel.groups).thenReturn([]);
    when(mockGroupViewModel.loadGroups()).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MedicationViewModel>.value(value: mockViewModel),
        ChangeNotifierProvider<MedicationGroupViewModel>.value(
          value: mockGroupViewModel,
        ),
      ],
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
    expect(find.text('Search medications and groups...'), findsOneWidget);
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

    expect(find.text('No active medications or groups'), findsOneWidget);
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
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MedicationViewModel>.value(
            value: mockViewModel,
          ),
          ChangeNotifierProvider<MedicationGroupViewModel>.value(
            value: mockGroupViewModel,
          ),
        ],
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

  testWidgets('should display medication groups in picker', (tester) async {
    final group = MedicationGroup(
      id: 1,
      profileId: 1,
      name: 'Morning Meds',
      memberMedicationIds: [1, 2],
      createdAt: DateTime.now(),
    );
    final medications = [
      Medication(id: 1, profileId: 1, name: 'Med 1'),
      Medication(id: 2, profileId: 1, name: 'Med 2'),
    ];
    when(mockGroupViewModel.groups).thenReturn([group]);
    when(mockViewModel.medications).thenReturn(medications);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('Medication Groups'), findsOneWidget);
    expect(find.text('Morning Meds'), findsOneWidget);
    expect(find.text('2 medications'), findsOneWidget);
  });

  testWidgets('should display groups before individual medications',
      (tester) async {
    final medication = Medication(
      id: 1,
      profileId: 1,
      name: 'Aspirin',
      dosage: '100',
      unit: 'mg',
      isActive: true,
      createdAt: DateTime.now(),
    );
    final group = MedicationGroup(
      id: 1,
      profileId: 1,
      name: 'Morning Meds',
      memberMedicationIds: [1],
      createdAt: DateTime.now(),
    );
    when(mockViewModel.medications).thenReturn([medication]);
    when(mockGroupViewModel.groups).thenReturn([group]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Both sections should be visible
    expect(find.text('Medication Groups'), findsOneWidget);
    expect(find.text('Individual Medications'), findsOneWidget);
  });

  testWidgets('should filter groups by search term', (tester) async {
    final group1 = MedicationGroup(
      id: 1,
      profileId: 1,
      name: 'Morning Meds',
      memberMedicationIds: [1],
      createdAt: DateTime.now(),
    );
    final group2 = MedicationGroup(
      id: 2,
      profileId: 1,
      name: 'Evening Meds',
      memberMedicationIds: [1],
      createdAt: DateTime.now(),
    );
    when(mockGroupViewModel.groups).thenReturn([group1, group2]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Initially both visible
    expect(find.text('Morning Meds'), findsOneWidget);
    expect(find.text('Evening Meds'), findsOneWidget);

    // Search for "Morning"
    await tester.enterText(find.byType(TextField), 'Morning');
    await tester.pump();

    // Only Morning Meds should be visible
    expect(find.text('Morning Meds'), findsOneWidget);
    expect(find.text('Evening Meds'), findsNothing);
  });

  testWidgets('should return selected group when group is tapped',
      (tester) async {
    final group = MedicationGroup(
      id: 1,
      profileId: 1,
      name: 'Morning Meds',
      memberMedicationIds: [1, 2],
      createdAt: DateTime.now(),
    );
    when(mockGroupViewModel.groups).thenReturn([group]);

    dynamic selectedItem;
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<MedicationViewModel>.value(
            value: mockViewModel,
          ),
          ChangeNotifierProvider<MedicationGroupViewModel>.value(
            value: mockGroupViewModel,
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  selectedItem = await showMedicationPicker(context);
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

    await tester.tap(find.text('Morning Meds'));
    await tester.pumpAndSettle();

    expect(selectedItem, isA<MedicationGroup>());
    expect((selectedItem as MedicationGroup).name, 'Morning Meds');
  });

  testWidgets('should show folder icon for groups', (tester) async {
    final group = MedicationGroup(
      id: 1,
      profileId: 1,
      name: 'Morning Meds',
      memberMedicationIds: [1],
      createdAt: DateTime.now(),
    );
    when(mockGroupViewModel.groups).thenReturn([group]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.folder), findsOneWidget);
  });

  testWidgets('should show empty message when no groups and no medications',
      (tester) async {
    when(mockViewModel.medications).thenReturn([]);
    when(mockGroupViewModel.groups).thenReturn([]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.text('No active medications or groups'), findsOneWidget);
  });
}

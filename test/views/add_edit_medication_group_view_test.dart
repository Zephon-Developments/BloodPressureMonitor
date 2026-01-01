import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/views/medication/add_edit_medication_group_view.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockMedicationGroupViewModel mockGroupViewModel;
  late MockMedicationViewModel mockMedicationViewModel;
  late MockActiveProfileViewModel mockProfileViewModel;
  late List<Medication> testMedications;

  setUp(() {
    mockGroupViewModel = MockMedicationGroupViewModel();
    mockMedicationViewModel = MockMedicationViewModel();
    mockProfileViewModel = MockActiveProfileViewModel();

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
    ];

    when(mockMedicationViewModel.medications).thenReturn(testMedications);
    when(mockMedicationViewModel.isLoading).thenReturn(false);
    when(mockMedicationViewModel.loadMedications()).thenAnswer((_) async {});
    when(mockProfileViewModel.activeProfileId).thenReturn(1);
    when(mockGroupViewModel.createGroup(any)).thenAnswer((_) async {});
    when(mockGroupViewModel.updateGroup(any)).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest({MedicationGroup? group}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MedicationGroupViewModel>.value(
          value: mockGroupViewModel,
        ),
        ChangeNotifierProvider<MedicationViewModel>.value(
          value: mockMedicationViewModel,
        ),
        ChangeNotifierProvider<ActiveProfileViewModel>.value(
          value: mockProfileViewModel,
        ),
      ],
      child: MaterialApp(
        home: AddEditMedicationGroupView(group: group),
      ),
    );
  }

  group('AddEditMedicationGroupView Widget Tests', () {
    testWidgets('should display "Add Group" title when creating',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Add Group'), findsOneWidget);
    });

    testWidgets('should display "Edit Group" title when editing',
        (tester) async {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1],
      );

      await tester.pumpWidget(createWidgetUnderTest(group: group));

      expect(find.text('Edit Group'), findsOneWidget);
    });

    testWidgets('should populate fields when editing existing group',
        (tester) async {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2],
      );

      await tester.pumpWidget(createWidgetUnderTest(group: group));
      await tester.pumpAndSettle();

      expect(find.text('Morning Meds'), findsOneWidget);
      // Should show 2 selected medications
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.text('Lisinopril'), findsOneWidget);
    });

    testWidgets('should show validation error for empty name', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Try to save without entering name
      await tester.tap(find.text('Create Group'));
      await tester.pump();

      expect(find.text('Please enter a group name'), findsOneWidget);
    });

    testWidgets('should show validation error for name too short',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter single character
      await tester.enterText(
        find.byType(TextField).first,
        'A',
      );
      await tester.tap(find.text('Create Group'));
      await tester.pump();

      expect(
        find.text('Group name must be at least 2 characters'),
        findsOneWidget,
      );
    });

    testWidgets('should require at least one medication', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter valid name
      await tester.enterText(
        find.byType(TextField).first,
        'Test Group',
      );

      // Try to save without selecting medications
      await tester.tap(find.text('Create Group'));
      await tester.pump();

      expect(
        find.text('Please select at least one medication'),
        findsOneWidget,
      );
    });

    testWidgets('should open medication picker when Select Medications tapped',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Should show the multi-select picker
      expect(find.text('Select Medications'), findsNWidgets(2));
    });

    testWidgets('should display selected medications as list items',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Open picker
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();

      // Select medications
      await tester.tap(find.text('Aspirin'));
      await tester.pump();

      // Close picker
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Should show list item with medication name
      expect(find.text('Aspirin'), findsOneWidget);
      expect(find.byType(ListTile), findsOneWidget);
    });

    testWidgets('should remove medication when delete icon is tapped',
        (tester) async {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Test Group',
        memberMedicationIds: [1],
      );

      await tester.pumpWidget(createWidgetUnderTest(group: group));
      await tester.pumpAndSettle();

      // Medication should be shown
      expect(find.text('Aspirin'), findsOneWidget);

      // Tap delete icon
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      // Medication should be removed
      expect(find.text('Aspirin'), findsNothing);
    });

    testWidgets('should call createGroup when saving new group',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter name
      await tester.enterText(
        find.byType(TextField).first,
        'New Group',
      );

      // Add medication
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aspirin'));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Create Group'));
      await tester.pump();

      verify(mockGroupViewModel.createGroup(any)).called(1);
    });

    testWidgets('should call updateGroup when saving existing group',
        (tester) async {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Original Name',
        memberMedicationIds: [1],
      );

      await tester.pumpWidget(createWidgetUnderTest(group: group));
      await tester.pumpAndSettle();

      // Modify name
      await tester.enterText(
        find.byType(TextField).first,
        'Modified Name',
      );

      // Save
      await tester.tap(find.text('Update Group'));
      await tester.pump();

      verify(mockGroupViewModel.updateGroup(any)).called(1);
    });

    testWidgets('should pop with true on successful save', (tester) async {
      bool? result;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<MedicationGroupViewModel>.value(
              value: mockGroupViewModel,
            ),
            ChangeNotifierProvider<MedicationViewModel>.value(
              value: mockMedicationViewModel,
            ),
            ChangeNotifierProvider<ActiveProfileViewModel>.value(
              value: mockProfileViewModel,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => const AddEditMedicationGroupView(),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open form
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      // Fill form
      await tester.enterText(
        find.byType(TextField).first,
        'Test Group',
      );
      await tester.tap(find.byType(OutlinedButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Aspirin'));
      await tester.pump();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Create Group'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('should show loading indicator when medications are loading',
        (tester) async {
      // Make loadMedications hang
      when(mockMedicationViewModel.loadMedications())
          .thenAnswer((_) async => Completer<void>().future);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show empty state when no medications selected',
        (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(
        find.text('Select at least one medication for this group'),
        findsOneWidget,
      );
    });
  });
}

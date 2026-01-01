import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/views/medication/medication_group_list_view.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockMedicationGroupViewModel mockGroupViewModel;
  late MockMedicationViewModel mockMedicationViewModel;
  late List<MedicationGroup> testGroups;
  late List<Medication> testMedications;

  setUp(() {
    mockGroupViewModel = MockMedicationGroupViewModel();
    mockMedicationViewModel = MockMedicationViewModel();

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

    testGroups = [
      MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Morning Meds',
        memberMedicationIds: [1, 2],
        createdAt: DateTime.now(),
      ),
      MedicationGroup(
        id: 2,
        profileId: 1,
        name: 'Evening Meds',
        memberMedicationIds: [1],
        createdAt: DateTime.now(),
      ),
    ];

    when(mockGroupViewModel.groups).thenReturn([]);
    when(mockGroupViewModel.isLoading).thenReturn(false);
    when(mockGroupViewModel.errorMessage).thenReturn(null);
    when(mockGroupViewModel.loadGroups()).thenAnswer((_) async {});
    when(mockGroupViewModel.deleteGroup(any)).thenAnswer((_) async {});
    when(mockMedicationViewModel.medications).thenReturn(testMedications);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MedicationGroupViewModel>.value(
          value: mockGroupViewModel,
        ),
        ChangeNotifierProvider<MedicationViewModel>.value(
          value: mockMedicationViewModel,
        ),
      ],
      child: const MaterialApp(
        home: MedicationGroupListView(),
      ),
    );
  }

  group('MedicationGroupListView Widget Tests', () {
    testWidgets('should display title in app bar', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Medication Groups'), findsOneWidget);
    });

    testWidgets('should call loadGroups on init', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      verify(mockGroupViewModel.loadGroups()).called(1);
    });

    testWidgets('should display loading indicator when loading',
        (tester) async {
      when(mockGroupViewModel.isLoading).thenReturn(true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error message when error occurs',
        (tester) async {
      when(mockGroupViewModel.errorMessage).thenReturn('Test error');

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Test error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should reload groups when retry is tapped', (tester) async {
      when(mockGroupViewModel.errorMessage).thenReturn('Test error');

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Retry'));
      await tester.pump();

      verify(mockGroupViewModel.loadGroups())
          .called(2); // Once on init, once on retry
    });

    testWidgets('should display empty state when no groups', (tester) async {
      when(mockGroupViewModel.groups).thenReturn([]);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('No medication groups yet'), findsOneWidget);
      expect(
        find.textContaining(
          'Create a group to log multiple medications at once.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display list of groups', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Morning Meds'), findsOneWidget);
      expect(find.text('Evening Meds'), findsOneWidget);
    });

    testWidgets('should display member count for each group', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('2 medications'), findsOneWidget);
      expect(find.text('1 medication'), findsOneWidget);
    });

    testWidgets('should have Add Group button', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('should navigate to add form when Add Group tapped',
        (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      expect(find.text('Add Group'), findsOneWidget);
    });

    testWidgets('should navigate to edit form when group is tapped',
        (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.tap(find.text('Morning Meds'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Group'), findsOneWidget);
    });

    testWidgets('should show delete confirmation dialog on swipe',
        (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Swipe to reveal delete action
      await tester.drag(
        find.text('Morning Meds'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Should show confirmation dialog
      expect(find.text('Delete Medication Group'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to delete "Morning Meds"?'),
        findsOneWidget,
      );
    });

    testWidgets('should cancel delete when Cancel is tapped', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Trigger delete
      await tester.drag(
        find.text('Morning Meds'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Should not call delete
      verifyNever(mockGroupViewModel.deleteGroup(any));
    });

    testWidgets('should call deleteGroup when Delete is confirmed', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Trigger delete
      await tester.drag(
        find.text('Morning Meds'),
        const Offset(-500, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      // Confirm delete
      await tester.tap(find.text('DELETE'));
      await tester.pumpAndSettle();

      // Should call deleteGroup with correct ID
      verify(mockGroupViewModel.deleteGroup(1)).called(1);
    });

    testWidgets('should navigate to add form when FAB tapped', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Open add form
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.text('Add Group'), findsOneWidget);
    });

    testWidgets('should display medication icon for groups', (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Should have medication icon for each group
      expect(find.byIcon(Icons.medication), findsNWidgets(2));
    });

    testWidgets('should show correct medication count in subtitle',
        (tester) async {
      when(mockGroupViewModel.groups).thenReturn(testGroups);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Morning Meds has 2 medications
      expect(find.text('2 medications'), findsOneWidget);
      // Evening Meds has 1 medication
      expect(find.text('1 medication'), findsOneWidget);
    });
  });
}

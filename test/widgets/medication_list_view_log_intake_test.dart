import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/views/medication/medication_list_view.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockMedicationViewModel mockViewModel;

  setUp(() {
    mockViewModel = MockMedicationViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.errorMessage).thenReturn(null);
    when(mockViewModel.medications).thenReturn([]);
    when(mockViewModel.showInactive).thenReturn(false);
    when(mockViewModel.loadMedications()).thenAnswer((_) async {});
    when(mockViewModel.search(any)).thenAnswer((_) async {});
  });

  Widget createWidgetUnderTest() {
    return ChangeNotifierProvider<MedicationViewModel>.value(
      value: mockViewModel,
      child: const MaterialApp(
        home: MedicationListView(),
      ),
    );
  }

  testWidgets('should display log intake button for active medications',
      (tester) async {
    final medications = [
      Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
    when(mockViewModel.medications).thenReturn(medications);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
    expect(find.byTooltip('Log intake'), findsOneWidget);
  });

  testWidgets('should not display log intake button for inactive medications',
      (tester) async {
    final medications = [
      Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        isActive: false,
        createdAt: DateTime.now(),
      ),
    ];
    when(mockViewModel.medications).thenReturn(medications);
    when(mockViewModel.showInactive).thenReturn(true);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.add_circle_outline), findsNothing);
  });

  testWidgets(
      'should display multiple log intake buttons for multiple active meds',
      (tester) async {
    final medications = [
      Medication(
        id: 1,
        profileId: 1,
        name: 'Aspirin',
        isActive: true,
        createdAt: DateTime.now(),
      ),
      Medication(
        id: 2,
        profileId: 1,
        name: 'Lisinopril',
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];
    when(mockViewModel.medications).thenReturn(medications);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    expect(find.byIcon(Icons.add_circle_outline), findsNWidgets(2));
  });
}

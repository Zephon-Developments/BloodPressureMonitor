import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/units_preference.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/views/weight/add_weight_view.dart';

import '../../test_mocks.mocks.dart';

void main() {
  late MockWeightService mockWeightService;
  late MockUnitsPreferenceService mockUnitsService;
  late WeightViewModel viewModel;
  late WeightEntry sampleEntry;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockWeightService = MockWeightService();
    mockUnitsService = MockUnitsPreferenceService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();

    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
    when(mockUnitsService.getUnitsPreference())
        .thenAnswer((_) async => const UnitsPreference());

    viewModel = WeightViewModel(
      mockWeightService,
      mockActiveProfileViewModel,
      mockUnitsService,
    );
    sampleEntry = WeightEntry(
      id: 5,
      profileId: 1,
      takenAt: DateTime(2025, 1, 3, 7),
      weightValue: 70,
      unit: WeightUnit.kg,
    );

    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <WeightEntry>[]);
  });

  testWidgets('requires weight value before submission', (tester) async {
    await _pumpAddWeightView(tester, viewModel);

    final saveButton = find.text('Save Weight Entry');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter a weight value'), findsOneWidget);
  });

  testWidgets('submits valid form and delegates to WeightService',
      (tester) async {
    when(mockWeightService.createWeightEntry(any))
        .thenAnswer((invocation) async {
      final WeightEntry entry =
          invocation.positionalArguments.first as WeightEntry;
      return entry.copyWith(id: 10);
    });
    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <WeightEntry>[sampleEntry]);

    await _pumpAddWeightView(tester, viewModel);

    final weightField = find.widgetWithText(TextFormField, 'Weight (kg)');
    await tester.enterText(weightField, '72.4');

    final saveButton = find.text('Save Weight Entry');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(mockWeightService.createWeightEntry(any)).called(1);
    expect(find.byType(AddWeightView), findsNothing);
  });

  testWidgets('prefills and updates existing entry', (tester) async {
    when(mockWeightService.updateWeightEntry(any)).thenAnswer(
      (invocation) async => invocation.positionalArguments.first as WeightEntry,
    );

    await _pumpAddWeightView(
      tester,
      viewModel,
      editingEntry: sampleEntry,
    );

    expect(find.text('Edit Weight Entry'), findsOneWidget);

    final weightField = find.widgetWithText(TextFormField, 'Weight (kg)');
    final textField = tester.widget<TextFormField>(weightField);
    expect(textField.controller!.text, '70.0');

    final saveButton = find.text('Update Weight Entry');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(mockWeightService.updateWeightEntry(any)).called(1);
  });
}

Future<void> _pumpAddWeightView(
  WidgetTester tester,
  WeightViewModel viewModel, {
  WeightEntry? editingEntry,
}) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<WeightViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        home: _RouteLauncher(
          child: AddWeightView(editingEntry: editingEntry),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

class _RouteLauncher extends StatefulWidget {
  const _RouteLauncher({required this.child});

  final Widget child;

  @override
  State<_RouteLauncher> createState() => _RouteLauncherState();
}

class _RouteLauncherState extends State<_RouteLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => widget.child),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/views/weight/add_weight_view.dart';

import '../../test_mocks.mocks.dart';

void main() {
  late MockWeightService mockWeightService;
  late WeightViewModel viewModel;
  late WeightEntry sampleEntry;

  setUp(() {
    mockWeightService = MockWeightService();
    viewModel = WeightViewModel(mockWeightService);
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

    final weightField = find.widgetWithText(TextFormField, 'Weight');
    await tester.enterText(weightField, '72.4');

    final saveButton = find.text('Save Weight Entry');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(mockWeightService.createWeightEntry(any)).called(1);
    expect(find.byType(AddWeightView), findsNothing);
  });
}

Future<void> _pumpAddWeightView(
  WidgetTester tester,
  WeightViewModel viewModel,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<WeightViewModel>.value(
      value: viewModel,
      child: const MaterialApp(
        home: _RouteLauncher(child: AddWeightView()),
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

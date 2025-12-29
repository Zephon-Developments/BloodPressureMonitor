import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/views/sleep/add_sleep_view.dart';

import '../../test_mocks.mocks.dart';

void main() {
  late MockSleepService mockSleepService;
  late SleepViewModel viewModel;
  late SleepEntry sampleEntry;

  setUp(() {
    mockSleepService = MockSleepService();
    viewModel = SleepViewModel(mockSleepService);
    sampleEntry = SleepEntry(
      id: 3,
      profileId: 1,
      startedAt: DateTime(2025, 1, 4, 22),
      endedAt: DateTime(2025, 1, 5, 6, 30),
      durationMinutes: 510,
      quality: 4,
    );

    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <SleepEntry>[]);
  });

  testWidgets('validates notes character limit', (tester) async {
    await _pumpAddSleepView(tester, viewModel);

    final notesField = find.widgetWithText(TextFormField, 'Notes');
    final longNote = List.generate(501, (_) => 'a').join();
    await tester.enterText(notesField, longNote);

    final saveButton = find.text('Save Sleep Session');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Notes cannot exceed 500 characters'), findsOneWidget);
  });

  testWidgets('submits sleep session and pops route', (tester) async {
    when(mockSleepService.createSleepEntry(any)).thenAnswer((invocation) async {
      final SleepEntry entry =
          invocation.positionalArguments.first as SleepEntry;
      return entry.copyWith(id: 11);
    });
    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <SleepEntry>[sampleEntry]);

    await _pumpAddSleepView(tester, viewModel);

    final saveButton = find.text('Save Sleep Session');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    verify(mockSleepService.createSleepEntry(any)).called(1);
    expect(find.byType(AddSleepView), findsNothing);
  });
}

Future<void> _pumpAddSleepView(
  WidgetTester tester,
  SleepViewModel viewModel,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<SleepViewModel>.value(
      value: viewModel,
      child: const MaterialApp(
        home: _RouteLauncher(child: AddSleepView()),
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

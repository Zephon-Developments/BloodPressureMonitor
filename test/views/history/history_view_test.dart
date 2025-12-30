import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:blood_pressure_monitor/views/history/history_view.dart';

import '../../test_mocks.mocks.dart';

void main() {
  late MockHistoryService mockHistoryService;
  late HistoryViewModel viewModel;
  final DateTime now = DateTime.utc(2025, 1, 15);

  ReadingGroup buildGroup(int id, DateTime start, String ids) {
    return ReadingGroup(
      id: id,
      profileId: 1,
      groupStartAt: start,
      windowMinutes: 30,
      avgSystolic: 120,
      avgDiastolic: 80,
      avgPulse: 70,
      memberReadingIds: ids,
    );
  }

  Reading buildReading(int id, DateTime takenAt) {
    return Reading(
      id: id,
      profileId: 1,
      systolic: 118,
      diastolic: 76,
      pulse: 66,
      takenAt: takenAt,
      localOffsetMinutes: 0,
    );
  }

  Widget createSubject({
    DateRangePickerBuilder? dateRangePicker,
    TagEditorBuilder? tagEditor,
  }) {
    return ChangeNotifierProvider<HistoryViewModel>.value(
      value: viewModel,
      child: MaterialApp(
        home: Scaffold(
          body: HistoryView(
            dateRangePicker: dateRangePicker,
            tagEditor: tagEditor,
          ),
        ),
      ),
    );
  }

  setUp(() {
    mockHistoryService = MockHistoryService();
    viewModel = HistoryViewModel(
      mockHistoryService,
      clock: () => now,
    );

    when(
      mockHistoryService.fetchRawHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <Reading>[]);
  });

  tearDown(() {
    viewModel.dispose();
  });

  testWidgets('preset chip reloads with expected window', (tester) async {
    final recordedStarts = <DateTime?>[];
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((invocation) async {
      recordedStarts.add(invocation.namedArguments[#start] as DateTime?);
      return <ReadingGroup>[];
    });

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('7 days'));
    await tester.pumpAndSettle();

    expect(recordedStarts.length, greaterThanOrEqualTo(2));
    expect(
      recordedStarts.last,
      equals(now.subtract(const Duration(days: 7))),
    );
  });

  testWidgets('mode toggle switches to raw list', (tester) async {
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <ReadingGroup>[]);

    final reading = buildReading(1, DateTime.utc(2025, 1, 10, 8));
    when(
      mockHistoryService.fetchRawHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <Reading>[reading]);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Raw'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pulse ${reading.pulse}'), findsOneWidget);
  });

  testWidgets('expanding a group shows child readings', (tester) async {
    final group = buildGroup(1, now.subtract(const Duration(days: 1)), '1,2');
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <ReadingGroup>[group]);

    when(mockHistoryService.fetchGroupMembers(group)).thenAnswer(
      (_) async => <Reading>[
        buildReading(10, now.subtract(const Duration(hours: 2))),
      ],
    );

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.text('2 readings'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.textContaining('118/76'), findsOneWidget);
    verify(mockHistoryService.fetchGroupMembers(group)).called(1);
  });

  testWidgets('scrolling near bottom triggers pagination', (tester) async {
    final firstPage = List<ReadingGroup>.generate(20, (index) {
      return buildGroup(
        index + 1,
        now.subtract(Duration(hours: index)),
        '${index + 1}',
      );
    });
    final secondPageGroup = buildGroup(
      21,
      now.subtract(const Duration(days: 2)),
      '1,2',
    );

    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((invocation) async {
      final DateTime? before = invocation.namedArguments[#before] as DateTime?;
      if (before == null) {
        return firstPage;
      }
      return <ReadingGroup>[secondPageGroup];
    });

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('2 readings'), findsOneWidget);
    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).called(2);
  });

  testWidgets('pull-to-refresh reloads history', (tester) async {
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <ReadingGroup>[]);

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    clearInteractions(mockHistoryService);

    await tester.drag(find.byType(ListView), const Offset(0, 200));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).called(1);
  });

  testWidgets('custom range picker applies selected dates', (tester) async {
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <ReadingGroup>[]);

    final desiredRange = DateTimeRange(
      start: DateTime(2025, 1, 1),
      end: DateTime(2025, 1, 7),
    );

    Future<DateTimeRange?> picker(
      BuildContext context,
      DateTimeRange initial,
    ) async {
      return desiredRange;
    }

    await tester.pumpWidget(
      createSubject(dateRangePicker: picker),
    );
    await tester.pumpAndSettle();

    clearInteractions(mockHistoryService);

    await tester.tap(
      find.widgetWithIcon(OutlinedButton, Icons.date_range),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: argThat(
          equals(DateTime.utc(2025, 1, 1)),
          named: 'start',
        ),
        end: argThat(
          equals(DateTime.utc(2025, 1, 7, 23, 59, 59)),
          named: 'end',
        ),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).called(1);
  });

  testWidgets('tag editor updates filters', (tester) async {
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async => <ReadingGroup>[]);

    Future<Set<String>?> tagEditor(
      BuildContext context,
      Set<String> current,
    ) async {
      return <String>{'fasting'};
    }

    await tester.pumpWidget(
      createSubject(tagEditor: tagEditor),
    );
    await tester.pumpAndSettle();

    clearInteractions(mockHistoryService);

    await tester.tap(
      find.widgetWithIcon(OutlinedButton, Icons.label),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: argThat(contains('fasting'), named: 'tags'),
      ),
    ).called(1);
  });

  testWidgets('error state shows retry and reloads history', (tester) async {
    var shouldThrow = true;
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer((_) async {
      if (shouldThrow) {
        throw Exception('db down');
      }
      return <ReadingGroup>[];
    });

    await tester.pumpWidget(createSubject());
    await tester.pumpAndSettle();

    expect(find.text('Retry'), findsOneWidget);

    shouldThrow = false;
    clearInteractions(mockHistoryService);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).called(1);
  });
}

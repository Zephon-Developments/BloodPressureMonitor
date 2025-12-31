import 'package:blood_pressure_monitor/models/history.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockHistoryService mockHistoryService;
  late HistoryViewModel viewModel;
  late MockActiveProfileViewModel mockActiveProfileViewModel;
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

  Reading buildReading(int id, DateTime timestamp) {
    return Reading(
      id: id,
      profileId: 1,
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      takenAt: timestamp,
      localOffsetMinutes: 0,
    );
  }

  setUp(() {
    mockHistoryService = MockHistoryService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
    viewModel = HistoryViewModel(
      mockHistoryService,
      mockActiveProfileViewModel,
      clock: () => now,
    );
  });

  test('loadInitial loads averaged groups', () async {
    final group = buildGroup(1, DateTime.utc(2025, 1, 10), '1,2');
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

    await viewModel.loadInitial();

    expect(viewModel.groups, hasLength(1));
    expect(viewModel.isLoading, isFalse);
    expect(viewModel.error, isNull);
  });

  test('loadMore appends additional groups', () async {
    const int pageSize = 20;
    final List<ReadingGroup> firstPage = List<ReadingGroup>.generate(
      pageSize,
      (int index) {
        final DateTime start = DateTime.utc(2025, 1, 12).subtract(
          Duration(hours: index),
        );
        return buildGroup(index + 1, start, '${index + 1}');
      },
    );
    final ReadingGroup nextGroup = buildGroup(
      pageSize + 1,
      DateTime.utc(2025, 1, 1),
      '${pageSize + 1}',
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
    ).thenAnswer((Invocation invocation) async {
      final DateTime? before = invocation.namedArguments[#before] as DateTime?;
      if (before == null) {
        return firstPage;
      }
      expect(before, equals(firstPage.last.groupStartAt));
      return <ReadingGroup>[nextGroup];
    });

    await viewModel.loadInitial();
    await viewModel.loadMore();

    expect(viewModel.groups, hasLength(pageSize + 1));
    expect(viewModel.groups.first.group.id, equals(1));
    expect(viewModel.groups.last.group.id, equals(pageSize + 1));
  });

  test('toggleGroupExpansion loads members once', () async {
    final group = buildGroup(1, DateTime.utc(2025, 1, 12), '1,2');
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
        buildReading(1, DateTime.utc(2025, 1, 12, 8)),
        buildReading(2, DateTime.utc(2025, 1, 12, 8, 20)),
      ],
    );

    await viewModel.loadInitial();
    await viewModel.toggleGroupExpansion(1);
    await viewModel.toggleGroupExpansion(1); // collapse
    await viewModel.toggleGroupExpansion(1); // expand again, reuse cache

    verify(mockHistoryService.fetchGroupMembers(group)).called(1);
    expect(viewModel.groups.first.children, isNotNull);
    expect(viewModel.groups.first.children, hasLength(2));
  });

  test('setViewMode switches to raw history', () async {
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

    when(
      mockHistoryService.fetchRawHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenAnswer(
      (_) async => <Reading>[
        buildReading(3, DateTime.utc(2025, 1, 9, 8)),
      ],
    );

    await viewModel.loadInitial();
    await viewModel.setViewMode(HistoryViewMode.raw);

    expect(viewModel.filters.viewMode, HistoryViewMode.raw);
    expect(viewModel.rawReadings, hasLength(1));
    expect(viewModel.groups, isEmpty);
  });

  test('loadInitial surfaces service errors', () async {
    when(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: anyNamed('tags'),
      ),
    ).thenThrow(Exception('db unavailable'));

    await viewModel.loadInitial();

    expect(viewModel.error, contains('Failed to load history'));
    expect(viewModel.isLoading, isFalse);
  });

  test('loadMore surfaces errors and resets loading flag', () async {
    const int pageSize = 20;
    final firstPage = List<ReadingGroup>.generate(pageSize, (index) {
      return buildGroup(
        index + 1,
        now.subtract(Duration(hours: index)),
        '${index + 1}',
      );
    });

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
      throw Exception('next page failed');
    });

    await viewModel.loadInitial();
    await viewModel.loadMore();

    expect(viewModel.error, contains('Failed to load more history'));
    expect(viewModel.isLoadingMore, isFalse);
    expect(viewModel.groups, hasLength(pageSize));
  });

  test('applyPreset updates filters with expected window', () async {
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

    await viewModel.applyPreset(HistoryRangePreset.sevenDays);

    expect(viewModel.activePreset, HistoryRangePreset.sevenDays);
    expect(
      viewModel.filters.startDate,
      equals(now.subtract(const Duration(days: 7))),
    );
    expect(viewModel.filters.endDate, equals(now));
  });

  test('setCustomRange normalizes bounds to full days', () async {
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

    final start = DateTime.utc(2025, 1, 1, 13, 45);
    final end = DateTime.utc(2025, 1, 3, 2, 30);
    await viewModel.setCustomRange(start, end);

    expect(viewModel.activePreset, HistoryRangePreset.custom);
    expect(viewModel.filters.startDate, equals(DateTime.utc(2025, 1, 1)));
    expect(
      viewModel.filters.endDate,
      equals(DateTime.utc(2025, 1, 3, 23, 59, 59)),
    );
  });

  test('updateTags normalizes values and triggers reload', () async {
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

    await viewModel.updateTags({'Fasting ', ' EVENING'});

    expect(viewModel.filters.tags, equals({'fasting', 'evening'}));
    verify(
      mockHistoryService.fetchGroupedHistory(
        profileId: anyNamed('profileId'),
        start: anyNamed('start'),
        end: anyNamed('end'),
        before: anyNamed('before'),
        limit: anyNamed('limit'),
        tags: argThat(
          containsAll(<String>['fasting', 'evening']),
          named: 'tags',
        ),
      ),
    ).called(1);
  });
}

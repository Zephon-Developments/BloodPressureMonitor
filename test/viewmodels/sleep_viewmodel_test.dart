import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockSleepService mockSleepService;
  late SleepViewModel viewModel;
  late SleepEntry sampleEntry;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockSleepService = MockSleepService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
    viewModel = SleepViewModel(mockSleepService, mockActiveProfileViewModel);
    sampleEntry = SleepEntry(
      id: 7,
      profileId: 1,
      startedAt: DateTime.parse('2025-01-01T22:00:00Z'),
      endedAt: DateTime.parse('2025-01-02T06:00:00Z'),
      durationMinutes: 480,
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

  test('loadEntries populates sessions on success', () async {
    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <SleepEntry>[sampleEntry]);

    await viewModel.loadEntries();

    expect(viewModel.entries, [sampleEntry]);
    expect(viewModel.error, isNull);
    expect(viewModel.isLoading, false);
  });

  test('saveSleepEntry creates session and reloads list', () async {
    when(mockSleepService.createSleepEntry(any)).thenAnswer((invocation) async {
      final SleepEntry entry =
          invocation.positionalArguments.first as SleepEntry;
      return entry.copyWith(id: 42);
    });
    when(
      mockSleepService.listSleepEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <SleepEntry>[sampleEntry]);

    final start = DateTime.parse('2025-01-05T22:30:00Z');
    final end = start.add(const Duration(hours: 7));

    final result = await viewModel.saveSleepEntry(
      start: start,
      end: end,
      quality: 3,
    );

    expect(result, isNull);
    expect(viewModel.entries, [sampleEntry]);
    verify(mockSleepService.createSleepEntry(any)).called(1);
  });

  test('saveSleepEntry surfaces validation errors', () async {
    when(mockSleepService.createSleepEntry(any)).thenThrow(
      ArgumentError('Duration invalid'),
    );

    final start = DateTime.parse('2025-01-05T22:30:00Z');
    final end = start.add(const Duration(hours: 2));
    final result = await viewModel.saveSleepEntry(start: start, end: end);

    expect(result, isNotNull);
    expect(viewModel.error, contains('Duration invalid'));
    expect(viewModel.isSubmitting, false);
  });

  test('deleteSleepEntry returns user facing message on failure', () async {
    when(mockSleepService.deleteSleepEntry(5)).thenThrow(Exception('db issue'));

    final error = await viewModel.deleteSleepEntry(5);

    expect(error, contains('Failed to delete sleep entry'));
    expect(viewModel.error, contains('Failed to delete sleep entry'));
  });
}

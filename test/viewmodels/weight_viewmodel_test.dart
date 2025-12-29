import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';

import '../test_mocks.mocks.dart';

void main() {
  late MockWeightService mockWeightService;
  late WeightViewModel viewModel;
  late WeightEntry sampleEntry;

  setUp(() {
    mockWeightService = MockWeightService();
    viewModel = WeightViewModel(mockWeightService);
    sampleEntry = WeightEntry(
      id: 1,
      profileId: 1,
      takenAt: DateTime.parse('2025-01-01T08:00:00Z'),
      weightValue: 72.5,
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

  test('loadEntries populates entries on success', () async {
    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <WeightEntry>[sampleEntry]);

    await viewModel.loadEntries();

    expect(viewModel.entries, [sampleEntry]);
    expect(viewModel.isLoading, false);
    expect(viewModel.error, isNull);
  });

  test('loadEntries captures service errors', () async {
    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenThrow(Exception('db failure'));

    await viewModel.loadEntries();

    expect(viewModel.error, contains('Failed to load weight entries'));
    expect(viewModel.entries, isEmpty);
  });

  test('saveWeightEntry creates entry and refreshes list', () async {
    when(mockWeightService.createWeightEntry(any))
        .thenAnswer((invocation) async {
      final WeightEntry entry =
          invocation.positionalArguments.first as WeightEntry;
      return entry.copyWith(id: 99);
    });
    when(
      mockWeightService.listWeightEntries(
        profileId: anyNamed('profileId'),
        from: anyNamed('from'),
        to: anyNamed('to'),
      ),
    ).thenAnswer((_) async => <WeightEntry>[sampleEntry]);

    final result = await viewModel.saveWeightEntry(
      weightValue: 70,
      unit: WeightUnit.kg,
      recordedAt: DateTime.parse('2025-01-02T07:00:00Z'),
    );

    expect(result, isNull);
    expect(viewModel.entries, [sampleEntry]);
    verify(mockWeightService.createWeightEntry(any)).called(1);
  });

  test('saveWeightEntry surfaces validation errors', () async {
    when(mockWeightService.createWeightEntry(any)).thenThrow(
      ArgumentError('Invalid weight entry'),
    );

    final result = await viewModel.saveWeightEntry(
      weightValue: 10,
      unit: WeightUnit.kg,
      recordedAt: DateTime.now(),
    );

    expect(result, isNotNull);
    expect(viewModel.error, contains('Invalid weight entry'));
    expect(viewModel.isSubmitting, false);
  });

  test('deleteWeightEntry returns user-friendly errors', () async {
    when(mockWeightService.deleteWeightEntry(1)).thenAnswer((_) async => false);

    final result = await viewModel.deleteWeightEntry(1);

    expect(result, 'Weight entry not found');
    expect(viewModel.error, 'Weight entry not found');
  });
}

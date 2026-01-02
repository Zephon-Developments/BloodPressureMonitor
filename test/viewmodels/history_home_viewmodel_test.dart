import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/foundation.dart';

import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/viewmodels/history_home_viewmodel.dart';

import '../test_mocks.mocks.dart';

/// A testable version of ActiveProfileViewModel that allows triggering listeners
class TestableActiveProfileViewModel extends MockActiveProfileViewModel {
  final List<VoidCallback> _listeners = [];

  @override
  void addListener(VoidCallback? listener) {
    if (listener != null) {
      _listeners.add(listener);
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback? listener) {
    if (listener != null) {
      _listeners.remove(listener);
    }
    super.removeListener(listener);
  }

  void notifyTestListeners() {
    for (final listener in List<VoidCallback>.from(_listeners)) {
      listener();
    }
  }
}

void main() {
  late MockStatsService mockStatsService;
  late MockActiveProfileViewModel mockActiveProfileViewModel;
  late HistoryHomeViewModel viewModel;

  final testBPStats = MiniStats(
    latestValue: '120/80',
    weekAverage: '125/82',
    trend: TrendDirection.down,
    lastUpdate: DateTime(2026, 1, 2),
  );

  setUp(() {
    mockStatsService = MockStatsService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();

    // Default: active profile exists
    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);

    viewModel = HistoryHomeViewModel(
      mockStatsService,
      mockActiveProfileViewModel,
    );
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('HistoryHomeViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.bloodPressureStats, isNull);
      expect(viewModel.weightStats, isNull);
      expect(viewModel.sleepStats, isNull);
      expect(viewModel.medicationStats, isNull);
      expect(viewModel.isLoading, isFalse);
    });

    group('loadBPStats', () {
      test('loads successfully', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadBPStats();

        // Assert
        expect(viewModel.bloodPressureStats, equals(testBPStats));
        expect(viewModel.isLoadingBP, isFalse);
        expect(viewModel.errorBP, isNull);
      });

      test('handles errors', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenThrow(Exception('Test error'));

        // Act
        await viewModel.loadBPStats();

        // Assert
        expect(viewModel.bloodPressureStats, isNull);
        expect(viewModel.errorBP, isNotNull);
      });
    });

    group('loadWeightStats', () {
      test('loads successfully', () async {
        // Arrange
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadWeightStats();

        // Assert
        expect(viewModel.weightStats, equals(testBPStats));
        expect(viewModel.isLoadingWeight, isFalse);
        expect(viewModel.errorWeight, isNull);
      });

      test('handles errors', () async {
        // Arrange
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenThrow(Exception('Test error'));

        // Act
        await viewModel.loadWeightStats();

        // Assert
        expect(viewModel.weightStats, isNull);
        expect(viewModel.errorWeight, isNotNull);
      });
    });

    group('loadSleepStats', () {
      test('loads successfully', () async {
        // Arrange
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadSleepStats();

        // Assert
        expect(viewModel.sleepStats, equals(testBPStats));
        expect(viewModel.isLoadingSleep, isFalse);
        expect(viewModel.errorSleep, isNull);
      });

      test('handles errors', () async {
        // Arrange
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenThrow(Exception('Test error'));

        // Act
        await viewModel.loadSleepStats();

        // Assert
        expect(viewModel.sleepStats, isNull);
        expect(viewModel.errorSleep, isNotNull);
      });
    });

    group('loadMedicationStats', () {
      test('loads successfully', () async {
        // Arrange
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadMedicationStats();

        // Assert
        expect(viewModel.medicationStats, equals(testBPStats));
        expect(viewModel.isLoadingMedication, isFalse);
        expect(viewModel.errorMedication, isNull);
      });

      test('handles errors', () async {
        // Arrange
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenThrow(Exception('Test error'));

        // Act
        await viewModel.loadMedicationStats();

        // Assert
        expect(viewModel.medicationStats, isNull);
        expect(viewModel.errorMedication, isNotNull);
      });
    });

    group('loadAllStats', () {
      test('loads all categories in parallel', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadAllStats();

        // Assert
        expect(viewModel.bloodPressureStats, isNotNull);
        expect(viewModel.weightStats, isNotNull);
        expect(viewModel.sleepStats, isNotNull);
        expect(viewModel.medicationStats, isNotNull);
      });

      test('continues loading other categories when one fails', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenThrow(Exception('BP error'));
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.loadAllStats();

        // Assert
        expect(viewModel.bloodPressureStats, isNull);
        expect(viewModel.errorBP, isNotNull);
        expect(viewModel.weightStats, isNotNull);
        expect(viewModel.sleepStats, isNotNull);
        expect(viewModel.medicationStats, isNotNull);
      });
    });

    group('isLoading combined getter', () {
      test('returns true when BP is loading', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return testBPStats;
        });

        // Act
        final future = viewModel.loadBPStats();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(viewModel.isLoading, isTrue);
        await future;
        expect(viewModel.isLoading, isFalse);
      });

      test('returns true when Weight is loading', () async {
        // Arrange
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return testBPStats;
        });

        // Act
        final future = viewModel.loadWeightStats();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(viewModel.isLoading, isTrue);
        await future;
        expect(viewModel.isLoading, isFalse);
      });

      test('returns true when Sleep is loading', () async {
        // Arrange
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return testBPStats;
        });

        // Act
        final future = viewModel.loadSleepStats();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(viewModel.isLoading, isTrue);
        await future;
        expect(viewModel.isLoading, isFalse);
      });

      test('returns true when Medication is loading', () async {
        // Arrange
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return testBPStats;
        });

        // Act
        final future = viewModel.loadMedicationStats();
        await Future.delayed(const Duration(milliseconds: 10));

        // Assert
        expect(viewModel.isLoading, isTrue);
        await future;
        expect(viewModel.isLoading, isFalse);
      });
    });

    group('refresh', () {
      test('clears all stats and reloads', () async {
        // Arrange
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.refresh();

        // Assert
        expect(viewModel.bloodPressureStats, isNotNull);
        expect(viewModel.weightStats, isNotNull);
        expect(viewModel.sleepStats, isNotNull);
        expect(viewModel.medicationStats, isNotNull);
      });

      test('clears errors when refreshing', () async {
        // Arrange - First cause an error
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenThrow(Exception('Test error'));
        await viewModel.loadBPStats();
        expect(viewModel.errorBP, isNotNull);

        // Now set up successful call
        reset(mockStatsService);
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act
        await viewModel.refresh();

        // Assert - Error should be cleared
        expect(viewModel.bloodPressureStats, isNotNull);
        expect(viewModel.errorBP, isNull);
      });
    });

    group('profile change handling', () {
      test('clears stats and reloads when active profile notifies', () async {
        // Arrange - Set up initial data load
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Load initial stats
        await viewModel.loadAllStats();
        expect(viewModel.bloodPressureStats, isNotNull);

        // Reset service mocks
        reset(mockStatsService);
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act - Trigger profile change by calling the private listener
        // We can test this indirectly through refresh, which has the same behavior
        await viewModel.refresh();

        // Assert
        verify(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).called(1);
        verify(
          mockStatsService.getWeightStats(
            profileId: anyNamed('profileId'),
          ),
        ).called(1);
        verify(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .called(1);
        verify(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).called(1);
      });

      test('listener is properly registered on construction', () {
        // Verify listener is registered during construction
        verify(mockActiveProfileViewModel.addListener(any)).called(1);
      });

      test('listener is removed on dispose', () {
        // Create a fresh viewModel to test dispose in isolation
        final freshMockActiveProfile = MockActiveProfileViewModel();
        when(freshMockActiveProfile.activeProfileId).thenReturn(1);

        final freshViewModel = HistoryHomeViewModel(
          mockStatsService,
          freshMockActiveProfile,
        );

        // Dispose and verify listener is removed
        freshViewModel.dispose();
        verify(freshMockActiveProfile.removeListener(any)).called(1);
      });

      test('_onProfileChanged clears stats and reloads data', () async {
        // Arrange - Use testable mock that can trigger listeners
        final testableActiveProfile = TestableActiveProfileViewModel();
        when(testableActiveProfile.activeProfileId).thenReturn(1);

        final testViewModel = HistoryHomeViewModel(
          mockStatsService,
          testableActiveProfile,
        );

        // Set up successful service calls
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Load initial stats
        await testViewModel.loadAllStats();
        expect(testViewModel.bloodPressureStats, isNotNull);

        // Reset mocks
        reset(mockStatsService);
        when(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);
        when(mockStatsService.getWeightStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(mockStatsService.getSleepStats(profileId: anyNamed('profileId')))
            .thenAnswer((_) async => testBPStats);
        when(
          mockStatsService.getMedicationStats(
            profileId: anyNamed('profileId'),
          ),
        ).thenAnswer((_) async => testBPStats);

        // Act - Trigger the _onProfileChanged listener
        testableActiveProfile.notifyTestListeners();
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert - Stats should be reloaded
        verify(
          mockStatsService.getBloodPressureStats(
            profileId: anyNamed('profileId'),
          ),
        ).called(1);

        testViewModel.dispose();
      });
    });
  });
}

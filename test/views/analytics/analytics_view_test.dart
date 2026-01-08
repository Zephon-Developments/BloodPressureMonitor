import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/views/analytics/analytics_view.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/time_range_selector.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/analytics_empty_state.dart';

import '../../viewmodels/analytics_viewmodel_test.mocks.dart';

void main() {
  group('AnalyticsView Widget Tests', () {
    late MockAnalyticsService mockService;
    late MockActiveProfileViewModel mockActiveProfileViewModel;
    late AnalyticsViewModel viewModel;

    setUp(() {
      mockService = MockAnalyticsService();
      mockActiveProfileViewModel = MockActiveProfileViewModel();

      when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
      when(mockActiveProfileViewModel.addListener(any)).thenReturn(null);
      when(mockActiveProfileViewModel.removeListener(any)).thenReturn(null);

      viewModel = AnalyticsViewModel(
        analyticsService: mockService,
        activeProfileViewModel: mockActiveProfileViewModel,
        clock: () => DateTime.utc(2025, 1, 10),
      );
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AnalyticsViewModel>.value(
            value: viewModel,
            child: const AnalyticsView(),
          ),
        ),
      );
    }

    testWidgets('shows TimeRangeSelector even when no data is present',
        (WidgetTester tester) async {
      // Setup: No data
      when(
        mockService.calculateStats(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return _emptyStats();
      });

      when(
        mockService.getChartData(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
        ),
      ).thenAnswer((_) async => _emptyChart());

      when(
        mockService.getChartDataSmoothed(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
        ),
      ).thenAnswer((_) async => _emptyChart());

      when(
        mockService.getDualAxisBpData(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
          smoothed: anyNamed('smoothed'),
        ),
      ).thenAnswer((_) async => _emptyDualAxis());

      await tester.pumpWidget(createWidget());
      // Trigger the post-frame callback
      await tester.pump();

      // Verify loading state shows selector
      expect(find.byType(TimeRangeSelector), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for the delayed mock to complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify empty state shows selector
      expect(find.byType(TimeRangeSelector), findsOneWidget);
      expect(find.byType(AnalyticsEmptyState), findsOneWidget);
    });

    testWidgets('shows TimeRangeSelector even when error occurs',
        (WidgetTester tester) async {
      // Setup: Error
      when(
        mockService.calculateStats(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        ),
      ).thenAnswer((_) => Future.error(Exception('Fetch failed')));

      // Stub other fetches to return successful empty data
      when(
        mockService.getChartData(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
        ),
      ).thenAnswer((_) async => _emptyChart());

      when(
        mockService.getChartDataSmoothed(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
        ),
      ).thenAnswer((_) async => _emptyChart());

      when(
        mockService.getDualAxisBpData(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
          smoothed: anyNamed('smoothed'),
        ),
      ).thenAnswer((_) async => _emptyDualAxis());

      await tester.pumpWidget(createWidget());

      // Manually trigger loadData and wait for it to complete
      await viewModel.loadData();

      // Verify viewmodel state
      expect(viewModel.error, equals('Failed to load analytics data'));

      await tester.pump();

      // Verify error state shows selector
      expect(find.byType(TimeRangeSelector), findsOneWidget);
      expect(find.text('Failed to load analytics data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });
}

HealthStats _emptyStats() {
  return HealthStats(
    minSystolic: 0,
    avgSystolic: 0,
    maxSystolic: 0,
    minDiastolic: 0,
    avgDiastolic: 0,
    maxDiastolic: 0,
    minPulse: 0,
    avgPulse: 0,
    maxPulse: 0,
    systolicStdDev: 0,
    systolicCv: 0,
    diastolicStdDev: 0,
    diastolicCv: 0,
    pulseStdDev: 0,
    pulseCv: 0,
    split: const MorningEveningSplit(
      morning: ReadingBucketStats(
        count: 0,
        minSystolic: 0,
        avgSystolic: 0,
        maxSystolic: 0,
        minDiastolic: 0,
        avgDiastolic: 0,
        maxDiastolic: 0,
        minPulse: 0,
        avgPulse: 0,
        maxPulse: 0,
      ),
      evening: ReadingBucketStats(
        count: 0,
        minSystolic: 0,
        avgSystolic: 0,
        maxSystolic: 0,
        minDiastolic: 0,
        avgDiastolic: 0,
        maxDiastolic: 0,
        minPulse: 0,
        avgPulse: 0,
        maxPulse: 0,
      ),
      morningCount: 0,
      eveningCount: 0,
    ),
    totalReadings: 0,
    periodStart: DateTime.utc(2025, 1, 1),
    periodEnd: DateTime.utc(2025, 1, 7),
  );
}

ChartDataSet _emptyChart() {
  return ChartDataSet(
    systolicPoints: [],
    diastolicPoints: [],
    pulsePoints: [],
    minDate: DateTime.utc(2025, 1, 1),
    maxDate: DateTime.utc(2025, 1, 7),
  );
}

DualAxisBpData _emptyDualAxis() {
  final now = DateTime.utc(2025, 1, 1);
  return DualAxisBpData(
    timestamps: [],
    systolic: [],
    diastolic: [],
    minDate: now,
    maxDate: now,
  );
}

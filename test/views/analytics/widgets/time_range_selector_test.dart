import 'package:blood_pressure_monitor/utils/time_range.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/time_range_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'time_range_selector_test.mocks.dart';

@GenerateMocks([AnalyticsViewModel])
void main() {
  group('TimeRangeSelector Accessibility Tests', () {
    late MockAnalyticsViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockAnalyticsViewModel();
      when(mockViewModel.selectedRange).thenReturn(TimeRange.sevenDays);
      when(mockViewModel.showSleepOverlay).thenReturn(false);
      when(
        mockViewModel.loadData(
          forceRefresh: anyNamed('forceRefresh'),
          forceOverlayRefresh: anyNamed('forceOverlayRefresh'),
        ),
      ).thenAnswer((_) async => {});
    });

    Widget buildTestWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<AnalyticsViewModel>.value(
            value: mockViewModel,
            child: const TimeRangeSelector(),
          ),
        ),
      );
    }

    testWidgets('has semantic label for screen readers', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify container semantic label exists
      final semantics = tester.getSemantics(find.byType(TimeRangeSelector));
      expect(semantics.label, contains('Time range selector'));
    });

    testWidgets('individual segments are accessible to screen readers',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify that all time range segments are discoverable by semantics
      // This ensures excludeSemantics is NOT blocking segment accessibility
      for (final range in TimeRange.values) {
        expect(
          find.bySemanticsLabel(range.label),
          findsOneWidget,
          reason: 'Segment "${range.label}" should be accessible',
        );
      }
    });

    testWidgets('works with large text scaling at 2.0x', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
            child: Scaffold(
              body: ChangeNotifierProvider<AnalyticsViewModel>.value(
                value: mockViewModel,
                child: const TimeRangeSelector(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render without overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(TimeRangeSelector), findsOneWidget);
    });

    testWidgets('all segments are accessible', (tester) async {
      await tester.pumpWidget(buildTestWidget());

      // Verify all time range buttons are present
      for (final range in TimeRange.values) {
        expect(find.text(range.label), findsOneWidget);
      }
    });
  });
}

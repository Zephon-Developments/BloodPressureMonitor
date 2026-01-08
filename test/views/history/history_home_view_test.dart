import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/viewmodels/history_home_viewmodel.dart';
import 'package:blood_pressure_monitor/views/history/history_home_view.dart';

@GenerateMocks([HistoryHomeViewModel])
import 'history_home_view_test.mocks.dart';

void main() {
  late MockHistoryHomeViewModel mockViewModel;

  final testBPStats = MiniStats(
    latestValue: '120/80',
    weekAverage: '125/82',
    trend: TrendDirection.down,
    lastUpdate: DateTime(2026, 1, 2),
  );

  final testWeightStats = MiniStats(
    latestValue: '70 kg',
    weekAverage: '71 kg',
    trend: TrendDirection.down,
    lastUpdate: DateTime(2026, 1, 2),
  );

  setUp(() {
    mockViewModel = MockHistoryHomeViewModel();

    // Default state - no data loaded yet
    when(mockViewModel.bloodPressureStats).thenReturn(null);
    when(mockViewModel.weightStats).thenReturn(null);
    when(mockViewModel.sleepStats).thenReturn(null);
    when(mockViewModel.medicationStats).thenReturn(null);

    when(mockViewModel.isLoadingBP).thenReturn(false);
    when(mockViewModel.isLoadingWeight).thenReturn(false);
    when(mockViewModel.isLoadingSleep).thenReturn(false);
    when(mockViewModel.isLoadingMedication).thenReturn(false);
    when(mockViewModel.isLoading).thenReturn(false);

    when(mockViewModel.errorBP).thenReturn(null);
    when(mockViewModel.errorWeight).thenReturn(null);
    when(mockViewModel.errorSleep).thenReturn(null);
    when(mockViewModel.errorMedication).thenReturn(null);

    when(mockViewModel.loadAllStats()).thenAnswer((_) async => {});
    when(mockViewModel.refresh()).thenAnswer((_) async => {});
  });

  Widget createTestWidget() {
    return MaterialApp(
      home: ChangeNotifierProvider<HistoryHomeViewModel>.value(
        value: mockViewModel,
        child: const HistoryHomeView(),
      ),
    );
  }

  group('HistoryHomeView', () {
    testWidgets('renders app bar with correct title',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('History'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('displays all 4 collapsible sections',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
      expect(find.text('Medication'), findsOneWidget);
    });

    testWidgets('loads all stats on init', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      verify(mockViewModel.loadAllStats()).called(1);
    });

    testWidgets('displays "No data" when stats are null',
        (WidgetTester tester) async {
      // Arrange - mockViewModel already returns null for all stats

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No data'), findsNWidgets(4)); // One for each section
    });

    testWidgets('shows loading indicator when loading',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.isLoadingBP).thenReturn(true);
      when(mockViewModel.isLoading).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester
          .pump(); // Use pump() instead of pumpAndSettle() for loading states

      // Assert
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('displays stats when data is available',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.bloodPressureStats).thenReturn(testBPStats);
      when(mockViewModel.weightStats).thenReturn(testWeightStats);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert - MiniStatsDisplay widgets should be present
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // Verify no "No data" text for BP and Weight
      expect(
        find.text('No data'),
        findsNWidgets(2),
      ); // Only for Sleep and Medication
    });

    testWidgets('shows error icon when there is an error',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.errorBP).thenReturn('Failed to load BP stats');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.error_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('pull-to-refresh triggers refresh',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Assert
      verify(mockViewModel.refresh()).called(1);
    });

    testWidgets('expanding section shows full content',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.bloodPressureStats).thenReturn(testBPStats);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap to expand Blood Pressure section
      await tester.tap(find.text('Blood Pressure'));
      await tester.pumpAndSettle();

      // Assert - "View Full History" button should be visible
      expect(find.text('View Full History'), findsAtLeastNWidgets(1));
    });

    testWidgets('View Full History button is visible when section expanded',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.bloodPressureStats).thenReturn(testBPStats);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand BP section
      await tester.tap(find.text('Blood Pressure'));
      await tester.pumpAndSettle();

      // Assert - Button is visible
      expect(find.text('View Full History'), findsAtLeastNWidgets(1));
    });

    testWidgets('shows empty state message when expanded with no data',
        (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand Weight section
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No data available'), findsOneWidget);
      expect(find.textContaining('Start tracking'), findsOneWidget);
    });

    testWidgets('shows error message when expanded with error',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.errorWeight).thenReturn('Failed to load weight stats');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand Weight section
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load weight stats'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsAtLeastNWidgets(1));
    });

    testWidgets('shows loading indicator when expanded while loading',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.isLoadingSleep).thenReturn(true);
      when(mockViewModel.isLoading).thenReturn(true);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Use pump() for loading states

      // Expand Sleep section
      await tester.tap(find.text('Sleep'));
      await tester.pump(); // Use pump() for loading states

      // Assert
      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
    });

    testWidgets('all sections have correct icons', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget); // BP
      expect(find.byIcon(Icons.monitor_weight), findsOneWidget); // Weight
      expect(find.byIcon(Icons.bedtime), findsOneWidget); // Sleep
      expect(find.byIcon(Icons.medication), findsOneWidget); // Medication
    });

    testWidgets('handles multiple sections expanded simultaneously',
        (WidgetTester tester) async {
      // Arrange
      when(mockViewModel.bloodPressureStats).thenReturn(testBPStats);
      when(mockViewModel.weightStats).thenReturn(testWeightStats);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Expand BP section
      await tester.tap(find.text('Blood Pressure'));
      await tester.pumpAndSettle();

      // Expand Weight section
      await tester.tap(find.text('Weight'));
      await tester.pumpAndSettle();

      // Assert - both sections should show "View Full History" button
      expect(find.text('View Full History'), findsNWidgets(2));
    });
  });
}

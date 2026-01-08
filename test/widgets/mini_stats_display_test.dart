import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/widgets/mini_stats_display.dart';

void main() {
  group('MiniStatsDisplay', () {
    testWidgets('displays latest value correctly', (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '128/82',
        weekAverage: '130/85',
        trend: TrendDirection.stable,
        lastUpdate: DateTime.now(),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('128/82'), findsOneWidget);
    });

    testWidgets('displays 7-day average correctly', (tester) async {
      // Arrange
      const stats = MiniStats(
        latestValue: '75 kg',
        weekAverage: '76 kg',
        trend: TrendDirection.down,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'Weight',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('76 kg'), findsOneWidget);
      expect(find.textContaining('7-day avg:'), findsOneWidget);
    });

    testWidgets('displays values without trend indicators (zero inference)',
        (tester) async {
      // Arrange - test with various trend directions
      const statsUp = MiniStats(
        latestValue: '140/90',
        weekAverage: '130/85',
        trend: TrendDirection.up,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: statsUp,
              metricType: 'BP',
            ),
          ),
        ),
      );

      // Assert - NO trend indicators should be present
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
      expect(find.byIcon(Icons.trending_flat), findsNothing);
      expect(find.text('Increasing'), findsNothing);
      expect(find.text('Decreasing'), findsNothing);
      // Should only show the data values
      expect(find.text('140/90'), findsOneWidget);
      expect(find.textContaining('7-day avg:'), findsOneWidget);
    });

    testWidgets('compact mode renders differently than normal mode',
        (tester) async {
      // Arrange
      const stats = MiniStats(
        latestValue: '128/82',
        weekAverage: '130/85',
        trend: TrendDirection.down,
      );

      // Act - normal mode
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
              compact: false,
            ),
          ),
        ),
      );

      // Assert - normal mode shows labels, no trend indicators
      expect(find.text('Latest: '), findsOneWidget);
      expect(find.textContaining('7-day avg:'), findsOneWidget);
      expect(find.byIcon(Icons.trending_down), findsNothing);

      // Act - compact mode
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
              compact: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - compact mode doesn't show labels
      expect(find.text('Latest: '), findsNothing);
      expect(find.textContaining('7-day avg:'), findsNothing);
      // But still shows the value
      expect(find.text('128/82'), findsOneWidget);
    });

    testWidgets('handles null lastUpdate gracefully', (tester) async {
      // Arrange
      const stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '128/83',
        trend: TrendDirection.stable,
        lastUpdate: null,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );

      // Assert - no "Updated" text should appear
      expect(find.textContaining('Updated'), findsNothing);
    });

    testWidgets('displays lastUpdate when provided', (tester) async {
      // Arrange
      final now = DateTime.now();
      final stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '128/83',
        trend: TrendDirection.stable,
        lastUpdate: now.subtract(const Duration(hours: 2)),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );

      // Assert
      expect(find.textContaining('Updated'), findsOneWidget);
      expect(find.textContaining('hr ago'), findsOneWidget);
    });

    testWidgets('accessibility semantics are correct', (tester) async {
      // Arrange
      const stats = MiniStats(
        latestValue: '128/82',
        weekAverage: '130/85',
        trend: TrendDirection.down,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );

      // Assert - verify semantic label is present (no trend info)
      expect(
        find.bySemanticsLabel(
          'Latest: 128/82, 7-day average: 130/85',
        ),
        findsOneWidget,
      );
    });

    testWidgets('compact mode has accessibility semantics', (tester) async {
      // Arrange
      const stats = MiniStats(
        latestValue: '75 kg',
        weekAverage: '76 kg',
        trend: TrendDirection.up,
      );

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'Weight',
              compact: true,
            ),
          ),
        ),
      );

      // Assert - verify semantic label is present (no trend info)
      expect(
        find.bySemanticsLabel(
          'Latest: 75 kg, 7-day average: 76 kg',
        ),
        findsOneWidget,
      );
    });

    testWidgets('formats recent updates correctly', (tester) async {
      // Arrange - test various time differences
      final now = DateTime.now();

      // Test 30 minutes ago
      var stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '128/83',
        trend: TrendDirection.stable,
        lastUpdate: now.subtract(const Duration(minutes: 30)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );

      expect(find.textContaining('min ago'), findsOneWidget);

      // Test yesterday
      stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '128/83',
        trend: TrendDirection.stable,
        lastUpdate: now.subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Updated yesterday'), findsOneWidget);
    });
  });
}

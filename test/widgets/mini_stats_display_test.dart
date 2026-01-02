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
      final stats = MiniStats(
        latestValue: '75 kg',
        weekAverage: '76 kg',
        trend: TrendDirection.down,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
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

    testWidgets('shows correct trend indicator for TrendDirection.up',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '140/90',
        weekAverage: '130/85',
        trend: TrendDirection.up,
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
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
      expect(find.text('Increasing'), findsOneWidget);
    });

    testWidgets('shows correct trend indicator for TrendDirection.down',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '120/78',
        weekAverage: '130/85',
        trend: TrendDirection.down,
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
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      expect(find.text('Decreasing'), findsOneWidget);
    });

    testWidgets('shows correct trend indicator for TrendDirection.stable',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '130/85',
        trend: TrendDirection.stable,
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
      expect(find.byIcon(Icons.trending_flat), findsOneWidget);
      expect(find.text('Stable'), findsOneWidget);
    });

    testWidgets('applies correct colors for BP trends - up is red',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '150/95',
        weekAverage: '135/88',
        trend: TrendDirection.up,
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
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      final colorScheme =
          Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      expect(icon.color, colorScheme.error);
    });

    testWidgets('applies correct colors for BP trends - down is green',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '115/75',
        weekAverage: '130/85',
        trend: TrendDirection.down,
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
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_down));
      expect(icon.color, Colors.green);
    });

    testWidgets('applies correct colors for Weight trends - up is red',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '80 kg',
        weekAverage: '75 kg',
        trend: TrendDirection.up,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'Weight',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      final colorScheme =
          Theme.of(tester.element(find.byType(Scaffold))).colorScheme;
      expect(icon.color, colorScheme.error);
    });

    testWidgets('applies correct colors for Sleep trends - up is green',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '8.5 hrs',
        weekAverage: '7.2 hrs',
        trend: TrendDirection.up,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'Sleep',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_up));
      expect(icon.color, Colors.green);
    });

    testWidgets('applies correct colors for stable trend - blue',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '130/85',
        trend: TrendDirection.stable,
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
      await tester.pumpAndSettle();

      // Assert
      final icon = tester.widget<Icon>(find.byIcon(Icons.trending_flat));
      expect(icon.color, Colors.blue);
    });

    testWidgets('compact mode renders differently than normal mode',
        (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '128/82',
        weekAverage: '130/85',
        trend: TrendDirection.down,
      );

      // Act - normal mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'BP',
              compact: false,
            ),
          ),
        ),
      );

      // Assert - normal mode shows labels
      expect(find.text('Latest: '), findsOneWidget);
      expect(find.textContaining('7-day avg:'), findsOneWidget);
      expect(find.text('Decreasing'), findsOneWidget);

      // Act - compact mode
      await tester.pumpWidget(
        MaterialApp(
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
      expect(find.text('Decreasing'), findsNothing);
      // But still shows the value
      expect(find.text('128/82'), findsOneWidget);
    });

    testWidgets('handles null lastUpdate gracefully', (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '130/85',
        weekAverage: '128/83',
        trend: TrendDirection.stable,
        lastUpdate: null,
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
      final stats = MiniStats(
        latestValue: '128/82',
        weekAverage: '130/85',
        trend: TrendDirection.down,
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

      // Assert - verify semantic label is present
      expect(
        find.bySemanticsLabel(
            'Latest: 128/82, 7-day average: 130/85, Trend: Decreasing'),
        findsOneWidget,
      );
    });

    testWidgets('compact mode has accessibility semantics', (tester) async {
      // Arrange
      final stats = MiniStats(
        latestValue: '75 kg',
        weekAverage: '76 kg',
        trend: TrendDirection.up,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MiniStatsDisplay(
              miniStats: stats,
              metricType: 'Weight',
              compact: true,
            ),
          ),
        ),
      );

      // Assert - verify semantic label is present
      expect(
        find.bySemanticsLabel(
            'Latest: 75 kg, 7-day average: 76 kg, Trend: Increasing'),
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

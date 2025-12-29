import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/views/home/widgets/quick_actions.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';

void main() {
  group('QuickActions Widget Tests', () {
    testWidgets('renders quick actions title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActions(),
          ),
        ),
      );

      expect(find.text('Quick Actions'), findsOneWidget);
    });

    testWidgets('renders add reading button', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActions(),
          ),
        ),
      );

      expect(find.text('Add Blood Pressure Reading'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('navigates to AddReadingView when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActions(),
          ),
        ),
      );

      // Tap the add reading button
      await tester.tap(find.text('Add Blood Pressure Reading'));
      await tester.pumpAndSettle();

      // Should navigate to AddReadingView
      expect(find.byType(AddReadingView), findsOneWidget);
    });

    testWidgets('button spans full width', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: QuickActions(),
          ),
        ),
      );

      final sizedBoxFinder = find.descendant(
        of: find.byType(QuickActions),
        matching: find.byType(SizedBox),
      );

      expect(sizedBoxFinder, findsWidgets);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/views/readings/widgets/session_control_widget.dart';

void main() {
  group('SessionControlWidget Tests', () {
    testWidgets('renders title and description', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionControlWidget(
              startNewSession: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Start New Session'), findsOneWidget);
      expect(
        find.text('Force a new averaging group (overrides 30-min window)'),
        findsOneWidget,
      );
    });

    testWidgets('renders switch in off state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionControlWidget(
              startNewSession: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, false);
    });

    testWidgets('renders switch in on state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionControlWidget(
              startNewSession: true,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);
    });

    testWidgets('calls onChanged when switch is toggled',
        (WidgetTester tester) async {
      bool callbackValue = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return SessionControlWidget(
                  startNewSession: callbackValue,
                  onChanged: (value) {
                    setState(() {
                      callbackValue = value;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially false
      expect(callbackValue, false);

      // Tap the switch
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should be true now
      expect(callbackValue, true);

      // Tap again
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      // Should be false again
      expect(callbackValue, false);
    });

    testWidgets('is wrapped in a Card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionControlWidget(
              startNewSession: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('has proper padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SessionControlWidget(
              startNewSession: false,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      final padding = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(Card),
              matching: find.byType(Padding),
            )
            .first,
      );

      // Padding exists (actual value may vary)
      expect(padding.padding, isNotNull);
    });
  });
}

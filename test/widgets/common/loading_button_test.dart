import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';

void main() {
  group('LoadingButton Widget Tests', () {
    testWidgets('displays child text when not loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () {},
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      expect(find.text('Submit'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator when loading',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: null,
              isLoading: true,
              child: Text('Submit'),
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('disables button while loading', (WidgetTester tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () {
                wasCalled = true;
              },
              isLoading: true,
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      // Should be disabled
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);

      // Tap should not trigger callback
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(wasCalled, isFalse);
    });

    testWidgets('respects isLoading parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: null,
              isLoading: true,
              child: Text('Submit'),
            ),
          ),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });

    testWidgets('disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: null,
              child: Text('Submit'),
            ),
          ),
        ),
      );

      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('calls onPressed when tapped', (WidgetTester tester) async {
      bool wasCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingButton(
              onPressed: () async {
                wasCalled = true;
              },
              child: const Text('Submit'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(wasCalled, isTrue);
    });
  });
}

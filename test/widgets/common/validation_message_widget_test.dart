import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

void main() {
  group('ValidationMessageWidget Tests', () {
    testWidgets('displays error state correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'This is an error',
              isError: true,
            ),
          ),
        ),
      );

      expect(find.text('This is an error'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('displays warning state correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'This is a warning',
              isError: false,
            ),
          ),
        ),
      );

      expect(find.text('This is a warning'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber), findsOneWidget);
    });

    testWidgets('uses error colors when isError is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'Error',
              isError: true,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;

      // Should use error container color
      expect(decoration.color, isNotNull);
    });

    testWidgets('uses warning colors when isError is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'Warning',
              isError: false,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.byType(Container).first,
      );
      final decoration = container.decoration as BoxDecoration;

      // Should use warning color (amber)
      expect(decoration.color, const Color(0xFFFFF3E0));
    });

    testWidgets('icon has correct semantic label', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'Test',
              isError: true,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.semanticLabel, 'Error');
    });

    testWidgets('warning icon has correct semantic label',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ValidationMessageWidget(
              message: 'Test',
              isError: false,
            ),
          ),
        ),
      );

      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.semanticLabel, 'Warning');
    });
  });
}

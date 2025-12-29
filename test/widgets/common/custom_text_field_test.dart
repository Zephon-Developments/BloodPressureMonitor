import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';

void main() {
  group('CustomTextField Widget Tests', () {
    testWidgets('displays label and helper text', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test Label',
              helperText: 'Test Helper',
              controller: TextEditingController(),
            ),
          ),
        ),
      );

      expect(find.text('Test Label'), findsOneWidget);
      expect(find.text('Test Helper'), findsOneWidget);
    });

    testWidgets('displays error text when provided',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: TextEditingController(),
              errorText: 'Error message',
            ),
          ),
        ),
      );

      expect(find.text('Error message'), findsOneWidget);
    });

    testWidgets('calls onChanged when text changes',
        (WidgetTester tester) async {
      String? changedValue;
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: controller,
              onChanged: (value) {
                changedValue = value;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'New Value');
      expect(changedValue, 'New Value');
    });

    testWidgets('respects enabled parameter', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: TextEditingController(),
              enabled: false,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, isFalse);
    });

    testWidgets('applies numeric keyboard when specified',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: TextEditingController(),
              keyboardType: TextInputType.number,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.number);
    });

    testWidgets('respects maxLines and minLines', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: TextEditingController(),
              maxLines: 5,
              minLines: 2,
            ),
          ),
        ),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.maxLines, 5);
      expect(textField.minLines, 2);
    });

    testWidgets('applies inputFormatters when provided',
        (WidgetTester tester) async {
      final controller = TextEditingController();
      final formatters = [
        FilteringTextInputFormatter.digitsOnly,
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTextField(
              label: 'Test',
              controller: controller,
              inputFormatters: formatters,
            ),
          ),
        ),
      );

      // Try to enter non-digits
      await tester.enterText(find.byType(TextField), 'abc123');
      // Only digits should remain
      expect(controller.text, '123');
    });
  });
}

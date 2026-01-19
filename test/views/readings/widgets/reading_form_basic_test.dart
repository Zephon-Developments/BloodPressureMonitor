import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/views/readings/widgets/reading_form_basic.dart';

void main() {
  group('ReadingFormBasic Widget Tests', () {
    late TextEditingController systolicController;
    late TextEditingController diastolicController;
    late TextEditingController pulseController;
    late DateTime selectedDateTime;
    bool dateTimeChangeRequested = false;

    setUp(() {
      systolicController = TextEditingController();
      diastolicController = TextEditingController();
      pulseController = TextEditingController();
      selectedDateTime = DateTime(2025, 12, 29, 10, 30);
      dateTimeChangeRequested = false;
    });

    tearDown(() {
      systolicController.dispose();
      diastolicController.dispose();
      pulseController.dispose();
    });

    Widget createWidget() {
      return MaterialApp(
        home: Scaffold(
          body: ReadingFormBasic(
            systolicController: systolicController,
            diastolicController: diastolicController,
            pulseController: pulseController,
            selectedDateTime: selectedDateTime,
            onDateTimeChanged: () {
              dateTimeChangeRequested = true;
            },
          ),
        ),
      );
    }

    testWidgets('renders all labels', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Systolic'), findsOneWidget);
      expect(find.text('Diastolic'), findsOneWidget);
      expect(find.text('Pulse'), findsOneWidget);
    });

    testWidgets('systolic field accepts numeric input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Systolic'),
        '120',
      );

      expect(systolicController.text, '120');
    });

    testWidgets('diastolic field accepts numeric input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Diastolic'),
        '80',
      );

      expect(diastolicController.text, '80');
    });

    testWidgets('pulse field accepts numeric input',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Pulse'),
        '70',
      );

      expect(pulseController.text, '70');
    });

    testWidgets('displays selected date and time', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Should have a button to select date/time
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('triggers date time picker when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Find and tap the calendar button
      await tester.tap(find.byIcon(Icons.calendar_today));
      await tester.pump();

      expect(dateTimeChangeRequested, true);
    });

    testWidgets('shows helper text for fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('70-250 mmHg'), findsOneWidget);
      expect(find.text('40-150 mmHg'), findsOneWidget);
      expect(find.text('30-200 bpm'), findsOneWidget);
    });

    testWidgets('fields use responsive wrap layout for BP',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      final wrapFinder = find.ancestor(
        of: find.widgetWithText(TextField, 'Systolic'),
        matching: find.byType(Wrap),
      );

      expect(wrapFinder, findsOneWidget);

      final wrap = tester.widget<Wrap>(wrapFinder);
      expect(wrap.spacing, 16);
      expect(wrap.runSpacing, 16);
      expect(wrap.children.length, 4);
    });
  });
}

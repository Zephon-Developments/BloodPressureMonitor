import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';
import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

@GenerateMocks([BloodPressureViewModel])
import 'add_reading_view_test.mocks.dart';

void main() {
  group('AddReadingView Widget Tests', () {
    late MockBloodPressureViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockBloodPressureViewModel();
      when(
        mockViewModel.addReading(
          any,
          confirmOverride: anyNamed('confirmOverride'),
        ),
      ).thenAnswer((_) async => const ValidationResult.valid());
    });

    Widget createWidget() {
      return ChangeNotifierProvider<BloodPressureViewModel>.value(
        value: mockViewModel,
        child: const MaterialApp(
          home: AddReadingView(),
        ),
      );
    }

    testWidgets('renders app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Add Reading'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders all form fields', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Basic fields
      expect(find.text('Systolic'), findsOneWidget);
      expect(find.text('Diastolic'), findsOneWidget);
      expect(find.text('Pulse'), findsOneWidget);

      // DateTime button
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('shows advanced section when expanded',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Find and tap the Advanced section
      await tester.tap(find.text('Advanced Options'));
      await tester.pumpAndSettle();

      // Advanced fields should be visible
      expect(find.text('Arm'), findsOneWidget);
      expect(find.text('Posture'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
    });

    testWidgets(
      'validates empty form submission',
      (WidgetTester tester) async {
        await tester.pumpWidget(createWidget());

        // Try to submit without filling fields
        await tester.tap(find.byType(LoadingButton));
        await tester.pump();

        // Should show validation errors (form validation prevents submission)
        // ViewModel should not be called
        verifyNever(
          mockViewModel.addReading(
            any,
            confirmOverride: anyNamed('confirmOverride'),
          ),
        );

        // Verify validation error messages are displayed
        expect(
          find.text('Required'),
          findsNWidgets(3),
        ); // Systolic, Diastolic, Pulse
      },
    );

    testWidgets('submits valid reading successfully',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '80',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '70',
      );

      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Verify submission
      verify(mockViewModel.addReading(any, confirmOverride: false)).called(1);
    });

    testWidgets('shows warning confirmation for out-of-range values',
        (WidgetTester tester) async {
      // Setup warning result
      when(mockViewModel.addReading(any, confirmOverride: false)).thenAnswer(
        (_) async => const ValidationResult.warning(
          'Systolic is higher than normal range',
        ),
      );

      await tester.pumpWidget(createWidget());

      // Enter high systolic value
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '160',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '90',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '75',
      );

      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Should show override confirmation
      expect(find.text('Override Confirmation Required'), findsOneWidget);
      expect(find.text('Confirm Override'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancels override confirmation', (WidgetTester tester) async {
      when(mockViewModel.addReading(any, confirmOverride: false)).thenAnswer(
        (_) async => const ValidationResult.warning(
          'Systolic is higher than normal range',
        ),
      );

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '160',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '90',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '75',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Confirmation should be hidden
      expect(find.text('Override Confirmation Required'), findsNothing);
    });

    testWidgets('confirms override and submits', (WidgetTester tester) async {
      when(mockViewModel.addReading(any, confirmOverride: false)).thenAnswer(
        (_) async => const ValidationResult.warning(
          'Systolic is higher than normal range',
        ),
      );
      when(mockViewModel.addReading(any, confirmOverride: true))
          .thenAnswer((_) async => const ValidationResult.valid());

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '160',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '90',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '75',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Confirm override
      await tester.tap(find.text('Confirm Override'));
      await tester.pumpAndSettle();

      // Should call with confirmOverride: true
      verify(mockViewModel.addReading(any, confirmOverride: true)).called(1);
    });

    testWidgets('displays error validation message',
        (WidgetTester tester) async {
      when(
        mockViewModel.addReading(
          any,
          confirmOverride: anyNamed('confirmOverride'),
        ),
      ).thenAnswer(
        (_) async => const ValidationResult.error(
          'Systolic value is medically implausible',
        ),
      );

      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '240',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '100',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '80',
      );

      await tester.pumpAndSettle();
      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Should show error message
      expect(find.byType(ValidationMessageWidget), findsOneWidget);
      expect(
        find.text('Systolic value is medically implausible'),
        findsOneWidget,
      );
    });

    testWidgets('toggles start new session switch',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Expand advanced section
      await tester.tap(find.text('Advanced Options'));
      await tester.pumpAndSettle();

      // Scroll to the switch
      await tester.dragUntilVisible(
        find.byType(Switch),
        find.byType(SingleChildScrollView),
        const Offset(0, -100),
      );

      // Find the switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);

      // Initial state should be false
      Switch switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, false);

      // Tap to enable
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // State should change
      switchWidget = tester.widget(switchFinder);
      expect(switchWidget.value, true);
    });

    testWidgets('selects arm and posture', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // First fill basic fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Systolic').first,
        '120',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Diastolic').first,
        '80',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Pulse').first,
        '70',
      );

      await tester.pumpAndSettle();

      // Expand advanced section
      await tester.tap(find.text('Advanced Options'));
      await tester.pumpAndSettle();

      // Select left arm
      await tester.tap(find.text('Left'));
      await tester.pumpAndSettle();

      // Select sitting posture
      await tester.ensureVisible(find.text('Sitting'));
      await tester.tap(find.text('Sitting'));
      await tester.pumpAndSettle();

      // Scroll to submit button
      await tester.ensureVisible(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(LoadingButton));
      await tester.pumpAndSettle();

      // Verify the reading includes arm and posture
      final captured = verify(
        mockViewModel.addReading(
          captureAny,
          confirmOverride: false,
        ),
      ).captured;

      final reading = captured.first as Reading;
      expect(reading.arm, 'left');
      expect(reading.posture, 'sitting');
    });
  });
}

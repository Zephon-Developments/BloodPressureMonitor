import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/views/readings/widgets/reading_form_advanced.dart';

void main() {
  group('ReadingFormAdvanced Widget Tests', () {
    late TextEditingController notesController;
    late TextEditingController tagsController;
    String? selectedArm;
    String? selectedPosture;

    setUp(() {
      notesController = TextEditingController();
      tagsController = TextEditingController();
      selectedArm = null;
      selectedPosture = null;
    });

    tearDown(() {
      notesController.dispose();
      tagsController.dispose();
    });

    Widget createWidget({
      String? arm,
      String? posture,
      Function(String?)? onArmChanged,
      Function(String?)? onPostureChanged,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return ReadingFormAdvanced(
                notesController: notesController,
                tagsController: tagsController,
                selectedArm: arm ?? selectedArm,
                selectedPosture: posture ?? selectedPosture,
                onArmChanged: onArmChanged ??
                    (value) {
                      setState(() {
                        selectedArm = value;
                      });
                    },
                onPostureChanged: onPostureChanged ??
                    (value) {
                      setState(() {
                        selectedPosture = value;
                      });
                    },
              );
            },
          ),
        ),
      );
    }

    testWidgets('renders all labels', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Arm'), findsOneWidget);
      expect(find.text('Posture'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Tags'), findsOneWidget);
    });

    testWidgets('renders arm choice chips', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Left'), findsOneWidget);
      expect(find.text('Right'), findsOneWidget);
    });

    testWidgets('renders posture choice chips', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(find.text('Sitting'), findsOneWidget);
      expect(find.text('Standing'), findsOneWidget);
      expect(find.text('Lying'), findsOneWidget);
    });

    testWidgets('selects left arm when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Left'));
      await tester.pumpAndSettle();

      // Find the chip and verify it's selected
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final leftChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Left',
      );
      expect(leftChip.selected, true);
    });

    testWidgets('selects right arm when tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Right'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final rightChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Right',
      );
      expect(rightChip.selected, true);
    });

    testWidgets('selects sitting posture when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Sitting'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final sittingChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Sitting',
      );
      expect(sittingChip.selected, true);
    });

    testWidgets('selects standing posture when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Standing'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final standingChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Standing',
      );
      expect(standingChip.selected, true);
    });

    testWidgets('selects lying posture when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.tap(find.text('Lying'));
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final lyingChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Lying',
      );
      expect(lyingChip.selected, true);
    });

    testWidgets('arm can be changed', (WidgetTester tester) async {
      await tester.pumpWidget(
        createWidget(
          arm: 'left',
        ),
      );

      // Verify left is selected
      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      final leftChip = chips.firstWhere(
        (chip) => (chip.label as Text).data == 'Left',
      );
      expect(leftChip.selected, true);
    });

    testWidgets('notes field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Notes'),
        'Measured after exercise',
      );

      expect(notesController.text, 'Measured after exercise');
    });

    testWidgets('tags field accepts text input', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      await tester.enterText(
        find.widgetWithText(TextField, 'Tags'),
        'morning, fasting',
      );

      expect(tagsController.text, 'morning, fasting');
    });

    testWidgets('shows helper text for notes and tags',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      expect(
        find.text('Any additional observations or context'),
        findsOneWidget,
      );
      expect(
        find.text('Comma-separated tags (e.g., morning, exercise)'),
        findsOneWidget,
      );
    });

    testWidgets('notes field is multi-line', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      final textField = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Notes'),
      );

      expect(textField.maxLines, 3);
      expect(textField.minLines, 2);
    });
  });
}

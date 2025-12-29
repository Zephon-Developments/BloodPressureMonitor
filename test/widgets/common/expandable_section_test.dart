import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:blood_pressure_monitor/widgets/common/expandable_section.dart';

void main() {
  group('ExpandableSection Widget Tests', () {
    testWidgets('initially collapsed when initiallyExpanded is false',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableSection(
              title: 'Test Section',
              initiallyExpanded: false,
              children: [
                Text('Child Content'),
              ],
            ),
          ),
        ),
      );

      // Should show title
      expect(find.text('Test Section'), findsOneWidget);

      // Icon should be expand_more when collapsed
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Check AnimatedCrossFade state
      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);
    });

    testWidgets('initially expanded when initiallyExpanded is true',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableSection(
              title: 'Test Section',
              initiallyExpanded: true,
              children: [
                Text('Child Content'),
              ],
            ),
          ),
        ),
      );

      // Should show title
      expect(find.text('Test Section'), findsOneWidget);

      // Icon should be expand_less when expanded
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Check AnimatedCrossFade state
      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
    });

    testWidgets('toggles expanded state when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableSection(
              title: 'Test Section',
              initiallyExpanded: false,
              children: [
                Text('Child Content'),
              ],
            ),
          ),
        ),
      );

      // Initially collapsed
      var crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);

      // Tap to expand
      await tester.tap(find.text('Test Section'));
      await tester.pumpAndSettle();

      // Should now be expanded
      crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);

      // Tap again to collapse
      await tester.tap(find.text('Test Section'));
      await tester.pumpAndSettle();

      // Should be collapsed again
      crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showFirst);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('animates expansion and collapse', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ExpandableSection(
              title: 'Test Section',
              initiallyExpanded: false,
              children: [
                SizedBox(
                  height: 100,
                  child: Text('Child Content'),
                ),
              ],
            ),
          ),
        ),
      );

      // Tap to start expansion
      await tester.tap(find.text('Test Section'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 100)); // Mid-animation

      // Final settle
      await tester.pumpAndSettle();

      // Should be fully expanded
      final crossFade = tester.widget<AnimatedCrossFade>(
        find.byType(AnimatedCrossFade),
      );
      expect(crossFade.crossFadeState, CrossFadeState.showSecond);
    });
  });
}

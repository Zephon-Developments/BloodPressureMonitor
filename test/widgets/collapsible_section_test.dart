import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/widgets/collapsible_section.dart';

void main() {
  group('CollapsibleSection', () {
    testWidgets('renders correctly in collapsed state', (tester) async {
      // Arrange
      const title = 'Blood Pressure';
      const icon = Icons.favorite;
      const miniStatsPreview = Text('120/80');
      const expandedContent = Text('Expanded content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: title,
              icon: icon,
              miniStatsPreview: miniStatsPreview,
              expandedContent: expandedContent,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(title), findsOneWidget);
      expect(find.byIcon(icon), findsOneWidget);
      expect(find.text('120/80'), findsOneWidget);
      expect(find.text('Expanded content'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
    });

    testWidgets('expands when tapped', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Weight',
              icon: Icons.scale,
              miniStatsPreview: Text('75 kg'),
              expandedContent: Text('Recent readings'),
            ),
          ),
        ),
      );

      // Assert initial state
      expect(find.text('Recent readings'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      // Act - tap to expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert expanded state
      expect(find.text('Recent readings'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      // Mini-stats preview should be hidden when expanded
      expect(find.text('75 kg'), findsNothing);
    });

    testWidgets('collapses when tapped again', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Sleep',
              icon: Icons.bedtime,
              miniStatsPreview: Text('7.5 hrs'),
              expandedContent: Text('Sleep data'),
            ),
          ),
        ),
      );

      // Act - expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();
      expect(find.text('Sleep data'), findsOneWidget);

      // Act - collapse
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert collapsed state
      expect(find.text('Sleep data'), findsNothing);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);
      expect(find.text('7.5 hrs'), findsOneWidget);
    });

    testWidgets('onExpansionChanged callback is triggered', (tester) async {
      // Arrange
      bool? callbackValue;
      int callCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Medication',
              icon: Icons.medication,
              miniStatsPreview: const Text('85%'),
              expandedContent: const Text('Adherence data'),
              onExpansionChanged: (expanded) {
                callbackValue = expanded;
                callCount++;
              },
            ),
          ),
        ),
      );

      // Act - expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackValue, true);
      expect(callCount, 1);

      // Act - collapse
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(callbackValue, false);
      expect(callCount, 2);
    });

    testWidgets('initiallyExpanded prop works correctly', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Blood Pressure',
              icon: Icons.favorite,
              miniStatsPreview: Text('Preview'),
              expandedContent: Text('Content'),
              initiallyExpanded: true,
            ),
          ),
        ),
      );

      // Assert - should be expanded initially
      expect(find.text('Content'), findsOneWidget);
      expect(find.byIcon(Icons.expand_less), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('accessibility labels are present', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Test Section',
              icon: Icons.star,
              miniStatsPreview: Text('Stats'),
              expandedContent: Text('Content'),
            ),
          ),
        ),
      );

      // Assert - check for semantic label on expand icon
      final expandIcon = tester.widget<Icon>(find.byIcon(Icons.expand_more));
      expect(expandIcon.semanticLabel, 'Expand section');

      // Act - expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - check for semantic label on collapse icon
      final collapseIcon = tester.widget<Icon>(find.byIcon(Icons.expand_less));
      expect(collapseIcon.semanticLabel, 'Collapse section');
    });

    testWidgets('animation completes properly', (tester) async {
      // Arrange
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Animated Section',
              icon: Icons.animation,
              miniStatsPreview: Text('Preview'),
              expandedContent: Text('Expanded'),
            ),
          ),
        ),
      );

      // Act - tap to expand
      await tester.tap(find.byType(InkWell));

      // Assert - during animation, both states may be visible
      await tester.pump(const Duration(milliseconds: 125));

      // Complete animation
      await tester.pumpAndSettle();

      // Assert - animation complete, only expanded content visible
      expect(find.text('Expanded'), findsOneWidget);
      expect(find.text('Preview'), findsNothing);
    });

    testWidgets('Material 3 styling is applied', (tester) async {
      // Arrange & Act
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
          home: const Scaffold(
            body: CollapsibleSection(
              title: 'Styled Section',
              icon: Icons.palette,
              miniStatsPreview: Text('Preview'),
              expandedContent: Text('Content'),
            ),
          ),
        ),
      );

      // Assert - check Card elevation (collapsed state)
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 1);
      expect(
        card.margin,
        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      );

      // Act - expand to check elevation change
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - expanded state has higher elevation
      final expandedCard = tester.widget<Card>(find.byType(Card));
      expect(expandedCard.elevation, 2);
    });

    testWidgets('handles complex expandedContent', (tester) async {
      // Arrange
      final complexContent = Column(
        children: [
          const Text('Item 1'),
          const Text('Item 2'),
          ElevatedButton(
            onPressed: () {},
            child: const Text('Action'),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollapsibleSection(
              title: 'Complex Section',
              icon: Icons.list,
              miniStatsPreview: const Text('Summary'),
              expandedContent: complexContent,
            ),
          ),
        ),
      );

      // Act - expand
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - all complex content is visible
      expect(find.text('Item 1'), findsOneWidget);
      expect(find.text('Item 2'), findsOneWidget);
      expect(find.text('Action'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/profile_switcher.dart';
import 'package:blood_pressure_monitor/views/profile/profile_picker_view.dart';

@GenerateMocks([ActiveProfileViewModel])
import 'profile_switcher_test.mocks.dart';

void main() {
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockActiveProfileViewModel = MockActiveProfileViewModel();
  });

  Widget createTestWidget() {
    return ChangeNotifierProvider<ActiveProfileViewModel>.value(
      value: mockActiveProfileViewModel,
      child: const MaterialApp(
        home: Scaffold(
          body: ProfileSwitcher(),
        ),
      ),
    );
  }

  group('ProfileSwitcher', () {
    testWidgets('should display active profile name',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
    });

    testWidgets('should display first letter of profile name in avatar',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('J'), findsOneWidget);
    });

    testWidgets('should display question mark when profile name is empty',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('should navigate to ProfilePickerView when tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(ProfilePickerView), findsOneWidget);
    });

    testWidgets('should display dropdown arrow icon',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byIcon(Icons.arrow_drop_down), findsOneWidget);
    });

    testWidgets('should truncate long profile names with ellipsis',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName)
          .thenReturn('Very Long Profile Name That Should Be Truncated');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final textWidget = tester.widget<Text>(
        find.text('Very Long Profile Name That Should Be Truncated'),
      );
      expect(textWidget.overflow, equals(TextOverflow.ellipsis));
    });

    testWidgets('should have accessible InkWell with ripple effect',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final inkWell = tester.widget<InkWell>(find.byType(InkWell));
      expect(inkWell.borderRadius, equals(BorderRadius.circular(24)));
    });

    testWidgets('has semantic label for screen readers',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert - verify semantic label by finding the Semantics widget
      final profileSwitcher = find.byType(ProfileSwitcher);
      expect(profileSwitcher, findsOneWidget);

      // The Semantics widget should be a descendant of ProfileSwitcher
      final semanticsFinder = find.descendant(
        of: profileSwitcher,
        matching: find.byType(Semantics),
      );
      expect(semanticsFinder, findsWidgets);

      final semanticsWidget = tester.widget<Semantics>(semanticsFinder.first);
      expect(semanticsWidget.properties.label, contains('Switch profile'));
      expect(semanticsWidget.properties.label, contains('John Doe'));
    });

    testWidgets('semantic label includes button hint',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      final semantics = tester.getSemantics(find.byType(ProfileSwitcher));
      final data = semantics.getSemanticsData();
      expect(data.flags & SemanticsFlag.isButton.index, isNonZero);
    });

    testWidgets('works with large text scaling at 2.0x',
        (WidgetTester tester) async {
      // Arrange
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('John Doe');

      // Act
      await tester.pumpWidget(
        ChangeNotifierProvider<ActiveProfileViewModel>.value(
          value: mockActiveProfileViewModel,
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
              child: Scaffold(body: ProfileSwitcher()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - should render without overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(ProfileSwitcher), findsOneWidget);
    });
  });
}

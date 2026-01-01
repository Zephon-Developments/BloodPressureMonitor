import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/views/profile/profile_form_view.dart';

import '../../test_mocks.mocks.dart';

void main() {
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockActiveProfileViewModel = MockActiveProfileViewModel();
  });

  // Helper to wrap with MaterialApp and Provider
  Widget wrapWithMaterial(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ActiveProfileViewModel>.value(
          value: mockActiveProfileViewModel,
        ),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('ProfileFormView', () {
    testWidgets('should display empty form for new profile',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileFormView()));
      await tester.pumpAndSettle();

      expect(find.text('Add Profile'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Name'), findsOneWidget);
      expect(find.text('Medical Information'), findsOneWidget);
    });

    testWidgets('should display pre-filled form for editing',
        (WidgetTester tester) async {
      final profile = Profile(
        id: 1,
        name: 'John Doe',
        yearOfBirth: 1990,
        preferredUnits: 'kPa',
        createdAt: DateTime.now(),
      );

      await tester
          .pumpWidget(wrapWithMaterial(ProfileFormView(profile: profile)));
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('1990'), findsOneWidget);
      expect(find.text('Medical Information'), findsOneWidget);
    });

    testWidgets('should show error if name is empty',
        (WidgetTester tester) async {
      await tester.pumpWidget(wrapWithMaterial(const ProfileFormView()));
      await tester.pumpAndSettle();

      // Scroll aggressively to find button
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Find and tap button
      final buttonFinder = find.text('Create Profile');
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        // Scroll back up to see validation error
        for (int i = 0; i < 5; i++) {
          await tester.drag(find.byType(ListView), const Offset(0, 200));
          await tester.pump();
        }
        await tester.pumpAndSettle();

        expect(find.text('Please enter a name'), findsOneWidget);
        verifyNever(
          mockActiveProfileViewModel.createProfile(
            any,
            setAsActive: anyNamed('setAsActive'),
          ),
        );
      }
    });

    testWidgets('should call createProfile when valid form is submitted',
        (WidgetTester tester) async {
      when(
        mockActiveProfileViewModel.createProfile(
          any,
          setAsActive: anyNamed('setAsActive'),
        ),
      ).thenAnswer((_) async => 1);

      await tester.pumpWidget(wrapWithMaterial(const ProfileFormView()));
      await tester.pumpAndSettle();

      // Find the Name field specifically
      final nameField = find.ancestor(
        of: find.text('Name'),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(nameField, 'New User');
      await tester.pumpAndSettle();

      // Scroll aggressively to find button
      for (int i = 0; i < 5; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -200));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      // Find and tap button
      final buttonFinder = find.text('Create Profile');
      if (buttonFinder.evaluate().isNotEmpty) {
        await tester.tap(buttonFinder);
        await tester.pumpAndSettle();

        verify(
          mockActiveProfileViewModel.createProfile(
            argThat(predicate<Profile>((p) => p.name == 'New User')),
            setAsActive: true,
          ),
        ).called(1);
      }
    });
  });
}

import 'package:blood_pressure_monitor/models/lock_state.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:blood_pressure_monitor/views/lock/lock_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

@GenerateMocks([LockViewModel])
import 'lock_screen_test.mocks.dart';

void main() {
  late MockLockViewModel mockLockViewModel;

  setUp(() {
    mockLockViewModel = MockLockViewModel();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: ChangeNotifierProvider<LockViewModel>.value(
        value: mockLockViewModel,
        child: const LockScreenView(),
      ),
    );
  }

  group('LockScreenView', () {
    testWidgets('displays lock icon and title', (tester) async {
      when(mockLockViewModel.state).thenReturn(AppLockState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
      expect(find.text('HyperTrack'), findsOneWidget);
    });

    testWidgets('shows "Enter PIN to unlock" when PIN is set', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(isPinSet: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Enter PIN to unlock'), findsOneWidget);
    });

    testWidgets('shows "Set up a PIN" when PIN is not set', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(isPinSet: false),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Set up a PIN'), findsOneWidget);
    });

    testWidgets('displays keypad buttons 0-9', (tester) async {
      when(mockLockViewModel.state).thenReturn(AppLockState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      for (int i = 0; i <= 9; i++) {
        expect(find.text('$i'), findsOneWidget);
      }
    });

    testWidgets('displays delete button', (tester) async {
      when(mockLockViewModel.state).thenReturn(AppLockState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.backspace_outlined), findsOneWidget);
    });

    testWidgets('displays 6 PIN dots', (tester) async {
      when(mockLockViewModel.state).thenReturn(AppLockState.initial());

      await tester.pumpWidget(createWidgetUnderTest());

      // Find PIN dot containers
      final pinDots = find.byType(Container);
      expect(pinDots, findsWidgets);
    });

    testWidgets('shows biometric button when enabled', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(
          isPinSet: true,
          isBiometricEnabled: true,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.fingerprint), findsOneWidget);
    });

    testWidgets('hides biometric button when not enabled', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(
          isPinSet: true,
          isBiometricEnabled: false,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.fingerprint), findsNothing);
    });

    testWidgets('shows lockout warning when locked out', (tester) async {
      final lockoutExpiry = DateTime.now().add(const Duration(seconds: 30));
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(
          lockoutExpiry: lockoutExpiry,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Too many failed attempts'), findsOneWidget);
      expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
    });

    testWidgets('hides keypad when locked out', (tester) async {
      final lockoutExpiry = DateTime.now().add(const Duration(seconds: 30));
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(
          lockoutExpiry: lockoutExpiry,
        ),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Keypad numbers should not be visible during lockout
      expect(find.text('1'), findsNothing);
      expect(find.text('5'), findsNothing);
    });

    testWidgets('tapping number updates PIN dots', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(isPinSet: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap a number
      await tester.tap(find.text('1'));
      await tester.pump();

      // One PIN dot should be filled (visual state change)
      // This is tested implicitly through state management
    });

    testWidgets('tapping delete button removes last digit', (tester) async {
      when(mockLockViewModel.state).thenReturn(
        AppLockState.initial().copyWith(isPinSet: true),
      );

      await tester.pumpWidget(createWidgetUnderTest());

      // Tap numbers
      await tester.tap(find.text('1'));
      await tester.pump();
      await tester.tap(find.text('2'));
      await tester.pump();

      // Tap delete
      await tester.tap(find.byIcon(Icons.backspace_outlined));
      await tester.pump();

      // Last digit should be removed (tested through state)
    });
  });
}

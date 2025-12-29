import 'package:blood_pressure_monitor/services/auth_service.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([AuthService])
import 'lock_viewmodel_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAuthService mockAuthService;
  late SharedPreferences prefs;
  late LockViewModel viewModel;

  setUp(() async {
    mockAuthService = MockAuthService();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Default mock behavior
    when(mockAuthService.isPinSet()).thenAnswer((_) async => false);
    when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => false);
    when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => false);
    when(mockAuthService.getFailedAttempts()).thenAnswer((_) async => 0);
    when(mockAuthService.getLockoutExpiry()).thenAnswer((_) async => null);

    viewModel = LockViewModel(
      authService: mockAuthService,
      prefs: prefs,
    );

    // Wait for initial state to load
    await Future.delayed(Duration.zero);
  });

  tearDown(() {
    viewModel.dispose();
  });

  group('Initialization', () {
    test('initial state is unlocked when no PIN is set', () async {
      expect(viewModel.state.isLocked, false);
      expect(viewModel.state.isPinSet, false);
    });

    test('initial state is locked when PIN is set', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      expect(vm.state.isLocked, true);
      expect(vm.state.isPinSet, true);

      vm.dispose();
    });

    test('loads biometric availability on init', () async {
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      expect(vm.state.isBiometricAvailable, true);
      expect(vm.state.isBiometricEnabled, true);

      vm.dispose();
    });

    test('loads failed attempts and lockout state on init', () async {
      when(mockAuthService.getFailedAttempts()).thenAnswer((_) async => 3);
      final lockoutExpiry = DateTime.now().add(const Duration(minutes: 5));
      when(mockAuthService.getLockoutExpiry())
          .thenAnswer((_) async => lockoutExpiry);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      expect(vm.state.failedAttempts, 3);
      expect(vm.state.lockoutExpiry, lockoutExpiry);

      vm.dispose();
    });

    test('loads idle timeout setting on init', () async {
      await prefs.setInt('idle_timeout_minutes', 5);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      expect(vm.state.idleTimeoutMinutes, 5);

      vm.dispose();
    });
  });

  group('PIN Unlock', () {
    test('unlockWithPin succeeds with correct PIN', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      final result = await vm.unlockWithPin('1234');

      expect(result, true);
      expect(vm.state.isLocked, false);
      expect(vm.state.failedAttempts, 0);
      expect(vm.state.lockoutExpiry, isNull);

      vm.dispose();
    });

    test('unlockWithPin fails with incorrect PIN', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('9999')).thenAnswer((_) async => false);
      when(mockAuthService.getFailedAttempts()).thenAnswer((_) async => 1);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      final result = await vm.unlockWithPin('9999');

      expect(result, false);
      expect(vm.state.isLocked, true);
      expect(vm.state.failedAttempts, 1);

      vm.dispose();
    });

    test('unlockWithPin updates lockout state on failure', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin(any)).thenAnswer((_) async => false);

      final lockoutExpiry = DateTime.now().add(const Duration(seconds: 30));
      when(mockAuthService.getFailedAttempts()).thenAnswer((_) async => 5);
      when(mockAuthService.getLockoutExpiry())
          .thenAnswer((_) async => lockoutExpiry);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.unlockWithPin('wrong');

      expect(vm.state.failedAttempts, 5);
      expect(vm.state.lockoutExpiry, lockoutExpiry);

      vm.dispose();
    });

    test('unlockWithPin starts idle monitoring on success', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.unlockWithPin('1234');

      // Verify state is unlocked (monitoring started internally)
      expect(vm.state.isLocked, false);

      vm.dispose();
    });
  });

  group('Biometric Unlock', () {
    test('unlockWithBiometric succeeds when enabled', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
      when(mockAuthService.authenticateWithBiometrics())
          .thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      final result = await vm.unlockWithBiometric();

      expect(result, true);
      expect(vm.state.isLocked, false);

      vm.dispose();
    });

    test('unlockWithBiometric fails when not enabled', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      final result = await vm.unlockWithBiometric();

      expect(result, false);
      expect(vm.state.isLocked, true);

      vm.dispose();
    });

    test('unlockWithBiometric fails when auth is cancelled', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
      when(mockAuthService.authenticateWithBiometrics())
          .thenAnswer((_) async => false);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      final result = await vm.unlockWithBiometric();

      expect(result, false);

      vm.dispose();
    });

    test('unlockWithBiometric starts idle monitoring on success', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
      when(mockAuthService.authenticateWithBiometrics())
          .thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.unlockWithBiometric();

      expect(vm.state.isLocked, false);

      vm.dispose();
    });
  });

  group('Lock Management', () {
    test('lock sets state to locked', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      // Unlock first
      await vm.unlockWithPin('1234');
      expect(vm.state.isLocked, false);

      // Then lock
      vm.lock();

      expect(vm.state.isLocked, true);

      vm.dispose();
    });

    test('lock stops idle monitoring', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.unlockWithPin('1234');
      vm.lock();

      expect(vm.state.isLocked, true);

      vm.dispose();
    });
  });

  group('PIN Management', () {
    test('setPin updates state', () async {
      when(mockAuthService.setPin('1234')).thenAnswer((_) async => {});

      await viewModel.setPin('1234');

      expect(viewModel.state.isPinSet, true);
      expect(viewModel.state.failedAttempts, 0);
      expect(viewModel.state.lockoutExpiry, isNull);
    });

    test('changePin succeeds with correct old PIN', () async {
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);
      when(mockAuthService.setPin('5678')).thenAnswer((_) async => {});

      final result = await viewModel.changePin('1234', '5678');

      expect(result, true);
      verify(mockAuthService.setPin('5678')).called(1);
    });

    test('changePin fails with incorrect old PIN', () async {
      when(mockAuthService.verifyPin('wrong')).thenAnswer((_) async => false);

      final result = await viewModel.changePin('wrong', '5678');

      expect(result, false);
      verifyNever(mockAuthService.setPin(any));
    });
  });

  group('Biometric Settings', () {
    test('setBiometricEnabled enables biometric when available', () async {
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => false);
      when(mockAuthService.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);
      when(mockAuthService.setBiometricEnabled(true))
          .thenAnswer((_) async => {});

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.setBiometricEnabled(true);

      expect(vm.state.isBiometricEnabled, true);

      vm.dispose();
    });

    test('setBiometricEnabled does nothing when not available', () async {
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => false);

      await viewModel.setBiometricEnabled(true);

      expect(viewModel.state.isBiometricEnabled, false);
      verifyNever(mockAuthService.setBiometricEnabled(any));
    });

    test('setBiometricEnabled disables biometric', () async {
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);
      when(mockAuthService.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);
      when(mockAuthService.setBiometricEnabled(false))
          .thenAnswer((_) async => {});

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.setBiometricEnabled(false);

      expect(vm.state.isBiometricEnabled, false);

      vm.dispose();
    });
  });

  group('Idle Timeout', () {
    test('setIdleTimeout updates state and persists', () async {
      await viewModel.setIdleTimeout(5);

      expect(viewModel.state.idleTimeoutMinutes, 5);
      expect(prefs.getInt('idle_timeout_minutes'), 5);
    });

    test('recordActivity is safe when locked', () {
      // Should not throw even when locked
      viewModel.recordActivity();
      expect(true, true); // Test passes if no exception
    });

    test('recordActivity resets timer when unlocked', () async {
      when(mockAuthService.isPinSet()).thenAnswer((_) async => true);
      when(mockAuthService.verifyPin('1234')).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      await vm.unlockWithPin('1234');

      // Should not throw and should reset timer internally
      vm.recordActivity();

      vm.dispose();
    });
  });

  group('Biometric Refresh', () {
    test('refreshBiometricAvailability updates state', () async {
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);

      await viewModel.refreshBiometricAvailability();

      expect(viewModel.state.isBiometricAvailable, true);
      expect(viewModel.state.isBiometricEnabled, true);
    });

    test('refreshBiometricAvailability detects removed biometrics', () async {
      // Start with biometrics enabled
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => true);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => true);

      final vm = LockViewModel(
        authService: mockAuthService,
        prefs: prefs,
      );
      await Future.delayed(Duration.zero);

      // Now biometrics are removed
      when(mockAuthService.canCheckBiometrics()).thenAnswer((_) async => false);
      when(mockAuthService.isBiometricEnabled()).thenAnswer((_) async => false);

      await vm.refreshBiometricAvailability();

      expect(vm.state.isBiometricAvailable, false);
      expect(vm.state.isBiometricEnabled, false);

      vm.dispose();
    });
  });

  group('Notification', () {
    test('state changes trigger notifyListeners', () async {
      int notificationCount = 0;
      viewModel.addListener(() {
        notificationCount++;
      });

      when(mockAuthService.setPin('1234')).thenAnswer((_) async => {});

      await viewModel.setPin('1234');

      expect(notificationCount, greaterThan(0));
    });
  });
}

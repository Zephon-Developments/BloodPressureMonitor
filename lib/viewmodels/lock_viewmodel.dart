import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blood_pressure_monitor/models/lock_state.dart' show AppLockState;
import 'package:blood_pressure_monitor/services/auth_service.dart';
import 'package:blood_pressure_monitor/services/idle_timer_service.dart';

/// ViewModel managing the app lock state and authentication.
///
/// Orchestrates AuthService and IdleTimerService to provide a unified
/// lock/unlock interface for the UI.
class LockViewModel extends ChangeNotifier with WidgetsBindingObserver {
  final AuthService _authService;
  final SharedPreferences _prefs;
  late final IdleTimerService _idleTimerService;

  AppLockState _state = AppLockState.initial();
  AppLockState get state => _state;

  LockViewModel({
    required AuthService authService,
    required SharedPreferences prefs,
  })  : _authService = authService,
        _prefs = prefs {
    _idleTimerService = IdleTimerService(
      prefs: _prefs,
      onIdleTimeout: lock,
    );
    
    WidgetsBinding.instance.addObserver(this);
    _loadInitialState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _idleTimerService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _idleTimerService.handleLifecycleChange(state);
  }

  /// Loads the initial lock state from persisted settings.
  Future<void> _loadInitialState() async {
    final isPinSet = await _authService.isPinSet();
    final isBiometricAvailable = await _authService.canCheckBiometrics();
    final isBiometricEnabled = await _authService.isBiometricEnabled();
    final failedAttempts = await _authService.getFailedAttempts();
    final lockoutExpiry = await _authService.getLockoutExpiry();
    final idleTimeoutMinutes = _idleTimerService.getIdleTimeoutMinutes();

    _state = AppLockState(
      isLocked: isPinSet, // Start locked if PIN is set
      isPinSet: isPinSet,
      isBiometricAvailable: isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled,
      failedAttempts: failedAttempts,
      lockoutExpiry: lockoutExpiry,
      idleTimeoutMinutes: idleTimeoutMinutes,
    );

    notifyListeners();
  }

  /// Attempts to unlock with PIN.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> unlockWithPin(String pin) async {
    final success = await _authService.verifyPin(pin);

    if (success) {
      _state = _state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutExpiry: null,
      );
      _idleTimerService.startMonitoring();
      notifyListeners();
      return true;
    } else {
      // Update failed attempts and lockout state
      final failedAttempts = await _authService.getFailedAttempts();
      final lockoutExpiry = await _authService.getLockoutExpiry();

      _state = _state.copyWith(
        failedAttempts: failedAttempts,
        lockoutExpiry: lockoutExpiry,
      );
      notifyListeners();
      return false;
    }
  }

  /// Attempts to unlock with biometric authentication.
  ///
  /// Returns true if successful, false otherwise.
  Future<bool> unlockWithBiometric() async {
    if (!_state.isBiometricEnabled) {
      return false;
    }

    final success = await _authService.authenticateWithBiometrics();

    if (success) {
      _state = _state.copyWith(
        isLocked: false,
        failedAttempts: 0,
        lockoutExpiry: null,
      );
      _idleTimerService.startMonitoring();
      notifyListeners();
      return true;
    }

    return false;
  }

  /// Locks the app.
  void lock() {
    _state = _state.copyWith(isLocked: true);
    _idleTimerService.stopMonitoring();
    notifyListeners();
  }

  /// Sets a new PIN.
  Future<void> setPin(String pin) async {
    await _authService.setPin(pin);
    _state = _state.copyWith(
      isPinSet: true,
      failedAttempts: 0,
      lockoutExpiry: null,
    );
    notifyListeners();
  }

  /// Changes the existing PIN.
  Future<bool> changePin(String oldPin, String newPin) async {
    if (!await _authService.verifyPin(oldPin)) {
      return false;
    }

    await _authService.setPin(newPin);
    notifyListeners();
    return true;
  }

  /// Enables or disables biometric authentication.
  Future<void> setBiometricEnabled(bool enabled) async {
    if (enabled && !_state.isBiometricAvailable) {
      return; // Can't enable if not available
    }

    await _authService.setBiometricEnabled(enabled);
    _state = _state.copyWith(isBiometricEnabled: enabled);
    notifyListeners();
  }

  /// Sets the idle timeout in minutes.
  Future<void> setIdleTimeout(int minutes) async {
    await _idleTimerService.setIdleTimeoutMinutes(minutes);
    _state = _state.copyWith(idleTimeoutMinutes: minutes);
    notifyListeners();
  }

  /// Records user activity to reset the idle timer.
  void recordActivity() {
    if (!_state.isLocked) {
      _idleTimerService.recordActivity();
    }
  }

  /// Refreshes the biometric availability state.
  ///
  /// Should be called when the app resumes to detect if biometrics
  /// were removed.
  Future<void> refreshBiometricAvailability() async {
    final isBiometricAvailable = await _authService.canCheckBiometrics();
    final isBiometricEnabled = await _authService.isBiometricEnabled();

    _state = _state.copyWith(
      isBiometricAvailable: isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled,
    );
    notifyListeners();
  }
}

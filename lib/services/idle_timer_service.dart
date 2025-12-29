import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing idle timeout for automatic app locking.
///
/// Tracks user activity and triggers lock after a configurable period of
/// inactivity. Listens to app lifecycle events to lock on background.
class IdleTimerService {
  final SharedPreferences _prefs;
  final void Function() _onIdleTimeout;

  Timer? _idleTimer;

  static const String _idleTimeoutMinutesKey = 'idle_timeout_minutes';
  static const int _defaultIdleTimeoutMinutes = 2;

  IdleTimerService({
    required SharedPreferences prefs,
    required void Function() onIdleTimeout,
  })  : _prefs = prefs,
        _onIdleTimeout = onIdleTimeout;

  /// Gets the configured idle timeout in minutes.
  int getIdleTimeoutMinutes() {
    return _prefs.getInt(_idleTimeoutMinutesKey) ?? _defaultIdleTimeoutMinutes;
  }

  /// Sets the idle timeout in minutes.
  Future<void> setIdleTimeoutMinutes(int minutes) async {
    await _prefs.setInt(_idleTimeoutMinutesKey, minutes);
    _resetIdleTimer();
  }

  /// Starts monitoring for idle timeout.
  ///
  /// Should be called when the app is unlocked and user activity
  /// monitoring should begin.
  void startMonitoring() {
    _resetIdleTimer();
  }

  /// Stops monitoring for idle timeout.
  ///
  /// Should be called when the app is locked or monitoring is no longer needed.
  void stopMonitoring() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  /// Records user activity, resetting the idle timer.
  ///
  /// Should be called whenever the user interacts with the app
  /// (taps, scrolls, etc.).
  void recordActivity() {
    _resetIdleTimer();
  }

  /// Handles app lifecycle state changes.
  ///
  /// Locks the app immediately when it goes into the background per
  /// Clive's requirement.
  void handleLifecycleChange(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // App is backgrounded or hidden - lock immediately
        _onIdleTimeout();
        stopMonitoring();
        break;
      case AppLifecycleState.resumed:
        // App resumed - monitoring will be started by lock screen if unlocked
        break;
    }
  }

  /// Resets the idle timer based on current timeout setting.
  void _resetIdleTimer() {
    _idleTimer?.cancel();

    final timeoutMinutes = getIdleTimeoutMinutes();
    _idleTimer = Timer(Duration(minutes: timeoutMinutes), () {
      _onIdleTimeout();
    });
  }

  /// Disposes of resources.
  void dispose() {
    stopMonitoring();
  }
}

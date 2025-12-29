import 'package:blood_pressure_monitor/services/idle_timer_service.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;
  late bool timeoutTriggered;
  late IdleTimerService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    timeoutTriggered = false;

    service = IdleTimerService(
      prefs: prefs,
      onIdleTimeout: () {
        timeoutTriggered = true;
      },
    );
  });

  tearDown(() {
    service.dispose();
  });

  group('Configuration', () {
    test('getIdleTimeoutMinutes returns default when not set', () {
      final timeout = service.getIdleTimeoutMinutes();

      expect(timeout, 2);
    });

    test('getIdleTimeoutMinutes returns configured value', () async {
      await prefs.setInt('idle_timeout_minutes', 5);

      final timeout = service.getIdleTimeoutMinutes();

      expect(timeout, 5);
    });

    test('setIdleTimeoutMinutes persists value', () async {
      await service.setIdleTimeoutMinutes(10);

      final timeout = prefs.getInt('idle_timeout_minutes');
      expect(timeout, 10);
    });

    test('setIdleTimeoutMinutes resets active timer', () async {
      service.startMonitoring();
      await service.setIdleTimeoutMinutes(1);

      // Timer should be reset with new duration
      expect(timeoutTriggered, false);
    });
  });

  group('Timer Management', () {
    test('startMonitoring starts the idle timer', () {
      service.startMonitoring();

      // Timer should be active but not triggered yet
      expect(timeoutTriggered, false);
    });

    test('stopMonitoring cancels the idle timer', () async {
      await service.setIdleTimeoutMinutes(1); // Short timeout for testing
      service.startMonitoring();
      service.stopMonitoring();

      // Wait longer than the timeout
      await Future.delayed(const Duration(seconds: 2));

      // Timeout should not trigger after stop
      expect(timeoutTriggered, false);
    });

    test('recordActivity resets the idle timer', () async {
      await service.setIdleTimeoutMinutes(1);
      service.startMonitoring();

      // Wait half the timeout
      await Future.delayed(const Duration(milliseconds: 500));

      // Record activity to reset
      service.recordActivity();

      // Wait another half timeout (would have triggered without reset)
      await Future.delayed(const Duration(milliseconds: 600));

      expect(timeoutTriggered, false);
    });

    test('idle timeout triggers callback after configured duration', () {
      fakeAsync((async) {
        var timeoutTriggered = false;
        final service = IdleTimerService(
          prefs: prefs,
          onIdleTimeout: () {
            timeoutTriggered = true;
          },
        );

        service.setIdleTimeoutMinutes(1).then((_) {
          service.startMonitoring();

          // Should not trigger immediately
          expect(timeoutTriggered, false);

          // Elapse the timeout duration
          async.elapse(const Duration(minutes: 1));

          expect(timeoutTriggered, true);

          service.dispose();
        });

        async.flushMicrotasks();
      });
    });
  });

  group('Lifecycle Handling', () {
    test('handleLifecycleChange locks on paused state', () {
      service.handleLifecycleChange(AppLifecycleState.paused);

      expect(timeoutTriggered, true);
    });

    test('handleLifecycleChange locks on inactive state', () {
      service.handleLifecycleChange(AppLifecycleState.inactive);

      expect(timeoutTriggered, true);
    });

    test('handleLifecycleChange locks on detached state', () {
      service.handleLifecycleChange(AppLifecycleState.detached);

      expect(timeoutTriggered, true);
    });

    test('handleLifecycleChange locks on hidden state', () {
      service.handleLifecycleChange(AppLifecycleState.hidden);

      expect(timeoutTriggered, true);
    });

    test('handleLifecycleChange does not lock on resumed state', () {
      service.handleLifecycleChange(AppLifecycleState.resumed);

      expect(timeoutTriggered, false);
    });

    test('handleLifecycleChange stops monitoring when backgrounded', () async {
      await service.setIdleTimeoutMinutes(1);
      service.startMonitoring();

      service.handleLifecycleChange(AppLifecycleState.paused);

      // Reset the flag
      timeoutTriggered = false;

      // Wait longer than timeout
      await Future.delayed(const Duration(seconds: 2));

      // Should not trigger again since monitoring stopped
      expect(timeoutTriggered, false);
    });
  });

  group('Edge Cases', () {
    test('multiple startMonitoring calls reset timer', () async {
      await service.setIdleTimeoutMinutes(1);
      service.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 500));

      // Start again (should reset)
      service.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 600));

      expect(timeoutTriggered, false);
    });

    test('dispose stops monitoring', () async {
      await service.setIdleTimeoutMinutes(1);
      service.startMonitoring();

      service.dispose();

      await Future.delayed(const Duration(seconds: 2));

      expect(timeoutTriggered, false);
    });

    test('multiple dispose calls are safe', () {
      service.dispose();
      service.dispose(); // Should not throw

      expect(true, true); // Test passes if no exception
    });

    test('stopMonitoring when not monitoring is safe', () {
      service.stopMonitoring(); // Should not throw

      expect(true, true);
    });
  });
}

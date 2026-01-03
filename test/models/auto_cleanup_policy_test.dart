import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_pressure_monitor/models/auto_cleanup_policy.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AutoCleanupPolicy', () {
    test('defaultPolicy returns correct values', () {
      final policy = AutoCleanupPolicy.defaultPolicy();
      expect(policy.enabled, true);
      expect(policy.maxAge, const Duration(days: 90));
      expect(policy.maxFilesPerType, 5);
      expect(policy.maxTotalSizeMB, null);
    });

    test('disabled creates disabled policy', () {
      final policy = AutoCleanupPolicy.disabled();
      expect(policy.enabled, false);
    });

    test('save and load roundtrip', () async {
      const policy = AutoCleanupPolicy(
        enabled: true,
        maxAge: Duration(days: 60),
        maxFilesPerType: 25,
        maxTotalSizeMB: 100,
      );

      await policy.save();
      final loaded = await AutoCleanupPolicy.load();

      expect(loaded.enabled, policy.enabled);
      expect(loaded.maxAge, policy.maxAge);
      expect(loaded.maxFilesPerType, policy.maxFilesPerType);
      expect(loaded.maxTotalSizeMB, policy.maxTotalSizeMB);
    });

    test('load with no saved values returns defaults', () async {
      final loaded = await AutoCleanupPolicy.load();
      final defaults = AutoCleanupPolicy.defaultPolicy();
      expect(loaded.enabled, defaults.enabled);
      expect(loaded.maxAge, defaults.maxAge);
      expect(loaded.maxFilesPerType, defaults.maxFilesPerType);
      expect(loaded.maxTotalSizeMB, defaults.maxTotalSizeMB);
    });

    test('copyWith creates modified copy', () {
      const policy = AutoCleanupPolicy(
        enabled: true,
        maxAge: Duration(days: 90),
        maxFilesPerType: 50,
      );

      final modified = policy.copyWith(enabled: false);
      expect(modified.enabled, false);
      expect(modified.maxAge, policy.maxAge);
      expect(modified.maxFilesPerType, policy.maxFilesPerType);
    });
  });
}

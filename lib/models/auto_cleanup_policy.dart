import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for automatic cleanup of old export and report files.
class AutoCleanupPolicy {
  /// Maximum age before a file is eligible for cleanup (null = no age limit).
  final Duration? maxAge;

  /// Maximum number of files to retain per type (null = no count limit).
  final int? maxFilesPerType;

  /// Maximum total storage in megabytes (null = no size limit).
  final int? maxTotalSizeMB;

  /// Whether automatic cleanup is enabled.
  final bool enabled;

  const AutoCleanupPolicy({
    this.maxAge,
    this.maxFilesPerType,
    this.maxTotalSizeMB,
    this.enabled = true,
  });

  /// Default policy: 90 days age limit, keep 5 files per type, enabled.
  factory AutoCleanupPolicy.defaultPolicy() {
    return const AutoCleanupPolicy(
      maxAge: Duration(days: 90),
      maxFilesPerType: 5,
      enabled: true,
    );
  }

  /// Disabled policy: no cleanup.
  factory AutoCleanupPolicy.disabled() {
    return const AutoCleanupPolicy(enabled: false);
  }

  /// Loads policy from SharedPreferences.
  static Future<AutoCleanupPolicy> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultP = AutoCleanupPolicy.defaultPolicy();

    final enabled = prefs.getBool('cleanup_enabled') ?? defaultP.enabled;
    final ageDays =
        prefs.getInt('cleanup_max_age_days') ?? defaultP.maxAge?.inDays;
    final maxFiles =
        prefs.getInt('cleanup_max_files_per_type') ?? defaultP.maxFilesPerType;
    final maxSizeMB =
        prefs.getInt('cleanup_max_total_size_mb') ?? defaultP.maxTotalSizeMB;

    return AutoCleanupPolicy(
      enabled: enabled,
      maxAge: ageDays != null ? Duration(days: ageDays) : null,
      maxFilesPerType: maxFiles,
      maxTotalSizeMB: maxSizeMB,
    );
  }

  /// Saves policy to SharedPreferences.
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cleanup_enabled', enabled);
    if (maxAge != null) {
      await prefs.setInt('cleanup_max_age_days', maxAge!.inDays);
    } else {
      await prefs.remove('cleanup_max_age_days');
    }
    if (maxFilesPerType != null) {
      await prefs.setInt('cleanup_max_files_per_type', maxFilesPerType!);
    } else {
      await prefs.remove('cleanup_max_files_per_type');
    }
    if (maxTotalSizeMB != null) {
      await prefs.setInt('cleanup_max_total_size_mb', maxTotalSizeMB!);
    } else {
      await prefs.remove('cleanup_max_total_size_mb');
    }
  }

  AutoCleanupPolicy copyWith({
    Duration? maxAge,
    int? maxFilesPerType,
    int? maxTotalSizeMB,
    bool? enabled,
  }) {
    return AutoCleanupPolicy(
      maxAge: maxAge ?? this.maxAge,
      maxFilesPerType: maxFilesPerType ?? this.maxFilesPerType,
      maxTotalSizeMB: maxTotalSizeMB ?? this.maxTotalSizeMB,
      enabled: enabled ?? this.enabled,
    );
  }
}

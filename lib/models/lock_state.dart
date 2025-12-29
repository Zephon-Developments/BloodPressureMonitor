/// Represents the current state of the app security lock.
class AppLockState {
  final bool isLocked;
  final bool isPinSet;
  final bool isBiometricAvailable;
  final bool isBiometricEnabled;
  final int failedAttempts;
  final DateTime? lockoutExpiry;
  final int idleTimeoutMinutes;

  const AppLockState({
    required this.isLocked,
    required this.isPinSet,
    required this.isBiometricAvailable,
    required this.isBiometricEnabled,
    this.failedAttempts = 0,
    this.lockoutExpiry,
    required this.idleTimeoutMinutes,
  });

  /// Creates an initial locked state.
  factory AppLockState.initial() {
    return const AppLockState(
      isLocked: true,
      isPinSet: false,
      isBiometricAvailable: false,
      isBiometricEnabled: false,
      failedAttempts: 0,
      lockoutExpiry: null,
      idleTimeoutMinutes: 2,
    );
  }

  /// Creates a copy with some fields replaced.
  AppLockState copyWith({
    bool? isLocked,
    bool? isPinSet,
    bool? isBiometricAvailable,
    bool? isBiometricEnabled,
    int? failedAttempts,
    DateTime? lockoutExpiry,
    int? idleTimeoutMinutes,
  }) {
    return AppLockState(
      isLocked: isLocked ?? this.isLocked,
      isPinSet: isPinSet ?? this.isPinSet,
      isBiometricAvailable: isBiometricAvailable ?? this.isBiometricAvailable,
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      failedAttempts: failedAttempts ?? this.failedAttempts,
      lockoutExpiry: lockoutExpiry ?? this.lockoutExpiry,
      idleTimeoutMinutes: idleTimeoutMinutes ?? this.idleTimeoutMinutes,
    );
  }

  /// Checks if the app is currently locked out due to failed attempts.
  bool get isLockedOut => lockoutExpiry != null && DateTime.now().isBefore(lockoutExpiry!);

  /// Gets the remaining lockout time in seconds, or 0 if not locked out.
  int get lockoutRemainingSeconds {
    if (lockoutExpiry == null) return 0;
    final now = DateTime.now();
    if (now.isAfter(lockoutExpiry!)) return 0;
    return lockoutExpiry!.difference(now).inSeconds;
  }
}

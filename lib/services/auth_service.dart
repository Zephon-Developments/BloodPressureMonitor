import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service managing PIN and biometric authentication for the app lock screen.
///
/// Handles PIN storage using PBKDF2 hashing, failed attempt tracking with
/// lockout, and biometric authentication availability checking.
class AuthService {
  final FlutterSecureStorage _secureStorage;
  final LocalAuthentication _localAuth;
  final SharedPreferences _prefs;

  static const String _pinHashKey = 'pin_hash';
  static const String _pinSaltKey = 'pin_salt';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutUntilKey = 'lockout_until';
  static const String _biometricEnabledKey = 'biometric_enabled';

  // PBKDF2 parameters per Clive's requirements
  static const int _pbkdf2Iterations = 10000;
  static const int _saltLength = 32;
  static const int _hashLength = 32;

  AuthService({
    FlutterSecureStorage? secureStorage,
    LocalAuthentication? localAuth,
    required SharedPreferences prefs,
  })  : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
        _localAuth = localAuth ?? LocalAuthentication(),
        _prefs = prefs;

  /// Checks if a PIN has been set.
  Future<bool> isPinSet() async {
    final hash = await _secureStorage.read(key: _pinHashKey);
    return hash != null;
  }

  /// Sets a new PIN, replacing any existing PIN.
  ///
  /// The PIN is hashed using PBKDF2 with 10,000 iterations and stored
  /// in platform secure storage.
  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);

    await _secureStorage.write(key: _pinHashKey, value: hash);
    await _secureStorage.write(key: _pinSaltKey, value: salt);

    // Reset failed attempts when PIN is changed
    await _resetFailedAttempts();
  }

  /// Verifies the provided PIN against the stored hash.
  ///
  /// Returns true if the PIN matches. Updates failed attempt count and
  /// lockout status on failure.
  Future<bool> verifyPin(String pin) async {
    // Check lockout first
    if (await isLockedOut()) {
      return false;
    }

    final storedHash = await _secureStorage.read(key: _pinHashKey);
    final storedSalt = await _secureStorage.read(key: _pinSaltKey);

    if (storedHash == null || storedSalt == null) {
      return false;
    }

    final hash = _hashPin(pin, storedSalt);

    if (hash == storedHash) {
      await _resetFailedAttempts();
      return true;
    } else {
      await _incrementFailedAttempts();
      return false;
    }
  }

  /// Checks if the account is currently locked out due to failed attempts.
  Future<bool> isLockedOut() async {
    final lockoutUntil = _prefs.getInt(_lockoutUntilKey);
    if (lockoutUntil == null) {
      return false;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now < lockoutUntil) {
      return true;
    }

    // Lockout expired, reset
    await _prefs.remove(_lockoutUntilKey);
    return false;
  }

  /// Gets the timestamp when the current lockout expires, or null if not locked.
  Future<DateTime?> getLockoutExpiry() async {
    final lockoutUntil = _prefs.getInt(_lockoutUntilKey);
    if (lockoutUntil == null) {
      return null;
    }

    final expiry = DateTime.fromMillisecondsSinceEpoch(lockoutUntil);
    final now = DateTime.now();

    if (now.isAfter(expiry)) {
      await _prefs.remove(_lockoutUntilKey);
      return null;
    }

    return expiry;
  }

  /// Gets the current number of failed attempts.
  Future<int> getFailedAttempts() async {
    return _prefs.getInt(_failedAttemptsKey) ?? 0;
  }

  /// Resets the PIN, requiring it to be set again.
  Future<void> resetPin() async {
    await _secureStorage.delete(key: _pinHashKey);
    await _secureStorage.delete(key: _pinSaltKey);
    await _resetFailedAttempts();
  }

  /// Checks if biometric authentication is available on the device.
  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } on Exception {
      return false;
    }
  }

  /// Gets the list of available biometric types on the device.
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } on Exception {
      return [];
    }
  }

  /// Checks if biometric authentication is both available and enabled by user.
  Future<bool> isBiometricEnabled() async {
    final enabled = _prefs.getBool(_biometricEnabledKey) ?? false;
    if (!enabled) {
      return false;
    }

    // Verify biometrics are still available (user may have removed them)
    final biometrics = await getAvailableBiometrics();
    if (biometrics.isEmpty) {
      // Disable biometric auth if none available
      await setBiometricEnabled(false);
      return false;
    }

    return true;
  }

  /// Enables or disables biometric authentication.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(_biometricEnabledKey, enabled);
  }

  /// Attempts biometric authentication.
  ///
  /// Returns true if successful, false otherwise. Does not affect
  /// failed attempt count.
  Future<bool> authenticateWithBiometrics() async {
    if (!await isBiometricEnabled()) {
      debugPrint('Biometric authentication skipped: not enabled');
      return false;
    }

    try {
      debugPrint('Attempting biometric authentication...');
      final result = await _localAuth.authenticate(
        localizedReason: 'Authenticate to unlock HyperTrack',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false, // Allow device PIN fallback if biometric fails
        ),
      );
      debugPrint('Biometric authentication result: $result');
      return result;
    } catch (e) {
      debugPrint('Biometric authentication error: $e');
      return false;
    }
  }

  /// Generates a cryptographically secure random salt.
  String _generateSalt() {
    final random = Random.secure();
    final bytes = Uint8List(_saltLength);

    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    return base64.encode(bytes);
  }

  /// Hashes a PIN using PBKDF2 with the provided salt.
  ///
  /// Uses HMAC-SHA256 with 10,000 iterations per Clive's requirements.
  String _hashPin(String pin, String saltBase64) {
    final salt = base64.decode(saltBase64);
    final pinBytes = utf8.encode(pin);

    // PBKDF2 implementation using HMAC-SHA256
    final hash = _pbkdf2(pinBytes, salt, _pbkdf2Iterations, _hashLength);

    return base64.encode(hash);
  }

  /// PBKDF2 key derivation function.
  ///
  /// Implements PBKDF2 using HMAC-SHA256 as the pseudorandom function.
  Uint8List _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final hmac = Hmac(sha256, password);
    final blocks = (keyLength / sha256.convert([]).bytes.length).ceil();
    final derivedKey = <int>[];

    for (var block = 1; block <= blocks; block++) {
      final blockSalt = Uint8List(salt.length + 4)
        ..setRange(0, salt.length, salt)
        ..buffer.asByteData().setUint32(salt.length, block, Endian.big);

      var u = hmac.convert(blockSalt).bytes;
      var f = List<int>.from(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < f.length; j++) {
          f[j] ^= u[j];
        }
      }

      derivedKey.addAll(f);
    }

    return Uint8List.fromList(derivedKey.sublist(0, keyLength));
  }

  /// Increments failed attempt counter and applies lockout if thresholds reached.
  ///
  /// Lockout policy per Clive's requirements:
  /// - 5 attempts: 30 seconds
  /// - 10 attempts: 5 minutes
  /// - 15+ attempts: 30 minutes (cap)
  Future<void> _incrementFailedAttempts() async {
    final attempts = await getFailedAttempts() + 1;
    await _prefs.setInt(_failedAttemptsKey, attempts);

    // Apply lockout based on attempt count
    int lockoutSeconds;
    if (attempts >= 15) {
      lockoutSeconds = 30 * 60; // 30 minutes
    } else if (attempts >= 10) {
      lockoutSeconds = 5 * 60; // 5 minutes
    } else if (attempts >= 5) {
      lockoutSeconds = 30; // 30 seconds
    } else {
      return; // No lockout yet
    }

    final lockoutUntil = DateTime.now()
        .add(Duration(seconds: lockoutSeconds))
        .millisecondsSinceEpoch;

    await _prefs.setInt(_lockoutUntilKey, lockoutUntil);
  }

  /// Resets failed attempt counter and clears lockout.
  Future<void> _resetFailedAttempts() async {
    await _prefs.remove(_failedAttemptsKey);
    await _prefs.remove(_lockoutUntilKey);
  }
}

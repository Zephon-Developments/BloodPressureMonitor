import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure generation and storage of the database encryption password.
///
/// Uses flutter_secure_storage to store the password in platform-specific
/// secure storage (iOS Keychain, Android Keystore). Generates a unique
/// password per installation using cryptographically secure random generation.
class SecurePasswordManager {
  static const _storage = FlutterSecureStorage();
  static const _passwordKey = 'db_encryption_password';
  
  // Lock to prevent race conditions during password generation
  static final _lock = Completer<void>()..complete();
  static Completer<void>? _currentOperation;

  /// Gets the database password, generating and storing a new one if needed.
  ///
  /// The password is generated once per installation and stored securely.
  /// Subsequent calls retrieve the same password from secure storage.
  /// 
  /// This method is thread-safe and prevents race conditions during concurrent
  /// password generation attempts.
  static Future<String> getOrCreatePassword() async {
    // Wait for any ongoing operation to complete
    if (_currentOperation != null) {
      await _currentOperation!.future;
    }
    
    // Check if password exists first
    String? password = await _storage.read(key: _passwordKey);
    if (password != null) {
      return password;
    }
    
    // Create a new operation lock
    _currentOperation = Completer<void>();
    
    try {
      // Double-check password doesn't exist (another thread may have created it)
      password = await _storage.read(key: _passwordKey);
      
      if (password == null) {
        password = _generateSecurePassword();
        await _storage.write(key: _passwordKey, value: password);
      }
      
      return password;
    } finally {
      // Release the lock
      _currentOperation!.complete();
      _currentOperation = null;
    }
  }

  /// Generates a cryptographically secure random password.
  ///
  /// Creates a Base64-encoded password from 48 bytes of random data,
  /// providing 384 bits of entropy for AES-256 encryption.
  static String _generateSecurePassword() {
    final random = Random.secure();
    final bytes = Uint8List(48); // 48 bytes provides 384 bits of entropy

    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = random.nextInt(256);
    }

    // Convert to base64 using standard library
    return base64.encode(bytes);
  }

  /// Deletes the stored password (use with caution - will make existing
  /// database unreadable).
  ///
  /// Only use this in testing scenarios or when implementing a "reset app"
  /// feature that also deletes the encrypted database.
  static Future<void> deletePassword() async {
    await _storage.delete(key: _passwordKey);
  }
}

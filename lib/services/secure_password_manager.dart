import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages secure generation and storage of the database encryption password.
///
/// Uses flutter_secure_storage to store the password in platform-specific
/// secure storage (iOS Keychain, Android Keystore). Generates a unique
/// password per installation using cryptographically secure random generation.
class SecurePasswordManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );
  static const _passwordKey = 'db_encryption_password';

  /// Gets the database password, generating and storing a new one if needed.
  ///
  /// The password is generated once per installation and stored securely.
  /// Subsequent calls retrieve the same password from secure storage.
  static Future<String> getOrCreatePassword() async {
    String? password = await _storage.read(key: _passwordKey);

    if (password == null) {
      password = _generateSecurePassword();
      await _storage.write(key: _passwordKey, value: password);
    }

    return password;
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

    // Convert to base64 for a safe string representation
    return _bytesToBase64(bytes);
  }

  /// Converts bytes to Base64 string without using dart:convert
  /// to maintain compatibility with sqflite_sqlcipher.
  static String _bytesToBase64(Uint8List bytes) {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    final buffer = StringBuffer();

    for (int i = 0; i < bytes.length; i += 3) {
      final chunk = (bytes[i] << 16) |
          ((i + 1 < bytes.length ? bytes[i + 1] : 0) << 8) |
          (i + 2 < bytes.length ? bytes[i + 2] : 0);

      buffer.write(chars[(chunk >> 18) & 0x3F]);
      buffer.write(chars[(chunk >> 12) & 0x3F]);
      buffer.write(i + 1 < bytes.length ? chars[(chunk >> 6) & 0x3F] : '=');
      buffer.write(i + 2 < bytes.length ? chars[chunk & 0x3F] : '=');
    }

    return buffer.toString();
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

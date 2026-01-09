import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart';

import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';

/// Result of a backup operation.
sealed class BackupResult {
  const BackupResult();
}

/// Successful backup with file path.
class BackupSuccess extends BackupResult {
  final String filePath;
  final int sizeBytes;

  const BackupSuccess({
    required this.filePath,
    required this.sizeBytes,
  });
}

/// Backup operation failed.
class BackupFailure extends BackupResult {
  final String message;
  final BackupErrorType errorType;

  const BackupFailure({
    required this.message,
    required this.errorType,
  });
}

/// Result of a restore operation.
sealed class RestoreResult {
  const RestoreResult();
}

/// Successful restore.
class RestoreSuccess extends RestoreResult {
  const RestoreSuccess();
}

/// Restore operation failed.
class RestoreFailure extends RestoreResult {
  final String message;
  final RestoreErrorType errorType;

  const RestoreFailure({
    required this.message,
    required this.errorType,
  });
}

/// Backup error categories.
enum BackupErrorType {
  weakPassphrase,
  databaseAccess,
  encryption,
  fileSystem,
  unexpected,
}

/// Restore error categories.
enum RestoreErrorType {
  invalidFile,
  corruptedFile,
  wrongPassphrase,
  versionMismatch,
  insufficientSpace,
  databaseAccess,
  decryption,
  fileSystem,
  unexpected,
}

/// Service for creating and restoring encrypted full-app backups.
///
/// Uses AES-256-GCM for encryption with PBKDF2-HMAC-SHA256 key derivation.
/// Backups are stored in a custom .htb (HealthLog Backup) format with
/// header metadata and encrypted SQLCipher database payload.
class BackupService {
  static const String _backupExtension = '.htb';
  static const String _magicHeader = 'HTB1';
  static const int _saltLength = 32;
  static const int _ivLength = 12;
  static const int _kdfIterations = 100000;
  static const int _minPassphraseLength = 8;

  final AppInfoService _appInfoService;

  const BackupService({
    required AppInfoService appInfoService,
  }) : _appInfoService = appInfoService;

  /// Creates an encrypted backup of the application database.
  ///
  /// Returns [BackupSuccess] with the file path on success,
  /// or [BackupFailure] with error details on failure.
  ///
  /// The backup process:
  /// 1. Validates passphrase strength (min 8 chars)
  /// 2. Reads the SQLCipher database file
  /// 3. Computes SHA-256 checksum of plaintext
  /// 4. Derives encryption key using PBKDF2 (100k iterations)
  /// 5. Encrypts with AES-256-GCM
  /// 6. Writes .htb file with header + encrypted payload
  ///
  /// Heavy cryptographic operations run in an isolate to avoid UI jank.
  Future<BackupResult> createBackup({
    required String passphrase,
  }) async {
    try {
      // Validate passphrase strength
      if (passphrase.length < _minPassphraseLength) {
        return BackupFailure(
          message:
              'Passphrase must be at least $_minPassphraseLength characters.',
          errorType: BackupErrorType.weakPassphrase,
        );
      }

      // Get database file path
      final dbFile = await _getDatabaseFile();
      if (!await dbFile.exists()) {
        return const BackupFailure(
          message: 'Database file not found.',
          errorType: BackupErrorType.databaseAccess,
        );
      }

      // Read database file
      final Uint8List dbBytes = await dbFile.readAsBytes();

      // Compute checksum of plaintext
      final checksumBytes = sha256.convert(dbBytes).bytes;

      // Get app version
      final appVersion = await _appInfoService.getAppVersion();

      // Prepare encryption parameters
      final encryptionParams = _EncryptionParams(
        plaintext: dbBytes,
        passphrase: passphrase,
        appVersion: appVersion,
        schemaVersion: DatabaseService.schemaVersion,
        plaintextChecksum: Uint8List.fromList(checksumBytes),
      );

      // Run encryption in isolate
      final encryptedData = await compute(
        _encryptInIsolate,
        encryptionParams,
      );

      // Generate backup filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename = 'HealthLog_backup_$timestamp$_backupExtension';

      // Get backup directory
      final backupDir = await getApplicationDocumentsDirectory();
      final backupPath = path.join(backupDir.path, filename);

      // Write backup file
      final backupFile = File(backupPath);
      await backupFile.writeAsBytes(encryptedData, flush: true);

      return BackupSuccess(
        filePath: backupPath,
        sizeBytes: encryptedData.length,
      );
    } on BackupFailure catch (e) {
      return e;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during backup: $e');
      debugPrint(stackTrace.toString());
      return BackupFailure(
        message: 'An unexpected error occurred during backup.',
        errorType: BackupErrorType.unexpected,
      );
    }
  }

  /// Restores the database from an encrypted backup file.
  ///
  /// Returns [RestoreSuccess] on success, or [RestoreFailure] with error
  /// details on failure.
  ///
  /// The restore process:
  /// 1. Validates backup file exists and is readable
  /// 2. Parses header and validates magic/version
  /// 3. Checks free space (must be ≥2x backup size)
  /// 4. Creates checkpoint of current database
  /// 5. Derives decryption key using PBKDF2
  /// 6. Decrypts payload in isolate
  /// 7. Validates checksum of decrypted data
  /// 8. Checks schema compatibility
  /// 9. Atomically swaps database file
  /// 10. Rolls back to checkpoint on any failure
  ///
  /// CRITICAL: Existing database is preserved if restore fails.
  Future<RestoreResult> restoreBackup({
    required String passphrase,
    required String backupPath,
  }) async {
    File? checkpoint;

    try {
      // Validate backup file
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return const RestoreFailure(
          message: 'Backup file not found.',
          errorType: RestoreErrorType.invalidFile,
        );
      }

      // Read backup file
      final backupBytes = await backupFile.readAsBytes();

      // Parse header
      final headerResult = _parseHeader(backupBytes);
      if (headerResult is _HeaderParseFailure) {
        return RestoreFailure(
          message: headerResult.message,
          errorType: RestoreErrorType.corruptedFile,
        );
      }

      final header = (headerResult as _HeaderParseSuccess).header;

      // Check schema compatibility
      if (header.schemaVersion > DatabaseService.schemaVersion) {
        return RestoreFailure(
          message:
              'Backup schema version (${header.schemaVersion}) is newer than app version (${DatabaseService.schemaVersion}). Please update the app.',
          errorType: RestoreErrorType.versionMismatch,
        );
      }

      // Check free space (need at least 2x backup size)
      final documentsDir = await getApplicationDocumentsDirectory();
      final availableSpace = await _getAvailableSpace(documentsDir.path);
      final requiredSpace = backupBytes.length * 2;

      if (availableSpace < requiredSpace) {
        final requiredMB = (requiredSpace / (1024 * 1024)).toStringAsFixed(1);
        final availableMB = (availableSpace / (1024 * 1024)).toStringAsFixed(1);
        return RestoreFailure(
          message:
              'Insufficient storage space. Need $requiredMB MB, have $availableMB MB.',
          errorType: RestoreErrorType.insufficientSpace,
        );
      }

      // Create checkpoint of current database
      final dbFile = await _getDatabaseFile();
      if (await dbFile.exists()) {
        final checkpointPath = '${dbFile.path}.checkpoint';
        checkpoint = File(checkpointPath);
        await dbFile.copy(checkpointPath);
        debugPrint('Created database checkpoint at $checkpointPath');
      }

      // Extract encrypted payload
      final payload = backupBytes.sublist(header.headerLength);

      // Prepare decryption parameters
      final decryptionParams = _DecryptionParams(
        encryptedPayload: payload,
        passphrase: passphrase,
        saltEnc: header.saltEnc,
        iv: header.iv,
        authTag: header.authTag,
        expectedChecksum: header.checksum,
      );

      // Run decryption in isolate
      final decryptResult = await compute(
        _decryptInIsolate,
        decryptionParams,
      );

      if (decryptResult is _DecryptFailure) {
        return RestoreFailure(
          message: decryptResult.message,
          errorType: decryptResult.errorType,
        );
      }

      final decryptedDb = (decryptResult as _DecryptSuccess).plaintext;

      // Close database connection before swap
      await DatabaseService.closeDatabase();

      // Atomic file swap
      final tempFile = File('${dbFile.path}.restore_temp');
      await tempFile.writeAsBytes(decryptedDb, flush: true);
      await tempFile.rename(dbFile.path);

      debugPrint('Database restored successfully');

      // Clean up checkpoint on success
      await checkpoint?.delete();

      return const RestoreSuccess();
    } on RestoreFailure catch (e) {
      // Rollback to checkpoint if it exists
      if (checkpoint != null && await checkpoint.exists()) {
        try {
          final dbFile = await _getDatabaseFile();
          await checkpoint.copy(dbFile.path);
          await checkpoint.delete();
          debugPrint('Rolled back to checkpoint after restore failure');
        } catch (rollbackError) {
          debugPrint('Failed to rollback to checkpoint: $rollbackError');
        }
      }
      return e;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during restore: $e');
      debugPrint(stackTrace.toString());

      // Rollback to checkpoint if it exists
      if (checkpoint != null && await checkpoint.exists()) {
        try {
          final dbFile = await _getDatabaseFile();
          await checkpoint.copy(dbFile.path);
          await checkpoint.delete();
          debugPrint('Rolled back to checkpoint after unexpected error');
        } catch (rollbackError) {
          debugPrint('Failed to rollback to checkpoint: $rollbackError');
        }
      }

      return RestoreFailure(
        message: 'An unexpected error occurred during restore.',
        errorType: RestoreErrorType.unexpected,
      );
    }
  }

  /// Validates a backup file without decrypting it.
  ///
  /// Returns true if the file has a valid header and structure.
  /// Does NOT validate the passphrase or decrypt the payload.
  Future<bool> validateBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return false;
      }

      final backupBytes = await backupFile.readAsBytes();
      final headerResult = _parseHeader(backupBytes);

      return headerResult is _HeaderParseSuccess;
    } catch (e) {
      debugPrint('Error validating backup: $e');
      return false;
    }
  }

  /// Gets the database file handle.
  Future<File> _getDatabaseFile() async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final dbPath = path.join(documentsDir.path, DatabaseService.databaseName);
    return File(dbPath);
  }

  /// Gets available disk space in bytes.
  Future<int> _getAvailableSpace(String directoryPath) async {
    if (Platform.isAndroid || Platform.isLinux) {
      try {
        final result = await Process.run('df', ['-k', directoryPath]);
        if (result.exitCode == 0) {
          final lines = (result.stdout as String).split('\n');
          if (lines.length > 1) {
            final parts = lines[1].split(RegExp(r'\s+'));
            if (parts.length > 3) {
              final availableKB = int.tryParse(parts[3]) ?? 0;
              return availableKB * 1024;
            }
          }
        }
      } catch (e) {
        debugPrint('Error getting available space: $e');
      }
    }

    // Fallback: assume 1GB available (conservative)
    return 1024 * 1024 * 1024;
  }

  /// Parses the backup file header.
  _HeaderParseResult _parseHeader(Uint8List data) {
    try {
      if (data.length < 100) {
        return _HeaderParseFailure('File too small to be valid backup');
      }

      int offset = 0;

      // Magic header (4 bytes)
      final magic = utf8.decode(data.sublist(offset, offset + 4));
      offset += 4;
      if (magic != _magicHeader) {
        return _HeaderParseFailure('Invalid file format (magic: $magic)');
      }

      // App version length (4 bytes)
      final appVersionLength = ByteData.sublistView(
        data,
        offset,
        offset + 4,
      ).getUint32(0, Endian.little);
      offset += 4;

      // App version (variable)
      final appVersion =
          utf8.decode(data.sublist(offset, offset + appVersionLength));
      offset += appVersionLength;

      // Schema version (4 bytes)
      final schemaVersion = ByteData.sublistView(
        data,
        offset,
        offset + 4,
      ).getUint32(0, Endian.little);
      offset += 4;

      // Created timestamp (8 bytes)
      final createdMs = ByteData.sublistView(
        data,
        offset,
        offset + 8,
      ).getUint64(0, Endian.little);
      offset += 8;

      // Salt for encryption (32 bytes)
      final saltEnc = Uint8List.fromList(data.sublist(offset, offset + 32));
      offset += 32;

      // Salt for checksum (32 bytes) - currently unused but reserved
      offset += 32; // skip saltChk

      // IV/Nonce (12 bytes)
      final iv = Uint8List.fromList(data.sublist(offset, offset + 12));
      offset += 12;

      // Auth tag length (4 bytes)
      final authTagLength = ByteData.sublistView(
        data,
        offset,
        offset + 4,
      ).getUint32(0, Endian.little);
      offset += 4;

      // Auth tag (variable, typically 16 bytes for GCM)
      final authTag =
          Uint8List.fromList(data.sublist(offset, offset + authTagLength));
      offset += authTagLength;

      // Checksum (32 bytes SHA-256)
      final checksum = Uint8List.fromList(data.sublist(offset, offset + 32));
      offset += 32;

      // Payload length (8 bytes)
      final payloadLength = ByteData.sublistView(
        data,
        offset,
        offset + 8,
      ).getUint64(0, Endian.little);
      offset += 8;

      final header = _BackupHeader(
        magic: magic,
        appVersion: appVersion,
        schemaVersion: schemaVersion,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
        saltEnc: saltEnc,
        iv: iv,
        authTag: authTag,
        checksum: checksum,
        payloadLength: payloadLength,
        headerLength: offset,
      );

      return _HeaderParseSuccess(header);
    } catch (e) {
      return _HeaderParseFailure('Header parsing failed: $e');
    }
  }

  /// Encrypts data in an isolate (static top-level function).
  static Uint8List _encryptInIsolate(_EncryptionParams params) {
    // Generate random salts and IV
    final saltEnc = _generateRandomBytes(_saltLength);
    final saltChk = _generateRandomBytes(_saltLength); // Reserved
    final iv = _generateRandomBytes(_ivLength);

    // Derive encryption key using PBKDF2
    final key = _deriveKey(
      passphrase: params.passphrase,
      salt: saltEnc,
      iterations: _kdfIterations,
    );

    // Encrypt with AES-256-GCM
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        true,
        AEADParameters(
          KeyParameter(key),
          128, // 128-bit authentication tag
          iv,
          Uint8List(0), // No additional authenticated data
        ),
      );

    // In GCM mode, process() returns ciphertext + auth tag combined
    final encryptedWithTag = cipher.process(params.plaintext);

    // Extract auth tag (last 16 bytes) and ciphertext
    final authTagLength = 16; // 128 bits
    final ciphertextLength = encryptedWithTag.length - authTagLength;
    final encrypted = Uint8List.fromList(
      encryptedWithTag.sublist(0, ciphertextLength),
    );
    final authTag = Uint8List.fromList(
      encryptedWithTag.sublist(ciphertextLength),
    );

    // Build header
    final appVersionBytes = utf8.encode(params.appVersion);
    final createdMs = DateTime.now().millisecondsSinceEpoch;

    final header = BytesBuilder();
    header.add(utf8.encode(_magicHeader)); // 4 bytes
    header.add(_uint32Bytes(appVersionBytes.length)); // 4 bytes
    header.add(appVersionBytes); // variable
    header.add(_uint32Bytes(params.schemaVersion)); // 4 bytes
    header.add(_uint64Bytes(createdMs)); // 8 bytes
    header.add(saltEnc); // 32 bytes
    header.add(saltChk); // 32 bytes (reserved)
    header.add(iv); // 12 bytes
    header.add(_uint32Bytes(authTag.length)); // 4 bytes
    header.add(authTag); // 16 bytes
    header.add(params.plaintextChecksum); // 32 bytes
    header.add(_uint64Bytes(encrypted.length)); // 8 bytes

    // Combine header + payload
    final result = BytesBuilder();
    result.add(header.toBytes());
    result.add(encrypted);

    return result.toBytes();
  }

  /// Decrypts data in an isolate (static top-level function).
  static _DecryptResult _decryptInIsolate(_DecryptionParams params) {
    try {
      // Derive decryption key
      final key = _deriveKey(
        passphrase: params.passphrase,
        salt: params.saltEnc,
        iterations: _kdfIterations,
      );

      // Decrypt with AES-256-GCM
      final cipher = GCMBlockCipher(AESEngine())
        ..init(
          false,
          AEADParameters(
            KeyParameter(key),
            128, // 128-bit authentication tag
            params.iv,
            Uint8List(0), // No additional authenticated data
          ),
        );

      // For GCM decryption, process() expects ciphertext + auth tag combined
      final ciphertextWithTag =
          Uint8List(params.encryptedPayload.length + params.authTag.length);
      ciphertextWithTag.setRange(
          0, params.encryptedPayload.length, params.encryptedPayload);
      ciphertextWithTag.setRange(params.encryptedPayload.length,
          ciphertextWithTag.length, params.authTag);

      final decrypted = cipher.process(ciphertextWithTag);

      // Verify checksum
      final actualChecksum = sha256.convert(decrypted).bytes;
      if (!_bytesEqual(actualChecksum, params.expectedChecksum)) {
        return _DecryptFailure(
          message: 'Backup file is corrupted or passphrase is incorrect.',
          errorType: RestoreErrorType.corruptedFile,
        );
      }

      return _DecryptSuccess(plaintext: decrypted);
    } catch (e) {
      return _DecryptFailure(
        message: 'Decryption failed: $e',
        errorType: RestoreErrorType.decryption,
      );
    }
  }

  /// Derives a cryptographic key using PBKDF2-HMAC-SHA256.
  static Uint8List _deriveKey({
    required String passphrase,
    required Uint8List salt,
    required int iterations,
  }) {
    final passphraseBytes = utf8.encode(passphrase);
    final hmac = Hmac(sha256, passphraseBytes);

    // PBKDF2 implementation
    var result = Uint8List(32); // 256 bits

    // Single block for 256-bit key
    final blockIndex = _uint32BytesBigEndian(1);
    var u = hmac.convert([...salt, ...blockIndex]).bytes;

    for (var i = 0; i < 32; i++) {
      result[i] = u[i];
    }

    for (var iter = 1; iter < iterations; iter++) {
      u = hmac.convert(u).bytes;
      for (var i = 0; i < 32; i++) {
        result[i] ^= u[i];
      }
    }

    return result;
  }

  /// Generates cryptographically secure random bytes.
  static Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(length, (_) => random.nextInt(256)),
    );
  }

  /// Compares two byte arrays for equality.
  static bool _bytesEqual(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Converts uint32 to little-endian bytes.
  static Uint8List _uint32Bytes(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Converts uint64 to little-endian bytes.
  static Uint8List _uint64Bytes(int value) {
    final data = ByteData(8);
    data.setUint64(0, value, Endian.little);
    return data.buffer.asUint8List();
  }

  /// Converts uint32 to big-endian bytes (for PBKDF2).
  static Uint8List _uint32BytesBigEndian(int value) {
    final data = ByteData(4);
    data.setUint32(0, value, Endian.big);
    return data.buffer.asUint8List();
  }
}

// Internal classes for encryption/decryption

class _EncryptionParams {
  final Uint8List plaintext;
  final String passphrase;
  final String appVersion;
  final int schemaVersion;
  final Uint8List plaintextChecksum;

  const _EncryptionParams({
    required this.plaintext,
    required this.passphrase,
    required this.appVersion,
    required this.schemaVersion,
    required this.plaintextChecksum,
  });
}

class _DecryptionParams {
  final Uint8List encryptedPayload;
  final String passphrase;
  final Uint8List saltEnc;
  final Uint8List iv;
  final Uint8List authTag;
  final Uint8List expectedChecksum;

  const _DecryptionParams({
    required this.encryptedPayload,
    required this.passphrase,
    required this.saltEnc,
    required this.iv,
    required this.authTag,
    required this.expectedChecksum,
  });
}

sealed class _DecryptResult {}

class _DecryptSuccess extends _DecryptResult {
  final Uint8List plaintext;

  _DecryptSuccess({required this.plaintext});
}

class _DecryptFailure extends _DecryptResult {
  final String message;
  final RestoreErrorType errorType;

  _DecryptFailure({
    required this.message,
    required this.errorType,
  });
}

class _BackupHeader {
  final String magic;
  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final Uint8List saltEnc;
  final Uint8List iv;
  final Uint8List authTag;
  final Uint8List checksum;
  final int payloadLength;
  final int headerLength;

  const _BackupHeader({
    required this.magic,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    required this.saltEnc,
    required this.iv,
    required this.authTag,
    required this.checksum,
    required this.payloadLength,
    required this.headerLength,
  });
}

sealed class _HeaderParseResult {}

class _HeaderParseSuccess extends _HeaderParseResult {
  final _BackupHeader header;

  _HeaderParseSuccess(this.header);
}

class _HeaderParseFailure extends _HeaderParseResult {
  final String message;

  _HeaderParseFailure(this.message);
}

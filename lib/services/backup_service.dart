import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

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
/// Uses SQLCipher's native backup functionality with AES-256 encryption.
/// Backups are stored in a custom .htb (HealthLog Backup) format with
/// metadata header and encrypted SQLCipher database.
class BackupService {
  static const String _backupExtension = '.htb';
  static const String _magicHeader = 'HTB2'; // Version 2 for SQLCipher-native
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
  /// 2. Uses SQLCipher's ATTACH/sqlcipher_export to create encrypted copy
  /// 3. Wraps the encrypted DB in .htb format with metadata header
  /// 4. Writes final backup file with header + encrypted database
  ///
  /// CRITICAL: Uses SQLCipher's native C-level encryption (AES-256-CBC).
  Future<BackupResult> createBackup({
    required String passphrase,
  }) async {
    File? tempBackupFile;

    try {
      // Validate passphrase strength
      if (passphrase.length < _minPassphraseLength) {
        return BackupFailure(
          message:
              'Passphrase must be at least $_minPassphraseLength characters.',
          errorType: BackupErrorType.weakPassphrase,
        );
      }

      // Get main database
      final dbService = DatabaseService();
      final mainDb = await dbService.database;

      // Generate backup filename
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final backupDir = await getApplicationDocumentsDirectory();

      // Create temporary encrypted database
      final tempBackupPath = path.join(
        backupDir.path,
        'temp_backup_$timestamp.db',
      );
      tempBackupFile = File(tempBackupPath);

      // Use SQLCipher's native backup: ATTACH + sqlcipher_export
      await mainDb.execute(
        'ATTACH DATABASE ? AS backup KEY ?',
        [tempBackupPath, passphrase],
      );

      await mainDb.execute('SELECT sqlcipher_export(\'backup\')');
      await mainDb.execute('DETACH DATABASE backup');

      debugPrint('SQLCipher export completed to $tempBackupPath');

      // Read the encrypted database file
      final encryptedDbBytes = await tempBackupFile.readAsBytes();

      // Get app version
      final appVersion = await _appInfoService.getAppVersion();

      // Build header
      final header = _buildHeader(
        appVersion: appVersion,
        schemaVersion: DatabaseService.schemaVersion,
        payloadSize: encryptedDbBytes.length,
      );

      // Combine header + encrypted database
      final finalBackupPath = path.join(
        backupDir.path,
        'HealthLog_backup_$timestamp$_backupExtension',
      );

      final finalBackupFile = File(finalBackupPath);
      final sink = finalBackupFile.openWrite();
      sink.add(header);
      sink.add(encryptedDbBytes);
      await sink.flush();
      await sink.close();

      // Clean up temp file
      await tempBackupFile.delete();

      final fileSize = await finalBackupFile.length();

      return BackupSuccess(
        filePath: finalBackupPath,
        sizeBytes: fileSize,
      );
    } on BackupFailure catch (e) {
      return e;
    } catch (e, stackTrace) {
      debugPrint('Unexpected error during backup: $e');
      debugPrint(stackTrace.toString());

      // Clean up temp file
      if (tempBackupFile != null && await tempBackupFile.exists()) {
        await tempBackupFile.delete();
      }

      return BackupFailure(
        message: 'An unexpected error occurred during backup: $e',
        errorType: BackupErrorType.unexpected,
      );
    } finally {
      // Ensure backup database is detached
      try {
        final dbService = DatabaseService();
        final mainDb = await dbService.database;
        await mainDb.execute('DETACH DATABASE backup');
      } catch (_) {
        // Ignore detach errors (may not be attached)
      }
    }
  }

  /// Restores the database from an encrypted backup file.
  ///
  /// Returns [RestoreSuccess] on success, or [RestoreFailure] with error
  /// details on failure.
  ///
  /// The restore process:
  /// 1. Validates backup file exists and header is valid
  /// 2. Checks schema compatibility
  /// 3. Checks free space (must be ≥2x backup size)
  /// 4. Creates checkpoint of current database
  /// 5. Opens backup file with user passphrase
  /// 6. Exports to new database file
  /// 7. Atomically swaps database file
  /// 8. Rolls back to checkpoint on any failure
  ///
  /// CRITICAL: Existing database is preserved if restore fails.
  Future<RestoreResult> restoreBackup({
    required String passphrase,
    required String backupPath,
  }) async {
    File? checkpoint;
    File? tempRestoreFile;

    try {
      // Validate backup file
      final backupFile = File(backupPath);
      if (!await backupFile.exists()) {
        return const RestoreFailure(
          message: 'Backup file not found.',
          errorType: RestoreErrorType.invalidFile,
        );
      }

      // Read and parse header
      final backupBytes = await backupFile.readAsBytes();
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

      // Check free space
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

      // Extract encrypted database from backup
      final encryptedDb = backupBytes.sublist(header.headerLength);

      // Write encrypted DB to temporary file
      final tempRestorePath = '${dbFile.path}.restore_temp';
      tempRestoreFile = File(tempRestorePath);
      await tempRestoreFile.writeAsBytes(encryptedDb, flush: true);

      // Try to open backup database with passphrase
      Database? testDb;
      try {
        testDb = await openDatabase(
          tempRestorePath,
          password: passphrase,
          readOnly: true,
        );

        // Validate it's a valid SQLCipher database
        await testDb.rawQuery('SELECT COUNT(*) FROM sqlite_master');
        await testDb.close();
      } catch (e) {
        await testDb?.close();
        return RestoreFailure(
          message:
              'Failed to open backup file. Incorrect passphrase or corrupted backup.',
          errorType: RestoreErrorType.wrongPassphrase,
        );
      }

      // Close main database connection before swap
      await DatabaseService.closeDatabase();

      // Atomic file swap
      await tempRestoreFile.rename(dbFile.path);

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

      // Clean up temp restore file
      if (tempRestoreFile != null && await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
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

      // Clean up temp restore file
      if (tempRestoreFile != null && await tempRestoreFile.exists()) {
        await tempRestoreFile.delete();
      }

      return RestoreFailure(
        message: 'An unexpected error occurred during restore: $e',
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

  /// Builds a metadata header for the backup file.
  List<int> _buildHeader({
    required String appVersion,
    required int schemaVersion,
    required int payloadSize,
  }) {
    final buffer = <int>[];

    // Magic header (4 bytes)
    buffer.addAll(utf8.encode(_magicHeader));

    // App version length (4 bytes, little-endian)
    final appVersionBytes = utf8.encode(appVersion);
    buffer.addAll(_uint32Bytes(appVersionBytes.length));

    // App version (variable)
    buffer.addAll(appVersionBytes);

    // Schema version (4 bytes)
    buffer.addAll(_uint32Bytes(schemaVersion));

    // Created timestamp (8 bytes)
    final createdMs = DateTime.now().millisecondsSinceEpoch;
    buffer.addAll(_uint64Bytes(createdMs));

    // Payload length (8 bytes)
    buffer.addAll(_uint64Bytes(payloadSize));

    return buffer;
  }

  /// Parses the backup file header.
  _HeaderParseResult _parseHeader(List<int> data) {
    try {
      if (data.length < 30) {
        return _HeaderParseFailure('File too small to be valid backup');
      }

      int offset = 0;

      // Magic header (4 bytes)
      final magic = utf8.decode(data.sublist(offset, offset + 4));
      offset += 4;

      if (magic != _magicHeader) {
        return _HeaderParseFailure(
          'Invalid file format (expected $_magicHeader, got $magic)',
        );
      }

      // App version length (4 bytes)
      final appVersionLength = _readUint32(data, offset);
      offset += 4;

      // App version (variable)
      final appVersion =
          utf8.decode(data.sublist(offset, offset + appVersionLength));
      offset += appVersionLength;

      // Schema version (4 bytes)
      final schemaVersion = _readUint32(data, offset);
      offset += 4;

      // Created timestamp (8 bytes)
      final createdMs = _readUint64(data, offset);
      offset += 8;

      // Payload length (8 bytes)
      final payloadLength = _readUint64(data, offset);
      offset += 8;

      final header = _BackupHeader(
        magic: magic,
        appVersion: appVersion,
        schemaVersion: schemaVersion,
        createdAt: DateTime.fromMillisecondsSinceEpoch(createdMs),
        payloadLength: payloadLength,
        headerLength: offset,
      );

      return _HeaderParseSuccess(header);
    } catch (e) {
      return _HeaderParseFailure('Header parsing failed: $e');
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

  /// Converts uint32 to little-endian bytes.
  List<int> _uint32Bytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
    ];
  }

  /// Converts uint64 to little-endian bytes.
  List<int> _uint64Bytes(int value) {
    return [
      value & 0xFF,
      (value >> 8) & 0xFF,
      (value >> 16) & 0xFF,
      (value >> 24) & 0xFF,
      (value >> 32) & 0xFF,
      (value >> 40) & 0xFF,
      (value >> 48) & 0xFF,
      (value >> 56) & 0xFF,
    ];
  }

  /// Reads uint32 from byte list at offset.
  int _readUint32(List<int> data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24);
  }

  /// Reads uint64 from byte list at offset.
  int _readUint64(List<int> data, int offset) {
    return data[offset] |
        (data[offset + 1] << 8) |
        (data[offset + 2] << 16) |
        (data[offset + 3] << 24) |
        (data[offset + 4] << 32) |
        (data[offset + 5] << 40) |
        (data[offset + 6] << 48) |
        (data[offset + 7] << 56);
  }
}

// Internal header types

class _BackupHeader {
  final String magic;
  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final int payloadLength;
  final int headerLength;

  const _BackupHeader({
    required this.magic,
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
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

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/backup_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import '../helpers/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late BackupService backupService;

  setUp(() async {
    // Mock package_info_plus
    PackageInfo.setMockInitialValues(
      appName: 'HealthLog',
      packageName: 'com.zephondevelopments.healthlog',
      version: '1.3.0',
      buildNumber: '3',
      buildSignature: '',
      installerStore: null,
    );

    // Mock flutter_secure_storage
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return 'test_secure_password_12345';
      } else if (methodCall.method == 'write') {
        return null;
      }
      return null;
    });

    // Set up temp directory
    tempDir = await Directory.systemTemp.createTemp('backup_test');
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);

    // Initialize sqflite_ffi for testing
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    // Create test database
    final dbPath = path.join(tempDir.path, DatabaseService.databaseName);
    final testDb = await openDatabase(
      dbPath,
      version: DatabaseService.schemaVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE Profile (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            colorHex TEXT,
            avatarIcon TEXT,
            preferredUnits TEXT NOT NULL DEFAULT 'mmHg',
            preferredWeightUnit TEXT NOT NULL DEFAULT 'kg',
            dateOfBirth TEXT,
            patientId TEXT,
            doctorName TEXT,
            clinicName TEXT,
            createdAt TEXT NOT NULL
          )
        ''');
      },
    );

    // Insert test data
    await testDb.insert('Profile', {
      'name': 'Test User',
      'createdAt': DateTime.now().toIso8601String(),
    });

    await testDb.close();

    backupService = BackupService(
      appInfoService: const AppInfoService(),
    );
  });

  tearDown(() async {
    await DatabaseService.closeDatabase();
    await tempDir.delete(recursive: true);
    // Clean up mock method channel handler
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage')
        .setMockMethodCallHandler(null);
  });

  group('BackupService', () {
    group('createBackup', () {
      test('rejects weak passphrase', () async {
        final result = await backupService.createBackup(
          passphrase: 'short',
        );

        expect(result, isA<BackupFailure>());
        final failure = result as BackupFailure;
        expect(failure.errorType, BackupErrorType.weakPassphrase);
      });

      test('creates backup with valid passphrase', () async {
        final result = await backupService.createBackup(
          passphrase: 'ValidPassphrase123',
        );

        expect(result, isA<BackupSuccess>());
        final success = result as BackupSuccess;
        expect(success.filePath, contains('.htb'));
        expect(success.sizeBytes, greaterThan(0));

        // Verify file exists
        final backupFile = File(success.filePath);
        expect(await backupFile.exists(), isTrue);
      });

      test('backup filename includes timestamp', () async {
        final result = await backupService.createBackup(
          passphrase: 'ValidPassphrase123',
        );

        expect(result, isA<BackupSuccess>());
        final success = result as BackupSuccess;
        final filename = path.basename(success.filePath);
        expect(filename, matches(RegExp(r'HealthLog_backup_\d{8}_\d{6}\.htb')));
      });
    });

    group('validateBackup', () {
      test('returns false for non-existent file', () async {
        final isValid = await backupService.validateBackup(
          '/non/existent/path.htb',
        );

        expect(isValid, isFalse);
      });

      test('returns true for valid backup file', () async {
        // Create a backup first
        final createResult = await backupService.createBackup(
          passphrase: 'ValidPassphrase123',
        );

        expect(createResult, isA<BackupSuccess>());
        final backupPath = (createResult as BackupSuccess).filePath;

        // Validate it
        final isValid = await backupService.validateBackup(backupPath);
        expect(isValid, isTrue);
      });

      test('returns false for corrupted file', () async {
        // Create invalid backup file
        final invalidPath = path.join(tempDir.path, 'invalid.htb');
        final invalidFile = File(invalidPath);
        await invalidFile.writeAsBytes(Uint8List.fromList([1, 2, 3]));

        final isValid = await backupService.validateBackup(invalidPath);
        expect(isValid, isFalse);
      });
    });

    group('restoreBackup', () {
      test('rejects non-existent backup file', () async {
        final result = await backupService.restoreBackup(
          passphrase: 'ValidPassphrase123',
          backupPath: '/non/existent/path.htb',
        );

        expect(result, isA<RestoreFailure>());
        final failure = result as RestoreFailure;
        expect(failure.errorType, RestoreErrorType.invalidFile);
      });

      test('successfully restores valid backup', () async {
        // Create a backup
        final createResult = await backupService.createBackup(
          passphrase: 'ValidPassphrase123',
        );

        expect(createResult, isA<BackupSuccess>());
        final backupPath = (createResult as BackupSuccess).filePath;

        // Get original database file info
        final dbPath = path.join(tempDir.path, DatabaseService.databaseName);
        final originalDbFile = File(dbPath);
        final originalModified = await originalDbFile.lastModified();

        // Close database for restore
        await DatabaseService.closeDatabase();

        // Small delay to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 100));

        // Restore backup
        final restoreResult = await backupService.restoreBackup(
          passphrase: 'ValidPassphrase123',
          backupPath: backupPath,
        );

        expect(restoreResult, isA<RestoreSuccess>());

        // Verify database file was modified
        final restoredDbFile = File(dbPath);
        expect(await restoredDbFile.exists(), isTrue);

        // File should have been replaced (different modification time)
        final restoredModified = await restoredDbFile.lastModified();
        expect(
          restoredModified.isAfter(originalModified),
          isTrue,
          reason: 'Database file should have been replaced',
        );
      });

      test('rejects wrong passphrase', () async {
        // Create a backup
        final createResult = await backupService.createBackup(
          passphrase: 'CorrectPassphrase123',
        );

        expect(createResult, isA<BackupSuccess>());
        final backupPath = (createResult as BackupSuccess).filePath;

        // Close database
        await DatabaseService.closeDatabase();

        // Try to restore with wrong passphrase
        final restoreResult = await backupService.restoreBackup(
          passphrase: 'WrongPassphrase123',
          backupPath: backupPath,
        );

        expect(restoreResult, isA<RestoreFailure>());
        final failure = restoreResult as RestoreFailure;
        // AES-GCM returns decryption error for wrong passphrase
        expect(failure.errorType, RestoreErrorType.decryption);
      });
    });

    group('KDF and encryption', () {
      test('same passphrase produces different backups (salt randomness)',
          () async {
        final result1 = await backupService.createBackup(
          passphrase: 'SamePassphrase123',
        );

        // Small delay to ensure different timestamp
        await Future.delayed(const Duration(milliseconds: 100));

        final result2 = await backupService.createBackup(
          passphrase: 'SamePassphrase123',
        );

        expect(result1, isA<BackupSuccess>());
        expect(result2, isA<BackupSuccess>());

        final file1 = File((result1 as BackupSuccess).filePath);
        final file2 = File((result2 as BackupSuccess).filePath);

        final bytes1 = await file1.readAsBytes();
        final bytes2 = await file2.readAsBytes();

        // Files should differ (different salts/IVs)
        expect(bytes1, isNot(equals(bytes2)));
      });
    });
  });
}

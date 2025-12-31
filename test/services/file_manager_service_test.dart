import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:blood_pressure_monitor/models/managed_file.dart';
import 'package:blood_pressure_monitor/models/auto_cleanup_policy.dart';
import 'package:blood_pressure_monitor/services/file_manager_service.dart';
import '../helpers/test_path_provider.dart';

void main() {
  late Directory tempDir;
  late FileManagerService service;

  setUp(() async {
    // Create temp directory for tests
    tempDir = await Directory.systemTemp.createTemp('file_manager_test_');
    PathProviderPlatform.instance = TestPathProviderPlatform(tempDir.path);
    service = FileManagerService();
  });

  tearDown(() async {
    // Clean up temp directory
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileManagerService', () {
    test('listFiles returns empty list when no files exist', () async {
      final files = await service.listFiles();
      expect(files, isEmpty);
    });

    test('listFiles finds and parses export JSON files', () async {
      final file =
          File('${tempDir.path}/bp_export_John_Doe_20251231_1430.json');
      await file.writeAsString('{}');

      final files = await service.listFiles();
      expect(files.length, 1);
      expect(files[0].kind, FileKind.exportJson);
      expect(files[0].profileName, 'John Doe');
      expect(files[0].name, 'bp_export_John_Doe_20251231_1430.json');
    });

    test('listFiles finds and parses export CSV files', () async {
      final file =
          File('${tempDir.path}/bp_export_Jane_Smith_20251231_1500.csv');
      await file.writeAsString('data');

      final files = await service.listFiles();
      expect(files.length, 1);
      expect(files[0].kind, FileKind.exportCsv);
      expect(files[0].profileName, 'Jane Smith');
    });

    test('listFiles finds and parses PDF report files', () async {
      final file = File('${tempDir.path}/bp_report_Test_User_20251231.pdf');
      await file.writeAsString('pdf data');

      final files = await service.listFiles();
      expect(files.length, 1);
      expect(files[0].kind, FileKind.reportPdf);
      expect(files[0].profileName, 'Test User');
    });

    test('listFiles ignores non-matching files', () async {
      await File('${tempDir.path}/random_file.txt').writeAsString('data');
      await File('${tempDir.path}/other.json').writeAsString('data');

      final files = await service.listFiles();
      expect(files, isEmpty);
    });

    test('listFiles filters by profileName', () async {
      await File('${tempDir.path}/bp_export_John_Doe_20251231_1430.json')
          .writeAsString('{}');
      await File('${tempDir.path}/bp_export_Jane_Smith_20251231_1500.csv')
          .writeAsString('data');

      final johnFiles = await service.listFiles(profileName: 'John Doe');
      expect(johnFiles.length, 1);
      expect(johnFiles[0].profileName, 'John Doe');

      final janeFiles = await service.listFiles(profileName: 'Jane Smith');
      expect(janeFiles.length, 1);
      expect(janeFiles[0].profileName, 'Jane Smith');

      final unknownFiles = await service.listFiles(profileName: 'Unknown');
      expect(unknownFiles, isEmpty);
    });

    test('listFiles sorts by creation date, newest first', () async {
      final file1 = File('${tempDir.path}/bp_export_A_20251231_1000.json');
      await file1.writeAsString('{}');
      await file1.setLastModified(
        DateTime.now().subtract(const Duration(seconds: 10)),
      );

      final file2 = File('${tempDir.path}/bp_export_B_20251231_1100.json');
      await file2.writeAsString('{}');
      await file2.setLastModified(DateTime.now());

      final files = await service.listFiles();
      expect(files.length, 2);
      // Newer file should be first
      expect(files[0].name, 'bp_export_B_20251231_1100.json');
      expect(files[1].name, 'bp_export_A_20251231_1000.json');
    });

    test('deleteFile deletes existing file', () async {
      final file = File('${tempDir.path}/bp_export_Test_20251231_1200.json');
      await file.writeAsString('{}');
      expect(await file.exists(), true);

      final result = await service.deleteFile(file.path);
      expect(result, true);
      expect(await file.exists(), false);
    });

    test('deleteFile returns false for non-existent file', () async {
      final result =
          await service.deleteFile('${tempDir.path}/nonexistent.json');
      expect(result, false);
    });

    test('deleteFiles removes multiple files', () async {
      final file1 = File('${tempDir.path}/bp_export_A_20251231.json');
      final file2 = File('${tempDir.path}/bp_export_B_20251231.json');
      await file1.writeAsString('{}');
      await file2.writeAsString('{}');

      final result = await service.deleteFiles([file1.path, file2.path]);
      expect(result.filesDeleted, 2);
      expect(result.bytesFreed, greaterThan(0));
      expect(result.errors, isEmpty);
    });

    test('deleteFiles handles missing files gracefully', () async {
      final file1 = File('${tempDir.path}/bp_export_A_20251231.json');
      await file1.writeAsString('{}');

      final result = await service.deleteFiles([
        file1.path,
        '${tempDir.path}/nonexistent.json',
      ]);
      expect(result.filesDeleted, 1);
      expect(result.errors, isEmpty);
    });

    test('getTotalStorageBytes calculates total size', () async {
      await File('${tempDir.path}/bp_export_John_20251231_1200.json')
          .writeAsString('{"data": "test"}'); // ~16 bytes
      await File('${tempDir.path}/bp_export_Jane_20251231_1200.json')
          .writeAsString('{"data": "test"}'); // ~16 bytes

      final totalAll = await service.getTotalStorageBytes();
      expect(totalAll, greaterThan(30));

      final totalJohn = await service.getTotalStorageBytes(profileName: 'John');
      expect(totalJohn, lessThan(20));
      expect(totalJohn, greaterThan(10));
    });

    test('runAutoCleanup with disabled policy does nothing', () async {
      await File('${tempDir.path}/bp_export_Old_20200101_1200.json')
          .writeAsString('{}');

      final policy = AutoCleanupPolicy.disabled();
      final result = await service.runAutoCleanup(policy);
      expect(result.filesDeleted, 0);
      expect(result.bytesFreed, 0);
    });

    test('runAutoCleanup deletes files older than maxAge', () async {
      // Create an old file (modify date will be recent, but let's test the logic)
      final oldFile = File('${tempDir.path}/bp_export_Old_20200101_1200.json');
      await oldFile.writeAsString('{}');

      // Set file modification time to 100 days ago
      final oldDate = DateTime.now().subtract(const Duration(days: 100));
      await oldFile.setLastModified(oldDate);

      const policy = AutoCleanupPolicy(
        enabled: true,
        maxAge: Duration(days: 90),
      );
      final result = await service.runAutoCleanup(policy);
      expect(result.filesDeleted, 1);
    });

    test('runAutoCleanup keeps most recent N files per type', () async {
      // Create 60 export JSON files
      for (int i = 0; i < 60; i++) {
        final file = File(
          '${tempDir.path}/bp_export_Test_File_20251231_${1000 + i}.json',
        );
        await file.writeAsString('{}');
        // Ensure different timestamps
        await Future.delayed(const Duration(milliseconds: 10));
      }

      const policy = AutoCleanupPolicy(
        enabled: true,
        maxFilesPerType: 50,
      );
      final result = await service.runAutoCleanup(policy);
      expect(result.filesDeleted, 10); // Should delete oldest 10
    });

    test('runAutoCleanup respects size limit', () async {
      // Create files with known size
      for (int i = 0; i < 10; i++) {
        final file =
            File('${tempDir.path}/bp_export_File_20251231_${1000 + i}.json');
        await file.writeAsString('x' * 1024 * 1024); // 1 MB each
        await Future.delayed(const Duration(milliseconds: 10));
      }

      const policy = AutoCleanupPolicy(
        enabled: true,
        maxTotalSizeMB: 5, // 5 MB limit, should delete oldest ~5 files
      );
      final result = await service.runAutoCleanup(policy);
      expect(result.filesDeleted, greaterThan(0));
    });

    test('runAutoCleanup filters by profileName', () async {
      // Create 10 files for John
      for (int i = 0; i < 10; i++) {
        await File(
          '${tempDir.path}/bp_export_John_Doe_20251231_${1000 + i}.json',
        ).writeAsString('{}');
        await Future.delayed(const Duration(milliseconds: 10));
      }
      // Create 10 files for Jane
      for (int i = 0; i < 10; i++) {
        await File(
          '${tempDir.path}/bp_export_Jane_Smith_20251231_${1000 + i}.json',
        ).writeAsString('{}');
        await Future.delayed(const Duration(milliseconds: 10));
      }

      const policy = AutoCleanupPolicy(
        enabled: true,
        maxFilesPerType: 5,
      );

      // Cleanup only John's files
      final result =
          await service.runAutoCleanup(policy, profileName: 'John Doe');
      expect(result.filesDeleted, 5);

      // Verify John has 5 files left
      final johnFiles = await service.listFiles(profileName: 'John Doe');
      expect(johnFiles.length, 5);

      // Verify Jane still has 10 files
      final janeFiles = await service.listFiles(profileName: 'Jane Smith');
      expect(janeFiles.length, 10);
    });
  });

  group('CleanupResult', () {
    test('formattedBytesFreed formats bytes correctly', () {
      const result1 = CleanupResult(filesDeleted: 1, bytesFreed: 500);
      expect(result1.formattedBytesFreed, '500 B');

      const result2 = CleanupResult(filesDeleted: 1, bytesFreed: 2048);
      expect(result2.formattedBytesFreed, '2.0 KB');

      const result3 = CleanupResult(filesDeleted: 1, bytesFreed: 2097152);
      expect(result3.formattedBytesFreed, '2.0 MB');
    });
  });
}

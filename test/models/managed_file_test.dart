import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/models/managed_file.dart';

void main() {
  group('FileKind', () {
    test('displayName returns correct values', () {
      expect(FileKind.exportJson.displayName, 'JSON Export');
      expect(FileKind.exportCsv.displayName, 'CSV Export');
      expect(FileKind.reportPdf.displayName, 'PDF Report');
      expect(FileKind.unknown.displayName, 'Unknown');
    });

    test('extension returns correct values', () {
      expect(FileKind.exportJson.extension, 'json');
      expect(FileKind.exportCsv.extension, 'csv');
      expect(FileKind.reportPdf.extension, 'pdf');
      expect(FileKind.unknown.extension, null);
    });
  });

  group('ManagedFile', () {
    test('formattedSize formats bytes correctly', () {
      final file1 = ManagedFile(
        path: '/test/file.json',
        name: 'file.json',
        sizeBytes: 500,
        createdAt: DateTime(2025, 1, 1),
        kind: FileKind.exportJson,
      );
      expect(file1.formattedSize, '500 B');

      final file2 = ManagedFile(
        path: '/test/file.json',
        name: 'file.json',
        sizeBytes: 2048,
        createdAt: DateTime(2025, 1, 1),
        kind: FileKind.exportJson,
      );
      expect(file2.formattedSize, '2.0 KB');

      final file3 = ManagedFile(
        path: '/test/file.json',
        name: 'file.json',
        sizeBytes: 2097152,
        createdAt: DateTime(2025, 1, 1),
        kind: FileKind.exportJson,
      );
      expect(file3.formattedSize, '2.0 MB');
    });

    test('shareText returns correct text for each kind', () {
      expect(
        ManagedFile(
          path: '/test/file.json',
          name: 'file.json',
          sizeBytes: 100,
          createdAt: DateTime(2025, 1, 1),
          kind: FileKind.exportJson,
        ).shareText,
        'Sensitive health data – Blood Pressure Export',
      );

      expect(
        ManagedFile(
          path: '/test/file.csv',
          name: 'file.csv',
          sizeBytes: 100,
          createdAt: DateTime(2025, 1, 1),
          kind: FileKind.exportCsv,
        ).shareText,
        'Sensitive health data – Blood Pressure Export',
      );

      expect(
        ManagedFile(
          path: '/test/file.pdf',
          name: 'file.pdf',
          sizeBytes: 100,
          createdAt: DateTime(2025, 1, 1),
          kind: FileKind.reportPdf,
        ).shareText,
        'Blood Pressure Report',
      );

      expect(
        ManagedFile(
          path: '/test/file.txt',
          name: 'file.txt',
          sizeBytes: 100,
          createdAt: DateTime(2025, 1, 1),
          kind: FileKind.unknown,
        ).shareText,
        'HealthLog File',
      );
    });
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/viewmodels/export_viewmodel.dart';
import '../helpers/service_mocks.dart';

void main() {
  late MockExportService exportService;
  late ExportViewModel viewModel;

  setUp(() {
    exportService = MockExportService();
    viewModel = ExportViewModel(exportService: exportService);
  });

  group('ExportViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.isExporting, isFalse);
      expect(viewModel.lastExportPath, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('exportToJson sets isExporting during operation', () async {
      final mockFile = File('/path/to/export.json');
      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test User',
        ),
      ).thenAnswer((_) async {
        expect(viewModel.isExporting, isTrue);
        return Success(mockFile);
      });

      await viewModel.exportToJson(
        profileId: 1,
        profileName: 'Test User',
      );

      expect(viewModel.isExporting, isFalse);
    });

    test('exportToJson success sets lastExportPath and returns true', () async {
      final mockFile = File('/path/to/export.json');
      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test User',
        ),
      ).thenAnswer((_) async => Success(mockFile));

      final result = await viewModel.exportToJson(
        profileId: 1,
        profileName: 'Test User',
      );

      expect(result, isTrue);
      expect(viewModel.lastExportPath, '/path/to/export.json');
      expect(viewModel.errorMessage, isNull);
    });

    test('exportToJson failure sets error message and returns false', () async {
      final error = AppError.fileSystem('Failed to write file');
      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test User',
        ),
      ).thenAnswer((_) async => Failure(error));

      final result = await viewModel.exportToJson(
        profileId: 1,
        profileName: 'Test User',
      );

      expect(result, isFalse);
      expect(
        viewModel.errorMessage,
        'File operation failed. Please check permissions and try again.',
      );
      expect(viewModel.lastExportPath, isNull);
    });

    test('exportToJson passes all parameters correctly', () async {
      final mockFile = File('/path/to/export.json');
      when(
        exportService.exportToJson(
          profileId: 42,
          profileName: 'John Doe',
          includeReadings: true,
          includeWeight: false,
          includeSleep: true,
          includeMedications: false,
        ),
      ).thenAnswer((_) async => Success(mockFile));

      await viewModel.exportToJson(
        profileId: 42,
        profileName: 'John Doe',
        includeReadings: true,
        includeWeight: false,
        includeSleep: true,
        includeMedications: false,
      );

      verify(
        exportService.exportToJson(
          profileId: 42,
          profileName: 'John Doe',
          includeReadings: true,
          includeWeight: false,
          includeSleep: true,
          includeMedications: false,
        ),
      ).called(1);
    });

    test('clearError clears error message', () async {
      final error = AppError.unexpected('Test error');
      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test',
        ),
      ).thenAnswer((_) async => Failure(error));

      await viewModel.exportToJson(profileId: 1, profileName: 'Test');

      expect(viewModel.errorMessage, isNotNull);

      viewModel.clearError();
      expect(viewModel.errorMessage, isNull);
    });

    test('shareLastExport returns false when no file path exists', () async {
      final result = await viewModel.shareLastExport();

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'No file to share');
    });

    test('shareLastExport returns false when file does not exist', () async {
      // Set up a successful export first
      final mockFile = File('/path/to/export.json');
      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test User',
        ),
      ).thenAnswer((_) async => Success(mockFile));

      await viewModel.exportToJson(
        profileId: 1,
        profileName: 'Test User',
      );

      final result = await viewModel.shareLastExport();

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'Export file no longer exists');
    });

    test('shareLastExport returns true when file exists and share succeeds',
        () async {
      // Create a file that exists
      final tempDir = Directory.systemTemp.createTempSync('export_test');
      final mockFile = File('${tempDir.path}/export.json');
      await mockFile.writeAsString('{}');

      when(
        exportService.exportToJson(
          profileId: 1,
          profileName: 'Test User',
        ),
      ).thenAnswer((_) async => Success(mockFile));

      // Don't stub shareExport - let it be called (Mock will return Future.value())

      await viewModel.exportToJson(
        profileId: 1,
        profileName: 'Test User',
      );

      final result = await viewModel.shareLastExport();

      expect(result, isTrue);
      expect(viewModel.errorMessage, isNull);

      // Cleanup
      tempDir.deleteSync(recursive: true);
    });
  });
}

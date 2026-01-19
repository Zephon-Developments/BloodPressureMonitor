import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:file_picker/file_picker.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';
import 'package:blood_pressure_monitor/models/result.dart';
import 'package:blood_pressure_monitor/viewmodels/import_viewmodel.dart';
import '../helpers/service_mocks.dart';

class MockFilePicker extends Mock implements FilePicker {}

void main() {
  late MockImportService importService;
  late ImportViewModel viewModel;

  setUp(() {
    importService = MockImportService();
    viewModel = ImportViewModel(importService: importService);
  });

  group('ImportViewModel', () {
    test('initial state is correct', () {
      expect(viewModel.isImporting, isFalse);
      expect(viewModel.importResult, isNull);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.selectedFile, isNull);
      expect(viewModel.overwriteExisting, isFalse);
    });

    test('setOverwrite updates state', () {
      viewModel.setOverwrite(true);
      expect(viewModel.overwriteExisting, isTrue);
    });

    test('clearSelection resets state', () {
      viewModel.setOverwrite(true);
      viewModel.clearSelection();
      expect(viewModel.selectedFile, isNull);
      expect(viewModel.importResult, isNull);
      expect(viewModel.errorMessage, isNull);
    });

    test('importData returns false when no file selected', () async {
      final result = await viewModel.importData(
        profileId: 1,
        conflictMode: ImportConflictMode.append,
      );

      expect(result, isFalse);
      expect(viewModel.errorMessage, 'No file selected');
    });

    test('importData success sets result and returns true', () async {
      final mockFile = File('data.json');
      final mockResult = ImportResult(
        readingsImported: 10,
        weightsImported: 0,
        sleepLogsImported: 0,
        medicationsImported: 0,
        intakesImported: 0,
        duplicatesSkipped: 2,
        errors: [],
      );

      when(
        importService.importFromJson(
          file: mockFile,
          profileId: 1,
          conflictMode: ImportConflictMode.append,
        ),
      ).thenAnswer((_) async => Success(mockResult));

      viewModel.setSelectedFileForTesting(mockFile);

      final success = await viewModel.importData(
        profileId: 1,
        conflictMode: ImportConflictMode.append,
      );

      expect(success, isTrue);
      expect(viewModel.importResult, mockResult);
      expect(viewModel.errorMessage, isNull);
    });

    test('importData failure sets error message', () async {
      final mockFile = File('data.json');
      final error = AppError.validation('Invalid format');

      when(
        importService.importFromJson(
          file: mockFile,
          profileId: 1,
          conflictMode: ImportConflictMode.overwrite,
        ),
      ).thenAnswer((_) async => Failure(error));

      viewModel.setSelectedFileForTesting(mockFile);

      final success = await viewModel.importData(
        profileId: 1,
        conflictMode: ImportConflictMode.overwrite,
      );

      expect(success, isFalse);
      expect(
        viewModel.errorMessage,
        'Invalid data format. Please check your file and try again.',
      );
      expect(viewModel.importResult, isNull);
    });

    test('pickFile stores selected json file', () async {
      final tempDir = Directory.systemTemp.createTempSync();
      final tempFile = File('${tempDir.path}/sample.json')
        ..writeAsStringSync('{}');
      addTearDown(() {
        if (tempFile.existsSync()) {
          tempFile.deleteSync();
        }
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      });

      viewModel = ImportViewModel(
        importService: importService,
        pickFiles: ({
          required FileType type,
          List<String>? allowedExtensions,
        }) async {
          return FilePickerResult([
            PlatformFile(
              name: 'sample.json',
              size: tempFile.lengthSync(),
              path: tempFile.path,
            ),
          ]);
        },
      );

      await viewModel.pickFile();

      expect(viewModel.selectedFile, isNotNull);
      expect(viewModel.selectedFile!.path, tempFile.path);
      expect(viewModel.errorMessage, isNull);
    });

    test('pickFile falls back to FileType.any on unsupported filter', () async {
      var callCount = 0;
      viewModel = ImportViewModel(
        importService: importService,
        pickFiles: ({
          required FileType type,
          List<String>? allowedExtensions,
        }) async {
          callCount++;
          if (callCount == 1) {
            throw PlatformException(
              code: 'FilePicker',
              message: 'Unsupported filter',
            );
          }
          return FilePickerResult([
            PlatformFile(
              name: 'fallback.json',
              size: 10,
              path: 'fallback.json',
            ),
          ]);
        },
      );

      await viewModel.pickFile();

      expect(callCount, 2);
      expect(viewModel.selectedFile, isNotNull);
      expect(viewModel.selectedFile!.path, 'fallback.json');
    });

    test('pickFile rejects non json files', () async {
      viewModel = ImportViewModel(
        importService: importService,
        pickFiles: ({
          required FileType type,
          List<String>? allowedExtensions,
        }) async {
          return FilePickerResult([
            PlatformFile(
              name: 'notes.txt',
              size: 20,
              path: 'notes.txt',
            ),
          ]);
        },
      );

      await viewModel.pickFile();

      expect(viewModel.selectedFile, isNull);
      expect(
        viewModel.errorMessage,
        'Please select a file with the .json extension.',
      );
    });
  });
}

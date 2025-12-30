import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/import_viewmodel.dart';
import 'package:blood_pressure_monitor/models/export_import.dart';

class ImportView extends StatelessWidget {
  const ImportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import Data'),
      ),
      body: Consumer<ImportViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Import data from a previously exported JSON or CSV file.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                if (viewModel.selectedFile == null)
                  ElevatedButton.icon(
                    onPressed:
                        viewModel.isImporting ? null : viewModel.pickFile,
                    icon: const Icon(Icons.file_open),
                    label: const Text('Select File to Import'),
                  )
                else
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(
                              viewModel.selectedFile!.path.split('/').last,
                            ),
                            subtitle: Text(
                              'Size: ${(viewModel.selectedFile!.lengthSync() / 1024).toStringAsFixed(2)} KB',
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: viewModel.isImporting
                                  ? null
                                  : viewModel.clearSelection,
                            ),
                          ),
                          const Divider(),
                          const Text('Choose Import Strategy:'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ChoiceChip(
                                label: const Text('Append'),
                                selected: !viewModel.overwriteExisting,
                                onSelected: viewModel.isImporting
                                    ? null
                                    : (selected) =>
                                        viewModel.setOverwrite(false),
                              ),
                              ChoiceChip(
                                label: const Text('Overwrite'),
                                selected: viewModel.overwriteExisting,
                                onSelected: viewModel.isImporting
                                    ? null
                                    : (selected) =>
                                        viewModel.setOverwrite(true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (viewModel.overwriteExisting)
                            const Padding(
                              padding: EdgeInsets.only(bottom: 16.0),
                              child: Text(
                                'WARNING: Overwrite will delete all current data before importing.',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: viewModel.isImporting
                                ? null
                                : () => _handleImport(context, viewModel),
                            icon: const Icon(Icons.upload),
                            label: const Text('Start Import'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: viewModel.overwriteExisting
                                  ? Colors.red
                                  : null,
                              foregroundColor: viewModel.overwriteExisting
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (viewModel.isImporting) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(child: Text('Importing data...')),
                ],
                if (viewModel.importResult != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getImportResultColor(viewModel.importResult!)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getImportResultColor(viewModel.importResult!),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getImportResultIcon(viewModel.importResult!),
                          color: _getImportResultColor(viewModel.importResult!),
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getImportResultTitle(viewModel.importResult!),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color:
                                _getImportResultColor(viewModel.importResult!),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Readings: ${viewModel.importResult!.readingsImported}',
                        ),
                        Text(
                          'Weights: ${viewModel.importResult!.weightsImported}',
                        ),
                        Text(
                          'Sleep Logs: ${viewModel.importResult!.sleepLogsImported}',
                        ),
                        Text(
                          'Medications: ${viewModel.importResult!.medicationsImported}',
                        ),
                        if (viewModel.importResult!.duplicatesSkipped > 0)
                          Text(
                            'Duplicates Skipped: ${viewModel.importResult!.duplicatesSkipped}',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        if (viewModel.importResult!.errors.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            'Errors:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            constraints: const BoxConstraints(maxHeight: 150),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: viewModel.importResult!.errors
                                    .map(
                                      (error) => Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('• '),
                                            Expanded(
                                              child: Text(
                                                error.toString(),
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
                if (viewModel.errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleImport(
    BuildContext context,
    ImportViewModel viewModel,
  ) async {
    // Get active profile from ActiveProfileViewModel before any async operations
    final activeProfile = context.read<ActiveProfileViewModel>();

    if (viewModel.overwriteExisting) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Overwrite'),
          content: const Text(
            'This will delete all your current data. This action cannot be undone. Are you sure?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Overwrite Everything'),
            ),
          ],
        ),
      );

      if (confirm != true) return;
    }

    final success = await viewModel.importData(
      profileId: activeProfile.activeProfileId,
      conflictMode: viewModel.overwriteExisting
          ? ImportConflictMode.overwrite
          : ImportConflictMode.append,
    );
    if (success) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import completed successfully')),
      );
    }
  }

  /// Determines the appropriate title based on import result status.
  String _getImportResultTitle(ImportResult result) {
    final hasErrors = result.errors.isNotEmpty;
    final hasImports = result.readingsImported > 0 ||
        result.weightsImported > 0 ||
        result.sleepLogsImported > 0 ||
        result.medicationsImported > 0;

    if (!hasErrors && hasImports) {
      return 'Import Successful!';
    } else if (hasErrors && hasImports) {
      return 'Import Completed with Errors';
    } else if (hasErrors && !hasImports) {
      return 'Import Failed';
    } else {
      return 'No Data Imported';
    }
  }

  /// Determines the appropriate icon based on import result status.
  IconData _getImportResultIcon(ImportResult result) {
    final hasErrors = result.errors.isNotEmpty;
    final hasImports = result.readingsImported > 0 ||
        result.weightsImported > 0 ||
        result.sleepLogsImported > 0 ||
        result.medicationsImported > 0;

    if (!hasErrors && hasImports) {
      return Icons.check_circle;
    } else if (hasErrors && hasImports) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  /// Determines the appropriate color based on import result status.
  Color _getImportResultColor(ImportResult result) {
    final hasErrors = result.errors.isNotEmpty;
    final hasImports = result.readingsImported > 0 ||
        result.weightsImported > 0 ||
        result.sleepLogsImported > 0 ||
        result.medicationsImported > 0;

    if (!hasErrors && hasImports) {
      return Colors.green;
    } else if (hasErrors && hasImports) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}

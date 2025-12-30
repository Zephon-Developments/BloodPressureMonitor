import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Import Successful!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
      profileId: 1,
      conflictMode: viewModel.overwriteExisting
          ? ImportConflictMode.overwrite
          : ImportConflictMode.append,
    );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Import completed successfully')),
      );
    }
  }
}

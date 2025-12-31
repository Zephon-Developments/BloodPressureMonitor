import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/export_viewmodel.dart';
import 'package:blood_pressure_monitor/views/file_manager_view.dart';

class ExportView extends StatelessWidget {
  const ExportView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: Consumer<ExportViewModel>(
        builder: (context, viewModel, child) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Export your data to a file for backup or to share with your doctor.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.code),
                          title: Text('JSON Export'),
                          subtitle: Text(
                            'Best for backups and importing back into this app.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: viewModel.isExporting
                              ? null
                              : () => _handleExport(context, viewModel, true),
                          icon: const Icon(Icons.download),
                          label: const Text('Export to JSON'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const ListTile(
                          leading: Icon(Icons.table_chart),
                          title: Text('CSV Export'),
                          subtitle: Text(
                            'Best for viewing in Excel or other spreadsheet software.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: viewModel.isExporting
                              ? null
                              : () => _handleExport(context, viewModel, false),
                          icon: const Icon(Icons.download),
                          label: const Text('Export to CSV'),
                        ),
                      ],
                    ),
                  ),
                ),
                if (viewModel.isExporting) ...[
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator()),
                  const SizedBox(height: 8),
                  const Center(child: Text('Generating export file...')),
                ],
                if (viewModel.lastExportPath != null) ...[
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
                          'Export Successful!',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'File saved to:\n${viewModel.lastExportPath}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _shareLastExport(context),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () => _openFileManager(context),
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Manage Files'),
                            ),
                          ],
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

  Future<void> _handleExport(
    BuildContext context,
    ExportViewModel viewModel,
    bool isJson,
  ) async {
    // Get active profile from ActiveProfileViewModel
    final activeProfile = context.read<ActiveProfileViewModel>();

    final success = isJson
        ? await viewModel.exportToJson(
            profileId: activeProfile.activeProfileId,
            profileName: activeProfile.activeProfileName,
          )
        : await viewModel.exportToCsv(
            profileId: activeProfile.activeProfileId,
            profileName: activeProfile.activeProfileName,
          );
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export completed successfully')),
      );
    }
  }

  Future<void> _shareLastExport(BuildContext context) async {
    final viewModel = context.read<ExportViewModel>();
    await viewModel.shareLastExport();
  }

  void _openFileManager(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const FileManagerView(),
      ),
    );
  }
}

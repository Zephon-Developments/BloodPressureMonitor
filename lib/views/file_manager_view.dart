import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/managed_file.dart';
import 'package:blood_pressure_monitor/viewmodels/file_manager_viewmodel.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';

/// View for managing export and report files.
class FileManagerView extends StatefulWidget {
  const FileManagerView({super.key});

  @override
  State<FileManagerView> createState() => _FileManagerViewState();
}

class _FileManagerViewState extends State<FileManagerView> {
  @override
  void initState() {
    super.initState();
    // Load files when view is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FileManagerViewModel>().loadFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<FileManagerViewModel>().loadFiles();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Consumer<FileManagerViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.files.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              _buildSummaryHeader(viewModel),
              if (viewModel.errorMessage != null) _buildErrorBanner(viewModel),
              Expanded(
                child: viewModel.files.isEmpty
                    ? _buildEmptyState()
                    : _buildFileList(viewModel),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<FileManagerViewModel>(
        builder: (context, viewModel, child) {
          final policy = viewModel.policy;
          if (policy == null || !policy.enabled) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton.extended(
            onPressed: viewModel.isLoading ? null : () => _runCleanup(context),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Run Cleanup'),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(FileManagerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${viewModel.files.length} files',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                viewModel.formattedTotalStorage,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          if (viewModel.policy != null && viewModel.policy!.enabled)
            const Chip(
              avatar: Icon(Icons.auto_awesome, size: 16),
              label: Text('Auto-cleanup ON'),
            )
          else
            const Chip(
              avatar: Icon(Icons.block, size: 16),
              label: Text('Auto-cleanup OFF'),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(FileManagerViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.red.withValues(alpha: 0.1),
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
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => viewModel.clearError(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open,
            size: 80,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No files found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          const Text(
            'Export data or generate reports to see them here.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileList(FileManagerViewModel viewModel) {
    final filesByKind = viewModel.filesByKind;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        for (final entry in filesByKind.entries)
          _buildFileSection(entry.key, entry.value),
      ],
    );
  }

  Widget _buildFileSection(FileKind kind, List<ManagedFile> files) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            kind.displayName,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...files.map((file) => _buildFileCard(file)),
        const Divider(),
      ],
    );
  }

  Widget _buildFileCard(ManagedFile file) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(_getIconForKind(file.kind)),
        title: Text(
          file.profileName ?? file.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${file.formattedSize} • ${DateFormats.standardDateTime.format(file.createdAt.toLocal())}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _shareFile(file),
              tooltip: 'Share',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(file),
              tooltip: 'Delete',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForKind(FileKind kind) {
    switch (kind) {
      case FileKind.exportJson:
        return Icons.code;
      case FileKind.exportCsv:
        return Icons.table_chart;
      case FileKind.reportPdf:
        return Icons.picture_as_pdf;
      case FileKind.unknown:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _shareFile(ManagedFile file) async {
    final viewModel = context.read<FileManagerViewModel>();
    await viewModel.shareFile(file);
  }

  Future<void> _confirmDelete(ManagedFile file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: Text(
          'Are you sure you want to delete this file?\n\n${file.name}\n${file.formattedSize}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final viewModel = context.read<FileManagerViewModel>();
      final success = await viewModel.deleteFile(file.path);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted')),
        );
      }
    }
  }

  Future<void> _runCleanup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run Auto-Cleanup?'),
        content: const Text(
          'This will delete files based on your cleanup policy:\n\n'
          '• Files older than 90 days\n'
          '• Keep only the 50 most recent files per type\n\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Run Cleanup'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      
      // ignore: use_build_context_synchronously
      final messenger = ScaffoldMessenger.of(context);
      // ignore: use_build_context_synchronously
      final viewModel = context.read<FileManagerViewModel>();
      
      final result = await viewModel.runAutoCleanup();
      
      if (!mounted) return;
      if (result != null) {
        messenger.showSnackBar(
          SnackBar(content: Text(result)),
        );
      }
    }
  }
}

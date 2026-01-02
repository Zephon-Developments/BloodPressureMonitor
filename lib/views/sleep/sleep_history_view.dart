import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/views/sleep/add_sleep_view.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// Displays the history of recorded sleep sessions.
class SleepHistoryView extends StatefulWidget {
  /// Creates a [SleepHistoryView].
  const SleepHistoryView({super.key});

  @override
  State<SleepHistoryView> createState() => _SleepHistoryViewState();
}

class _SleepHistoryViewState extends State<SleepHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SleepViewModel>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SleepViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadEntries(),
        child: _buildContent(viewModel),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const AddSleepView(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Log Sleep'),
      ),
    );
  }

  Widget _buildContent(SleepViewModel viewModel) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.hotel,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.3,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'No sleep sessions yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Track bedtime and wake-up patterns to correlate with readings.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final entry = viewModel.entries[index];
        return _SleepEntryCard(entry: entry);
      },
    );
  }
}

class _SleepEntryCard extends StatelessWidget {
  const _SleepEntryCard({required this.entry});

  final SleepEntry entry;

  @override
  Widget build(BuildContext context) {
    final start = DateFormats.shortDateTime.format(entry.startedAt);
    final end = entry.endedAt != null
        ? DateFormats.shortDateTime.format(entry.endedAt!)
        : 'In progress';
    final duration = _formatDuration(entry.durationMinutes);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  duration,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Ended $end',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Theme.of(context).hintColor),
                    ),
                    PopupMenuButton<_SleepEntryAction>(
                      tooltip: 'Sleep actions',
                      onSelected: (action) => _handleAction(context, action),
                      itemBuilder: (context) => const [
                        PopupMenuItem<_SleepEntryAction>(
                          value: _SleepEntryAction.edit,
                          child: Text('Edit'),
                        ),
                        PopupMenuItem<_SleepEntryAction>(
                          value: _SleepEntryAction.delete,
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Started $start',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (entry.notes != null) ...[
              const SizedBox(height: 8),
              Text(entry.notes!),
            ],
            if (_hasDetailedMetrics(entry)) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                'Sleep Stages',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (entry.deepMinutes != null && entry.deepMinutes! > 0)
                    _Chip(
                      label: 'Deep: ${_formatDuration(entry.deepMinutes!)}',
                      color: Colors.indigo,
                    ),
                  if (entry.lightMinutes != null && entry.lightMinutes! > 0)
                    _Chip(
                      label: 'Light: ${_formatDuration(entry.lightMinutes!)}',
                      color: Colors.lightBlue,
                    ),
                  if (entry.remMinutes != null && entry.remMinutes! > 0)
                    _Chip(
                      label: 'REM: ${_formatDuration(entry.remMinutes!)}',
                      color: Colors.purple,
                    ),
                  if (entry.awakeMinutes != null && entry.awakeMinutes! > 0)
                    _Chip(
                      label: 'Awake: ${_formatDuration(entry.awakeMinutes!)}',
                      color: Colors.orange,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (entry.quality != null)
                  _Chip(label: 'Quality: ${entry.quality}/5'),
                _Chip(label: _sourceLabel(entry.source)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    if (hours == 0) {
      return '$remainingMinutes min';
    }
    return '${hours}h ${remainingMinutes}m';
  }

  bool _hasDetailedMetrics(SleepEntry entry) {
    return (entry.deepMinutes != null && entry.deepMinutes! > 0) ||
        (entry.lightMinutes != null && entry.lightMinutes! > 0) ||
        (entry.remMinutes != null && entry.remMinutes! > 0) ||
        (entry.awakeMinutes != null && entry.awakeMinutes! > 0);
  }

  String _sourceLabel(SleepSource source) {
    switch (source) {
      case SleepSource.manual:
        return 'Manual entry';
      case SleepSource.import:
        return 'Imported';
    }
  }

  Future<void> _handleAction(
    BuildContext context,
    _SleepEntryAction action,
  ) async {
    switch (action) {
      case _SleepEntryAction.edit:
        await _editEntry(context);
        break;
      case _SleepEntryAction.delete:
        await _deleteEntry(context);
        break;
    }
  }

  Future<void> _editEntry(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddSleepView(editingEntry: entry),
      ),
    );

    if (updated == true && context.mounted) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep session updated')),
      );
    }
  }

  Future<void> _deleteEntry(BuildContext context) async {
    if (entry.id == null) {
      return;
    }

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete sleep session?',
      message:
          'This will delete the sleep session ending at ${DateFormats.shortDateTime.format(entry.endedAt ?? entry.startedAt)}.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final viewModel = context.read<SleepViewModel>();
    final error = await viewModel.deleteSleepEntry(entry.id!);
    if (!context.mounted) {
      return;
    }

    if (error == null) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep session deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

enum _SleepEntryAction { edit, delete }

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: color != null ? TextStyle(color: color) : null,
      ),
      side: BorderSide(
        color: color ?? Theme.of(context).colorScheme.outlineVariant,
      ),
      backgroundColor: color != null
          ? color!.withValues(alpha: 0.1)
          : Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

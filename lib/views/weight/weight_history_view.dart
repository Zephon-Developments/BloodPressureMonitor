import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/views/weight/add_weight_view.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// Displays the chronological history of weight entries with lifestyle context.
class WeightHistoryView extends StatefulWidget {
  /// Creates a [WeightHistoryView].
  const WeightHistoryView({super.key});

  @override
  State<WeightHistoryView> createState() => _WeightHistoryViewState();
}

class _WeightHistoryViewState extends State<WeightHistoryView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WeightViewModel>().loadEntries();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weight History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => viewModel.loadEntries(),
        child: _buildContent(viewModel),
      ),
      floatingActionButton: Semantics(
        label: 'Add new weight entry',
        button: true,
        excludeSemantics: true,
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const AddWeightView(),
              ),
            );
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Weight'),
        ),
      ),
    );
  }

  Widget _buildContent(WeightViewModel viewModel) {
    if (viewModel.isLoading && viewModel.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (viewModel.entries.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(32),
        children: [
          Icon(
            Icons.monitor_weight,
            size: 72,
            color: Theme.of(context).colorScheme.primary.withValues(
                  alpha: 0.3,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'No weight entries yet',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Track your weight to monitor correlations with blood pressure.',
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
        return _WeightEntryCard(entry: entry);
      },
    );
  }
}

class _WeightEntryCard extends StatelessWidget {
  const _WeightEntryCard({required this.entry});

  final WeightEntry entry;

  @override
  Widget build(BuildContext context) {
    final kg = entry.weightInKg;
    final lbs = entry.weightInLbs;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${kg.toStringAsFixed(1)} kg · ${lbs.toStringAsFixed(1)} lbs',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  DateFormats.shortDateTime.format(entry.takenAt),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                PopupMenuButton<_WeightEntryAction>(
                  tooltip: 'Weight actions',
                  onSelected: (action) => _handleAction(context, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem<_WeightEntryAction>(
                      value: _WeightEntryAction.edit,
                      child: Text('Edit'),
                    ),
                    PopupMenuItem<_WeightEntryAction>(
                      value: _WeightEntryAction.delete,
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if (entry.notes != null) ...[
              const SizedBox(height: 8),
              Text(entry.notes!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (entry.saltIntake != null)
                  _Chip(label: 'Salt: ${entry.saltIntake}'),
                if (entry.exerciseLevel != null)
                  _Chip(label: 'Exercise: ${entry.exerciseLevel}'),
                if (entry.stressLevel != null)
                  _Chip(label: 'Stress: ${entry.stressLevel}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    _WeightEntryAction action,
  ) async {
    switch (action) {
      case _WeightEntryAction.edit:
        await _editEntry(context);
        break;
      case _WeightEntryAction.delete:
        await _deleteEntry(context);
        break;
    }
  }

  Future<void> _editEntry(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddWeightView(editingEntry: entry),
      ),
    );
    if (updated == true && context.mounted) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight entry updated')),
      );
    }
  }

  Future<void> _deleteEntry(BuildContext context) async {
    if (entry.id == null) {
      return;
    }

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete weight entry?',
      message:
          'This will permanently remove the weight entry from ${DateFormats.shortDateTime.format(entry.takenAt)}.',
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final viewModel = context.read<WeightViewModel>();
    final error = await viewModel.deleteWeightEntry(entry.id!);
    if (!context.mounted) {
      return;
    }

    if (error == null) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Weight entry deleted')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

enum _WeightEntryAction { edit, delete }

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

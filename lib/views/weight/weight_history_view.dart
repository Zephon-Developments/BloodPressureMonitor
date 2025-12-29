import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/views/weight/add_weight_view.dart';

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
      floatingActionButton: FloatingActionButton.extended(
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${kg.toStringAsFixed(1)} kg · ${lbs.toStringAsFixed(1)} lbs',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  DateFormats.shortDateTime.format(entry.takenAt),
                  style: Theme.of(context).textTheme.bodySmall,
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
}

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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/views/sleep/add_sleep_view.dart';

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
                Text(
                  'Ended $end',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).hintColor),
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

  String _sourceLabel(SleepSource source) {
    switch (source) {
      case SleepSource.manual:
        return 'Manual entry';
      case SleepSource.import:
        return 'Imported';
    }
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

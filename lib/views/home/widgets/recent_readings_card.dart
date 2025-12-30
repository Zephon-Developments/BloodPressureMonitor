import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// Displays the most recent blood pressure readings.
///
/// Shows the last 3-5 averaged readings with timestamps.
/// Provides quick visual feedback on recent health status.
class RecentReadingsCard extends StatelessWidget {
  /// Creates a recent readings card.
  const RecentReadingsCard({super.key});

  Future<void> _handleEdit(BuildContext context, Reading reading) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => AddReadingView(editingReading: reading),
      ),
    );

    if (updated == true && context.mounted) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _handleDelete(
    BuildContext context,
    BloodPressureViewModel viewModel,
    Reading reading,
  ) async {
    if (reading.id == null) {
      return;
    }

    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete reading?',
      message:
          'This will permanently remove the reading from ${DateFormats.standardDateTime.format(reading.takenAt)}.',
      confirmLabel: 'Delete',
    );

    if (!confirmed) {
      return;
    }

    await viewModel.deleteReading(reading.id!);
    if (!context.mounted) {
      return;
    }

    context.refreshAnalyticsData();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reading deleted'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Readings',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Consumer<BloodPressureViewModel>(
            builder: (context, viewModel, child) {
              if (viewModel.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (viewModel.error != null) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            viewModel.error!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (viewModel.readings.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.favorite_border,
                            size: 48,
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No readings yet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Add your first blood pressure reading',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Show up to 5 recent readings
              final recentReadings = viewModel.readings.take(5).toList();

              return Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentReadings.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final reading = recentReadings[index];
                    return Slidable(
                      key: ValueKey('reading-${reading.id ?? index}'),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        extentRatio: 0.25,
                        children: [
                          CustomSlidableAction(
                            onPressed: (_) => _handleDelete(
                              context,
                              viewModel,
                              reading,
                            ),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                            child: Semantics(
                              button: true,
                              label: 'Delete reading',
                              hint:
                                  'Opens a confirmation dialog for this reading',
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.delete,
                                    color:
                                        Theme.of(context).colorScheme.onError,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'DELETE',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.onError,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      child: ListTile(
                        leading: Icon(
                          Icons.favorite,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        title: Text(
                          '${reading.systolic}/${reading.diastolic}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          'Pulse: ${reading.pulse} bpm • '
                          '${DateFormats.standardDateTime.format(reading.takenAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _handleEdit(context, reading),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

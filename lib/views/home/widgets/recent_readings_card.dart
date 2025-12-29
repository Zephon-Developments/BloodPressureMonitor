import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';

/// Displays the most recent blood pressure readings.
///
/// Shows the last 3-5 averaged readings with timestamps.
/// Provides quick visual feedback on recent health status.
class RecentReadingsCard extends StatelessWidget {
  /// Creates a recent readings card.
  const RecentReadingsCard({super.key});

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
                    return ListTile(
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
                      onTap: () {
                        // TODO: Navigate to reading details or history
                      },
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

import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';

/// Card highlighting morning versus evening averages.
class MorningEveningCard extends StatelessWidget {
  const MorningEveningCard({
    required this.split,
    super.key,
  });

  final MorningEveningSplit split;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Morning vs Evening',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _SplitColumn(
                    label: 'Morning',
                    stats: split.morning,
                    count: split.morningCount,
                    icon: Icons.wb_sunny,
                  ),
                ),
                const VerticalDivider(),
                Expanded(
                  child: _SplitColumn(
                    label: 'Evening',
                    stats: split.evening,
                    count: split.eveningCount,
                    icon: Icons.nightlight_round,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SplitColumn extends StatelessWidget {
  const _SplitColumn({
    required this.label,
    required this.stats,
    required this.count,
    required this.icon,
  });

  final String label;
  final ReadingBucketStats stats;
  final int count;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              '$label (${count}x)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Avg: ${stats.avgSystolic.toStringAsFixed(0)} / '
            '${stats.avgDiastolic.toStringAsFixed(0)} mmHg'),
        Text('Min: ${stats.minSystolic.toStringAsFixed(0)} / '
            '${stats.minDiastolic.toStringAsFixed(0)}'),
        Text('Max: ${stats.maxSystolic.toStringAsFixed(0)} / '
            '${stats.maxDiastolic.toStringAsFixed(0)}'),
      ],
    );
  }
}

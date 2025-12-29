import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/history.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';

/// Card representing a single averaged reading group with expandable details.
class HistoryGroupTile extends StatelessWidget {
  const HistoryGroupTile({
    super.key,
    required this.item,
    required this.onToggle,
  });

  final HistoryGroupItem item;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final rangeEnd = item.group.groupStartAt
        .add(Duration(minutes: item.group.windowMinutes));
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${item.group.avgSystolic.toStringAsFixed(0)} / '
                          '${item.group.avgDiastolic.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${DateFormats.shortDateTime.format(item.group.groupStartAt)}'
                          ' - ${DateFormats.shortDateTime.format(rangeEnd)}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${item.memberCount} readings',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pulse ${item.group.avgPulse.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  Icon(
                    item.isExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                  ),
                ],
              ),
              if (item.group.sessionId != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Session: ${item.group.sessionId}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
              if (item.isExpanded) ...[
                const Divider(height: 24),
                if (item.isLoadingChildren)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (item.childError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      item.childError!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  )
                else
                  _ReadingList(readings: item.children ?? <Reading>[]),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingList extends StatelessWidget {
  const _ReadingList({required this.readings});

  final List<Reading> readings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (readings.isEmpty) {
      return Text(
        'No raw readings available for this group.',
        style: theme.textTheme.bodySmall,
      );
    }

    return Column(
      children: readings
          .map(
            (reading) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reading.systolic}/${reading.diastolic} • '
                          'Pulse ${reading.pulse}',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          DateFormats.shortDateTime.format(reading.takenAt),
                          style: theme.textTheme.bodySmall,
                        ),
                        if (reading.tags != null && reading.tags!.isNotEmpty)
                          Text(
                            reading.tags!,
                            style: theme.textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

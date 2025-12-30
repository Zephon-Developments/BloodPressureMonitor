import 'dart:async';

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
    required this.onEditReading,
    required this.onDeleteReading,
    required this.onShowReadingDetails,
  });

  final HistoryGroupItem item;
  final VoidCallback onToggle;
  final Future<void> Function(Reading reading) onEditReading;
  final Future<void> Function(Reading reading) onDeleteReading;
  final void Function(Reading reading) onShowReadingDetails;

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
                    item.isExpanded ? Icons.expand_less : Icons.expand_more,
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
                  _ReadingList(
                    readings: item.children ?? <Reading>[],
                    onEdit: onEditReading,
                    onDelete: onDeleteReading,
                    onShowDetails: onShowReadingDetails,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadingList extends StatelessWidget {
  const _ReadingList({
    required this.readings,
    required this.onEdit,
    required this.onDelete,
    required this.onShowDetails,
  });

  final List<Reading> readings;
  final Future<void> Function(Reading reading) onEdit;
  final Future<void> Function(Reading reading) onDelete;
  final void Function(Reading reading) onShowDetails;

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
      children: readings.map((reading) {
        final tagValues = reading.tags == null
            ? const <String>[]
            : reading.tags!
                .split(',')
                .map((tag) => tag.trim())
                .where((tag) => tag.isNotEmpty)
                .toList(growable: false);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.access_time,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => onShowDetails(reading),
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
                      if (tagValues.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: tagValues
                              .map(
                                (tag) => Chip(
                                  label: Text(tag),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant,
                                  ),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              PopupMenuButton<_GroupReadingAction>(
                tooltip: 'Reading actions',
                onSelected: (action) {
                  switch (action) {
                    case _GroupReadingAction.edit:
                      unawaited(onEdit(reading));
                      break;
                    case _GroupReadingAction.delete:
                      unawaited(onDelete(reading));
                      break;
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem<_GroupReadingAction>(
                    value: _GroupReadingAction.edit,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem<_GroupReadingAction>(
                    value: _GroupReadingAction.delete,
                    child: Text('Delete'),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

enum _GroupReadingAction { edit, delete }

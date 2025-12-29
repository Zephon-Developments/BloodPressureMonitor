import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/history.dart';

/// Filter controls displayed at the top of the history screen.
class HistoryFilterBar extends StatelessWidget {
  const HistoryFilterBar({
    super.key,
    required this.filters,
    required this.activePreset,
    required this.onPresetSelected,
    required this.onCustomRange,
    required this.onEditTags,
    required this.onModeChanged,
  });

  final HistoryFilters filters;
  final HistoryRangePreset activePreset;
  final Future<void> Function(HistoryRangePreset preset) onPresetSelected;
  final Future<void> Function() onCustomRange;
  final Future<void> Function() onEditTags;
  final Future<void> Function(HistoryViewMode mode) onModeChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _presetChip(
                  context,
                  label: '7 days',
                  preset: HistoryRangePreset.sevenDays,
                ),
                _presetChip(
                  context,
                  label: '30 days',
                  preset: HistoryRangePreset.thirtyDays,
                ),
                _presetChip(
                  context,
                  label: '90 days',
                  preset: HistoryRangePreset.ninetyDays,
                ),
                _presetChip(
                  context,
                  label: 'All',
                  preset: HistoryRangePreset.all,
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    onCustomRange();
                  },
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    filters.startDate == null || filters.endDate == null
                        ? 'Custom range'
                        : _formatRange(),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    onEditTags();
                  },
                  icon: const Icon(Icons.label),
                  label: Text(_tagLabel()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<HistoryViewMode>(
              segments: const [
                ButtonSegment<HistoryViewMode>(
                  value: HistoryViewMode.averaged,
                  icon: Icon(Icons.analytics_outlined),
                  label: Text('Averaged'),
                ),
                ButtonSegment<HistoryViewMode>(
                  value: HistoryViewMode.raw,
                  icon: Icon(Icons.view_list),
                  label: Text('Raw'),
                ),
              ],
              selected: <HistoryViewMode>{filters.viewMode},
              onSelectionChanged: (selection) {
                if (selection.isEmpty) {
                  return;
                }
                onModeChanged(selection.first);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(
    BuildContext context, {
    required String label,
    required HistoryRangePreset preset,
  }) {
    final bool selected = activePreset == preset;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onPresetSelected(preset),
    );
  }

  String _formatRange() {
    final start = filters.startDate;
    final end = filters.endDate;
    if (start == null || end == null) {
      return 'Custom range';
    }
    final startStr = '${start.year}-${start.month.toString().padLeft(2, '0')}-'
        '${start.day.toString().padLeft(2, '0')}';
    final endStr = '${end.year}-${end.month.toString().padLeft(2, '0')}-'
        '${end.day.toString().padLeft(2, '0')}';
    return '$startStr → $endStr';
  }

  String _tagLabel() {
    final count = filters.tags.length;
    if (count == 0) {
      return 'Tags (any)';
    }
    if (count == 1) {
      return 'Tag: ${filters.tags.first}';
    }
    return 'Tags ($count)';
  }
}

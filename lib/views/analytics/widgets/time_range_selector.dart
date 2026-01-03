import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/utils/time_range.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';

/// Segmented control for selecting the analytics time window.
class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        return Semantics(
          label: 'Time range selector',
          container: true,
          child: SegmentedButton<TimeRange>(
            segments: TimeRange.values
                .map(
                  (range) => ButtonSegment<TimeRange>(
                    value: range,
                    label: Text(range.label),
                  ),
                )
                .toList(),
            selected: <TimeRange>{viewModel.selectedRange},
            onSelectionChanged: (selection) {
              final chosen = selection.first;
              if (chosen == viewModel.selectedRange) {
                return;
              }
              viewModel.setTimeRange(chosen);
              viewModel.loadData(
                forceRefresh: true,
                forceOverlayRefresh: viewModel.showSleepOverlay,
              );
            },
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/analytics_empty_state.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/bp_dual_axis_chart.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/chart_legend.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/morning_evening_card.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/pulse_line_chart.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/sleep_stacked_area_chart.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/stats_card_grid.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/time_range_selector.dart';

/// Main analytics tab embedding charts, stats, and optional overlays.
class AnalyticsView extends StatefulWidget {
  const AnalyticsView({super.key});

  @override
  State<AnalyticsView> createState() => _AnalyticsViewState();
}

class _AnalyticsViewState extends State<AnalyticsView> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) {
      return;
    }
    _initialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AnalyticsViewModel>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        // Always show the time range selector and content area
        // Keep selector visible even when no data is available
        return RefreshIndicator(
          onRefresh: () => viewModel.loadData(
            forceRefresh: true,
            forceOverlayRefresh: viewModel.showSleepOverlay,
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Time range selector - always visible
                const TimeRangeSelector(),
                const SizedBox(height: 16),

                // Content area - show loading, error, empty state or data
                if (viewModel.isLoading && !viewModel.hasData)
                  const Padding(
                    padding: EdgeInsets.only(top: 64.0),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (viewModel.error != null && !viewModel.hasData)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 32),
                        Text(
                          viewModel.error!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              viewModel.loadData(forceRefresh: true),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                else if (!viewModel.hasData)
                  const AnalyticsEmptyState()
                else
                  ..._buildDataContent(viewModel),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Builds the data content when data is available.
  List<Widget> _buildDataContent(AnalyticsViewModel viewModel) {
    final HealthStats stats = viewModel.stats!;
    final ChartDataSet chartData = viewModel.chartData!;
    final DualAxisBpData? dualAxisData = viewModel.dualAxisBpData;

    return [
      StatsCardGrid(stats: stats),
      const SizedBox(height: 24),
      ChartLegend(
        isSampled: chartData.isSampled,
        sleepCorrelation: viewModel.sleepCorrelation,
      ),
      const SizedBox(height: 12),
      if (dualAxisData != null && dualAxisData.hasData)
        BpDualAxisChart(
          dataSet: dualAxisData,
          sleepCorrelation:
              viewModel.showSleepOverlay ? viewModel.sleepCorrelation : null,
        )
      else
        const SizedBox.shrink(),
      const SizedBox(height: 24),
      PulseLineChart(dataSet: chartData),
      const SizedBox(height: 24),
      if (viewModel.showSleepOverlay &&
          viewModel.sleepStages != null &&
          !(viewModel.sleepStages?.isEmpty ?? true))
        SleepStackedAreaChart(series: viewModel.sleepStages!),
      if (viewModel.showSleepOverlay) const SizedBox(height: 24),
      MorningEveningCard(split: stats.split),
      if (viewModel.lastUpdated != null) ...[
        const SizedBox(height: 12),
        Text(
          'Last updated: '
          '${viewModel.lastUpdated!.toLocal()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ];
  }
}

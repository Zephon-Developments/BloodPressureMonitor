import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/analytics_empty_state.dart';
import 'package:blood_pressure_monitor/views/analytics/widgets/bp_line_chart.dart';
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
        if (viewModel.isLoading && !viewModel.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null && !viewModel.hasData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(viewModel.error!),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => viewModel.loadData(forceRefresh: true),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (!viewModel.hasData) {
          return const AnalyticsEmptyState();
        }

        final HealthStats stats = viewModel.stats!;
        final ChartDataSet chartData = viewModel.chartData!;

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
                const TimeRangeSelector(),
                const SizedBox(height: 16),
                StatsCardGrid(stats: stats),
                const SizedBox(height: 24),
                ChartLegend(
                  isSampled: chartData.isSampled,
                  sleepCorrelation: viewModel.sleepCorrelation,
                ),
                const SizedBox(height: 12),
                BpLineChart(
                  dataSet: chartData,
                  sleepCorrelation: viewModel.showSleepOverlay
                      ? viewModel.sleepCorrelation
                      : null,
                ),
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
              ],
            ),
          ),
        );
      },
    );
  }
}

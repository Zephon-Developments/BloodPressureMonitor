import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/mini_stats.dart';
import 'package:blood_pressure_monitor/viewmodels/history_home_viewmodel.dart';
import 'package:blood_pressure_monitor/views/history/history_view.dart';
import 'package:blood_pressure_monitor/views/medication/medication_history_view.dart';
import 'package:blood_pressure_monitor/views/sleep/sleep_history_view.dart';
import 'package:blood_pressure_monitor/views/weight/weight_history_view.dart';
import 'package:blood_pressure_monitor/widgets/collapsible_section.dart';
import 'package:blood_pressure_monitor/widgets/mini_stats_display.dart';

/// Unified history page displaying mini-statistics for all health metrics.
///
/// Shows collapsible sections for Blood Pressure, Weight, Sleep, and
/// Medication with mini-stats summaries. Each section can be expanded to
/// view full statistics and access detailed history views.
///
/// Uses [HistoryHomeViewModel] for state management and lazy loading of
/// statistics per category.
class HistoryHomeView extends StatefulWidget {
  const HistoryHomeView({super.key});

  @override
  State<HistoryHomeView> createState() => _HistoryHomeViewState();
}

class _HistoryHomeViewState extends State<HistoryHomeView> {
  @override
  void initState() {
    super.initState();
    // Load all stats after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryHomeViewModel>().loadAllStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: RefreshIndicator(
        onRefresh: () => context.read<HistoryHomeViewModel>().refresh(),
        child: Consumer<HistoryHomeViewModel>(
          builder: (context, viewModel, child) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBloodPressureSection(context, viewModel),
                const SizedBox(height: 16),
                _buildWeightSection(context, viewModel),
                const SizedBox(height: 16),
                _buildSleepSection(context, viewModel),
                const SizedBox(height: 16),
                _buildMedicationSection(context, viewModel),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Builds the Blood Pressure collapsible section.
  Widget _buildBloodPressureSection(
    BuildContext context,
    HistoryHomeViewModel viewModel,
  ) {
    return CollapsibleSection(
      title: 'Blood Pressure',
      icon: Icons.favorite,
      miniStatsPreview: _buildMiniStatsPreview(
        context,
        viewModel.bloodPressureStats,
        viewModel.isLoadingBP,
        viewModel.errorBP,
        'BP',
      ),
      expandedContent: _buildExpandedContent(
        context,
        viewModel.bloodPressureStats,
        viewModel.isLoadingBP,
        viewModel.errorBP,
        'BP',
        () => _navigateToFullHistory(context, 'bp'),
      ),
    );
  }

  /// Builds the Weight collapsible section.
  Widget _buildWeightSection(
    BuildContext context,
    HistoryHomeViewModel viewModel,
  ) {
    return CollapsibleSection(
      title: 'Weight',
      icon: Icons.monitor_weight,
      miniStatsPreview: _buildMiniStatsPreview(
        context,
        viewModel.weightStats,
        viewModel.isLoadingWeight,
        viewModel.errorWeight,
        'Weight',
      ),
      expandedContent: _buildExpandedContent(
        context,
        viewModel.weightStats,
        viewModel.isLoadingWeight,
        viewModel.errorWeight,
        'Weight',
        () => _navigateToFullHistory(context, 'weight'),
      ),
    );
  }

  /// Builds the Sleep collapsible section.
  Widget _buildSleepSection(
    BuildContext context,
    HistoryHomeViewModel viewModel,
  ) {
    return CollapsibleSection(
      title: 'Sleep',
      icon: Icons.bedtime,
      miniStatsPreview: _buildMiniStatsPreview(
        context,
        viewModel.sleepStats,
        viewModel.isLoadingSleep,
        viewModel.errorSleep,
        'Sleep',
      ),
      expandedContent: _buildExpandedContent(
        context,
        viewModel.sleepStats,
        viewModel.isLoadingSleep,
        viewModel.errorSleep,
        'Sleep',
        () => _navigateToFullHistory(context, 'sleep'),
      ),
    );
  }

  /// Builds the Medication collapsible section.
  Widget _buildMedicationSection(
    BuildContext context,
    HistoryHomeViewModel viewModel,
  ) {
    return CollapsibleSection(
      title: 'Medication',
      icon: Icons.medication,
      miniStatsPreview: _buildMiniStatsPreview(
        context,
        viewModel.medicationStats,
        viewModel.isLoadingMedication,
        viewModel.errorMedication,
        'Medication',
      ),
      expandedContent: _buildExpandedContent(
        context,
        viewModel.medicationStats,
        viewModel.isLoadingMedication,
        viewModel.errorMedication,
        'Medication',
        () => _navigateToFullHistory(context, 'medication'),
      ),
    );
  }

  /// Builds the mini-stats preview shown in collapsed state.
  Widget _buildMiniStatsPreview(
    BuildContext context,
    MiniStats? stats,
    bool isLoading,
    String? error,
    String metricType,
  ) {
    if (isLoading) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (error != null) {
      return Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 20,
      );
    }

    if (stats == null) {
      return Text(
        'No data',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }

    return MiniStatsDisplay(
      miniStats: stats,
      metricType: metricType,
      compact: true,
    );
  }

  /// Builds the expanded content shown when section is open.
  Widget _buildExpandedContent(
    BuildContext context,
    MiniStats? stats,
    bool isLoading,
    String? error,
    String metricType,
    VoidCallback onViewFullHistory,
  ) {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              'No data available',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start tracking to see your $metricType history',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: MiniStatsDisplay(
            miniStats: stats,
            metricType: metricType,
            compact: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            onPressed: onViewFullHistory,
            icon: const Icon(Icons.history),
            label: const Text('View Full History'),
          ),
        ),
      ],
    );
  }

  /// Navigates to the full history view for the specified metric type.
  void _navigateToFullHistory(BuildContext context, String metricType) {
    Widget destinationView;

    switch (metricType.toLowerCase()) {
      case 'bp':
        destinationView = const HistoryView();
        break;
      case 'weight':
        destinationView = const WeightHistoryView();
        break;
      case 'sleep':
        destinationView = const SleepHistoryView();
        break;
      case 'medication':
        destinationView = const MedicationHistoryView();
        break;
      default:
        // Fallback for unknown metric types
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Full $metricType history - Coming Soon'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => destinationView,
      ),
    );
  }
}

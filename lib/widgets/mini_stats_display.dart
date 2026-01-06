import 'package:flutter/material.dart';
import 'package:blood_pressure_monitor/models/mini_stats.dart';

/// Displays mini-statistics for health metrics.
///
/// Shows the latest value and 7-day average without any trend analysis
/// or medical inference. The widget adapts to compact mode for use in
/// collapsed section headers.
class MiniStatsDisplay extends StatelessWidget {
  /// Creates a mini-stats display widget.
  ///
  /// The [miniStats] parameter is required. If [compact] is true, the widget
  /// displays a condensed version suitable for section headers.
  const MiniStatsDisplay({
    required this.miniStats,
    required this.metricType,
    this.compact = false,
    super.key,
  });

  /// The statistics to display.
  final MiniStats miniStats;

  /// The type of metric being displayed (e.g., 'BP', 'Weight', 'Sleep').
  ///
  /// Used to determine appropriate trend colors and labels.
  final String metricType;

  /// Whether to display in compact mode.
  ///
  /// In compact mode, the layout is condensed for use in section headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (compact) {
      return _buildCompactLayout(theme);
    }

    return _buildFullLayout(theme);
  }

  Widget _buildCompactLayout(
    ThemeData theme,
  ) {
    return Semantics(
      label:
          'Latest: ${miniStats.latestValue}, 7-day average: ${miniStats.weekAverage}',
      excludeSemantics: true,
      child: Text(
        miniStats.latestValue,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildFullLayout(
    ThemeData theme,
  ) {
    return Semantics(
      label:
          'Latest: ${miniStats.latestValue}, 7-day average: ${miniStats.weekAverage}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Latest Value
          Row(
            children: [
              Text(
                'Latest: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                miniStats.latestValue,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // 7-Day Average
          Row(
            children: [
              Text(
                '7-day avg: ',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                miniStats.weekAverage,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          // Last Update
          if (miniStats.lastUpdate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Updated ${_formatLastUpdate(miniStats.lastUpdate!)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatLastUpdate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} min ago';
      }
      return '${difference.inHours} hr ago';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    // For older dates, show the date
    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }
}

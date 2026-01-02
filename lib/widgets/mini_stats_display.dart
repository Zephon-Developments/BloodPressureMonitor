import 'package:flutter/material.dart';
import 'package:blood_pressure_monitor/models/mini_stats.dart';

/// Displays mini-statistics with trend indicators.
///
/// Shows the latest value, 7-day average, and a visual trend indicator
/// (up, down, stable, or insufficient data). The widget adapts to compact
/// mode for use in collapsed section headers.
///
/// Colors and icons for trends are context-appropriate based on the metric type.
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

  /// Gets the color for the trend indicator based on direction and metric type.
  Color _getTrendColor(BuildContext context, TrendDirection trend) {
    final colorScheme = Theme.of(context).colorScheme;

    switch (trend) {
      case TrendDirection.up:
        // For BP and Weight, up is concerning (red)
        // For Sleep and Medication adherence, up is good (green)
        if (metricType == 'BP' || metricType == 'Weight') {
          return colorScheme.error;
        }
        return Colors.green;
      case TrendDirection.down:
        // For BP and Weight, down is good (green)
        // For Sleep and Medication adherence, down is concerning (red)
        if (metricType == 'BP' || metricType == 'Weight') {
          return Colors.green;
        }
        return colorScheme.error;
      case TrendDirection.stable:
        return Colors.blue;
    }
  }

  /// Gets the icon for the trend indicator.
  IconData _getTrendIcon(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Icons.trending_up;
      case TrendDirection.down:
        return Icons.trending_down;
      case TrendDirection.stable:
        return Icons.trending_flat;
    }
  }

  /// Gets a human-readable label for the trend.
  String _getTrendLabel(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return 'Increasing';
      case TrendDirection.down:
        return 'Decreasing';
      case TrendDirection.stable:
        return 'Stable';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trendColor = _getTrendColor(context, miniStats.trend);
    final trendIcon = _getTrendIcon(miniStats.trend);
    final trendLabel = _getTrendLabel(miniStats.trend);

    if (compact) {
      return _buildCompactLayout(theme, trendColor, trendIcon, trendLabel);
    }

    return _buildFullLayout(theme, trendColor, trendIcon, trendLabel);
  }

  Widget _buildCompactLayout(
    ThemeData theme,
    Color trendColor,
    IconData trendIcon,
    String trendLabel,
  ) {
    return Semantics(
      label:
          'Latest: ${miniStats.latestValue}, 7-day average: ${miniStats.weekAverage}, Trend: $trendLabel',
      excludeSemantics: true,
      child: Row(
        children: [
          Text(
            miniStats.latestValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            trendIcon,
            size: 16,
            color: trendColor,
          ),
        ],
      ),
    );
  }

  Widget _buildFullLayout(
    ThemeData theme,
    Color trendColor,
    IconData trendIcon,
    String trendLabel,
  ) {
    return Semantics(
      label:
          'Latest: ${miniStats.latestValue}, 7-day average: ${miniStats.weekAverage}, Trend: $trendLabel',
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
          const SizedBox(height: 8),
          // Trend Indicator
          Row(
            children: [
              Icon(
                trendIcon,
                size: 20,
                color: trendColor,
              ),
              const SizedBox(width: 4),
              Text(
                trendLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: trendColor,
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

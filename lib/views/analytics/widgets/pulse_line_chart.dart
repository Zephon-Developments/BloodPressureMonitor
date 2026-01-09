import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/utils/responsive_utils.dart';

/// Trend chart for pulse measurements.
class PulseLineChart extends StatelessWidget {
  const PulseLineChart({
    required this.dataSet,
    super.key,
  });

  final ChartDataSet dataSet;

  @override
  Widget build(BuildContext context) {
    if (dataSet.pulsePoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final spots = dataSet.pulsePoints
        .map(
          (point) => FlSpot(
            point.timestamp.millisecondsSinceEpoch.toDouble(),
            point.value,
          ),
        )
        .toList();

    final chartHeight = ResponsiveUtils.chartHeightFor(
      context,
      portraitHeight: 280,
      landscapeHeight: 210,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: chartHeight,
          child: LineChart(
            LineChartData(
              minY: 40,
              maxY: 160,
              gridData: const FlGridData(show: true, horizontalInterval: 20),
              titlesData: FlTitlesData(
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 20,
                    reservedSize: 40,
                    getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 36,
                    getTitlesWidget: (value, meta) {
                      final date =
                          DateTime.fromMillisecondsSinceEpoch(value.toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('${date.month}/${date.day}'),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (items) => items
                      .map(
                        (item) => LineTooltipItem(
                          '${DateTime.fromMillisecondsSinceEpoch(item.x.toInt()).month}/'
                          '${DateTime.fromMillisecondsSinceEpoch(item.x.toInt()).day}\n'
                          'Pulse ${item.y.toStringAsFixed(0)} bpm',
                          Theme.of(context).textTheme.bodyMedium!,
                        ),
                      )
                      .toList(),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.purple,
                  barWidth: 2,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.purple.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

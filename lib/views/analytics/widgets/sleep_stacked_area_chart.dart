import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';

/// Visualizes nightly sleep stage composition as a stacked area chart.
class SleepStackedAreaChart extends StatelessWidget {
  const SleepStackedAreaChart({
    required this.series,
    super.key,
  });

  final SleepStageSeries series;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxMinutes = series.stages
        .map((stage) => stage.totalMinutes)
        .fold<int>(0, (maxValue, value) => value > maxValue ? value : maxValue)
        .toDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sleep Stages',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (series.hasIncompleteSessions)
                  Text(
                    'Some sessions missing stage data',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).colorScheme.error),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxMinutes == 0 ? 10 : maxMinutes,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 60,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 0.5,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 60,
                        reservedSize: 40,
                        getTitlesWidget: (value, _) =>
                            Text('${value.toInt()}m'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                              value.toInt());
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${date.month}/${date.day}'),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: const LineTouchData(enabled: false),
                  lineBarsData: _buildLines(),
                  betweenBarsData: _buildBetweenBars(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<LineChartBarData> _buildLines() {
    final baseSpots = <FlSpot>[];
    final deepSpots = <FlSpot>[];
    final lightSpots = <FlSpot>[];
    final remSpots = <FlSpot>[];
    final awakeSpots = <FlSpot>[];

    for (final stage in series.stages) {
      final x = stage.sessionDate.millisecondsSinceEpoch.toDouble();
      final deep = stage.deepMinutes.toDouble();
      final light = deep + stage.lightMinutes;
      final rem = light + stage.remMinutes;
      final awake = rem + stage.awakeMinutes;

      baseSpots.add(FlSpot(x, 0));
      deepSpots.add(FlSpot(x, deep));
      lightSpots.add(FlSpot(x, light.toDouble()));
      remSpots.add(FlSpot(x, rem.toDouble()));
      awakeSpots.add(FlSpot(x, awake.toDouble()));
    }

    return [
      _line(baseSpots, Colors.transparent),
      _line(deepSpots, Colors.indigo.shade700),
      _line(lightSpots, Colors.blue.shade400),
      _line(remSpots, Colors.purple.shade400),
      _line(awakeSpots, Colors.red.shade300),
    ];
  }

  List<BetweenBarsData> _buildBetweenBars() {
    return [
      BetweenBarsData(
        fromIndex: 0,
        toIndex: 1,
        color: Colors.indigo.shade400.withValues(alpha: 0.35),
      ),
      BetweenBarsData(
        fromIndex: 1,
        toIndex: 2,
        color: Colors.blue.shade300.withValues(alpha: 0.35),
      ),
      BetweenBarsData(
        fromIndex: 2,
        toIndex: 3,
        color: Colors.purple.shade200.withValues(alpha: 0.35),
      ),
      BetweenBarsData(
        fromIndex: 3,
        toIndex: 4,
        color: Colors.red.shade200.withValues(alpha: 0.3),
      ),
    ];
  }

  LineChartBarData _line(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dotData: const FlDotData(show: false),
    );
  }
}

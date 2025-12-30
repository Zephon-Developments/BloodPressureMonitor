import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/views/analytics/painters/clinical_band_painter.dart';

/// Combined systolic/diastolic chart with clinical banding and sleep overlay.
class BpLineChart extends StatelessWidget {
  const BpLineChart({
    required this.dataSet,
    this.sleepCorrelation,
    super.key,
  });

  final ChartDataSet dataSet;
  final SleepCorrelationData? sleepCorrelation;

  static const double _minY = 40;
  static const double _maxY = 200;

  @override
  Widget build(BuildContext context) {
    if (!dataSet.hasPoints) {
      return const SizedBox.shrink();
    }

    final systolic = _toSpots(dataSet.systolicPoints);
    final diastolic = _toSpots(dataSet.diastolicPoints);

    return AspectRatio(
      aspectRatio: 1.5,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: ClinicalBandPainter(
                    minValue: _minY,
                    maxValue: _maxY,
                  ),
                ),
              ),
              LineChart(
                LineChartData(
                  minY: _minY,
                  maxY: _maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor,
                      strokeWidth: 0.5,
                    ),
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: 20,
                        getTitlesWidget: (value, _) => Text('${value.toInt()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text('${date.month}/${date.day}'),
                          );
                        },
                      ),
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    verticalLines: sleepCorrelation == null
                        ? const <VerticalLine>[]
                        : sleepCorrelation!.correlationPoints
                            .map(
                              (point) => VerticalLine(
                                x: point.date.millisecondsSinceEpoch.toDouble(),
                                color: _qualityColor(point.sleepEntry.quality)
                                    .withValues(alpha: 0.35),
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              ),
                            )
                            .toList(),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()).month}/'
                              '${DateTime.fromMillisecondsSinceEpoch(spot.x.toInt()).day}\n'
                              '${spot.barIndex == 0 ? 'Systolic' : 'Diastolic'} '
                              '${spot.y.toStringAsFixed(0)} mmHg',
                              Theme.of(context).textTheme.bodyMedium!,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  lineBarsData: [
                    _line(systolic, Colors.red.shade700),
                    _line(
                      diastolic,
                      Colors.blue.shade700,
                      dashArray: const [6, 4],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _toSpots(List<ChartPoint> points) {
    return points
        .map(
          (point) => FlSpot(
            point.timestamp.millisecondsSinceEpoch.toDouble(),
            point.value,
          ),
        )
        .toList();
  }

  LineChartBarData _line(
    List<FlSpot> spots,
    Color color, {
    List<int>? dashArray,
  }) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2,
      dashArray: dashArray,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(
        show: false,
      ),
    );
  }

  static Color _qualityColor(int? score) {
    final quality = SleepQualityParsing.fromScore(score);
    switch (quality) {
      case SleepQualityLevel.excellent:
        return Colors.green;
      case SleepQualityLevel.good:
        return Colors.lightGreen;
      case SleepQualityLevel.fair:
        return Colors.orange;
      case SleepQualityLevel.poor:
        return Colors.deepOrange;
      case SleepQualityLevel.veryPoor:
        return Colors.red;
      case null:
        return Colors.indigo;
    }
  }
}

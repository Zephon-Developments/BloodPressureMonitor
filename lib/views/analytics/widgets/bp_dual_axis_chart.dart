import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/utils/responsive_utils.dart';
import 'package:blood_pressure_monitor/views/analytics/painters/split_clinical_band_painter.dart';

/// Dual-axis blood pressure chart with split baseline.
///
/// Displays systolic values on positive y-axis (above center) and diastolic
/// values on negative y-axis (below center). Uses NICE home monitoring
/// guidelines for color-coded zones. Supports sleep correlation overlay.
class BpDualAxisChart extends StatelessWidget {
  const BpDualAxisChart({
    required this.dataSet,
    this.sleepCorrelation,
    super.key,
  });

  final DualAxisBpData dataSet;
  final SleepCorrelationData? sleepCorrelation;

  @override
  Widget build(BuildContext context) {
    if (!dataSet.hasData) {
      return const SizedBox.shrink();
    }

    // Calculate symmetric axis range for visual balance
    final maxSystolic = dataSet.systolic.reduce(max);

    // Map diastolic to negative values for split display
    final negatedDiastolic = dataSet.diastolic.map((d) => -d).toList();
    final minNegatedDiastolic = negatedDiastolic.reduce(min);

    // Compute symmetric range with padding
    final maxAbsValue = max(maxSystolic, minNegatedDiastolic.abs()) + 20;
    final minY = -maxAbsValue;
    final maxY = maxAbsValue;

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];

    for (var i = 0; i < dataSet.length; i++) {
      final x = dataSet.timestamps[i].millisecondsSinceEpoch.toDouble();
      systolicSpots.add(FlSpot(x, dataSet.systolic[i]));
      diastolicSpots.add(FlSpot(x, negatedDiastolic[i]));
    }

    final chartHeight = ResponsiveUtils.chartHeightFor(
      context,
      portraitHeight: 320,
      landscapeHeight: 240,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: SplitClinicalBandPainter(
                    minY: minY,
                    maxY: maxY,
                  ),
                ),
              ),
              LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 20,
                    getDrawingHorizontalLine: (value) {
                      // Emphasize center baseline
                      if (value == 0) {
                        return FlLine(
                          color: Colors.black.withValues(alpha: 0.3),
                          strokeWidth: 1.5,
                        );
                      }
                      return FlLine(
                        color: Theme.of(context).dividerColor,
                        strokeWidth: 0.5,
                      );
                    },
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
                        interval: 40,
                        getTitlesWidget: (value, _) {
                          // Show absolute values for diastolic (convert back from negative)
                          final displayValue = value.abs().toInt();
                          return Text('$displayValue');
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        interval: _calculateDateInterval(dataSet),
                        getTitlesWidget: (value, meta) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            value.toInt(),
                          );
                          return Transform.rotate(
                            angle: -0.5, // ~30 degrees
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
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
                      getTooltipItems: (spots) => spots.map(
                        (spot) {
                          final date = DateTime.fromMillisecondsSinceEpoch(
                            spot.x.toInt(),
                          );
                          final isSystolic = spot.barIndex == 0;
                          // Convert diastolic back to positive for display
                          final displayValue = isSystolic
                              ? spot.y.toStringAsFixed(0)
                              : (-spot.y).toStringAsFixed(0);
                          return LineTooltipItem(
                            '${date.month}/${date.day}\\n'
                            '${isSystolic ? 'Systolic' : 'Diastolic'} '
                            '$displayValue mmHg',
                            Theme.of(context).textTheme.bodyMedium!,
                          );
                        },
                      ).toList(),
                    ),
                  ),
                  lineBarsData: [
                    _line(systolicSpots, Colors.red.shade700),
                    _line(
                      diastolicSpots,
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

  /// Calculate adaptive date interval based on time range to prevent overlap.
  double _calculateDateInterval(DualAxisBpData dataSet) {
    if (dataSet.length < 2) {
      return 1;
    }

    final rangeDays = dataSet.maxDate.difference(dataSet.minDate).inDays;

    // Target ~6-8 labels across the x-axis
    if (rangeDays <= 7) {
      // Show daily for week or less
      return const Duration(days: 1).inMilliseconds.toDouble();
    } else if (rangeDays <= 30) {
      // Show every ~4 days for month
      return const Duration(days: 4).inMilliseconds.toDouble();
    } else if (rangeDays <= 90) {
      // Show weekly for quarter
      return const Duration(days: 7).inMilliseconds.toDouble();
    } else {
      // Show every 2 weeks for longer ranges
      return const Duration(days: 14).inMilliseconds.toDouble();
    }
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

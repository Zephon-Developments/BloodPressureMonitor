import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/constants/clinical_constants.dart';
import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/views/analytics/painters/clinical_band_painter.dart';

/// Displays separate synchronized charts for systolic and diastolic BP.
///
/// Each chart has its own Y-axis with appropriate NICE guideline bands,
/// while sharing a synchronized X-axis (time) for easy comparison.
/// Supports optional sleep correlation overlay.
class BpSplitCharts extends StatelessWidget {
  const BpSplitCharts({
    required this.dataSet,
    this.sleepCorrelation,
    super.key,
  });

  final ChartDataSet dataSet;
  final SleepCorrelationData? sleepCorrelation;

  @override
  Widget build(BuildContext context) {
    if (!dataSet.hasPoints) {
      return const SizedBox.shrink();
    }

    final systolicSpots = _toSpots(dataSet.systolicPoints);
    final diastolicSpots = _toSpots(dataSet.diastolicPoints);

    // Calculate shared X-axis range
    final minX = dataSet.minDate.millisecondsSinceEpoch.toDouble();
    final maxX = dataSet.maxDate.millisecondsSinceEpoch.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Systolic Chart
        _ChartSection(
          title: 'Systolic Blood Pressure',
          spots: systolicSpots,
          minX: minX,
          maxX: maxX,
          minY: BpClinicalRanges.systolicNormalMin.toDouble() - 10,
          maxY: 200,
          bpType: BpType.systolic,
          lineColor: Colors.red.shade700,
          sleepCorrelation: sleepCorrelation,
          showBottomTitles: false,
        ),
        const SizedBox(height: 16),
        // Diastolic Chart
        _ChartSection(
          title: 'Diastolic Blood Pressure',
          spots: diastolicSpots,
          minX: minX,
          maxX: maxX,
          minY: BpClinicalRanges.diastolicNormalMin.toDouble() - 10,
          maxY: 140,
          bpType: BpType.diastolic,
          lineColor: Colors.blue.shade700,
          sleepCorrelation: sleepCorrelation,
          showBottomTitles: true,
        ),
      ],
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
}

/// Individual chart section for systolic or diastolic display.
class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.spots,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    required this.bpType,
    required this.lineColor,
    required this.showBottomTitles,
    this.sleepCorrelation,
  });

  final String title;
  final List<FlSpot> spots;
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;
  final BpType bpType;
  final Color lineColor;
  final bool showBottomTitles;
  final SleepCorrelationData? sleepCorrelation;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chart title
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            // Chart
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ClinicalBandPainter(
                        minValue: minY,
                        maxValue: maxY,
                        bpType: bpType,
                      ),
                    ),
                  ),
                  LineChart(
                    LineChartData(
                      minX: minX,
                      maxX: maxX,
                      minY: minY,
                      maxY: maxY,
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
                            getTitlesWidget: (value, _) =>
                                Text('${value.toInt()}'),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: showBottomTitles,
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
                                    x: point.date.millisecondsSinceEpoch
                                        .toDouble(),
                                    color: _qualityColor(
                                      point.sleepEntry.quality,
                                    ).withValues(alpha: 0.35),
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
                                  '${spot.y.toStringAsFixed(0)} mmHg',
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
                          color: lineColor,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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

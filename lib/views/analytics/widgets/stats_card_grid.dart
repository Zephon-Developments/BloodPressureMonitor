import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';

/// Grid summarizing primary min/avg/max statistics and variability.
class StatsCardGrid extends StatelessWidget {
  const StatsCardGrid({
    required this.stats,
    super.key,
  });

  final HealthStats stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          title: 'Systolic',
          min: stats.minSystolic,
          avg: stats.avgSystolic,
          max: stats.maxSystolic,
          unit: 'mmHg',
          color: Colors.red.shade50,
        ),
        _StatCard(
          title: 'Diastolic',
          min: stats.minDiastolic,
          avg: stats.avgDiastolic,
          max: stats.maxDiastolic,
          unit: 'mmHg',
          color: Colors.blue.shade50,
        ),
        _StatCard(
          title: 'Pulse',
          min: stats.minPulse,
          avg: stats.avgPulse,
          max: stats.maxPulse,
          unit: 'bpm',
          color: Colors.purple.shade50,
        ),
        _VariabilityCard(stats: stats),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.min,
    required this.avg,
    required this.max,
    required this.unit,
    required this.color,
  });

  final String title;
  final double min;
  final double avg;
  final double max;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${avg.toStringAsFixed(0)} $unit',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Range: ${min.toStringAsFixed(0)}-${max.toStringAsFixed(0)}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VariabilityCard extends StatelessWidget {
  const _VariabilityCard({required this.stats});

  final HealthStats stats;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variability (SD / CV)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _variabilityRow('Systolic', stats.systolicStdDev, stats.systolicCv),
            _variabilityRow(
              'Diastolic',
              stats.diastolicStdDev,
              stats.diastolicCv,
            ),
            _variabilityRow('Pulse', stats.pulseStdDev, stats.pulseCv),
          ],
        ),
      ),
    );
  }

  Widget _variabilityRow(String label, double stdDev, double cv) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text('${stdDev.toStringAsFixed(1)} / ${cv.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

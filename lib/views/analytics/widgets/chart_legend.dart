import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';

/// Legend describing clinical bands and optional sleep overlay markers.
class ChartLegend extends StatelessWidget {
  const ChartLegend({
    this.isSampled = false,
    this.sleepCorrelation,
    super.key,
  });

  final bool isSampled;
  final SleepCorrelationData? sleepCorrelation;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            _LegendEntry(label: 'Normal <135/<85', color: Colors.green),
            _LegendEntry(label: 'Stage 1', color: Colors.amber),
            _LegendEntry(label: 'Stage 2', color: Colors.orange),
            _LegendEntry(label: 'Stage 3', color: Colors.red),
          ],
        ),
        if (sleepCorrelation != null)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 12,
              children: [
                _LegendEntry(label: 'Sleep overlay', color: Colors.indigo),
              ],
            ),
          ),
        if (isSampled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Data downsampled for smoother rendering.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}

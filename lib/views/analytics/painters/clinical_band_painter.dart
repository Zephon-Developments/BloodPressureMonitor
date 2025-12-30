import 'package:flutter/material.dart';

/// Paints NICE HBPM bands behind the blood pressure chart.
class ClinicalBandPainter extends CustomPainter {
  ClinicalBandPainter({
    required this.minValue,
    required this.maxValue,
  });

  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    final bands = <_Band>[
      _Band(color: Colors.green.withValues(alpha: 0.1), start: 0, end: 135),
      _Band(color: Colors.amber.withValues(alpha: 0.15), start: 135, end: 149),
      _Band(color: Colors.orange.withValues(alpha: 0.2), start: 150, end: 169),
      _Band(
          color: Colors.red.withValues(alpha: 0.25), start: 170, end: maxValue,),
    ];

    for (final band in bands) {
      final top = _valueToDy(band.end, size.height);
      final bottom = _valueToDy(band.start, size.height);
      final rect = Rect.fromLTRB(0, top, size.width, bottom);
      canvas.drawRect(rect, Paint()..color = band.color);
    }
  }

  double _valueToDy(double value, double height) {
    final clamped = value.clamp(minValue, maxValue);
    final normalized = (clamped - minValue) / (maxValue - minValue);
    return height - (normalized * height);
  }

  @override
  bool shouldRepaint(covariant ClinicalBandPainter oldDelegate) {
    return minValue != oldDelegate.minValue || maxValue != oldDelegate.maxValue;
  }
}

class _Band {
  const _Band({required this.color, required this.start, required this.end});

  final Color color;
  final double start;
  final double end;
}

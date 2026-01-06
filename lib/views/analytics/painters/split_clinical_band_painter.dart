import 'package:flutter/material.dart';

/// Paints split NICE HBPM bands for dual-axis blood pressure chart.
///
/// The chart has a center baseline at y=0. Systolic values are plotted above
/// (positive y-axis) and diastolic values below (negative y-axis). Each half
/// uses NICE home monitoring guidelines for color zones:
///
/// Systolic (above): Normal <135 (green), Stage 1: 135-149 (yellow),
/// Stage 2: 150-179 (orange), Stage 3: ≥180 (red)
///
/// Diastolic (below): Normal >-85 (green), Stage 1: -85 to -92 (yellow),
/// Stage 2: -93 to -119 (orange), Stage 3: ≤-120 (red)
class SplitClinicalBandPainter extends CustomPainter {
  SplitClinicalBandPainter({
    required this.minY,
    required this.maxY,
  });

  final double minY;
  final double maxY;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = _valueToDy(0, size.height);

    // Systolic bands (above center line, positive values)
    final systolicBands = <_Band>[
      _Band(
        color: Colors.green.withValues(alpha: 0.1),
        start: 0,
        end: 135,
      ),
      _Band(
        color: Colors.amber.withValues(alpha: 0.15),
        start: 135,
        end: 150,
      ),
      _Band(
        color: Colors.orange.withValues(alpha: 0.2),
        start: 150,
        end: 180,
      ),
      _Band(
        color: Colors.red.withValues(alpha: 0.25),
        start: 180,
        end: maxY,
      ),
    ];

    // Diastolic bands (below center line, negative values)
    final diastolicBands = <_Band>[
      _Band(
        color: Colors.green.withValues(alpha: 0.1),
        start: 0,
        end: -85,
      ),
      _Band(
        color: Colors.amber.withValues(alpha: 0.15),
        start: -85,
        end: -93,
      ),
      _Band(
        color: Colors.orange.withValues(alpha: 0.2),
        start: -93,
        end: -120,
      ),
      _Band(
        color: Colors.red.withValues(alpha: 0.25),
        start: -120,
        end: minY,
      ),
    ];

    // Paint systolic bands
    for (final band in systolicBands) {
      if (band.end > 0) {
        final top = _valueToDy(band.end, size.height);
        final bottom = _valueToDy(band.start, size.height).clamp(0.0, centerY);
        if (top < bottom) {
          final rect = Rect.fromLTRB(0, top, size.width, bottom);
          canvas.drawRect(rect, Paint()..color = band.color);
        }
      }
    }

    // Paint diastolic bands
    for (final band in diastolicBands) {
      if (band.start < 0) {
        final top =
            _valueToDy(band.start, size.height).clamp(centerY, size.height);
        final bottom = _valueToDy(band.end, size.height);
        if (top < bottom) {
          final rect = Rect.fromLTRB(0, top, size.width, bottom);
          canvas.drawRect(rect, Paint()..color = band.color);
        }
      }
    }

    // Draw center baseline
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..strokeWidth = 1.5;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      paint,
    );
  }

  double _valueToDy(double value, double height) {
    final clamped = value.clamp(minY, maxY);
    final normalized = (clamped - minY) / (maxY - minY);
    return height - (normalized * height);
  }

  @override
  bool shouldRepaint(covariant SplitClinicalBandPainter oldDelegate) {
    return minY != oldDelegate.minY || maxY != oldDelegate.maxY;
  }
}

class _Band {
  const _Band({required this.color, required this.start, required this.end});

  final Color color;
  final double start;
  final double end;
}

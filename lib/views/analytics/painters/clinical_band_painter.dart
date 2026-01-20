import 'package:flutter/material.dart';
import 'package:blood_pressure_monitor/constants/clinical_constants.dart';

/// Type of blood pressure measurement for clinical band display.
enum BpType {
  /// Systolic blood pressure (upper reading)
  systolic,

  /// Diastolic blood pressure (lower reading)
  diastolic,
}

/// Paints NICE HBPM bands behind the blood pressure chart.
///
/// Uses centralized clinical constants from [BpClinicalRanges] to display
/// color-coded zones based on NICE Home Monitoring Guidelines.
class ClinicalBandPainter extends CustomPainter {
  /// Creates a clinical band painter.
  ///
  /// The [bpType] determines whether to use systolic or diastolic thresholds.
  ClinicalBandPainter({
    required this.minValue,
    required this.maxValue,
    required this.bpType,
  });

  final double minValue;
  final double maxValue;
  final BpType bpType;

  @override
  void paint(Canvas canvas, Size size) {
    final List<_Band> bands;

    if (bpType == BpType.systolic) {
      bands = <_Band>[
        _Band(
          color: BpClinicalRanges.normalGreen
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.systolicNormalMin.toDouble(),
          end: BpClinicalRanges.systolicNormalMax.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage1Yellow
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.systolicNormalMax.toDouble() + 1,
          end: BpClinicalRanges.systolicStage1Max.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage2Orange
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.systolicStage1Max.toDouble() + 1,
          end: BpClinicalRanges.systolicStage2Max.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage3Red
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.systolicStage2Max.toDouble() + 1,
          end: maxValue,
        ),
      ];
    } else {
      // Diastolic
      bands = <_Band>[
        _Band(
          color: BpClinicalRanges.normalGreen
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.diastolicNormalMin.toDouble(),
          end: BpClinicalRanges.diastolicNormalMax.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage1Yellow
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.diastolicNormalMax.toDouble() + 1,
          end: BpClinicalRanges.diastolicStage1Max.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage2Orange
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.diastolicStage1Max.toDouble() + 1,
          end: BpClinicalRanges.diastolicStage2Max.toDouble(),
        ),
        _Band(
          color: BpClinicalRanges.stage3Red
              .withValues(alpha: BpClinicalRanges.bandOpacity),
          start: BpClinicalRanges.diastolicStage2Max.toDouble() + 1,
          end: maxValue,
        ),
      ];
    }

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
    return minValue != oldDelegate.minValue ||
        maxValue != oldDelegate.maxValue ||
        bpType != oldDelegate.bpType;
  }
}

class _Band {
  const _Band({required this.color, required this.start, required this.end});

  final Color color;
  final double start;
  final double end;
}

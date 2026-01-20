/// Clinical guidelines and reference ranges for blood pressure monitoring.
///
/// All values are based on NICE (National Institute for Health and Care Excellence)
/// Home Monitoring Guidelines for Blood Pressure.
library;

import 'dart:ui';

/// Blood pressure clinical ranges based on NICE guidelines.
///
/// These values are for visualization purposes only and do not constitute
/// medical advice. Users should consult healthcare professionals for
/// interpretation of their readings.
class BpClinicalRanges {
  /// Systolic blood pressure thresholds (mmHg)
  static const systolicNormalMin = 90;
  static const systolicNormalMax = 134;
  static const systolicStage1Max = 149;
  static const systolicStage2Max = 179;
  // Stage 3/Crisis is ≥180

  /// Diastolic blood pressure thresholds (mmHg)
  static const diastolicNormalMin = 60;
  static const diastolicNormalMax = 84;
  static const diastolicStage1Max = 94;
  static const diastolicStage2Max = 119;
  // Stage 3/Crisis is ≥120

  /// NICE guideline colors for blood pressure ranges.
  ///
  /// These colors are designed for clinical clarity and accessibility.
  static const Color normalGreen = Color(0xFF4CAF50);
  static const Color stage1Yellow = Color(0xFFFFC107);
  static const Color stage2Orange = Color(0xFFFF9800);
  static const Color stage3Red = Color(0xFFF44336);

  /// Background opacity for clinical band overlays on charts.
  static const double bandOpacity = 0.15;
}

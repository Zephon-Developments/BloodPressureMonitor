import 'package:blood_pressure_monitor/models/reading.dart';

/// Validation severity level for blood pressure readings.
enum ValidationLevel {
  /// Reading is within normal medical ranges.
  valid,

  /// Reading is outside normal ranges but within plausible medical bounds.
  /// Requires user confirmation before persistence.
  warning,

  /// Reading is outside plausible medical bounds or violates medical rules.
  /// Blocks persistence completely.
  error,
}

/// Result of validating a blood pressure reading.
///
/// Contains the validation level, optional message for display, and whether
/// user confirmation is required before proceeding.
class ValidationResult {
  /// The severity level of the validation result.
  final ValidationLevel level;

  /// Human-readable message describing the validation issue.
  final String? message;

  /// Whether user confirmation is required to proceed.
  ///
  /// True only for [ValidationLevel.warning]; errors always block.
  final bool requiresConfirmation;

  /// Creates a validation result.
  const ValidationResult({
    required this.level,
    this.message,
    required this.requiresConfirmation,
  });

  /// Creates a valid result (no issues).
  const ValidationResult.valid()
      : level = ValidationLevel.valid,
        message = null,
        requiresConfirmation = false;

  /// Creates a warning result (soft block).
  const ValidationResult.warning(this.message)
      : level = ValidationLevel.warning,
        requiresConfirmation = true;

  /// Creates an error result (hard block).
  const ValidationResult.error(this.message)
      : level = ValidationLevel.error,
        requiresConfirmation = false;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValidationResult &&
          runtimeType == other.runtimeType &&
          level == other.level &&
          message == other.message &&
          requiresConfirmation == other.requiresConfirmation;

  @override
  int get hashCode =>
      level.hashCode ^ message.hashCode ^ requiresConfirmation.hashCode;
}

/// Validates systolic and diastolic blood pressure values.
///
/// Enforces medical bounds and checks relationship between systolic/diastolic.
///
/// Ranges:
/// - Systolic: <70 error, 70–89 warning, 90–180 valid, 181–250 warning, >250 error
/// - Diastolic: <40 error, 40–59 warning, 60–100 valid, 101–150 warning, >150 error
/// - Relationship: systolic < diastolic → error; systolic == diastolic → warning
///
/// Returns a [ValidationResult] indicating the validation status.
ValidationResult validateBloodPressure(int systolic, int diastolic) {
  // Check relationship rules first (most critical)
  if (systolic < diastolic) {
    return const ValidationResult.error(
      'Systolic pressure cannot be lower than diastolic pressure',
    );
  }

  if (systolic == diastolic) {
    return const ValidationResult.warning(
      'Systolic and diastolic values are equal, which is medically unusual. '
      'Please confirm this reading is correct.',
    );
  }

  // Check error bounds first (outside medical plausibility)
  if (systolic < 70) {
    return const ValidationResult.error(
      'Systolic pressure is dangerously low (<70 mmHg). '
      'Please verify the reading.',
    );
  }

  if (systolic > 250) {
    return const ValidationResult.error(
      'Systolic pressure is dangerously high (>250 mmHg). '
      'Please verify the reading.',
    );
  }

  if (diastolic < 40) {
    return const ValidationResult.error(
      'Diastolic pressure is dangerously low (<40 mmHg). '
      'Please verify the reading.',
    );
  }

  if (diastolic > 150) {
    return const ValidationResult.error(
      'Diastolic pressure is dangerously high (>150 mmHg). '
      'Please verify the reading.',
    );
  }

  // Check for warning ranges (outside normal but within medical bounds)
  // Systolic: 70-89 warning, 90-180 valid, 181-250 warning
  if ((systolic >= 70 && systolic < 90) ||
      (systolic > 180 && systolic <= 250)) {
    return ValidationResult.warning(
      'Systolic pressure ($systolic mmHg) is outside the normal range '
      '(90-180 mmHg). Please confirm this reading is correct.',
    );
  }

  // Diastolic: 40-59 warning, 60-100 valid, 101-150 warning
  if ((diastolic >= 40 && diastolic < 60) ||
      (diastolic > 100 && diastolic <= 150)) {
    return ValidationResult.warning(
      'Diastolic pressure ($diastolic mmHg) is outside the normal range '
      '(60-100 mmHg). Please confirm this reading is correct.',
    );
  }

  return const ValidationResult.valid();
}

/// Validates pulse rate.
///
/// Ranges:
/// - Pulse: <30 error, 30–59 warning, 60–100 valid, 101–200 warning, >200 error
///
/// Returns a [ValidationResult] indicating the validation status.
ValidationResult validatePulse(int pulse) {
  if (pulse < 30) {
    return const ValidationResult.error(
      'Pulse rate is dangerously low (<30 bpm). Please verify the reading.',
    );
  }

  if (pulse > 200) {
    return const ValidationResult.error(
      'Pulse rate is dangerously high (>200 bpm). Please verify the reading.',
    );
  }

  if (pulse < 60 || pulse > 100) {
    return ValidationResult.warning(
      'Pulse rate ($pulse bpm) is outside the normal range (60-100 bpm). '
      'Please confirm this reading is correct.',
    );
  }

  return const ValidationResult.valid();
}

/// Validates a complete blood pressure reading.
///
/// Checks both blood pressure and pulse values, returning the most severe
/// validation result (error > warning > valid).
///
/// Parameters:
/// - [reading]: The reading to validate
///
/// Returns the most severe [ValidationResult] from all validations.
ValidationResult validateReading(Reading reading) {
  final bpResult = validateBloodPressure(reading.systolic, reading.diastolic);
  final pulseResult = validatePulse(reading.pulse);

  // Return the most severe result (error > warning > valid)
  if (bpResult.level == ValidationLevel.error ||
      pulseResult.level == ValidationLevel.error) {
    return bpResult.level == ValidationLevel.error ? bpResult : pulseResult;
  }

  if (bpResult.level == ValidationLevel.warning ||
      pulseResult.level == ValidationLevel.warning) {
    // Combine warning messages if both are warnings
    if (bpResult.level == ValidationLevel.warning &&
        pulseResult.level == ValidationLevel.warning) {
      return ValidationResult.warning(
        '${bpResult.message}\n${pulseResult.message}',
      );
    }
    return bpResult.level == ValidationLevel.warning ? bpResult : pulseResult;
  }

  return const ValidationResult.valid();
}

/// Legacy validator for backwards compatibility.
///
/// Deprecated: Use [validateBloodPressure] instead for detailed validation.
@Deprecated('Use validateBloodPressure for enhanced validation')
bool isValidBloodPressure(int systolic, int diastolic) {
  final result = validateBloodPressure(systolic, diastolic);
  return result.level == ValidationLevel.valid;
}

/// Legacy validator for backwards compatibility.
///
/// Deprecated: Use [validatePulse] instead for detailed validation.
@Deprecated('Use validatePulse for enhanced validation')
bool isValidPulse(int pulse) {
  final result = validatePulse(pulse);
  return result.level == ValidationLevel.valid;
}

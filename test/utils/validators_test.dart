import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateBloodPressure', () {
    group('valid ranges', () {
      test('accepts normal values', () {
        final result = validateBloodPressure(120, 80);
        expect(result.level, ValidationLevel.valid);
        expect(result.message, isNull);
        expect(result.requiresConfirmation, false);
      });

      test('accepts lower bound of normal range', () {
        final result = validateBloodPressure(90, 60);
        expect(result.level, ValidationLevel.valid);
      });

      test('accepts upper bound of normal range', () {
        final result = validateBloodPressure(180, 100);
        expect(result.level, ValidationLevel.valid);
      });

      test('accepts mid-range values', () {
        final result = validateBloodPressure(135, 85);
        expect(result.level, ValidationLevel.valid);
      });
    });

    group('warning ranges', () {
      test('warns on borderline low systolic', () {
        final result = validateBloodPressure(75, 60);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('Systolic'));
        expect(result.message, contains('75 mmHg'));
        expect(result.requiresConfirmation, true);
      });

      test('warns on borderline high systolic', () {
        final result = validateBloodPressure(185, 80);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('Systolic'));
        expect(result.message, contains('185 mmHg'));
        expect(result.requiresConfirmation, true);
      });

      test('warns on borderline low diastolic', () {
        final result = validateBloodPressure(120, 45);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('Diastolic'));
        expect(result.message, contains('45 mmHg'));
        expect(result.requiresConfirmation, true);
      });

      test('warns on borderline high diastolic', () {
        final result = validateBloodPressure(120, 105);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('Diastolic'));
        expect(result.message, contains('105 mmHg'));
        expect(result.requiresConfirmation, true);
      });

      test('warns on systolic near upper boundary', () {
        final result = validateBloodPressure(245, 80);
        expect(result.level, ValidationLevel.warning);
      });

      test('warns on diastolic in high warning range', () {
        final result = validateBloodPressure(120, 105);
        expect(result.level, ValidationLevel.warning);
      });

      test('warns when systolic equals diastolic', () {
        final result = validateBloodPressure(100, 100);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('equal'));
        expect(result.requiresConfirmation, true);
      });
    });

    group('error ranges', () {
      test('errors on dangerously low systolic', () {
        final result = validateBloodPressure(65, 40);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('Systolic'));
        expect(result.message, contains('dangerously low'));
        expect(result.requiresConfirmation, false);
      });

      test('errors on dangerously high systolic', () {
        final result = validateBloodPressure(260, 80);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('Systolic'));
        expect(result.message, contains('dangerously high'));
        expect(result.requiresConfirmation, false);
      });

      test('errors on dangerously low diastolic', () {
        final result = validateBloodPressure(120, 35);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('Diastolic'));
        expect(result.message, contains('dangerously low'));
        expect(result.requiresConfirmation, false);
      });

      test('errors on dangerously high diastolic', () {
        final result = validateBloodPressure(200, 155);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('Diastolic'));
        expect(result.message, contains('dangerously high'));
        expect(result.requiresConfirmation, false);
      });

      test('errors when systolic < diastolic', () {
        final result = validateBloodPressure(80, 120);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('cannot be lower than'));
        expect(result.requiresConfirmation, false);
      });

      test('errors on extreme low values', () {
        final result = validateBloodPressure(30, 20);
        expect(result.level, ValidationLevel.error);
      });

      test('errors on extreme high values', () {
        final result = validateBloodPressure(300, 200);
        expect(result.level, ValidationLevel.error);
      });
    });

    group('boundary values', () {
      test('systolic boundary at 70 (just valid)', () {
        final result = validateBloodPressure(70, 60);
        expect(result.level, ValidationLevel.warning);
      });

      test('systolic boundary at 69 (error)', () {
        final result = validateBloodPressure(69, 40);
        expect(result.level, ValidationLevel.error);
      });

      test('systolic boundary at 89 (warning)', () {
        final result = validateBloodPressure(89, 60);
        expect(result.level, ValidationLevel.warning);
      });

      test('systolic boundary at 90 (valid)', () {
        final result = validateBloodPressure(90, 60);
        expect(result.level, ValidationLevel.valid);
      });

      test('diastolic boundary at 40 (just valid)', () {
        final result = validateBloodPressure(100, 40);
        expect(result.level, ValidationLevel.warning);
      });

      test('diastolic boundary at 39 (error)', () {
        final result = validateBloodPressure(100, 39);
        expect(result.level, ValidationLevel.error);
      });
    });
  });

  group('validatePulse', () {
    group('valid ranges', () {
      test('accepts normal pulse', () {
        final result = validatePulse(70);
        expect(result.level, ValidationLevel.valid);
        expect(result.message, isNull);
        expect(result.requiresConfirmation, false);
      });

      test('accepts lower bound of normal range', () {
        final result = validatePulse(60);
        expect(result.level, ValidationLevel.valid);
      });

      test('accepts upper bound of normal range', () {
        final result = validatePulse(100);
        expect(result.level, ValidationLevel.valid);
      });
    });

    group('warning ranges', () {
      test('warns on borderline low pulse', () {
        final result = validatePulse(45);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('45 bpm'));
        expect(result.requiresConfirmation, true);
      });

      test('warns on borderline high pulse', () {
        final result = validatePulse(150);
        expect(result.level, ValidationLevel.warning);
        expect(result.message, contains('150 bpm'));
        expect(result.requiresConfirmation, true);
      });

      test('warns at pulse 30 (boundary)', () {
        final result = validatePulse(30);
        expect(result.level, ValidationLevel.warning);
      });

      test('warns at pulse 200 (boundary)', () {
        final result = validatePulse(200);
        expect(result.level, ValidationLevel.warning);
      });
    });

    group('error ranges', () {
      test('errors on dangerously low pulse', () {
        final result = validatePulse(25);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('dangerously low'));
        expect(result.requiresConfirmation, false);
      });

      test('errors on dangerously high pulse', () {
        final result = validatePulse(210);
        expect(result.level, ValidationLevel.error);
        expect(result.message, contains('dangerously high'));
        expect(result.requiresConfirmation, false);
      });

      test('errors at pulse 29 (just below minimum)', () {
        final result = validatePulse(29);
        expect(result.level, ValidationLevel.error);
      });

      test('errors at pulse 201 (just above maximum)', () {
        final result = validatePulse(201);
        expect(result.level, ValidationLevel.error);
      });
    });

    group('boundary values', () {
      test('pulse boundary at 59 (warning)', () {
        final result = validatePulse(59);
        expect(result.level, ValidationLevel.warning);
      });

      test('pulse boundary at 60 (valid)', () {
        final result = validatePulse(60);
        expect(result.level, ValidationLevel.valid);
      });

      test('pulse boundary at 100 (valid)', () {
        final result = validatePulse(100);
        expect(result.level, ValidationLevel.valid);
      });

      test('pulse boundary at 101 (warning)', () {
        final result = validatePulse(101);
        expect(result.level, ValidationLevel.warning);
      });
    });
  });

  group('validateReading', () {
    Reading createTestReading({
      required int systolic,
      required int diastolic,
      required int pulse,
    }) {
      return Reading(
        profileId: 1,
        systolic: systolic,
        diastolic: diastolic,
        pulse: pulse,
        takenAt: DateTime.now(),
        localOffsetMinutes: -300,
      );
    }

    test('validates normal reading as valid', () {
      final reading = createTestReading(systolic: 120, diastolic: 80, pulse: 70);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.valid);
    });

    test('returns error if blood pressure has error', () {
      final reading = createTestReading(systolic: 300, diastolic: 80, pulse: 70);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('Systolic'));
    });

    test('returns error if pulse has error', () {
      final reading = createTestReading(systolic: 120, diastolic: 80, pulse: 220);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('Pulse'));
    });

    test('returns error for blood pressure over pulse error', () {
      final reading = createTestReading(systolic: 80, diastolic: 120, pulse: 220);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.error);
      expect(result.message, contains('Systolic'));
    });

    test('returns warning if blood pressure has warning', () {
      final reading = createTestReading(systolic: 185, diastolic: 80, pulse: 70);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.warning);
      expect(result.message, contains('Systolic'));
    });

    test('returns warning if pulse has warning', () {
      final reading = createTestReading(systolic: 120, diastolic: 80, pulse: 150);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.warning);
      expect(result.message, contains('Pulse'));
    });

    test('combines warning messages when both BP and pulse warn', () {
      final reading = createTestReading(systolic: 185, diastolic: 80, pulse: 150);
      final result = validateReading(reading);
      expect(result.level, ValidationLevel.warning);
      expect(result.message, contains('Systolic'));
      expect(result.message, contains('Pulse'));
    });
  });

  group('ValidationResult equality', () {
    test('equal results are equal', () {
      const result1 = ValidationResult.valid();
      const result2 = ValidationResult.valid();
      expect(result1, equals(result2));
    });

    test('different levels are not equal', () {
      const result1 = ValidationResult.valid();
      const result2 = ValidationResult.warning('test');
      expect(result1, isNot(equals(result2)));
    });

    test('different messages are not equal', () {
      const result1 = ValidationResult.warning('message1');
      const result2 = ValidationResult.warning('message2');
      expect(result1, isNot(equals(result2)));
    });

    test('hashCode matches for equal results', () {
      const result1 = ValidationResult.valid();
      const result2 = ValidationResult.valid();
      expect(result1.hashCode, equals(result2.hashCode));
    });
  });

  group('legacy validators', () {
    test('isValidBloodPressure returns true for valid values', () {
      // ignore: deprecated_member_use_from_same_package
      expect(isValidBloodPressure(120, 80), true);
    });

    test('isValidBloodPressure returns false for invalid values', () {
      // ignore: deprecated_member_use_from_same_package
      expect(isValidBloodPressure(300, 80), false);
    });

    test('isValidPulse returns true for valid values', () {
      // ignore: deprecated_member_use_from_same_package
      expect(isValidPulse(70), true);
    });

    test('isValidPulse returns false for invalid values', () {
      // ignore: deprecated_member_use_from_same_package
      expect(isValidPulse(220), false);
    });
  });
}

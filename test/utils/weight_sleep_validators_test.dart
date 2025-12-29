import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateWeight', () {
    group('kg validation', () {
      test('returns error for zero weight', () {
        final result = validateWeight(0, 'kg');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('greater than zero'));
      });

      test('returns error for negative weight', () {
        final result = validateWeight(-5, 'kg');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('greater than zero'));
      });

      test('returns warning for weight below 25 kg', () {
        final result = validateWeight(24, 'kg');
        expect(result.level, equals(ValidationLevel.warning));
        expect(result.message, contains('unusually low'));
        expect(result.message, contains('25 kg'));
      });

      test('returns valid for 25 kg (lower bound)', () {
        final result = validateWeight(25, 'kg');
        expect(result.level, equals(ValidationLevel.valid));
      });

      test('returns valid for normal weight in kg', () {
        final result = validateWeight(70, 'kg');
        expect(result.level, equals(ValidationLevel.valid));
        expect(result.message, isNull);
      });

      test('returns valid for 310 kg (upper bound)', () {
        final result = validateWeight(310, 'kg');
        expect(result.level, equals(ValidationLevel.valid));
      });

      test('returns error for weight above 310 kg', () {
        final result = validateWeight(311, 'kg');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('310 kg'));
      });
    });

    group('lbs validation', () {
      test('returns error for zero weight', () {
        final result = validateWeight(0, 'lbs');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('greater than zero'));
      });

      test('returns warning for weight below 55 lbs', () {
        final result = validateWeight(54, 'lbs');
        expect(result.level, equals(ValidationLevel.warning));
        expect(result.message, contains('unusually low'));
        expect(result.message, contains('55 lbs'));
      });

      test('returns valid for 55 lbs (lower bound)', () {
        final result = validateWeight(55, 'lbs');
        expect(result.level, equals(ValidationLevel.valid));
      });

      test('returns valid for normal weight in lbs', () {
        final result = validateWeight(154, 'lbs');
        expect(result.level, equals(ValidationLevel.valid));
        expect(result.message, isNull);
      });

      test('returns valid for 670 lbs (upper bound)', () {
        final result = validateWeight(670, 'lbs');
        expect(result.level, equals(ValidationLevel.valid));
      });

      test('returns error for weight above 670 lbs', () {
        final result = validateWeight(671, 'lbs');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('670 lbs'));
      });
    });

    group('unit validation', () {
      test('returns error for invalid unit', () {
        final result = validateWeight(70, 'unknown');
        expect(result.level, equals(ValidationLevel.error));
        expect(result.message, contains('Invalid unit'));
      });

      test('handles case-insensitive kg', () {
        final result1 = validateWeight(70, 'KG');
        final result2 = validateWeight(70, 'Kg');
        expect(result1.level, equals(ValidationLevel.valid));
        expect(result2.level, equals(ValidationLevel.valid));
      });

      test('handles case-insensitive lbs', () {
        final result1 = validateWeight(154, 'LBS');
        final result2 = validateWeight(154, 'Lbs');
        expect(result1.level, equals(ValidationLevel.valid));
        expect(result2.level, equals(ValidationLevel.valid));
      });
    });
  });

  group('validateSleepDuration', () {
    test('returns warning for duration less than 60 minutes', () {
      final result = validateSleepDuration(59);
      expect(result.level, equals(ValidationLevel.warning));
      expect(result.message, contains('unusually short'));
      expect(result.message, contains('1 hour'));
    });

    test('returns valid for 60 minutes (lower bound)', () {
      final result = validateSleepDuration(60);
      expect(result.level, equals(ValidationLevel.valid));
    });

    test('returns valid for normal sleep duration', () {
      final result = validateSleepDuration(480); // 8 hours
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
    });

    test('returns valid for 1440 minutes (upper bound)', () {
      final result = validateSleepDuration(1440);
      expect(result.level, equals(ValidationLevel.valid));
    });

    test('returns error for duration greater than 1440 minutes', () {
      final result = validateSleepDuration(1441);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('24 hours'));
      expect(result.message, contains('1440'));
    });

    test('returns warning for very short nap', () {
      final result = validateSleepDuration(30);
      expect(result.level, equals(ValidationLevel.warning));
    });
  });

  group('validateSleepQuality', () {
    test('returns valid for null quality', () {
      final result = validateSleepQuality(null);
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
    });

    test('returns error for quality less than 1', () {
      final result = validateSleepQuality(0);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('between 1 and 5'));
    });

    test('returns valid for quality 1 (lower bound)', () {
      final result = validateSleepQuality(1);
      expect(result.level, equals(ValidationLevel.valid));
    });

    test('returns valid for quality 3 (middle)', () {
      final result = validateSleepQuality(3);
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
    });

    test('returns valid for quality 5 (upper bound)', () {
      final result = validateSleepQuality(5);
      expect(result.level, equals(ValidationLevel.valid));
    });

    test('returns error for quality greater than 5', () {
      final result = validateSleepQuality(6);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('between 1 and 5'));
    });

    test('returns error for negative quality', () {
      final result = validateSleepQuality(-1);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('between 1 and 5'));
    });
  });

  group('validateSleepTimes', () {
    final startTime = DateTime(2025, 12, 28, 22, 0);
    final endTime = DateTime(2025, 12, 29, 6, 0);

    test('returns valid when endedAt is null', () {
      final result = validateSleepTimes(startTime, null);
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
    });

    test('returns valid when endedAt is after startedAt', () {
      final result = validateSleepTimes(startTime, endTime);
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
    });

    test('returns error when endedAt equals startedAt', () {
      final result = validateSleepTimes(startTime, startTime);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('after start time'));
    });

    test('returns error when endedAt is before startedAt', () {
      final before = startTime.subtract(const Duration(hours: 1));
      final result = validateSleepTimes(startTime, before);
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, contains('after start time'));
    });

    test('handles multi-day sleep correctly', () {
      final nextDay = startTime.add(const Duration(hours: 10));
      final result = validateSleepTimes(startTime, nextDay);
      expect(result.level, equals(ValidationLevel.valid));
    });

    test('handles same day sleep correctly', () {
      final afternoon = DateTime(2025, 12, 28, 14, 0);
      final laterAfternoon = DateTime(2025, 12, 28, 16, 0);
      final result = validateSleepTimes(afternoon, laterAfternoon);
      expect(result.level, equals(ValidationLevel.valid));
    });
  });

  group('ValidationResult', () {
    test('valid result has correct properties', () {
      const result = ValidationResult.valid();
      expect(result.level, equals(ValidationLevel.valid));
      expect(result.message, isNull);
      expect(result.requiresConfirmation, isFalse);
    });

    test('warning result has correct properties', () {
      const result = ValidationResult.warning('Test warning');
      expect(result.level, equals(ValidationLevel.warning));
      expect(result.message, equals('Test warning'));
      expect(result.requiresConfirmation, isTrue);
    });

    test('error result has correct properties', () {
      const result = ValidationResult.error('Test error');
      expect(result.level, equals(ValidationLevel.error));
      expect(result.message, equals('Test error'));
      expect(result.requiresConfirmation, isFalse);
    });

    test('equality works correctly', () {
      const result1 = ValidationResult.valid();
      const result2 = ValidationResult.valid();
      const result3 = ValidationResult.warning('Test');

      expect(result1, equals(result2));
      expect(result1, isNot(equals(result3)));
    });

    test('hashCode is consistent', () {
      const result1 = ValidationResult.valid();
      const result2 = ValidationResult.valid();

      expect(result1.hashCode, equals(result2.hashCode));
    });
  });
}

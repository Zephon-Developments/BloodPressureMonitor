import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/unit_conversion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitConversion', () {
    group('weight conversions', () {
      group('kgToLbs', () {
        test('converts 0 kg correctly', () {
          expect(UnitConversion.kgToLbs(00), 0.0);
        });

        test('converts 1 kg correctly', () {
          expect(UnitConversion.kgToLbs(1), closeTo(2.20462, 0.00001));
        });

        test('converts 70 kg correctly', () {
          expect(UnitConversion.kgToLbs(70), closeTo(154.324, 0.001));
        });

        test('converts large values correctly', () {
          expect(UnitConversion.kgToLbs(200), closeTo(440.925, 0.001));
        });

        test('handles decimal values', () {
          expect(UnitConversion.kgToLbs(75.5), closeTo(166.449, 0.001));
        });
      });

      group('lbsToKg', () {
        test('converts 0 lbs correctly', () {
          expect(UnitConversion.lbsToKg(0), 0.0);
        });

        test('converts 1 lbs correctly', () {
          expect(UnitConversion.lbsToKg(1), closeTo(0.453592, 0.00001));
        });

        test('converts 154.32 lbs correctly', () {
          expect(UnitConversion.lbsToKg(154.32), closeTo(70.0, 0.01));
        });

        test('converts large values correctly', () {
          expect(UnitConversion.lbsToKg(440.925), closeTo(200.0, 0.01));
        });

        test('handles decimal values', () {
          expect(UnitConversion.lbsToKg(166.5), closeTo(75.523, 0.001));
        });
      });

      group('round-trip conversion symmetry', () {
        test('kg -> lbs -> kg preserves value', () {
          const original = 70.0;
          final lbs = UnitConversion.kgToLbs(original);
          final back = UnitConversion.lbsToKg(lbs);

          expect(back, closeTo(original, 0.00001));
        });

        test('lbs -> kg -> lbs preserves value', () {
          const original = 154.32;
          final kg = UnitConversion.lbsToKg(original);
          final back = UnitConversion.kgToLbs(kg);

          expect(back, closeTo(original, 0.00001));
        });

        test('handles edge case at 0', () {
          final lbs = UnitConversion.kgToLbs(0);
          final back = UnitConversion.lbsToKg(lbs);

          expect(back, 0.0);
        });
      });
    });

    group('temperature conversions', () {
      group('celsiusToFahrenheit', () {
        test('converts 0°C correctly', () {
          expect(UnitConversion.celsiusToFahrenheit(0), 32.0);
        });

        test('converts 37°C correctly (body temperature)', () {
          expect(UnitConversion.celsiusToFahrenheit(37), closeTo(98.6, 0.01));
        });

        test('converts 100°C correctly (boiling point)', () {
          expect(UnitConversion.celsiusToFahrenheit(100), 212.0);
        });

        test('converts negative temperatures correctly', () {
          expect(UnitConversion.celsiusToFahrenheit(-40), -40.0);
        });

        test('handles decimal values', () {
          expect(UnitConversion.celsiusToFahrenheit(36.5), closeTo(97.7, 0.01));
        });
      });

      group('fahrenheitToCelsius', () {
        test('converts 32°F correctly', () {
          expect(UnitConversion.fahrenheitToCelsius(32), 0.0);
        });

        test('converts 98.6°F correctly (body temperature)', () {
          expect(UnitConversion.fahrenheitToCelsius(98.6), closeTo(37.0, 0.01));
        });

        test('converts 212°F correctly (boiling point)', () {
          expect(UnitConversion.fahrenheitToCelsius(212), 100.0);
        });

        test('converts negative temperatures correctly', () {
          expect(UnitConversion.fahrenheitToCelsius(-40), -40.0);
        });

        test('handles decimal values', () {
          expect(UnitConversion.fahrenheitToCelsius(97.7), closeTo(36.5, 0.1));
        });
      });

      group('round-trip temperature conversion symmetry', () {
        test('C -> F -> C preserves value', () {
          const original = 37.0;
          final f = UnitConversion.celsiusToFahrenheit(original);
          final back = UnitConversion.fahrenheitToCelsius(f);

          expect(back, closeTo(original, 0.00001));
        });

        test('F -> C -> F preserves value', () {
          const original = 98.6;
          final c = UnitConversion.fahrenheitToCelsius(original);
          final back = UnitConversion.celsiusToFahrenheit(c);

          expect(back, closeTo(original, 0.00001));
        });
      });
    });

    group('formatWeight', () {
      test('formats kg with default precision', () {
        final result = UnitConversion.formatWeight(70.0, WeightUnit.kg);

        expect(result, '70.0 kg');
      });

      test('formats lbs with default precision', () {
        final result = UnitConversion.formatWeight(70.0, WeightUnit.lbs);

        expect(result, '154.3 lbs');
      });

      test('formats with custom fraction digits', () {
        final result = UnitConversion.formatWeight(
          70.123,
          WeightUnit.kg,
          fractionDigits: 2,
        );

        expect(result, '70.12 kg');
      });

      test('formats with 0 fraction digits', () {
        final result =
            UnitConversion.formatWeight(70.9, WeightUnit.kg, fractionDigits: 0);

        expect(result, '71 kg');
      });

      test('converts kg to lbs for display', () {
        final result = UnitConversion.formatWeight(70.0, WeightUnit.lbs);

        expect(result, contains('154.3'));
        expect(result, contains('lbs'));
      });

      test('handles zero weight', () {
        final result = UnitConversion.formatWeight(0.0, WeightUnit.kg);

        expect(result, '0.0 kg');
      });

      test('handles large values', () {
        final result = UnitConversion.formatWeight(200.0, WeightUnit.lbs);

        expect(result, '440.9 lbs');
      });
    });

    group('convertToKg', () {
      test('returns same value for kg input', () {
        expect(UnitConversion.convertToKg(70.0, WeightUnit.kg), 70.0);
      });

      test('converts lbs to kg', () {
        final result = UnitConversion.convertToKg(154.32, WeightUnit.lbs);

        expect(result, closeTo(70.0, 0.01));
      });

      test('handles zero', () {
        expect(UnitConversion.convertToKg(0.0, WeightUnit.kg), 0.0);
        expect(UnitConversion.convertToKg(0.0, WeightUnit.lbs), 0.0);
      });

      test('handles decimal values', () {
        final result = UnitConversion.convertToKg(165.5, WeightUnit.lbs);

        expect(result, closeTo(75.07, 0.01));
      });
    });

    group('convertFromKg', () {
      test('returns same value for kg output', () {
        expect(UnitConversion.convertFromKg(70.0, WeightUnit.kg), 70.0);
      });

      test('converts kg to lbs', () {
        final result = UnitConversion.convertFromKg(70.0, WeightUnit.lbs);

        expect(result, closeTo(154.32, 0.01));
      });

      test('handles zero', () {
        expect(UnitConversion.convertFromKg(0.0, WeightUnit.kg), 0.0);
        expect(UnitConversion.convertFromKg(0.0, WeightUnit.lbs), 0.0);
      });

      test('handles decimal values', () {
        final result = UnitConversion.convertFromKg(75.5, WeightUnit.lbs);

        expect(result, closeTo(166.45, 0.01));
      });
    });

    group('formatTemperature', () {
      test('formats Celsius with default precision', () {
        final result = UnitConversion.formatTemperature(
          37.0,
          TemperatureUnit.celsius,
        );

        expect(result, '37.0°C');
      });

      test('formats Fahrenheit with default precision', () {
        final result = UnitConversion.formatTemperature(
          37.0,
          TemperatureUnit.fahrenheit,
        );

        expect(result, '98.6°F');
      });

      test('formats with custom fraction digits', () {
        final result = UnitConversion.formatTemperature(
          36.789,
          TemperatureUnit.celsius,
          fractionDigits: 2,
        );

        expect(result, '36.79°C');
      });

      test('formats with 0 fraction digits', () {
        final result = UnitConversion.formatTemperature(
          36.9,
          TemperatureUnit.celsius,
          fractionDigits: 0,
        );

        expect(result, '37°C');
      });

      test('converts Celsius to Fahrenheit for display', () {
        final result = UnitConversion.formatTemperature(
          37.0,
          TemperatureUnit.fahrenheit,
        );

        expect(result, contains('98.6'));
        expect(result, contains('°F'));
      });
    });
  });
}

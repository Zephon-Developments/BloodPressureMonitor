import 'package:blood_pressure_monitor/models/units_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightUnit', () {
    test('has correct enum values', () {
      expect(WeightUnit.values, [WeightUnit.kg, WeightUnit.lbs]);
    });
  });

  group('TemperatureUnit', () {
    test('has correct enum values', () {
      expect(
        TemperatureUnit.values,
        [TemperatureUnit.celsius, TemperatureUnit.fahrenheit],
      );
    });
  });

  group('UnitsPreference', () {
    group('constructor', () {
      test('creates instance with default SI units when no parameters provided',
          () {
        const preference = UnitsPreference();

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('creates instance with specified units', () {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        expect(preference.weightUnit, WeightUnit.lbs);
        expect(preference.temperatureUnit, TemperatureUnit.fahrenheit);
      });
    });

    group('fromJson', () {
      test('parses valid JSON correctly', () {
        final json = {
          'weightUnit': 'kg',
          'temperatureUnit': 'celsius',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('parses lbs weight unit correctly', () {
        final json = {
          'weightUnit': 'lbs',
          'temperatureUnit': 'celsius',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.lbs);
      });

      test('parses fahrenheit temperature unit correctly', () {
        final json = {
          'weightUnit': 'kg',
          'temperatureUnit': 'fahrenheit',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.temperatureUnit, TemperatureUnit.fahrenheit);
      });

      test('handles case-insensitive unit strings', () {
        final json = {
          'weightUnit': 'KG',
          'temperatureUnit': 'CELSIUS',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('returns defaults for invalid weight unit', () {
        final json = {
          'weightUnit': 'invalid',
          'temperatureUnit': 'celsius',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
      });

      test('returns defaults for invalid temperature unit', () {
        final json = {
          'weightUnit': 'kg',
          'temperatureUnit': 'invalid',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('returns defaults for missing fields', () {
        final json = <String, dynamic>{};

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('returns defaults for null values', () {
        final json = {
          'weightUnit': null,
          'temperatureUnit': null,
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });

      test('returns defaults for corrupt JSON', () {
        final json = {
          'wrongKey': 'wrongValue',
        };

        final preference = UnitsPreference.fromJson(json);

        expect(preference.weightUnit, WeightUnit.kg);
        expect(preference.temperatureUnit, TemperatureUnit.celsius);
      });
    });

    group('toJson', () {
      test('serializes kg and celsius correctly', () {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        final json = preference.toJson();

        expect(json, {
          'weightUnit': 'kg',
          'temperatureUnit': 'celsius',
        });
      });

      test('serializes lbs and fahrenheit correctly', () {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        final json = preference.toJson();

        expect(json, {
          'weightUnit': 'lbs',
          'temperatureUnit': 'fahrenheit',
        });
      });
    });

    group('round-trip JSON serialization', () {
      test('preserves kg and celsius', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        final json = original.toJson();
        final restored = UnitsPreference.fromJson(json);

        expect(restored, original);
      });

      test('preserves lbs and fahrenheit', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        final json = original.toJson();
        final restored = UnitsPreference.fromJson(json);

        expect(restored, original);
      });
    });

    group('copyWith', () {
      test('creates copy with updated weight unit', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        final copy = original.copyWith(weightUnit: WeightUnit.lbs);

        expect(copy.weightUnit, WeightUnit.lbs);
        expect(copy.temperatureUnit, TemperatureUnit.celsius);
      });

      test('creates copy with updated temperature unit', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        final copy = original.copyWith(
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        expect(copy.weightUnit, WeightUnit.kg);
        expect(copy.temperatureUnit, TemperatureUnit.fahrenheit);
      });

      test('creates copy with both units updated', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        final copy = original.copyWith(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        expect(copy.weightUnit, WeightUnit.lbs);
        expect(copy.temperatureUnit, TemperatureUnit.fahrenheit);
      });

      test('preserves original when no parameters provided', () {
        const original = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        final copy = original.copyWith();

        expect(copy, original);
      });
    });

    group('equality', () {
      test('identical instances are equal', () {
        const pref1 = UnitsPreference();
        const pref2 = UnitsPreference();

        expect(pref1, pref2);
        expect(pref1.hashCode, pref2.hashCode);
      });

      test('instances with same values are equal', () {
        const pref1 = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );
        const pref2 = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        expect(pref1, pref2);
        expect(pref1.hashCode, pref2.hashCode);
      });

      test('instances with different weight units are not equal', () {
        const pref1 = UnitsPreference(weightUnit: WeightUnit.kg);
        const pref2 = UnitsPreference(weightUnit: WeightUnit.lbs);

        expect(pref1, isNot(pref2));
      });

      test('instances with different temperature units are not equal', () {
        const pref1 = UnitsPreference(temperatureUnit: TemperatureUnit.celsius);
        const pref2 =
            UnitsPreference(temperatureUnit: TemperatureUnit.fahrenheit);

        expect(pref1, isNot(pref2));
      });
    });

    group('toString', () {
      test('formats kg and celsius correctly', () {
        const preference = UnitsPreference();

        expect(
          preference.toString(),
          'UnitsPreference(weight: kg, temp: celsius)',
        );
      });

      test('formats lbs and fahrenheit correctly', () {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        expect(
          preference.toString(),
          'UnitsPreference(weight: lbs, temp: fahrenheit)',
        );
      });
    });
  });
}

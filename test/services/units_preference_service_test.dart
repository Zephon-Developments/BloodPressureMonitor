import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/units_preference.dart';
import 'package:blood_pressure_monitor/services/units_preference_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('UnitsPreferenceService', () {
    late SharedPreferences prefs;
    late UnitsPreferenceService service;

    setUp(() async {
      // Reset SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      service = UnitsPreferenceService(prefs);
    });

    group('getUnitsPreference', () {
      test('returns default preferences when no saved data exists', () async {
        final result = await service.getUnitsPreference();

        expect(result.weightUnit, WeightUnit.kg);
        expect(result.temperatureUnit, TemperatureUnit.celsius);
      });

      test('retrieves saved preferences correctly', () async {
        // Save preference
        await service.saveUnitsPreference(
          const UnitsPreference(
            weightUnit: WeightUnit.lbs,
            temperatureUnit: TemperatureUnit.fahrenheit,
          ),
        );

        // Retrieve it
        final result = await service.getUnitsPreference();

        expect(result.weightUnit, WeightUnit.lbs);
        expect(result.temperatureUnit, TemperatureUnit.fahrenheit);
      });

      test('returns defaults when saved data is corrupted', () async {
        // Manually set corrupted data
        await prefs.setString('units_preference', 'invalid json');

        final result = await service.getUnitsPreference();

        expect(result.weightUnit, WeightUnit.kg);
        expect(result.temperatureUnit, TemperatureUnit.celsius);
      });

      test('returns defaults when JSON structure is invalid', () async {
        // Set invalid JSON structure
        await prefs.setString('units_preference', '{"wrong": "structure"}');

        final result = await service.getUnitsPreference();

        expect(result.weightUnit, WeightUnit.kg);
        expect(result.temperatureUnit, TemperatureUnit.celsius);
      });

      test('handles missing fields gracefully', () async {
        // Set incomplete JSON
        await prefs.setString('units_preference', '{"weightUnit": "lbs"}');

        final result = await service.getUnitsPreference();

        expect(result.weightUnit, WeightUnit.lbs);
        expect(
          result.temperatureUnit,
          TemperatureUnit.celsius,
        ); // Default for missing field
      });
    });

    group('saveUnitsPreference', () {
      test('saves preference successfully', () async {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        await service.saveUnitsPreference(preference);

        // Verify it was saved
        final retrieved = await service.getUnitsPreference();
        expect(retrieved, preference);
      });

      test('overwrites existing preference', () async {
        // Save initial preference
        await service.saveUnitsPreference(
          const UnitsPreference(weightUnit: WeightUnit.kg),
        );

        // Overwrite with new preference
        const newPreference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );
        await service.saveUnitsPreference(newPreference);

        // Verify the new preference is saved
        final retrieved = await service.getUnitsPreference();
        expect(retrieved, newPreference);
      });

      test('saves kg and celsius correctly', () async {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.kg,
          temperatureUnit: TemperatureUnit.celsius,
        );

        await service.saveUnitsPreference(preference);

        final retrieved = await service.getUnitsPreference();
        expect(retrieved.weightUnit, WeightUnit.kg);
        expect(retrieved.temperatureUnit, TemperatureUnit.celsius);
      });

      test('saves lbs and fahrenheit correctly', () async {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        await service.saveUnitsPreference(preference);

        final retrieved = await service.getUnitsPreference();
        expect(retrieved.weightUnit, WeightUnit.lbs);
        expect(retrieved.temperatureUnit, TemperatureUnit.fahrenheit);
      });
    });

    group('clearUnitsPreference', () {
      test('removes saved preference', () async {
        // Save a preference
        await service.saveUnitsPreference(
          const UnitsPreference(weightUnit: WeightUnit.lbs),
        );

        // Verify it exists
        var retrieved = await service.getUnitsPreference();
        expect(retrieved.weightUnit, WeightUnit.lbs);

        // Clear it
        await service.clearUnitsPreference();

        // Verify defaults are returned
        retrieved = await service.getUnitsPreference();
        expect(retrieved.weightUnit, WeightUnit.kg);
        expect(retrieved.temperatureUnit, TemperatureUnit.celsius);
      });

      test('is idempotent (safe to call multiple times)', () async {
        await service.clearUnitsPreference();
        await service.clearUnitsPreference();

        final result = await service.getUnitsPreference();
        expect(result.weightUnit, WeightUnit.kg);
      });

      test('succeeds even when no preference exists', () async {
        // Clear without saving first
        await service.clearUnitsPreference();

        final result = await service.getUnitsPreference();
        expect(result.weightUnit, WeightUnit.kg);
      });
    });

    group('persistence across service instances', () {
      test('preference survives service recreation', () async {
        const preference = UnitsPreference(
          weightUnit: WeightUnit.lbs,
          temperatureUnit: TemperatureUnit.fahrenheit,
        );

        await service.saveUnitsPreference(preference);

        // Create new service instance
        final newService = UnitsPreferenceService(prefs);
        final retrieved = await newService.getUnitsPreference();

        expect(retrieved, preference);
      });
    });

    group('edge cases', () {
      test('handles rapid sequential saves', () async {
        await service.saveUnitsPreference(
          const UnitsPreference(weightUnit: WeightUnit.kg),
        );
        await service.saveUnitsPreference(
          const UnitsPreference(weightUnit: WeightUnit.lbs),
        );
        await service.saveUnitsPreference(
          const UnitsPreference(
            weightUnit: WeightUnit.kg,
            temperatureUnit: TemperatureUnit.fahrenheit,
          ),
        );

        final result = await service.getUnitsPreference();
        expect(result.weightUnit, WeightUnit.kg);
        expect(result.temperatureUnit, TemperatureUnit.fahrenheit);
      });

      test('handles save and immediate retrieve', () async {
        const preference = UnitsPreference(weightUnit: WeightUnit.lbs);

        await service.saveUnitsPreference(preference);
        final result = await service.getUnitsPreference();

        expect(result, preference);
      });
    });
  });
}

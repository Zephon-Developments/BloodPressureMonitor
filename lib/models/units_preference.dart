import 'package:blood_pressure_monitor/models/health_data.dart';

/// User preferences for display units throughout the application.
///
/// All data is stored internally in SI units (kg, °C), and these preferences
/// control only how values are displayed to the user.
class UnitsPreference {
  /// Preferred weight unit for display.
  final WeightUnit weightUnit;

  /// Preferred temperature unit for display.
  final TemperatureUnit temperatureUnit;

  /// Creates a [UnitsPreference] with the specified units.
  ///
  /// Defaults to SI units (kg, Celsius) if not specified.
  const UnitsPreference({
    this.weightUnit = WeightUnit.kg,
    this.temperatureUnit = TemperatureUnit.celsius,
  });

  /// Creates a [UnitsPreference] from a JSON map.
  ///
  /// Returns default preferences if the map is invalid or missing fields.
  factory UnitsPreference.fromJson(Map<String, dynamic> json) {
    try {
      return UnitsPreference(
        weightUnit: _parseWeightUnit(json['weightUnit'] as String?),
        temperatureUnit:
            _parseTemperatureUnit(json['temperatureUnit'] as String?),
      );
    } catch (e) {
      // Return defaults if parsing fails
      return const UnitsPreference();
    }
  }

  /// Converts this [UnitsPreference] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'weightUnit': _weightUnitToString(weightUnit),
      'temperatureUnit': _temperatureUnitToString(temperatureUnit),
    };
  }

  /// Creates a copy of this preference with the given fields replaced.
  UnitsPreference copyWith({
    WeightUnit? weightUnit,
    TemperatureUnit? temperatureUnit,
  }) {
    return UnitsPreference(
      weightUnit: weightUnit ?? this.weightUnit,
      temperatureUnit: temperatureUnit ?? this.temperatureUnit,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UnitsPreference &&
        other.weightUnit == weightUnit &&
        other.temperatureUnit == temperatureUnit;
  }

  @override
  int get hashCode => Object.hash(weightUnit, temperatureUnit);

  @override
  String toString() {
    return 'UnitsPreference(weight: ${_weightUnitToString(weightUnit)}, temp: ${_temperatureUnitToString(temperatureUnit)})';
  }

  // Helper methods for serialization

  static WeightUnit _parseWeightUnit(String? value) {
    switch (value?.toLowerCase()) {
      case 'kg':
        return WeightUnit.kg;
      case 'lbs':
        return WeightUnit.lbs;
      default:
        return WeightUnit.kg; // Default to SI
    }
  }

  static TemperatureUnit _parseTemperatureUnit(String? value) {
    switch (value?.toLowerCase()) {
      case 'celsius':
        return TemperatureUnit.celsius;
      case 'fahrenheit':
        return TemperatureUnit.fahrenheit;
      default:
        return TemperatureUnit.celsius; // Default to SI
    }
  }

  static String _weightUnitToString(WeightUnit unit) {
    switch (unit) {
      case WeightUnit.kg:
        return 'kg';
      case WeightUnit.lbs:
        return 'lbs';
    }
  }

  static String _temperatureUnitToString(TemperatureUnit unit) {
    switch (unit) {
      case TemperatureUnit.celsius:
        return 'celsius';
      case TemperatureUnit.fahrenheit:
        return 'fahrenheit';
    }
  }
}

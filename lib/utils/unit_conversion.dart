import 'package:blood_pressure_monitor/models/health_data.dart';

/// Utilities for converting between different units of measurement.
///
/// All conversions maintain precision suitable for health tracking.
class UnitConversion {
  /// Conversion factor from kg to lbs.
  static const double kgToLbsFactor = 2.20462262185;

  /// Conversion factor from lbs to kg.
  static const double lbsToKgFactor = 0.45359237;

  /// Converts weight from kilograms to pounds.
  ///
  /// Example:
  /// ```dart
  /// final lbs = UnitConversion.kgToLbs(70.0); // 154.32 lbs
  /// ```
  static double kgToLbs(double kg) {
    return kg * kgToLbsFactor;
  }

  /// Converts weight from pounds to kilograms.
  ///
  /// Example:
  /// ```dart
  /// final kg = UnitConversion.lbsToKg(154.32); // 70.0 kg
  /// ```
  static double lbsToKg(double lbs) {
    return lbs * lbsToKgFactor;
  }

  /// Converts temperature from Celsius to Fahrenheit.
  ///
  /// Formula: °F = (°C × 9/5) + 32
  ///
  /// Example:
  /// ```dart
  /// final f = UnitConversion.celsiusToFahrenheit(37.0); // 98.6°F
  /// ```
  static double celsiusToFahrenheit(double celsius) {
    return (celsius * 9.0 / 5.0) + 32.0;
  }

  /// Converts temperature from Fahrenheit to Celsius.
  ///
  /// Formula: °C = (°F - 32) × 5/9
  ///
  /// Example:
  /// ```dart
  /// final c = UnitConversion.fahrenheitToCelsius(98.6); // 37.0°C
  /// ```
  static double fahrenheitToCelsius(double fahrenheit) {
    return (fahrenheit - 32.0) * 5.0 / 9.0;
  }

  /// Formats a weight value for display, converting from kg to the preferred unit.
  ///
  /// The input [valueKg] is always in kilograms (SI storage format).
  /// Output is formatted according to the [unit] preference.
  ///
  /// Parameters:
  /// - [valueKg]: Weight value in kilograms
  /// - [unit]: Target display unit
  /// - [fractionDigits]: Number of decimal places (default: 1)
  ///
  /// Returns formatted string with unit abbreviation.
  ///
  /// Example:
  /// ```dart
  /// formatWeight(70.0, WeightUnit.kg); // "70.0 kg"
  /// formatWeight(70.0, WeightUnit.lbs); // "154.3 lbs"
  /// ```
  static String formatWeight(
    double valueKg,
    WeightUnit unit, {
    int fractionDigits = 1,
  }) {
    final displayValue = unit == WeightUnit.kg ? valueKg : kgToLbs(valueKg);
    final unitStr = unit == WeightUnit.kg ? 'kg' : 'lbs';
    return '${displayValue.toStringAsFixed(fractionDigits)} $unitStr';
  }

  /// Converts a weight value from the display unit to kilograms for storage.
  ///
  /// Parameters:
  /// - [value]: Weight value in the specified unit
  /// - [unit]: The unit of the input value
  ///
  /// Returns weight in kilograms for SI storage.
  ///
  /// Example:
  /// ```dart
  /// convertToKg(154.3, WeightUnit.lbs); // 70.0 kg
  /// convertToKg(70.0, WeightUnit.kg); // 70.0 kg
  /// ```
  static double convertToKg(double value, WeightUnit unit) {
    return unit == WeightUnit.kg ? value : lbsToKg(value);
  }

  /// Converts a weight value from kilograms to the specified display unit.
  ///
  /// Parameters:
  /// - [valueKg]: Weight value in kilograms
  /// - [unit]: Target display unit
  ///
  /// Returns weight in the specified unit.
  ///
  /// Example:
  /// ```dart
  /// convertFromKg(70.0, WeightUnit.lbs); // 154.32 lbs
  /// convertFromKg(70.0, WeightUnit.kg); // 70.0 kg
  /// ```
  static double convertFromKg(double valueKg, WeightUnit unit) {
    return unit == WeightUnit.kg ? valueKg : kgToLbs(valueKg);
  }

  /// Formats a temperature value for display.
  ///
  /// Parameters:
  /// - [valueCelsius]: Temperature in Celsius (SI storage format)
  /// - [unit]: Target display unit
  /// - [fractionDigits]: Number of decimal places (default: 1)
  ///
  /// Returns formatted string with unit symbol.
  ///
  /// Example:
  /// ```dart
  /// formatTemperature(37.0, TemperatureUnit.celsius); // "37.0°C"
  /// formatTemperature(37.0, TemperatureUnit.fahrenheit); // "98.6°F"
  /// ```
  static String formatTemperature(
    double valueCelsius,
    TemperatureUnit unit, {
    int fractionDigits = 1,
  }) {
    final displayValue = unit == TemperatureUnit.celsius
        ? valueCelsius
        : celsiusToFahrenheit(valueCelsius);
    final unitStr = unit == TemperatureUnit.celsius ? '°C' : '°F';
    return '${displayValue.toStringAsFixed(fractionDigits)}$unitStr';
  }
}

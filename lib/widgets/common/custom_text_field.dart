import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A reusable text field with built-in validation display.
///
/// Handles numeric input, error/helper text, and accessibility labels.
/// Designed for consistent form UX across the application.
class CustomTextField extends StatelessWidget {
  /// Creates a custom text field.
  const CustomTextField({
    required this.label,
    this.controller,
    this.helperText,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.onChanged,
    this.validator,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    super.key,
  });

  /// The field label.
  final String label;

  /// Optional controller for the text field.
  final TextEditingController? controller;

  /// Optional helper text displayed below the field.
  final String? helperText;

  /// Optional error text (replaces helper when set).
  final String? errorText;

  /// Keyboard type (e.g., number, text).
  final TextInputType? keyboardType;

  /// Input formatters (e.g., numeric only).
  final List<TextInputFormatter>? inputFormatters;

  /// Callback when text changes.
  final ValueChanged<String>? onChanged;

  /// Validator function for form validation.
  final String? Function(String?)? validator;

  /// Whether the field is enabled.
  final bool enabled;

  /// Maximum lines for the text field.
  final int? maxLines;

  /// Minimum lines for the text field.
  final int? minLines;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        errorText: errorText,
        border: const OutlineInputBorder(),
        filled: true,
        fillColor: enabled
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).disabledColor.withValues(alpha: 0.1),
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      onChanged: onChanged,
      validator: validator,
      enabled: enabled,
      maxLines: maxLines,
      minLines: minLines,
    );
  }
}

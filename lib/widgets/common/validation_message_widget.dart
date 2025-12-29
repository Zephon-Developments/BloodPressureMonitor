import 'package:flutter/material.dart';

/// Displays validation messages (warnings or errors) in a consistent banner.
///
/// Used to provide clear feedback about validation state in forms.
class ValidationMessageWidget extends StatelessWidget {
  /// Creates a validation message widget.
  const ValidationMessageWidget({
    required this.message,
    this.isError = false,
    super.key,
  });

  /// The message to display.
  final String message;

  /// Whether this is an error (true) or warning (false).
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = isError
        ? colorScheme.errorContainer
        : const Color(0xFFFFF3E0); // Amber 50
    final textColor = isError
        ? colorScheme.onErrorContainer
        : const Color(0xFFE65100); // Amber 900
    final icon = isError ? Icons.error_outline : Icons.warning_amber;

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: textColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: textColor,
            size: 20,
            semanticLabel: isError ? 'Error' : 'Warning',
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

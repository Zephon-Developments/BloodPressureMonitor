import 'package:flutter/material.dart';

/// A button widget that handles loading states.
///
/// Displays a loading indicator when busy and disables interaction.
/// Ensures consistent UX for async operations across the app.
class LoadingButton extends StatelessWidget {
  /// Creates a loading button.
  const LoadingButton({
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.style,
    super.key,
  });

  /// Callback when button is pressed. Ignored when loading.
  final VoidCallback? onPressed;

  /// The button's label (usually Text widget).
  final Widget child;

  /// Whether the button is currently in loading state.
  final bool isLoading;

  /// Button style (passed through to ElevatedButton).
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            )
          : child,
    );
  }
}

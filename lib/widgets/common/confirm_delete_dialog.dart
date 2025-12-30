import 'package:flutter/material.dart';

/// Dialog that confirms a destructive delete action.
///
/// Provides consistent styling with a destructive-filled button and
/// returns `true` when the user confirms deletion.
class ConfirmDeleteDialog extends StatelessWidget {
  /// Creates a confirmation dialog for delete actions.
  const ConfirmDeleteDialog({
    required this.title,
    required this.message,
    this.confirmLabel = 'Delete',
    this.cancelLabel = 'Cancel',
    super.key,
  });

  /// Title displayed at the top of the dialog.
  final String title;

  /// Supporting message describing what will be deleted.
  final String message;

  /// Label for the destructive confirmation button.
  final String confirmLabel;

  /// Label for the cancel button.
  final String cancelLabel;

  /// Shows the dialog and resolves to `true` only when confirmed.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Delete',
    String cancelLabel = 'Cancel',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    const destructiveHint =
        'Deletes the selected item immediately and cannot be undone';

    return Semantics(
      container: true,
      namesRoute: true,
      label: '$title confirmation dialog',
      hint: 'Review the message and choose confirm or cancel to proceed',
      child: AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          Semantics(
            button: true,
            label: 'Cancel deletion',
            hint: 'Dismiss the dialog without deleting',
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelLabel),
            ),
          ),
          Semantics(
            button: true,
            label: 'Confirm delete',
            hint: destructiveHint,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colorScheme.error,
                foregroundColor: colorScheme.onError,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmLabel.toUpperCase()),
            ),
          ),
        ],
      ),
    );
  }
}

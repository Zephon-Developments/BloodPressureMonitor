import 'package:flutter/material.dart';

/// Widget for controlling averaging session behavior.
///
/// Allows user to force a new averaging session to start,
/// overriding the default 30-minute window grouping.
class SessionControlWidget extends StatelessWidget {
  /// Creates a session control widget.
  const SessionControlWidget({
    required this.startNewSession,
    required this.onChanged,
    super.key,
  });

  /// Whether to start a new session.
  final bool startNewSession;

  /// Callback when the toggle changes.
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Session',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Force a new averaging group (overrides 30-min window)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: startNewSession,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

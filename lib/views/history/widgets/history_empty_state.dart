import 'package:flutter/material.dart';

/// Friendly empty-state displayed when no history exists.
class HistoryEmptyState extends StatelessWidget {
  const HistoryEmptyState({super.key, required this.onAddReading});

  final VoidCallback onAddReading;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history,
              size: 72,
              color: Theme.of(context).colorScheme.primary.withValues(
                    alpha: 0.5,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'No history yet',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add a blood pressure reading to start building your history.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onAddReading,
              icon: const Icon(Icons.add),
              label: const Text('Add Reading'),
            ),
          ],
        ),
      ),
    );
  }
}

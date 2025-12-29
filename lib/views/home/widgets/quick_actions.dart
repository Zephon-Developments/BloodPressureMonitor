import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';

/// Quick action buttons for the home screen.
///
/// Provides primary action (Add Reading) and secondary actions
/// for quick navigation.
class QuickActions extends StatelessWidget {
  /// Creates a quick actions widget.
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => const AddReadingView(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Blood Pressure Reading'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

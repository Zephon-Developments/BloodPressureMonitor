import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/views/history/history_view.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/views/sleep/sleep_history_view.dart';
import 'package:blood_pressure_monitor/views/weight/weight_history_view.dart';
import 'package:blood_pressure_monitor/views/medication/log_intake_sheet.dart';
import 'package:blood_pressure_monitor/widgets/medication/medication_picker_dialog.dart';

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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showMedicationPicker(context);
              if (selected != null && context.mounted) {
                if (selected is MedicationGroup) {
                  showLogGroupIntakeSheet(context, selected);
                } else if (selected is Medication) {
                  showLogIntakeSheet(context, selected);
                }
              }
            },
            icon: const Icon(Icons.medication),
            label: const Text('Log Medication Intake'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const HistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: const Text('View Blood Pressure History'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const WeightHistoryView(),
                ),
              );
            },
            icon: const Icon(Icons.monitor_weight),
            label: const Text('View Weight History'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => const SleepHistoryView(),
                ),
              );
            },
            icon: const Icon(Icons.bedtime),
            label: const Text('View Sleep History'),
            style: OutlinedButton.styleFrom(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

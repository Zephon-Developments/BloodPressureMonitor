import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/utils/responsive_utils.dart';
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = ResponsiveUtils.columnsFor(context, maxColumns: 2);
          const spacing = 12.0;
          final availableWidth = constraints.maxWidth;
          final buttonWidth = columns == 1
              ? availableWidth
              : (availableWidth - spacing) / columns;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: availableWidth,
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
              Wrap(
                spacing: spacing,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: buttonWidth,
                    child: _SecondaryActionButton(
                      icon: Icons.medication,
                      label: 'Log Medication Intake',
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
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _SecondaryActionButton(
                      icon: Icons.history,
                      label: 'View Blood Pressure History',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const HistoryScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _SecondaryActionButton(
                      icon: Icons.monitor_weight,
                      label: 'View Weight History',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const WeightHistoryView(),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(
                    width: buttonWidth,
                    child: _SecondaryActionButton(
                      icon: Icons.bedtime,
                      label: 'View Sleep History',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (context) => const SleepHistoryView(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 20,
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/views/weight/add_weight_view.dart';
import 'package:blood_pressure_monitor/views/sleep/add_sleep_view.dart';
import 'package:blood_pressure_monitor/views/medication/log_intake_sheet.dart';
import 'package:blood_pressure_monitor/widgets/medication/medication_picker_dialog.dart';

/// The primary landing page after profile selection.
///
/// Displays large, friendly buttons for the most common logging actions:
/// Blood Pressure, Medication, Sleep, and Weight.
class ProfileHomepageView extends StatelessWidget {
  const ProfileHomepageView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<ActiveProfileViewModel>(
      builder: (context, viewModel, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Active Profile: ${viewModel.activeProfileName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'What would you like to log?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Grid of large buttons
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 1.1,
                children: [
                  _LargeActionButton(
                    icon: Icons.favorite,
                    label: 'Log Blood Pressure / Pulse',
                    color: colorScheme.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddReadingView()),
                    ),
                  ),
                  _LargeActionButton(
                    icon: Icons.medication,
                    label: 'Log Medication',
                    color: colorScheme.secondary,
                    onTap: () async {
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
                  _LargeActionButton(
                    icon: Icons.bedtime,
                    label: 'Log Sleep',
                    color: Colors.indigo,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddSleepView()),
                    ),
                  ),
                  _LargeActionButton(
                    icon: Icons.monitor_weight,
                    label: 'Log Weight',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddWeightView()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LargeActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LargeActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

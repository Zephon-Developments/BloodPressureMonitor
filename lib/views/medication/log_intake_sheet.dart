import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_intake_viewmodel.dart';

/// Bottom sheet for logging medication intake.
///
/// Supports single medication intake with optional scheduled time.
class LogIntakeSheet extends StatefulWidget {
  final Medication medication;

  const LogIntakeSheet({super.key, required this.medication});

  @override
  State<LogIntakeSheet> createState() => _LogIntakeSheetState();
}

class _LogIntakeSheetState extends State<LogIntakeSheet> {
  DateTime _takenAt = DateTime.now();
  DateTime? _scheduledFor;
  final _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log Intake: ${widget.medication.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Taken At'),
            subtitle: Text(
              _takenAt.toLocal().toString().split('.')[0],
            ),
            onTap: _selectTakenAt,
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Scheduled For (Optional)'),
            subtitle: Text(
              _scheduledFor != null
                  ? _scheduledFor!.toLocal().toString().split('.')[0]
                  : 'Not scheduled',
            ),
            trailing: _scheduledFor != null
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _scheduledFor = null;
                      });
                    },
                  )
                : null,
            onTap: _selectScheduledFor,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (Optional)',
              hintText: 'Add a note about this intake',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          if (_isSaving)
            const Center(child: CircularProgressIndicator())
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _logIntake,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Log Intake'),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Future<void> _selectTakenAt() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_takenAt),
      );

      if (time != null && mounted) {
        setState(() {
          _takenAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _selectScheduledFor() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledFor ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: _scheduledFor != null
            ? TimeOfDay.fromDateTime(_scheduledFor!)
            : TimeOfDay.now(),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledFor = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _logIntake() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final intakeViewModel = context.read<MedicationIntakeViewModel>();

      final intake = MedicationIntake(
        medicationId: widget.medication.id!,
        profileId: widget.medication.profileId,
        takenAt: _takenAt,
        scheduledFor: _scheduledFor,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
      );

      await intakeViewModel.logIntake(intake);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Intake logged successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

/// Displays a button to show the intake logging sheet.
void showLogIntakeSheet(BuildContext context, Medication medication) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => LogIntakeSheet(medication: medication),
  );
}

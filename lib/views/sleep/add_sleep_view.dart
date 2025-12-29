import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';
import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';
import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

/// Screen for manually logging a sleep session.
class AddSleepView extends StatefulWidget {
  /// Creates an [AddSleepView].
  const AddSleepView({super.key});

  @override
  State<AddSleepView> createState() => _AddSleepViewState();
}

class _AddSleepViewState extends State<AddSleepView> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  DateTime _sleepDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 6, minute: 30);
  int? _quality;
  bool _submitted = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SleepViewModel>();
    final durationMinutes = _calculatedDurationMinutes();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Sleep Session'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (viewModel.error != null)
                ValidationMessageWidget(
                  message: viewModel.error!,
                  isError: true,
                ),
              const SizedBox(height: 12),
              _buildPickerTile(
                icon: Icons.calendar_today,
                title: 'Night of ${DateFormats.longDate.format(_sleepDate)}',
                subtitle: 'Tap to change date',
                onTap: _pickDate,
              ),
              const SizedBox(height: 12),
              _buildPickerTile(
                icon: Icons.bedtime,
                title: 'Bedtime: ${_startTime.format(context)}',
                subtitle: 'Tap to change start time',
                onTap: () => _pickTime(isStart: true),
              ),
              const SizedBox(height: 12),
              _buildPickerTile(
                icon: Icons.wb_sunny,
                title: 'Wake time: ${_endTime.format(context)}',
                subtitle: 'Tap to change wake time',
                onTap: () => _pickTime(isStart: false),
              ),
              const SizedBox(height: 12),
              if (durationMinutes != null)
                Text(
                  'Duration: ${durationMinutes ~/ 60}h ${durationMinutes % 60}m',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Sleep Quality (1-5)',
                  border: OutlineInputBorder(),
                ),
                initialValue: _quality,
                items: List<DropdownMenuItem<int>>.generate(5, (index) {
                  final value = index + 1;
                  return DropdownMenuItem<int>(
                    value: value,
                    child: Text('$value - ${_qualityLabel(value)}'),
                  );
                }),
                onChanged: (value) => setState(() => _quality = value),
                hint: const Text('Optional'),
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Notes',
                controller: _notesController,
                maxLines: 4,
                helperText: 'Optional context (up to 500 characters)',
                validator: (value) {
                  if (value != null && value.length > 500) {
                    return 'Notes cannot exceed 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              LoadingButton(
                onPressed: viewModel.isSubmitting ? null : _submit,
                isLoading: viewModel.isSubmitting,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Save Sleep Session'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.edit),
    );
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _sleepDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (!mounted || date == null) {
      return;
    }

    setState(() {
      _sleepDate = DateTime(date.year, date.month, date.day);
    });
  }

  Future<void> _pickTime({required bool isStart}) async {
    final initial = isStart ? _startTime : _endTime;
    final time = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (!mounted || time == null) {
      return;
    }

    setState(() {
      if (isStart) {
        _startTime = time;
      } else {
        _endTime = time;
      }
    });
  }

  int? _calculatedDurationMinutes() {
    final start = _combine(_sleepDate, _startTime);
    var end = _combine(_sleepDate, _endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }
    final minutes = end.difference(start).inMinutes;
    return minutes > 0 ? minutes : null;
  }

  String _qualityLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Poor';
      case 2:
        return 'Poor';
      case 3:
        return 'Fair';
      case 4:
        return 'Good';
      case 5:
        return 'Excellent';
      default:
        return 'Unknown';
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final start = _combine(_sleepDate, _startTime);
    var end = _combine(_sleepDate, _endTime);
    if (!end.isAfter(start)) {
      end = end.add(const Duration(days: 1));
    }

    final duration = end.difference(start).inMinutes;
    if (duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sleep duration must be greater than 0')),
      );
      return;
    }

    final viewModel = context.read<SleepViewModel>();
    final error = await viewModel.saveSleepEntry(
      start: start,
      end: end,
      quality: _quality,
      notes: _notesController.text,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sleep session saved'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

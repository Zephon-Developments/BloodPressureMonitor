import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/utils/responsive_utils.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';
import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';
import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

/// Screen for manually logging a sleep session.
class AddSleepView extends StatefulWidget {
  /// Creates an [AddSleepView].
  const AddSleepView({super.key, this.editingEntry});

  /// Entry being edited when not null.
  final SleepEntry? editingEntry;

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
  bool _isDetailedMode = false;
  int _deepMinutes = 0;
  int _lightMinutes = 0;
  int _remMinutes = 0;
  int _awakeMinutes = 0;

  bool get _isEditing => widget.editingEntry != null;

  /// Check if form has unsaved changes.
  bool get _isDirty {
    final editing = widget.editingEntry;
    if (editing == null) {
      // New entry - always dirty if user has selected times/quality/notes
      return _notesController.text.isNotEmpty || _quality != null;
    } else {
      // Editing - dirty if any field differs from original
      final originalStarted = editing.startedAt.toLocal();
      final originalEnded = (editing.endedAt ?? editing.startedAt).toLocal();
      final originalDate = DateTime(
        originalStarted.year,
        originalStarted.month,
        originalStarted.day,
      );
      final originalStartTime = TimeOfDay.fromDateTime(originalStarted);
      final originalEndTime = TimeOfDay.fromDateTime(originalEnded);

      return originalDate != _sleepDate ||
          originalStartTime != _startTime ||
          originalEndTime != _endTime ||
          editing.quality != _quality ||
          (editing.notes ?? '') != _notesController.text;
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;

    final shouldDiscard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return shouldDiscard ?? false;
  }

  @override
  void initState() {
    super.initState();
    final editing = widget.editingEntry;
    if (editing != null) {
      final started = editing.startedAt.toLocal();
      final ended = (editing.endedAt ?? editing.startedAt).toLocal();
      _sleepDate = DateTime(started.year, started.month, started.day);
      _startTime = TimeOfDay.fromDateTime(started);
      _endTime = TimeOfDay.fromDateTime(ended);
      _quality = editing.quality;
      _notesController.text = editing.notes ?? '';

      // Load detailed metrics if available
      if (editing.deepMinutes != null ||
          editing.lightMinutes != null ||
          editing.remMinutes != null ||
          editing.awakeMinutes != null) {
        _isDetailedMode = true;
        _deepMinutes = editing.deepMinutes ?? 0;
        _lightMinutes = editing.lightMinutes ?? 0;
        _remMinutes = editing.remMinutes ?? 0;
        _awakeMinutes = editing.awakeMinutes ?? 0;
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<SleepViewModel>();
    final durationMinutes = _calculatedDurationMinutes();

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmDiscard();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Sleep Session' : 'Log Sleep Session'),
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isTwoColumns =
                        ResponsiveUtils.columnsFor(context, maxColumns: 2) > 1;
                    const spacing = 16.0;
                    final tileWidth = isTwoColumns
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: tileWidth,
                          child: _buildPickerTile(
                            icon: Icons.calendar_today,
                            title:
                                'Night of ${DateFormats.longDate.format(_sleepDate)}',
                            subtitle: 'Tap to change date',
                            onTap: _pickDate,
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _buildPickerTile(
                            icon: Icons.bedtime,
                            title: 'Bedtime: ${_startTime.format(context)}',
                            subtitle: 'Tap to change start time',
                            onTap: () => _pickTime(isStart: true),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: _buildPickerTile(
                            icon: Icons.wb_sunny,
                            title: 'Wake time: ${_endTime.format(context)}',
                            subtitle: 'Tap to change wake time',
                            onTap: () => _pickTime(isStart: false),
                          ),
                        ),
                        if (durationMinutes != null)
                          SizedBox(
                            width: tileWidth,
                            child: Text(
                              'Duration: ${durationMinutes ~/ 60}h ${durationMinutes % 60}m',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        SizedBox(
                          width: tileWidth,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Sleep Quality (1-5)',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _quality,
                            items: List<DropdownMenuItem<int>>.generate(5,
                                (index) {
                              final value = index + 1;
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value - ${_qualityLabel(value)}'),
                              );
                            }),
                            onChanged: (value) =>
                                setState(() => _quality = value),
                            hint: const Text('Optional'),
                          ),
                        ),
                        SizedBox(
                          width: tileWidth,
                          child: SwitchListTile(
                            title: const Text('Detailed Sleep Tracking'),
                            subtitle: const Text(
                              'Track sleep stages (REM, Light, Deep)',
                            ),
                            value: _isDetailedMode,
                            onChanged: (value) =>
                                setState(() => _isDetailedMode = value),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_isDetailedMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Sleep Stages',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Total: ${_deepMinutes + _lightMinutes + _remMinutes + _awakeMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  _buildStageSlider(
                    label: 'Deep Sleep',
                    value: _deepMinutes,
                    max: durationMinutes?.toDouble() ?? 480,
                    onChanged: (value) =>
                        setState(() => _deepMinutes = value.toInt()),
                    color: Colors.indigo,
                  ),
                  _buildStageSlider(
                    label: 'Light Sleep',
                    value: _lightMinutes,
                    max: durationMinutes?.toDouble() ?? 480,
                    onChanged: (value) =>
                        setState(() => _lightMinutes = value.toInt()),
                    color: Colors.blue,
                  ),
                  _buildStageSlider(
                    label: 'REM Sleep',
                    value: _remMinutes,
                    max: durationMinutes?.toDouble() ?? 480,
                    onChanged: (value) =>
                        setState(() => _remMinutes = value.toInt()),
                    color: Colors.purple,
                  ),
                  _buildStageSlider(
                    label: 'Awake',
                    value: _awakeMinutes,
                    max: durationMinutes?.toDouble() ?? 480,
                    onChanged: (value) =>
                        setState(() => _awakeMinutes = value.toInt()),
                    color: Colors.orange,
                  ),
                ],
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
                  child: Text(
                    _isEditing ? 'Update Sleep Session' : 'Save Sleep Session',
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // Scaffold
    ); // PopScope
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

  Widget _buildStageSlider({
    required String label,
    required int value,
    required double max,
    required ValueChanged<double> onChanged,
    required Color color,
  }) {
    final hours = value ~/ 60;
    final minutes = value % 60;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              '${hours}h ${minutes}m',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          max: max,
          divisions: max.toInt(),
          onChanged: onChanged,
          activeColor: color,
        ),
      ],
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

    // Validate detailed mode stages
    if (_isDetailedMode) {
      final totalStages =
          _deepMinutes + _lightMinutes + _remMinutes + _awakeMinutes;
      if (totalStages > duration) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sleep stages total ($totalStages min) exceeds sleep duration ($duration min)',
            ),
          ),
        );
        return;
      }
    }

    final viewModel = context.read<SleepViewModel>();
    final error = await viewModel.saveSleepEntry(
      id: widget.editingEntry?.id,
      start: start,
      end: end,
      quality: _quality,
      deepMinutes: _isDetailedMode ? _deepMinutes : null,
      lightMinutes: _isDetailedMode ? _lightMinutes : null,
      remMinutes: _isDetailedMode ? _remMinutes : null,
      awakeMinutes: _isDetailedMode ? _awakeMinutes : null,
      notes: _notesController.text,
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Sleep session updated' : 'Sleep session saved',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/utils/responsive_utils.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';
import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';
import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

/// Screen for logging a manual weight entry with contextual lifestyle notes.
class AddWeightView extends StatefulWidget {
  /// Creates an [AddWeightView].
  const AddWeightView({super.key, this.editingEntry});

  /// Entry being edited, if any.
  final WeightEntry? editingEntry;

  @override
  State<AddWeightView> createState() => _AddWeightViewState();
}

class _AddWeightViewState extends State<AddWeightView> {
  final _formKey = GlobalKey<FormState>();
  final _weightController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _recordedAt = DateTime.now();
  String? _saltLevel;
  String? _exerciseLevel;
  int? _stressRating;
  bool _submitted = false;

  static const List<String> _saltLevels = <String>['Low', 'Medium', 'High'];
  static const List<String> _exerciseLevels = <String>[
    'None',
    'Light',
    'Moderate',
    'Intense',
  ];

  bool get _isEditing => widget.editingEntry != null;

  /// Check if form has unsaved changes.
  bool get _isDirty {
    final editing = widget.editingEntry;
    if (editing == null) {
      // New entry - dirty if weight field has content
      return _weightController.text.isNotEmpty ||
          _notesController.text.isNotEmpty;
    } else {
      // Editing - dirty if any field differs from original
      return editing.weightValue.toString() != _weightController.text ||
          (editing.notes ?? '') != _notesController.text ||
          !_isSameDateTime(editing.takenAt, _recordedAt) ||
          editing.saltIntake != _saltLevel ||
          editing.exerciseLevel != _exerciseLevel ||
          (editing.stressLevel == null
                  ? null
                  : int.tryParse(editing.stressLevel!)) !=
              _stressRating;
    }
  }

  /// Compare DateTimes ignoring microseconds/milliseconds.
  /// Only compares user-visible components: year, month, day, hour, minute.
  bool _isSameDateTime(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
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
      _recordedAt = editing.takenAt;
      // Convert from kg (storage) to preferred unit for display
      final viewModel = context.read<WeightViewModel>();
      final displayWeight = viewModel.getDisplayWeight(editing.weightValue);
      _weightController.text = displayWeight.toStringAsFixed(1);
      _notesController.text = editing.notes ?? '';
      _saltLevel = editing.saltIntake;
      _exerciseLevel = editing.exerciseLevel;
      _stressRating = editing.stressLevel == null
          ? null
          : int.tryParse(editing.stressLevel!);
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<WeightViewModel>();

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
          title: Text(_isEditing ? 'Edit Weight Entry' : 'Add Weight Entry'),
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
                    final fieldWidth = isTwoColumns
                        ? (constraints.maxWidth - spacing) / 2
                        : constraints.maxWidth;

                    Widget recordedAtTile = ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(
                        DateFormats.shortDateTime.format(_recordedAt),
                      ),
                      subtitle: const Text('Tap to change date & time'),
                      onTap: _pickDateTime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    );

                    return Wrap(
                      spacing: spacing,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: fieldWidth,
                          child: CustomTextField(
                            label:
                                viewModel.preferredWeightUnit == WeightUnit.kg
                                    ? 'Weight (kg)'
                                    : 'Weight (lbs)',
                            controller: _weightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^[0-9]*[.]?[0-9]*'),
                              ),
                            ],
                            helperText:
                                viewModel.preferredWeightUnit == WeightUnit.kg
                                    ? 'Enter value in kilograms (25-310 kg)'
                                    : 'Enter value in pounds (55-670 lbs)',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a weight value';
                              }
                              final parsed = double.tryParse(value);
                              if (parsed == null) {
                                return 'Invalid number';
                              }
                              final validation = validateWeight(
                                parsed,
                                viewModel.preferredWeightUnit == WeightUnit.kg
                                    ? 'kg'
                                    : 'lbs',
                              );
                              if (validation.level == ValidationLevel.error) {
                                return validation.message ?? 'Invalid weight';
                              }
                              return null;
                            },
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: recordedAtTile,
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _buildDropdown(
                            label: 'Salt Intake',
                            value: _saltLevel,
                            items: _saltLevels,
                            onChanged: (value) =>
                                setState(() => _saltLevel = value),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: _buildDropdown(
                            label: 'Exercise Level',
                            value: _exerciseLevel,
                            items: _exerciseLevels,
                            onChanged: (value) =>
                                setState(() => _exerciseLevel = value),
                          ),
                        ),
                        SizedBox(
                          width: fieldWidth,
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Stress Rating',
                              border: OutlineInputBorder(),
                            ),
                            initialValue: _stressRating,
                            items: List<DropdownMenuItem<int>>.generate(5,
                                (index) {
                              final value = index + 1;
                              return DropdownMenuItem<int>(
                                value: value,
                                child: Text('$value - ${_stressLabel(value)}'),
                              );
                            }),
                            onChanged: (value) =>
                                setState(() => _stressRating = value),
                            hint: const Text('Optional'),
                          ),
                        ),
                        SizedBox(
                          width: constraints.maxWidth,
                          child: CustomTextField(
                            label: 'Notes',
                            controller: _notesController,
                            maxLines: 4,
                            helperText:
                                'Optional context (up to 500 characters)',
                            validator: (value) {
                              if (value != null && value.length > 500) {
                                return 'Notes cannot exceed 500 characters';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    );
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
                    _isEditing ? 'Update Weight Entry' : 'Save Weight Entry',
                  ),
                ),
              ],
            ),
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String?>(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      initialValue: value,
      items: <DropdownMenuItem<String?>>[
        const DropdownMenuItem<String?>(value: null, child: Text('Optional')),
        ...items.map(
          (option) => DropdownMenuItem<String?>(
            value: option,
            child: Text(option),
          ),
        ),
      ],
      onChanged: onChanged,
    );
  }

  String _stressLabel(int rating) {
    switch (rating) {
      case 1:
        return 'Very Low';
      case 2:
        return 'Low';
      case 3:
        return 'Moderate';
      case 4:
        return 'High';
      case 5:
        return 'Very High';
      default:
        return 'Unknown';
    }
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );

    if (!mounted || date == null) {
      return;
    }

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );

    if (!mounted || time == null) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedWeight = double.parse(_weightController.text);
    final viewModel = context.read<WeightViewModel>();
    final error = await viewModel.saveWeightEntry(
      id: widget.editingEntry?.id,
      weightValue: parsedWeight,
      recordedAt: _recordedAt,
      notes: _notesController.text,
      saltIntake: _saltLevel,
      exerciseLevel: _exerciseLevel,
      stressLevel: _stressRating?.toString(),
    );

    if (!mounted) {
      return;
    }

    if (error == null) {
      context.refreshAnalyticsData();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing ? 'Weight entry updated' : 'Weight entry saved',
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

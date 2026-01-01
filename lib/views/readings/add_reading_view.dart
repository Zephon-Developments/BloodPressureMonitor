import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/utils/validators.dart';
import 'package:blood_pressure_monitor/utils/provider_extensions.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/views/readings/widgets/reading_form_advanced.dart';
import 'package:blood_pressure_monitor/views/readings/widgets/reading_form_basic.dart';
import 'package:blood_pressure_monitor/views/readings/widgets/session_control_widget.dart';
import 'package:blood_pressure_monitor/widgets/common/expandable_section.dart';
import 'package:blood_pressure_monitor/widgets/common/loading_button.dart';
import 'package:blood_pressure_monitor/widgets/common/validation_message_widget.dart';

/// Screen for adding a new blood pressure reading.
///
/// Provides basic fields (systolic, diastolic, pulse, timestamp) and
/// an advanced section for additional details (arm, posture, notes, tags).
/// Validates input using medical bounds and supports override confirmations.
class AddReadingView extends StatefulWidget {
  /// Creates an add/update reading view.
  const AddReadingView({super.key, this.editingReading});

  /// Reading being edited. When null the view operates in add mode.
  final Reading? editingReading;

  @override
  State<AddReadingView> createState() => _AddReadingViewState();
}

class _AddReadingViewState extends State<AddReadingView> {
  final _formKey = GlobalKey<FormState>();
  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _selectedDateTime = DateTime.now();
  String? _selectedArm;
  String? _selectedPosture;
  bool _startNewSession = false;
  bool _isSubmitting = false;
  ValidationResult? _validationResult;
  bool _showOverrideConfirmation = false;

  bool get _isEditing => widget.editingReading != null;

  /// Check if form has unsaved changes.
  bool get _isDirty {
    final editing = widget.editingReading;
    if (editing == null) {
      // New entry - dirty if any field has content
      return _systolicController.text.isNotEmpty ||
          _diastolicController.text.isNotEmpty ||
          _pulseController.text.isNotEmpty ||
          _notesController.text.isNotEmpty ||
          _tagsController.text.isNotEmpty;
    } else {
      // Editing - dirty if any field differs from original
      return editing.systolic.toString() != _systolicController.text ||
          editing.diastolic.toString() != _diastolicController.text ||
          editing.pulse.toString() != _pulseController.text ||
          (editing.note ?? '') != _notesController.text ||
          (editing.tags ?? '') != _tagsController.text ||
          editing.arm != _selectedArm ||
          editing.posture != _selectedPosture ||
          !_isSameDateTime(editing.takenAt, _selectedDateTime);
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
    final editing = widget.editingReading;
    if (editing != null) {
      _selectedDateTime = editing.takenAt;
      _systolicController.text = editing.systolic.toString();
      _diastolicController.text = editing.diastolic.toString();
      _pulseController.text = editing.pulse.toString();
      _notesController.text = editing.note ?? '';
      _tagsController.text = editing.tags ?? '';
      _selectedArm = editing.arm;
      _selectedPosture = editing.posture;
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (time == null || !mounted) return;

    setState(() {
      _selectedDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submitReading({bool confirmOverride = false}) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _showOverrideConfirmation = false;
    });

    final viewModel = context.read<BloodPressureViewModel>();
    final activeProfileViewModel = context.read<ActiveProfileViewModel>();

    final reading = Reading(
      id: widget.editingReading?.id,
      profileId: widget.editingReading?.profileId ??
          activeProfileViewModel.activeProfileId,
      takenAt: _selectedDateTime,
      localOffsetMinutes: _selectedDateTime.timeZoneOffset.inMinutes,
      systolic: int.parse(_systolicController.text),
      diastolic: int.parse(_diastolicController.text),
      pulse: int.parse(_pulseController.text),
      arm: _selectedArm,
      posture: _selectedPosture,
      note: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tags: _tagsController.text.trim().isEmpty
          ? null
          : _tagsController.text.trim(),
    );

    final result = _isEditing
        ? await viewModel.updateReading(
            reading,
            confirmOverride: confirmOverride,
          )
        : await viewModel.addReading(
            reading,
            confirmOverride: confirmOverride,
          );

    if (!mounted) return;

    setState(() {
      _isSubmitting = false;
      _validationResult = result;
    });

    if (result.level == ValidationLevel.warning && !confirmOverride) {
      // Show override confirmation dialog
      setState(() {
        _showOverrideConfirmation = true;
      });
    } else if (result.level == ValidationLevel.valid ||
        (result.level == ValidationLevel.warning && confirmOverride)) {
      // Success - show snackbar and navigate back
      if (mounted) {
        context.refreshAnalyticsData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Reading updated successfully'
                  : 'Reading added successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          title: Text(_isEditing ? 'Edit Reading' : 'Add Reading'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Validation message banner
                if (_validationResult != null &&
                    _validationResult!.level != ValidationLevel.valid &&
                    _validationResult!.message != null)
                  ValidationMessageWidget(
                    message: _validationResult!.message!,
                    isError: _validationResult!.level == ValidationLevel.error,
                  ),

                if (_showOverrideConfirmation)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            'Override Confirmation Required',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _validationResult?.message ?? '',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onErrorContainer,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      _showOverrideConfirmation = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: FilledButton(
                                  onPressed: () => _submitReading(
                                    confirmOverride: true,
                                  ),
                                  child: const Text('Confirm Override'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // Basic fields
                ReadingFormBasic(
                  systolicController: _systolicController,
                  diastolicController: _diastolicController,
                  pulseController: _pulseController,
                  selectedDateTime: _selectedDateTime,
                  onDateTimeChanged: _selectDateTime,
                ),

                const SizedBox(height: 16),

                // Advanced section (expandable)
                ExpandableSection(
                  title: 'Advanced Options',
                  children: [
                    ReadingFormAdvanced(
                      notesController: _notesController,
                      tagsController: _tagsController,
                      selectedArm: _selectedArm,
                      selectedPosture: _selectedPosture,
                      onArmChanged: (arm) {
                        setState(() {
                          _selectedArm = arm;
                        });
                      },
                      onPostureChanged: (posture) {
                        setState(() {
                          _selectedPosture = posture;
                        });
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (!_isEditing) ...[
                  SessionControlWidget(
                    startNewSession: _startNewSession,
                    onChanged: (value) {
                      setState(() {
                        _startNewSession = value;
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                ],

                // Submit button
                LoadingButton(
                  onPressed: _isSubmitting || _showOverrideConfirmation
                      ? null
                      : () => _submitReading(),
                  isLoading: _isSubmitting,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(_isEditing ? 'Update Reading' : 'Save Reading'),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }
}

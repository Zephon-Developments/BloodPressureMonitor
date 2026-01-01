import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/medication/unit_combo_box.dart';

/// View for adding or editing a medication.
///
/// Supports validation and profile-scoped creation/updates.
class AddEditMedicationView extends StatefulWidget {
  final Medication? medication;

  const AddEditMedicationView({super.key, this.medication});

  @override
  State<AddEditMedicationView> createState() => _AddEditMedicationViewState();
}

class _AddEditMedicationViewState extends State<AddEditMedicationView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _frequencyController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedUnit = 'mg';
  bool _isActive = true;
  bool _isSaving = false;

  /// Check if form has unsaved changes.
  bool get _isDirty {
    final medication = widget.medication;
    if (medication == null) {
      // New medication - dirty if name field has content
      return _nameController.text.isNotEmpty ||
          _dosageController.text.isNotEmpty ||
          _frequencyController.text.isNotEmpty;
    } else {
      // Editing - dirty if any field differs from original
      return medication.name != _nameController.text ||
          (medication.dosage ?? '') != _dosageController.text ||
          (medication.unit ?? 'mg') != _selectedUnit ||
          (medication.frequency ?? '') != _frequencyController.text ||
          medication.isActive != _isActive;
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
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _dosageController.text = widget.medication!.dosage ?? '';
      _selectedUnit = widget.medication!.unit ?? 'mg';
      _frequencyController.text = widget.medication!.frequency ?? '';
      _isActive = widget.medication!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _frequencyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medication != null;

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
          title: Text(isEdit ? 'Edit Medication' : 'Add Medication'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medication Name *',
                  hintText: 'e.g., Lisinopril',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Medication name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Dosage',
                  hintText: 'e.g., 10',
                  border: OutlineInputBorder(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (!RegExp(r'^\d+(\.\d+)?$').hasMatch(value.trim())) {
                      return 'Dosage must be a number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              UnitComboBox(
                initialValue: _selectedUnit,
                onChanged: (value) {
                  setState(() {
                    _selectedUnit = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _frequencyController,
                decoration: const InputDecoration(
                  labelText: 'Frequency',
                  hintText: 'e.g., twice daily, as needed',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (isEdit)
                SwitchListTile(
                  title: const Text('Active'),
                  subtitle: const Text(
                    'Inactive medications are hidden from the main list',
                  ),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() {
                      _isActive = value;
                    });
                  },
                ),
              const SizedBox(height: 24),
              if (_isSaving)
                const Center(child: CircularProgressIndicator())
              else
                ElevatedButton(
                  onPressed: _saveMedication,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isEdit ? 'Update Medication' : 'Add Medication'),
                ),
            ],
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final medicationViewModel = context.read<MedicationViewModel>();
      final activeProfileViewModel = context.read<ActiveProfileViewModel>();

      final medication = Medication(
        id: widget.medication?.id,
        profileId: activeProfileViewModel.activeProfileId,
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? null
            : _dosageController.text.trim(),
        unit: _selectedUnit,
        frequency: _frequencyController.text.trim().isEmpty
            ? null
            : _frequencyController.text.trim(),
        isActive: _isActive,
        createdAt: widget.medication?.createdAt,
      );

      if (widget.medication == null) {
        await medicationViewModel.createMedication(medication);
      } else {
        await medicationViewModel.updateMedication(medication);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.medication == null
                  ? 'Medication added successfully'
                  : 'Medication updated successfully',
            ),
          ),
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

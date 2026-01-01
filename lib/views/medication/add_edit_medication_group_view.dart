import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/medication/multi_select_medication_picker.dart';

/// Form view for creating or editing a medication group.
///
/// Allows users to specify a group name, optional description, and
/// select member medications from the multi-select picker.
///
/// Validation rules:
/// - Group name is required and must be at least 2 characters
/// - At least one medication must be selected
///
/// Usage:
/// ```dart
/// // Create new group
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AddEditMedicationGroupView(),
///   ),
/// );
///
/// // Edit existing group
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => AddEditMedicationGroupView(group: existingGroup),
///   ),
/// );
/// ```
class AddEditMedicationGroupView extends StatefulWidget {
  /// The group to edit. If null, creates a new group.
  final MedicationGroup? group;

  const AddEditMedicationGroupView({super.key, this.group});

  @override
  State<AddEditMedicationGroupView> createState() =>
      _AddEditMedicationGroupViewState();
}

class _AddEditMedicationGroupViewState
    extends State<AddEditMedicationGroupView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late List<int> _selectedMedicationIds;
  bool _isSubmitting = false;
  List<Medication> _availableMedications = [];
  bool _isLoadingMedications = true;

  bool get _isEditing => widget.group != null;

  /// Check if form has unsaved changes.
  bool get _isDirty {
    final group = widget.group;
    if (group == null) {
      // New group - dirty if name or medications are set
      return _nameController.text.isNotEmpty ||
          _selectedMedicationIds.isNotEmpty;
    } else {
      // Editing - dirty if name or medications differ
      return group.name != _nameController.text ||
          _listsDiffer(group.memberMedicationIds, _selectedMedicationIds);
    }
  }

  bool _listsDiffer(List<int> a, List<int> b) {
    if (a.length != b.length) return true;
    final aSet = Set<int>.from(a);
    final bSet = Set<int>.from(b);
    return !aSet.containsAll(bSet) || !bSet.containsAll(aSet);
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
    _nameController = TextEditingController(text: widget.group?.name ?? '');
    _selectedMedicationIds = List.from(widget.group?.memberMedicationIds ?? []);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMedications();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadMedications() async {
    if (!mounted) return;

    setState(() {
      _isLoadingMedications = true;
    });

    try {
      await context.read<MedicationViewModel>().loadMedications();
      if (mounted) {
        setState(() {
          _availableMedications = context
              .read<MedicationViewModel>()
              .medications
              .where((m) => m.isActive)
              .toList();
          _isLoadingMedications = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMedications = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load medications: $e')),
        );
      }
    }
  }

  Future<void> _selectMedications() async {
    final result = await MultiSelectMedicationPicker.show(
      context,
      medications: _availableMedications,
      initiallySelected: _selectedMedicationIds,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedMedicationIds = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMedicationIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one medication'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final viewModel = context.read<MedicationGroupViewModel>();
      final activeProfileId =
          context.read<ActiveProfileViewModel>().activeProfileId;

      final group = MedicationGroup(
        id: widget.group?.id,
        profileId: activeProfileId,
        name: _nameController.text.trim(),
        memberMedicationIds: _selectedMedicationIds,
        createdAt: widget.group?.createdAt ?? DateTime.now(),
      );

      if (_isEditing) {
        await viewModel.updateGroup(group);
      } else {
        await viewModel.createGroup(group);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving group: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  List<Medication> get _selectedMedications {
    return _availableMedications
        .where((m) => _selectedMedicationIds.contains(m.id))
        .toList();
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
          title: Text(_isEditing ? 'Edit Group' : 'Add Group'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'e.g., Morning Medications',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 2) {
                    return 'Group name must be at least 2 characters';
                  }
                  return null;
                },
                enabled: !_isSubmitting,
              ),
              const SizedBox(height: 24),
              Text(
                'Medications',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (_isLoadingMedications)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _selectMedications,
                  icon: const Icon(Icons.add),
                  label: Text(
                    _selectedMedicationIds.isEmpty
                        ? 'Select Medications'
                        : 'Change Selection',
                  ),
                ),
                if (_selectedMedications.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Card(
                    child: Column(
                      children: _selectedMedications.map((medication) {
                        return ListTile(
                          leading: const Icon(Icons.medication),
                          title: Text(medication.name),
                          subtitle: medication.dosage != null &&
                                  medication.unit != null
                              ? Text('${medication.dosage} ${medication.unit}')
                              : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _selectedMedicationIds
                                          .remove(medication.id);
                                    });
                                  },
                            tooltip: 'Remove from group',
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                if (_selectedMedicationIds.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Select at least one medication for this group',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _save,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isEditing ? 'Update Group' : 'Create Group'),
              ),
            ],
          ),
        ),
      ), // Scaffold
    ); // PopScope
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

/// View for creating or editing a user profile.
///
/// This view provides a form to enter profile details such as name,
/// year of birth, and preferred units. It handles both creation of new
/// profiles and updating existing ones.
///
/// When creating a new profile, it can optionally set it as the active profile.
/// When editing, it updates the profile in the database and refreshes the
/// active profile state if the edited profile is currently active.
class ProfileFormView extends StatefulWidget {
  /// The profile to edit. If null, a new profile will be created.
  final Profile? profile;

  const ProfileFormView({super.key, this.profile});

  @override
  State<ProfileFormView> createState() => _ProfileFormViewState();
}

class _ProfileFormViewState extends State<ProfileFormView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _patientIdController;
  late TextEditingController _doctorNameController;
  late TextEditingController _clinicNameController;
  late DateTime? _selectedDateOfBirth;
  late String _selectedUnits;
  late String _selectedWeightUnit;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile?.name ?? '');
    _patientIdController =
        TextEditingController(text: widget.profile?.patientId ?? '');
    _doctorNameController =
        TextEditingController(text: widget.profile?.doctorName ?? '');
    _clinicNameController =
        TextEditingController(text: widget.profile?.clinicName ?? '');
    _selectedDateOfBirth = widget.profile?.dateOfBirth;
    _selectedUnits = widget.profile?.preferredUnits ?? 'mmHg';
    _selectedWeightUnit = widget.profile?.preferredWeightUnit ?? 'kg';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _patientIdController.dispose();
    _doctorNameController.dispose();
    _clinicNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final viewModel = context.read<ActiveProfileViewModel>();
      final profile = Profile(
        id: widget.profile?.id,
        name: _nameController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
        patientId: _patientIdController.text.trim().isEmpty
            ? null
            : _patientIdController.text.trim(),
        doctorName: _doctorNameController.text.trim().isEmpty
            ? null
            : _doctorNameController.text.trim(),
        clinicName: _clinicNameController.text.trim().isEmpty
            ? null
            : _clinicNameController.text.trim(),
        preferredUnits: _selectedUnits,
        preferredWeightUnit: _selectedWeightUnit,
        colorHex: widget.profile?.colorHex,
        avatarIcon: widget.profile?.avatarIcon,
        createdAt: widget.profile?.createdAt,
      );

      if (widget.profile == null) {
        // Create new profile and set as active
        await viewModel.createProfile(profile, setAsActive: true);
      } else {
        // Update existing profile
        await viewModel.updateProfile(profile);
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.profile != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Profile' : 'Add Profile'),
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
                labelText: 'Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Medical Information',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateOfBirth ??
                      DateTime.now().subtract(const Duration(days: 365)),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now().subtract(const Duration(days: 365)),
                  helpText: 'Select Date of Birth',
                );
                if (picked != null) {
                  // Normalize to UTC midnight to avoid timezone issues
                  setState(
                    () => _selectedDateOfBirth = DateTime.utc(
                      picked.year,
                      picked.month,
                      picked.day,
                    ),
                  );
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Birth (Optional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_today),
                  suffixIcon: Icon(Icons.arrow_drop_down),
                ),
                child: Text(
                  _selectedDateOfBirth != null
                      ? DateFormat.yMMMd().format(_selectedDateOfBirth!)
                      : 'Not specified',
                  style: TextStyle(
                    color: _selectedDateOfBirth != null
                        ? Theme.of(context).textTheme.bodyLarge?.color
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ),
            ),
            if (_selectedDateOfBirth != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _selectedDateOfBirth = null),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _patientIdController,
              decoration: const InputDecoration(
                labelText: 'Patient ID (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.badge),
                hintText: 'e.g., NHS number',
              ),
              maxLength: 50,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _doctorNameController,
              decoration: const InputDecoration(
                labelText: 'Doctor\'s Name (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.medical_information),
                hintText: 'e.g., Dr. Jane Smith',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _clinicNameController,
              decoration: const InputDecoration(
                labelText: 'Clinic Name (Optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.local_hospital),
                hintText: 'e.g., City General Hospital',
              ),
              textCapitalization: TextCapitalization.words,
              maxLength: 100,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedUnits,
              decoration: const InputDecoration(
                labelText: 'Blood Pressure Units',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.straighten),
              ),
              items: const [
                DropdownMenuItem<String>(value: 'mmHg', child: Text('mmHg')),
                DropdownMenuItem<String>(value: 'kPa', child: Text('kPa')),
              ],
              onChanged: (value) => setState(() => _selectedUnits = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedWeightUnit,
              decoration: const InputDecoration(
                labelText: 'Weight Units',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.monitor_weight),
              ),
              items: const [
                DropdownMenuItem<String>(
                  value: 'kg',
                  child: Text('Kilograms (kg)'),
                ),
                DropdownMenuItem<String>(
                  value: 'lbs',
                  child: Text('Pounds (lbs)'),
                ),
              ],
              onChanged: (value) =>
                  setState(() => _selectedWeightUnit = value!),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isEditing ? 'Update Profile' : 'Create Profile',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

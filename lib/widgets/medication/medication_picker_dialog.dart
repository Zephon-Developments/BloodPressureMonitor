import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';

/// Dialog for picking a medication from the active profile's list.
///
/// Returns the selected [Medication] or null if cancelled.
class MedicationPickerDialog extends StatefulWidget {
  const MedicationPickerDialog({super.key});

  @override
  State<MedicationPickerDialog> createState() => _MedicationPickerDialogState();
}

class _MedicationPickerDialogState extends State<MedicationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationViewModel>().loadMedications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            Expanded(
              child: _buildMedicationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return AppBar(
      title: const Text('Select Medication'),
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Cancel',
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search medications...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchTerm.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _debounceTimer?.cancel();
                    setState(() {
                      _searchTerm = '';
                      _searchController.clear();
                    });
                    context.read<MedicationViewModel>().search('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          setState(() {
            _searchTerm = value;
          });
          // Cancel previous timer
          _debounceTimer?.cancel();
          // Start new timer for debouncing (300ms delay)
          _debounceTimer = Timer(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            context.read<MedicationViewModel>().search(value);
          });
        },
      ),
    );
  }

  Widget _buildMedicationList() {
    return Consumer<MedicationViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.loadMedications(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activeMedications =
            viewModel.medications.where((med) => med.isActive).toList();

        if (activeMedications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.medication_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No active medications',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: activeMedications.length,
          itemBuilder: (context, index) {
            final medication = activeMedications[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(
                  Icons.medication,
                  color: Colors.white,
                ),
              ),
              title: Text(medication.name),
              subtitle: medication.dosage != null || medication.unit != null
                  ? Text(
                      [
                        if (medication.dosage != null) medication.dosage,
                        if (medication.unit != null) medication.unit,
                      ].join(' '),
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(medication),
            );
          },
        );
      },
    );
  }
}

/// Shows the medication picker dialog.
///
/// Returns the selected [Medication] or null if cancelled.
Future<Medication?> showMedicationPicker(BuildContext context) async {
  return showDialog<Medication>(
    context: context,
    builder: (context) => const MedicationPickerDialog(),
  );
}

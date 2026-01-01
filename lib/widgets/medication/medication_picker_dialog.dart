import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';

/// Dialog for picking a medication or medication group from the active profile's list.
///
/// Returns the selected [Medication] or [MedicationGroup], or null if cancelled.
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
      context.read<MedicationGroupViewModel>().loadGroups();
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
              child: _buildContentList(),
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
          hintText: 'Search medications and groups...',
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

  Widget _buildContentList() {
    return Consumer2<MedicationViewModel, MedicationGroupViewModel>(
      builder: (context, medViewModel, groupViewModel, child) {
        if (medViewModel.isLoading || groupViewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (medViewModel.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  medViewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => medViewModel.loadMedications(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final activeMedications =
            medViewModel.medications.where((med) => med.isActive).toList();
        final activeGroups = groupViewModel.groups;

        // Filter groups based on search term
        final filteredGroups = _searchTerm.isEmpty
            ? activeGroups
            : activeGroups
                .where((g) =>
                    g.name.toLowerCase().contains(_searchTerm.toLowerCase()))
                .toList();

        if (activeMedications.isEmpty && activeGroups.isEmpty) {
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
                  'No active medications or groups',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          children: [
            if (filteredGroups.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text(
                  'Medication Groups',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              ...filteredGroups.map((group) {
                final groupMedCount = medViewModel.medications
                    .where((m) => group.memberMedicationIds.contains(m.id))
                    .length;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.secondary,
                    child: const Icon(
                      Icons.folder,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(group.name),
                  subtitle: Text(
                      '$groupMedCount medication${groupMedCount != 1 ? 's' : ''}'),
                  onTap: () => Navigator.of(context).pop(group),
                );
              }),
              if (activeMedications.isNotEmpty) ...[
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Individual Medications',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ],
            ...activeMedications.map((medication) {
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
            }),
          ],
        );
      },
    );
  }
}

/// Shows the medication picker dialog.
///
/// Returns the selected [Medication] or [MedicationGroup], or null if cancelled.
Future<dynamic> showMedicationPicker(BuildContext context) async {
  return showDialog<dynamic>(
    context: context,
    builder: (context) => const MedicationPickerDialog(),
  );
}

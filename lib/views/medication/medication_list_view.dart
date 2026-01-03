import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/views/medication/add_edit_medication_view.dart';
import 'package:blood_pressure_monitor/views/medication/medication_group_list_view.dart';
import 'package:blood_pressure_monitor/views/medication/log_intake_sheet.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// View for displaying and managing the list of medications.
///
/// Provides search, filtering, and CRUD operations for medications.
class MedicationListView extends StatefulWidget {
  const MedicationListView({super.key});

  @override
  State<MedicationListView> createState() => _MedicationListViewState();
}

class _MedicationListViewState extends State<MedicationListView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load medications on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationViewModel>().loadMedications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder),
            onPressed: () => _navigateToManageGroups(context),
            tooltip: 'Manage Groups',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToAddMedication(context),
            tooltip: 'Add Medication',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: _buildMedicationList(),
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Add new medication',
        button: true,
        excludeSemantics: true,
        child: FloatingActionButton(
          onPressed: () => _navigateToAddMedication(context),
          tooltip: 'Add Medication',
          child: const Icon(Icons.add),
        ),
      ),
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
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    context.read<MedicationViewModel>().search('');
                  },
                )
              : null,
          border: const OutlineInputBorder(),
        ),
        onChanged: (value) {
          context.read<MedicationViewModel>().search(value);
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<MedicationViewModel>(
      builder: (context, viewModel, child) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Wrap(
            spacing: 8.0,
            children: [
              FilterChip(
                label: const Text('Show Inactive'),
                selected: viewModel.showInactive,
                onSelected: (_) => viewModel.toggleShowInactive(),
              ),
            ],
          ),
        );
      },
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

        if (viewModel.medications.isEmpty) {
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
                  'No medications found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add your first medication to get started',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: viewModel.medications.length,
          itemBuilder: (context, index) {
            final medication = viewModel.medications[index];
            return _buildMedicationTile(context, medication, viewModel);
          },
        );
      },
    );
  }

  Widget _buildMedicationTile(
    BuildContext context,
    Medication medication,
    MedicationViewModel viewModel,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: medication.isActive
              ? Theme.of(context).primaryColor
              : Colors.grey,
          child: const Icon(
            Icons.medication,
            color: Colors.white,
          ),
        ),
        title: Text(
          medication.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            decoration: medication.isActive ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (medication.dosage != null || medication.unit != null)
              Text(
                '${medication.dosage ?? ''} ${medication.unit ?? ''}',
                style: const TextStyle(fontSize: 12),
              ),
            if (medication.frequency != null)
              Text(
                medication.frequency!,
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!medication.isActive)
              const Chip(
                label: Text('Inactive', style: TextStyle(fontSize: 10)),
                backgroundColor: Colors.grey,
                padding: EdgeInsets.zero,
              ),
            if (medication.isActive)
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => _logIntake(context, medication),
                tooltip: 'Log intake',
                color: Theme.of(context).primaryColor,
              ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _navigateToEditMedication(context, medication),
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _confirmDelete(context, medication, viewModel),
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _navigateToEditMedication(context, medication),
      ),
    );
  }

  Future<void> _navigateToAddMedication(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddEditMedicationView(),
      ),
    );
    if (mounted) {
      this.context.read<MedicationViewModel>().loadMedications();
    }
  }

  void _logIntake(BuildContext context, Medication medication) {
    showLogIntakeSheet(context, medication);
  }

  Future<void> _navigateToManageGroups(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const MedicationGroupListView(),
      ),
    );
    if (mounted) {
      this.context.read<MedicationViewModel>().loadMedications();
    }
  }

  Future<void> _navigateToEditMedication(
    BuildContext context,
    Medication medication,
  ) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditMedicationView(medication: medication),
      ),
    );
    if (mounted) {
      this.context.read<MedicationViewModel>().loadMedications();
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Medication medication,
    MedicationViewModel viewModel,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: 'Delete Medication',
        message:
            'Are you sure you want to delete "${medication.name}"? This will mark it as inactive but preserve intake history.',
      ),
    );

    if (confirmed == true && medication.id != null) {
      try {
        await viewModel.deleteMedication(medication.id!);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medication deleted successfully')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_intake_viewmodel.dart';

/// View for browsing medication intake history with filters and status indicators.
class MedicationHistoryView extends StatefulWidget {
  const MedicationHistoryView({super.key});

  @override
  State<MedicationHistoryView> createState() => _MedicationHistoryViewState();
}

class _MedicationHistoryViewState extends State<MedicationHistoryView> {
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int? _selectedMedicationId;

  @override
  void initState() {
    super.initState();
    // Default to last 90 days
    _filterFrom = DateTime.now().subtract(const Duration(days: 90));
    _filterTo = DateTime.now();

    // Load history on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
    });
  }

  void _loadHistory() {
    context.read<MedicationIntakeViewModel>().setDateRange(
          _filterFrom,
          _filterTo,
        );
    if (_selectedMedicationId != null) {
      context
          .read<MedicationIntakeViewModel>()
          .setMedicationFilter(_selectedMedicationId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSummary(),
          Expanded(
            child: _buildIntakeList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSummary() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing: ${_filterFrom != null ? _formatDate(_filterFrom!) : 'All'} - ${_filterTo != null ? _formatDate(_filterTo!) : 'Now'}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          if (_selectedMedicationId != null)
            Chip(
              label: const Text('Filtered by medication'),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () {
                setState(() {
                  _selectedMedicationId = null;
                });
                _loadHistory();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildIntakeList() {
    return Consumer<MedicationIntakeViewModel>(
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
                  onPressed: _loadHistory,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (viewModel.intakes.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No intake history found',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Log your first medication intake to see history',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: viewModel.intakes.length,
          itemBuilder: (context, index) {
            final intake = viewModel.intakes[index];
            return _buildIntakeTile(context, intake, viewModel);
          },
        );
      },
    );
  }

  Widget _buildIntakeTile(
    BuildContext context,
    MedicationIntake intake,
    MedicationIntakeViewModel viewModel,
  ) {
    final medication = viewModel.medicationCache[intake.medicationId];
    final status = viewModel.calculateStatusSync(intake);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: _buildStatusIcon(intake),
        title: Text(medication?.name ?? 'Unknown Medication'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Taken: ${_formatDateTime(intake.takenAt)}',
              style: const TextStyle(fontSize: 12),
            ),
            if (intake.scheduledFor != null)
              Text(
                'Scheduled: ${_formatDateTime(intake.scheduledFor!)}',
                style: const TextStyle(fontSize: 12),
              ),
            if (intake.note != null)
              Text(
                intake.note!,
                style:
                    const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
          ],
        ),
        trailing: _buildStatusChip(status),
      ),
    );
  }

  Widget _buildStatusIcon(MedicationIntake intake) {
    return const CircleAvatar(
      backgroundColor: Colors.blue,
      child: Icon(
        Icons.medication,
        color: Colors.white,
      ),
    );
  }

  Widget _buildStatusChip(IntakeStatus status) {
    Color color;
    String label;

    switch (status) {
      case IntakeStatus.onTime:
        color = Colors.green;
        label = 'On Time';
        break;
      case IntakeStatus.late:
        color = Colors.amber;
        label = 'Late';
        break;
      case IntakeStatus.missed:
        color = Colors.red;
        label = 'Missed';
        break;
      case IntakeStatus.unscheduled:
        color = Colors.grey;
        label = 'Unscheduled';
        break;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withAlpha((0.3 * 255).toInt()),
      padding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showFilterDialog() async {
    DateTime? tempFrom = _filterFrom;
    DateTime? tempTo = _filterTo;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter History'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('From Date'),
                subtitle: Text(
                  tempFrom != null ? _formatDate(tempFrom!) : 'Not set',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempFrom ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      tempFrom = date;
                    });
                  }
                },
              ),
              ListTile(
                title: const Text('To Date'),
                subtitle: Text(
                  tempTo != null ? _formatDate(tempTo!) : 'Not set',
                ),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: tempTo ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setDialogState(() {
                      tempTo = date;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _filterFrom = null;
                  _filterTo = null;
                  _selectedMedicationId = null;
                });
                Navigator.of(context).pop();
                _loadHistory();
              },
              child: const Text('Clear All'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filterFrom = tempFrom;
                  _filterTo = tempTo;
                });
                Navigator.of(context).pop();
                _loadHistory();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }
}

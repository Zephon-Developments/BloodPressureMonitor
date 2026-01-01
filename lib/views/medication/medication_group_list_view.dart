import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/views/medication/add_edit_medication_group_view.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// View for managing medication groups.
///
/// Displays a list of medication groups for the active profile with
/// options to create, edit, and delete groups. Groups can be used to
/// log multiple medications with a single action.
///
/// Features:
/// - List of all medication groups with member counts
/// - Swipe-to-delete with confirmation
/// - Empty state with helpful guidance
/// - Navigation to add/edit forms
///
/// Accessibility:
/// - All buttons have semantic labels
/// - Supports screen readers
/// - Works with large text scaling
class MedicationGroupListView extends StatefulWidget {
  const MedicationGroupListView({super.key});

  @override
  State<MedicationGroupListView> createState() =>
      _MedicationGroupListViewState();
}

class _MedicationGroupListViewState extends State<MedicationGroupListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationGroupViewModel>().loadGroups();
    });
  }

  Future<void> _addNewGroup() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const AddEditMedicationGroupView(),
      ),
    );
  }

  Future<void> _editGroup(MedicationGroup group) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => AddEditMedicationGroupView(group: group),
      ),
    );
  }

  Future<void> _deleteGroup(MedicationGroup group) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete Medication Group',
      message:
          'Are you sure you want to delete "${group.name}"? This will not delete the medications themselves, only the grouping.',
    );

    if (confirmed && mounted) {
      try {
        await context.read<MedicationGroupViewModel>().deleteGroup(group.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Medication group deleted'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete group: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Groups'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<MedicationGroupViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: viewModel.loadGroups,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (viewModel.groups.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.medication_outlined,
                      size: 80,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'No medication groups yet',
                      style: Theme.of(context).textTheme.headlineSmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create a group to log multiple medications at once. '
                      'Perfect for morning or evening medication routines.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _addNewGroup,
                      icon: const Icon(Icons.add),
                      label: const Text('Create Your First Group'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: viewModel.groups.length,
            itemBuilder: (context, index) {
              final group = viewModel.groups[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Slidable(
                  key: ValueKey(group.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) => _deleteGroup(group),
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        icon: Icons.delete,
                        label: 'Delete',
                      ),
                    ],
                  ),
                  child: Card(
                    child: InkWell(
                      onTap: () => _editGroup(group),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.medication,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.local_pharmacy,
                                        size: 16,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.memberMedicationIds.length} medication${group.memberMedicationIds.length != 1 ? 's' : ''}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addNewGroup,
        icon: const Icon(Icons.add),
        label: const Text('Add Group'),
      ),
    );
  }
}

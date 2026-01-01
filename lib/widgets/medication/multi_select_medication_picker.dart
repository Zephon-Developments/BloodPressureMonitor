import 'package:flutter/material.dart';
import 'package:blood_pressure_monitor/models/medication.dart';

/// Multi-select medication picker dialog.
///
/// Displays a searchable list of medications with checkboxes for selection.
/// Returns a list of selected medications when the user confirms.
///
/// Usage:
/// ```dart
/// final selected = await MultiSelectMedicationPicker.show(
///   context,
///   medications: availableMeds,
///   initiallySelected: currentSelection,
/// );
/// ```
class MultiSelectMedicationPicker extends StatefulWidget {
  /// List of all available medications to choose from.
  final List<Medication> medications;

  /// IDs of medications that should be initially selected.
  final List<int> initiallySelected;

  const MultiSelectMedicationPicker({
    super.key,
    required this.medications,
    this.initiallySelected = const [],
  });

  /// Shows the multi-select picker as a modal bottom sheet.
  ///
  /// Returns the list of selected medication IDs, or null if cancelled.
  static Future<List<int>?> show(
    BuildContext context, {
    required List<Medication> medications,
    List<int> initiallySelected = const [],
  }) {
    return showModalBottomSheet<List<int>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => MultiSelectMedicationPicker(
          medications: medications,
          initiallySelected: initiallySelected,
        ),
      ),
    );
  }

  @override
  State<MultiSelectMedicationPicker> createState() =>
      _MultiSelectMedicationPickerState();
}

class _MultiSelectMedicationPickerState
    extends State<MultiSelectMedicationPicker> {
  final TextEditingController _searchController = TextEditingController();
  final Set<int> _selectedIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initiallySelected);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Medication> get _filteredMedications {
    if (_searchQuery.isEmpty) {
      return widget.medications;
    }
    return widget.medications
        .where((med) => med.name.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
            child: Row(
              children: [
                Text(
                  'Select Medications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Text(
                  '${_selectedIds.length} selected',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search medications...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                        tooltip: 'Clear search',
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Medication list
          Expanded(
            child: _filteredMedications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No medications available'
                              : 'No medications match your search',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredMedications.length,
                    itemBuilder: (context, index) {
                      final medication = _filteredMedications[index];
                      final isSelected = _selectedIds.contains(medication.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          _toggleSelection(medication.id!);
                        },
                        title: Text(medication.name),
                        subtitle: medication.dosage != null &&
                                medication.unit != null
                            ? Text('${medication.dosage} ${medication.unit}')
                            : null,
                        secondary: Icon(
                          Icons.medication,
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
          ),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () =>
                            Navigator.of(context).pop(_selectedIds.toList()),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

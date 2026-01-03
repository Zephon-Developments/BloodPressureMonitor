import 'package:flutter/material.dart';

/// Combo box for selecting medication units.
///
/// Provides a dropdown with common medication units (mg, ml, IU, mcg, etc.)
/// plus a "Custom" option that allows free-form text entry.
///
/// Common units:
/// - mg (milligrams)
/// - ml (milliliters)
/// - IU (International Units)
/// - mcg (micrograms)
/// - units
/// - tablets
/// - capsules
///
/// Usage:
/// ```dart
/// UnitComboBox(
///   initialValue: 'mg',
///   onChanged: (unit) {
///     print('Selected unit: $unit');
///   },
/// )
/// ```
class UnitComboBox extends StatefulWidget {
  /// The initially selected unit value.
  final String? initialValue;

  /// Callback invoked when the unit selection changes.
  final ValueChanged<String> onChanged;

  /// Whether the combo box is enabled.
  final bool enabled;

  const UnitComboBox({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  State<UnitComboBox> createState() => _UnitComboBoxState();
}

class _UnitComboBoxState extends State<UnitComboBox> {
  /// Predefined common medication units.
  static const List<String> _commonUnits = [
    'mg',
    'ml',
    'IU',
    'mcg',
    'units',
    'tablets',
    'capsules',
    'drops',
    'puffs',
    'Custom',
  ];

  late String _selectedUnit;
  late TextEditingController _customUnitController;
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();

    // Initialize the controller unconditionally
    _customUnitController = TextEditingController();

    // Determine if initial value is a common unit or custom
    if (widget.initialValue != null && widget.initialValue!.isNotEmpty) {
      if (_commonUnits.contains(widget.initialValue)) {
        _selectedUnit = widget.initialValue!;
        _showCustomField = false;
      } else {
        _selectedUnit = 'Custom';
        _showCustomField = true;
        _customUnitController.text = widget.initialValue!;
      }
    } else {
      _selectedUnit = _commonUnits.first;
      _showCustomField = false;
    }

    _customUnitController.addListener(_onCustomUnitChanged);
  }

  @override
  void dispose() {
    _customUnitController.dispose();
    super.dispose();
  }

  void _onCustomUnitChanged() {
    if (_showCustomField && _customUnitController.text.isNotEmpty) {
      widget.onChanged(_customUnitController.text.trim());
    }
  }

  void _onDropdownChanged(String? value) {
    if (value == null) return;

    setState(() {
      _selectedUnit = value;
      _showCustomField = value == 'Custom';
    });

    if (value == 'Custom') {
      // Wait for custom field to appear, then focus it
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_customUnitController.text.isEmpty) {
          widget.onChanged('');
        } else {
          widget.onChanged(_customUnitController.text.trim());
        }
      });
    } else {
      widget.onChanged(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedUnit,
          decoration: const InputDecoration(
            labelText: 'Unit',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.straighten),
          ),
          items: _commonUnits.map((unit) {
            return DropdownMenuItem<String>(
              value: unit,
              child: Text(unit == 'Custom' ? 'Custom...' : unit),
            );
          }).toList(),
          onChanged: widget.enabled ? _onDropdownChanged : null,
        ),
        if (_showCustomField) ...[
          const SizedBox(height: 12),
          TextFormField(
            controller: _customUnitController,
            decoration: const InputDecoration(
              labelText: 'Custom Unit',
              hintText: 'Enter custom unit',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            enabled: widget.enabled,
            validator: (value) {
              if (_showCustomField && (value == null || value.trim().isEmpty)) {
                return 'Please enter a custom unit or select a predefined one';
              }
              return null;
            },
          ),
        ],
      ],
    );
  }
}

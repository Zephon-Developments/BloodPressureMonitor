import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:blood_pressure_monitor/utils/date_formats.dart';
import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';

/// Basic input fields for a blood pressure reading.
///
/// Includes systolic, diastolic, pulse, and timestamp selection.
class ReadingFormBasic extends StatelessWidget {
  /// Creates a basic reading form.
  const ReadingFormBasic({
    required this.systolicController,
    required this.diastolicController,
    required this.pulseController,
    required this.selectedDateTime,
    required this.onDateTimeChanged,
    super.key,
  });

  /// Controller for systolic value.
  final TextEditingController systolicController;

  /// Controller for diastolic value.
  final TextEditingController diastolicController;

  /// Controller for pulse value.
  final TextEditingController pulseController;

  /// The currently selected date/time for the reading.
  final DateTime selectedDateTime;

  /// Callback when user wants to change the date/time.
  final VoidCallback onDateTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Blood Pressure',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                label: 'Systolic',
                controller: systolicController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                helperText: '70-250 mmHg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null) {
                    return 'Invalid number';
                  }
                  if (intValue < 70 || intValue > 250) {
                    return 'Must be 70-250';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                label: 'Diastolic',
                controller: diastolicController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                helperText: '40-150 mmHg',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final intValue = int.tryParse(value);
                  if (intValue == null) {
                    return 'Invalid number';
                  }
                  if (intValue < 40 || intValue > 150) {
                    return 'Must be 40-150';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Pulse',
          controller: pulseController,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          helperText: '30-200 bpm',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
            final intValue = int.tryParse(value);
            if (intValue == null) {
              return 'Invalid number';
            }
            if (intValue < 30 || intValue > 200) {
              return 'Must be 30-200';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Date & Time'),
          subtitle: Text(
            DateFormats.standardDateTime.format(selectedDateTime),
          ),
          trailing: const Icon(Icons.calendar_today),
          onTap: onDateTimeChanged,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ],
    );
  }
}

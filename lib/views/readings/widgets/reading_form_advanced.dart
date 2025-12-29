import 'package:flutter/material.dart';

import 'package:blood_pressure_monitor/widgets/common/custom_text_field.dart';

/// Advanced input fields for a blood pressure reading.
///
/// Includes arm selection, posture, notes, and tags.
class ReadingFormAdvanced extends StatelessWidget {
  /// Creates an advanced reading form.
  const ReadingFormAdvanced({
    required this.notesController,
    required this.tagsController,
    required this.selectedArm,
    required this.selectedPosture,
    required this.onArmChanged,
    required this.onPostureChanged,
    super.key,
  });

  /// Controller for notes text field.
  final TextEditingController notesController;

  /// Controller for tags text field.
  final TextEditingController tagsController;

  /// Currently selected arm (null if not set).
  final String? selectedArm;

  /// Currently selected posture (null if not set).
  final String? selectedPosture;

  /// Callback when arm selection changes.
  final ValueChanged<String?> onArmChanged;

  /// Callback when posture selection changes.
  final ValueChanged<String?> onPostureChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          'Arm',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Left'),
              selected: selectedArm == 'left',
              onSelected: (selected) {
                onArmChanged(selected ? 'left' : null);
              },
            ),
            ChoiceChip(
              label: const Text('Right'),
              selected: selectedArm == 'right',
              onSelected: (selected) {
                onArmChanged(selected ? 'right' : null);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          'Posture',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Sitting'),
              selected: selectedPosture == 'sitting',
              onSelected: (selected) {
                onPostureChanged(selected ? 'sitting' : null);
              },
            ),
            ChoiceChip(
              label: const Text('Standing'),
              selected: selectedPosture == 'standing',
              onSelected: (selected) {
                onPostureChanged(selected ? 'standing' : null);
              },
            ),
            ChoiceChip(
              label: const Text('Lying'),
              selected: selectedPosture == 'lying',
              onSelected: (selected) {
                onPostureChanged(selected ? 'lying' : null);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Notes',
          controller: notesController,
          helperText: 'Any additional observations or context',
          maxLines: 3,
          minLines: 2,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Tags',
          controller: tagsController,
          helperText: 'Comma-separated tags (e.g., morning, exercise)',
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

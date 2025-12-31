import 'package:flutter/material.dart';
import '../models/theme_settings.dart';

/// Widget for selecting an accent color from the available palette.
///
/// Displays a grid of color options and highlights the currently selected one.
class ThemePalettePicker extends StatelessWidget {
  /// The currently selected accent color.
  final AccentColor selectedColor;

  /// Callback invoked when a color is selected.
  final ValueChanged<AccentColor> onColorSelected;

  const ThemePalettePicker({
    super.key,
    required this.selectedColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Accent Color',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: AccentColor.values.map((color) {
                final isSelected = color == selectedColor;
                return _ColorOption(
                  color: color,
                  isSelected: isSelected,
                  onTap: () => onColorSelected(color),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final AccentColor color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final materialColor = color.toColor();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
            width: isSelected ? 3 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: materialColor,
                shape: BoxShape.circle,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              color.displayName,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for selecting font scale option.
///
/// Displays radio buttons for available font scaling options.
class FontScaleSelector extends StatelessWidget {
  /// The currently selected font scale option.
  final FontScaleOption selectedScale;

  /// Callback invoked when a font scale is selected.
  final ValueChanged<FontScaleOption> onScaleSelected;

  const FontScaleSelector({
    super.key,
    required this.selectedScale,
    required this.onScaleSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Text Size',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...FontScaleOption.values.map((scale) {
              return RadioListTile<FontScaleOption>(
                title: Text(scale.displayName),
                subtitle: Text(
                  'Sample text at ${(scale.scaleFactor * 100).toInt()}% scale',
                  style: TextStyle(fontSize: 14 * scale.scaleFactor),
                ),
                value: scale,
                groupValue: selectedScale,
                onChanged: (value) {
                  if (value != null) {
                    onScaleSelected(value);
                  }
                },
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// Widget for toggling high-contrast mode.
///
/// Displays a switch tile with description of high-contrast benefits.
class ContrastToggleTile extends StatelessWidget {
  /// Whether high-contrast mode is currently enabled.
  final bool isEnabled;

  /// Callback invoked when the toggle is switched.
  final ValueChanged<bool> onToggle;

  const ContrastToggleTile({
    super.key,
    required this.isEnabled,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: SwitchListTile(
        title: Text(
          'High Contrast Mode',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: const Text(
          'Increases contrast between text and background for better readability',
        ),
        value: isEnabled,
        onChanged: onToggle,
      ),
    );
  }
}

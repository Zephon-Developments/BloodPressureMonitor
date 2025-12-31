import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/theme_settings.dart';
import 'package:blood_pressure_monitor/viewmodels/theme_viewmodel.dart';
import 'package:blood_pressure_monitor/widgets/theme_widgets.dart';

/// Screen for managing app appearance and theme settings.
///
/// Allows users to customize theme mode, accent color, font scaling, and
/// high-contrast mode. Changes are immediately applied and persisted.
class AppearanceView extends StatelessWidget {
  const AppearanceView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: 'Reset to defaults',
            onPressed: () => _showResetDialog(context),
          ),
        ],
      ),
      body: Consumer<ThemeViewModel>(
        builder: (context, themeViewModel, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Theme Mode Selection
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Theme Mode',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...AppThemeMode.values.map((mode) {
                          // ignore: deprecated_member_use
                          return RadioListTile<AppThemeMode>(
                            title: Text(mode.displayName),
                            subtitle: Text(_getThemeModeDescription(mode)),
                            value: mode,
                            // ignore: deprecated_member_use
                            groupValue: themeViewModel.themeMode,
                            // ignore: deprecated_member_use
                            onChanged: (value) {
                              if (value != null) {
                                themeViewModel.setThemeMode(value);
                              }
                            },
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Accent Color Picker
                ThemePalettePicker(
                  selectedColor: themeViewModel.accentColor,
                  onColorSelected: (color) {
                    themeViewModel.setAccentColor(color);
                  },
                ),
                const SizedBox(height: 16),

                // Font Scale Selector
                FontScaleSelector(
                  selectedScale: themeViewModel.fontScale,
                  onScaleSelected: (scale) {
                    themeViewModel.setFontScale(scale);
                  },
                ),
                const SizedBox(height: 16),

                // High Contrast Toggle
                ContrastToggleTile(
                  isEnabled: themeViewModel.highContrastMode,
                  onToggle: (_) {
                    themeViewModel.toggleHighContrastMode();
                  },
                ),
                const SizedBox(height: 24),

                // Preview Section
                _buildPreviewSection(context, themeViewModel),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getThemeModeDescription(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Always use light theme';
      case AppThemeMode.dark:
        return 'Always use dark theme';
      case AppThemeMode.system:
        return 'Follow system theme setting';
    }
  }

  Widget _buildPreviewSection(
      BuildContext context,
      ThemeViewModel themeViewModel,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Preview',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Headline Text',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Body text with current font scaling and color scheme. '
                    'This preview shows how your content will appear with the '
                    'selected theme settings.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {},
                    child: const Text('Sample Button'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showResetDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'Are you sure you want to reset all appearance settings to their default values?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final themeViewModel =
          Provider.of<ThemeViewModel>(context, listen: false);
      await themeViewModel.resetToDefaults();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

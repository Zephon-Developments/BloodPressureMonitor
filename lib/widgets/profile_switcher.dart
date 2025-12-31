import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/views/profile/profile_picker_view.dart';

/// Persistent profile switcher widget displayed in the app bar.
///
/// This widget provides a constant visual indicator of the currently active
/// profile and allows users to switch profiles by tapping. It displays:
/// - A circular avatar with the first letter of the profile name
/// - The profile name (truncated with ellipsis if too long)
/// - A dropdown arrow to indicate interactivity
///
/// The widget automatically updates when the active profile changes via
/// [ActiveProfileViewModel]. Tapping the widget opens [ProfilePickerView]
/// to allow profile selection.
///
/// This widget is designed to be placed in the app bar's `leading` position
/// and respects Material 3 theming for color contrast and accessibility.
///
/// Example usage:
/// ```dart
/// AppBar(
///   leading: const Padding(
///     padding: EdgeInsets.all(8.0),
///     child: ProfileSwitcher(),
///   ),
///   leadingWidth: 140,
/// )
/// ```
///
/// See also:
/// - [ProfilePickerView], which is opened when this widget is tapped
/// - [ActiveProfileViewModel], which provides the active profile data
class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ActiveProfileViewModel>(
      builder: (context, viewModel, _) {
        return InkWell(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (context) => const ProfilePickerView(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    viewModel.activeProfileName.isNotEmpty
                        ? viewModel.activeProfileName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 100),
                  child: Text(
                    viewModel.activeProfileName,
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }
}

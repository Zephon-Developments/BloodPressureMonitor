import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/views/profile/profile_form_view.dart';
import 'package:blood_pressure_monitor/widgets/common/confirm_delete_dialog.dart';

/// Profile selection screen shown after authentication when multiple profiles exist.
///
/// This screen displays all available profiles and allows the user to select
/// which profile to activate for the current session. It is typically shown
/// in two contexts:
/// 1. Immediately after the security gate (biometric/PIN authentication) when
///    the app detects multiple profiles in the database (no back button).
/// 2. When opened from the ProfileSwitcher in the app bar (shows back button).
///
/// The screen provides:
/// - A scrollable list of all profiles with avatars, names, and birth years
/// - Visual feedback during loading and error states
/// - The ability to add, edit, and delete profiles
/// - Edit and delete actions for each profile
/// - Automatic navigation back to home after successful profile selection
///
/// Example usage:
/// ```dart
/// // From security gate (mandatory selection)
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(
///     builder: (context) => const ProfilePickerView(allowBack: false),
///   ),
/// );
///
/// // From profile switcher (optional selection)
/// Navigator.of(context).push(
///   MaterialPageRoute<void>(
///     builder: (context) => const ProfilePickerView(),
///   ),
/// );
/// ```
///
/// See also:
/// - [ProfileSwitcher], which provides the persistent profile switcher widget
/// - [ActiveProfileViewModel], which manages the active profile state
/// - [ProfileFormView], which handles profile creation and editing
class ProfilePickerView extends StatefulWidget {
  const ProfilePickerView({
    super.key,
    this.onProfileSelected,
    this.allowBack = true,
  });

  /// Optional callback invoked after a profile is successfully selected.
  final VoidCallback? onProfileSelected;

  /// Whether to show a back button in the app bar.
  ///
  /// Set to `false` when shown as a mandatory step after authentication.
  /// Defaults to `true` for optional profile switching.
  final bool allowBack;

  @override
  State<ProfilePickerView> createState() => _ProfilePickerViewState();
}

class _ProfilePickerViewState extends State<ProfilePickerView> {
  List<Profile> _profiles = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final profileService = context.read<ProfileService>();
      final profiles = await profileService.getAllProfiles();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Failed to load profiles';
        _isLoading = false;
      });
    }
  }

  Future<void> _selectProfile(Profile profile) async {
    try {
      final activeProfileViewModel = context.read<ActiveProfileViewModel>();
      await activeProfileViewModel.setActive(profile);

      if (!mounted) return;

      // Invoke callback if provided (for embedded usage)
      widget.onProfileSelected?.call();

      // Navigate to home (pop this screen if pushed)
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select profile: $e')),
      );
    }
  }

  Future<void> _addNewProfile() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const ProfileFormView(),
      ),
    );

    if (result == true && mounted) {
      _loadProfiles();
    }
  }

  Future<void> _editProfile(Profile profile) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ProfileFormView(profile: profile),
      ),
    );

    if (result == true && mounted) {
      _loadProfiles();
    }
  }

  Future<void> _deleteProfile(Profile profile) async {
    final confirmed = await ConfirmDeleteDialog.show(
      context,
      title: 'Delete Profile',
      message:
          'Are you sure you want to delete "${profile.name}"? This will permanently delete all associated readings and health data.',
    );

    if (confirmed && mounted) {
      try {
        final viewModel = context.read<ActiveProfileViewModel>();
        await viewModel.deleteProfile(profile.id!);
        _loadProfiles();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: widget.allowBack,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfiles,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildProfileList(),
    );
  }

  Widget _buildProfileList() {
    if (_profiles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No profiles found'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addNewProfile,
              icon: const Icon(Icons.add),
              label: const Text('Add Profile'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _profiles.length + 1,
      itemBuilder: (context, index) {
        if (index == _profiles.length) {
          // Add new profile button at the end
          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.add),
              ),
              title: const Text('Add New Profile'),
              onTap: _addNewProfile,
            ),
          );
        }

        final profile = _profiles[index];
        final isActive =
            context.watch<ActiveProfileViewModel>().activeProfileId ==
                profile.id;

        return Card(
          elevation: isActive ? 4 : 1,
          shape: isActive
              ? RoundedRectangleBorder(
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: profile.colorHex != null
                  ? Color(int.parse(profile.colorHex!, radix: 16))
                  : Theme.of(context).colorScheme.primary,
              child: Text(
                profile.name.isNotEmpty ? profile.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              profile.name,
              style: TextStyle(
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: profile.dateOfBirth != null
                ? Text('Born: ${profile.dateOfBirth!.year}')
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  const Icon(Icons.check_circle, color: Colors.green),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editProfile(profile),
                  tooltip: 'Edit Profile',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteProfile(profile),
                  tooltip: 'Delete Profile',
                ),
              ],
            ),
            onTap: () => _selectProfile(profile),
          ),
        );
      },
    );
  }
}

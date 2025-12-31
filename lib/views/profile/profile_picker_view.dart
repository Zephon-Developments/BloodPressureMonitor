import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';

/// Profile selection screen shown after authentication when multiple profiles exist.
///
/// Allows users to select which profile to activate for the current session.
/// Supports adding new profiles and managing existing ones.
class ProfilePickerView extends StatefulWidget {
  const ProfilePickerView({super.key});

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

      // Navigate to home (pop this screen)
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to select profile: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
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
              onPressed: () {
                // TODO: Navigate to add profile screen
              },
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
              onTap: () {
                // TODO: Navigate to add profile screen
              },
            ),
          );
        }

        final profile = _profiles[index];
        return Card(
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
            title: Text(profile.name),
            subtitle: profile.yearOfBirth != null
                ? Text('Born: ${profile.yearOfBirth}')
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _selectProfile(profile),
          ),
        );
      },
    );
  }
}

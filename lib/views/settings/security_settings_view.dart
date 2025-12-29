import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';

/// Security settings screen for managing PIN, biometric auth, and idle timeout.
class SecuritySettingsView extends StatefulWidget {
  const SecuritySettingsView({super.key});

  @override
  State<SecuritySettingsView> createState() => _SecuritySettingsViewState();
}

class _SecuritySettingsViewState extends State<SecuritySettingsView> {
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lockViewModel = context.watch<LockViewModel>();
    final state = lockViewModel.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // PIN Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PIN Code',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.isPinSet ? 'PIN is currently set' : 'No PIN set',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () =>
                        _showChangePinDialog(context, lockViewModel),
                    icon: const Icon(Icons.lock_outline),
                    label: Text(state.isPinSet ? 'Change PIN' : 'Set PIN'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Biometric Section
          if (state.isBiometricAvailable)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Biometric Authentication',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use fingerprint or Face ID to unlock',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: state.isBiometricEnabled,
                      onChanged: state.isPinSet
                          ? (value) => _toggleBiometric(lockViewModel, value)
                          : null,
                      title: const Text('Enable Biometric'),
                      subtitle:
                          state.isPinSet ? null : const Text('Set a PIN first'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Idle Timeout Section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Auto-Lock Timeout',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lock app after inactivity',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  _buildTimeoutSelector(lockViewModel, state),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Security Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Security Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• All data is encrypted with AES-256\n'
                    '• PIN is hashed with PBKDF2\n'
                    '• App locks immediately when backgrounded\n'
                    '• Failed attempts trigger temporary lockout',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (state.failedAttempts > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Failed attempts: ${state.failedAttempts}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeoutSelector(LockViewModel lockViewModel, state) {
    final timeoutOptions = [
      (1, '1 minute'),
      (2, '2 minutes'),
      (5, '5 minutes'),
      (10, '10 minutes'),
      (30, '30 minutes'),
    ];

    return Column(
      children: timeoutOptions.map((option) {
        final (minutes, label) = option;
        // ignore: deprecated_member_use
        return RadioListTile<int>(
          value: minutes,
          // ignore: deprecated_member_use
          groupValue: state.idleTimeoutMinutes,
          // ignore: deprecated_member_use
          onChanged: (value) {
            if (value != null) {
              lockViewModel.setIdleTimeout(value);
            }
          },
          title: Text(label),
        );
      }).toList(),
    );
  }

  Future<void> _showChangePinDialog(
    BuildContext context,
    LockViewModel lockViewModel,
  ) async {
    final state = lockViewModel.state;
    _oldPinController.clear();
    _newPinController.clear();
    _confirmPinController.clear();

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(state.isPinSet ? 'Change PIN' : 'Set PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (state.isPinSet)
              TextField(
                controller: _oldPinController,
                decoration: const InputDecoration(
                  labelText: 'Current PIN',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
            if (state.isPinSet) const SizedBox(height: 16),
            TextField(
              controller: _newPinController,
              decoration: const InputDecoration(
                labelText: 'New PIN (6 digits)',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _confirmPinController,
              decoration: const InputDecoration(
                labelText: 'Confirm PIN',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _savePin(context, lockViewModel, state.isPinSet),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _savePin(
    BuildContext context,
    LockViewModel lockViewModel,
    bool isPinSet,
  ) async {
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (newPin.length != 6) {
      _showError(context, 'PIN must be 6 digits');
      return;
    }

    if (newPin != confirmPin) {
      _showError(context, 'PINs do not match');
      return;
    }

    if (isPinSet) {
      final oldPin = _oldPinController.text;
      final success = await lockViewModel.changePin(oldPin, newPin);

      if (!context.mounted) return;

      if (!success) {
        _showError(context, 'Current PIN is incorrect');
        return;
      }
    } else {
      await lockViewModel.setPin(newPin);
    }

    if (!context.mounted) return;

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN updated successfully')),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _toggleBiometric(
    LockViewModel lockViewModel,
    bool enabled,
  ) async {
    await lockViewModel.setBiometricEnabled(enabled);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? 'Biometric authentication enabled'
              : 'Biometric authentication disabled',
        ),
      ),
    );
  }
}

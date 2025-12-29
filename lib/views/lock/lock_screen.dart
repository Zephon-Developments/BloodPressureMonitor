import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';

/// Lock screen for PIN and biometric authentication.
///
/// Displays PIN entry keypad, biometric authentication button, and
/// lockout/error messaging. Prevents app switcher preview per security requirements.
class LockScreenView extends StatefulWidget {
  const LockScreenView({super.key});

  @override
  State<LockScreenView> createState() => _LockScreenViewState();
}

class _LockScreenViewState extends State<LockScreenView> with WidgetsBindingObserver {
  String _pin = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Clear entered PIN when app is backgrounded for security
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _pin = '';
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockViewModel = context.watch<LockViewModel>();
    final state = lockViewModel.state;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Icon/Logo
                Icon(
                  Icons.lock_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                  semanticLabel: 'Lock icon',
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Blood Pressure Monitor',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  state.isPinSet ? 'Enter PIN to unlock' : 'Set up a PIN',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Lockout warning or PIN dots
                if (state.isLockedOut)
                  _buildLockoutWarning(state)
                else ...[
                  _buildPinDots(),
                  const SizedBox(height: 16),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Keypad
                  _buildKeypad(lockViewModel, state),

                  // Biometric button
                  if (state.isBiometricEnabled && state.isPinSet) ...[
                    const SizedBox(height: 24),
                    _buildBiometricButton(lockViewModel),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLockoutWarning(state) {
    final remaining = state.lockoutRemainingSeconds;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Icon(
            Icons.timer_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            'Too many failed attempts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try again in ${minutes > 0 ? '${minutes}m ' : ''}${seconds}s',
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (index) {
        final isFilled = index < _pin.length;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isFilled
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 2,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeypad(LockViewModel lockViewModel, state) {
    return SizedBox(
      width: 300,
      child: Column(
        children: [
          _buildKeypadRow(['1', '2', '3'], lockViewModel, state),
          const SizedBox(height: 12),
          _buildKeypadRow(['4', '5', '6'], lockViewModel, state),
          const SizedBox(height: 12),
          _buildKeypadRow(['7', '8', '9'], lockViewModel, state),
          const SizedBox(height: 12),
          _buildKeypadRow(['', '0', 'delete'], lockViewModel, state),
        ],
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys, LockViewModel lockViewModel, state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) {
        if (key.isEmpty) {
          return const SizedBox(width: 80, height: 80);
        }

        if (key == 'delete') {
          return _buildDeleteButton();
        }

        return _buildNumberButton(key, lockViewModel, state);
      }).toList(),
    );
  }

  Widget _buildNumberButton(String number, LockViewModel lockViewModel, state) {
    return SizedBox(
      width: 80,
      height: 80,
      child: TextButton(
        onPressed: () => _onNumberPressed(number, lockViewModel, state),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: Text(
          number,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return SizedBox(
      width: 80,
      height: 80,
      child: IconButton(
        onPressed: _onDeletePressed,
        icon: const Icon(Icons.backspace_outlined),
        iconSize: 32,
        tooltip: 'Delete',
      ),
    );
  }

  Widget _buildBiometricButton(LockViewModel lockViewModel) {
    return OutlinedButton.icon(
      onPressed: () => _onBiometricPressed(lockViewModel),
      icon: const Icon(Icons.fingerprint),
      label: const Text('Use Biometric'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    );
  }

  void _onNumberPressed(String number, LockViewModel lockViewModel, state) async {
    if (_pin.length >= 6) return;

    setState(() {
      _pin += number;
      _errorMessage = null;
    });

    // Auto-submit when 6 digits entered
    if (_pin.length == 6) {
      await _submitPin(lockViewModel, state);
    }
  }

  void _onDeletePressed() {
    if (_pin.isEmpty) return;

    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  Future<void> _submitPin(LockViewModel lockViewModel, state) async {
    final pin = _pin;

    if (!state.isPinSet) {
      // Setting up initial PIN - would need confirmation flow
      // For now, just set it
      await lockViewModel.setPin(pin);
      setState(() {
        _pin = '';
      });
      return;
    }

    // Verify PIN
    final success = await lockViewModel.unlockWithPin(pin);

    if (!mounted) return;

    if (!success) {
      setState(() {
        _pin = '';
        final attempts = lockViewModel.state.failedAttempts;
        if (lockViewModel.state.isLockedOut) {
          _errorMessage = null; // Lockout warning will show instead
        } else if (attempts >= 10) {
          _errorMessage = 'Incorrect PIN. ${15 - attempts} attempts remaining.';
        } else if (attempts >= 5) {
          _errorMessage = 'Incorrect PIN. ${10 - attempts} attempts until lockout.';
        } else {
          _errorMessage = 'Incorrect PIN';
        }
      });
    }
  }

  Future<void> _onBiometricPressed(LockViewModel lockViewModel) async {
    final success = await lockViewModel.unlockWithBiometric();

    if (!mounted) return;

    if (!success) {
      setState(() {
        _errorMessage = 'Biometric authentication failed';
      });
    }
  }
}

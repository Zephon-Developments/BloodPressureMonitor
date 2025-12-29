import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blood_pressure_monitor/services/auth_service.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home_view.dart';
import 'package:blood_pressure_monitor/views/lock/lock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences for auth and settings
  final prefs = await SharedPreferences.getInstance();

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.database;

  // Initialize auth service
  final authService = AuthService(prefs: prefs);

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ProfileService>(create: (_) => ProfileService()),
        Provider<ReadingService>(create: (_) => ReadingService()),
        Provider<AveragingService>(create: (_) => AveragingService()),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<AuthService>.value(value: authService),
        ChangeNotifierProvider<LockViewModel>(
          create: (_) => LockViewModel(
            authService: authService,
            prefs: prefs,
          ),
        ),
        ChangeNotifierProvider<BloodPressureViewModel>(
          create: (context) => BloodPressureViewModel(
            context.read<ReadingService>(),
            context.read<AveragingService>(),
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Blood Pressure Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const _LockGate(),
    );
  }
}

/// Navigation gate that enforces lock screen when app is locked.
///
/// Also includes a privacy screen overlay that prevents sensitive data from
/// being visible in the app switcher when backgrounded.
class _LockGate extends StatefulWidget {
  const _LockGate();

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  bool _showPrivacyScreen = false;

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
    setState(() {
      // Show privacy screen when app is backgrounded/inactive to prevent
      // sensitive data from being visible in the app switcher
      _showPrivacyScreen = state == AppLifecycleState.paused ||
          state == AppLifecycleState.inactive ||
          state == AppLifecycleState.hidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lockViewModel = context.watch<LockViewModel>();

    Widget mainContent;
    if (lockViewModel.state.isLocked) {
      mainContent = const LockScreenView();
    } else {
      mainContent = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => lockViewModel.recordActivity(),
        onPanUpdate: (_) => lockViewModel.recordActivity(),
        child: const HomeView(),
      );
    }

    // Overlay privacy screen when app is backgrounded
    if (_showPrivacyScreen) {
      return Stack(
        children: [
          mainContent,
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite,
                    size: 80,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Blood Pressure Monitor',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return mainContent;
  }
}

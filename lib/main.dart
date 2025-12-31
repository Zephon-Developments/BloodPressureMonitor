import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/services/auth_service.dart';
import 'package:blood_pressure_monitor/services/averaging_service.dart';
import 'package:blood_pressure_monitor/services/correlation_service.dart';
import 'package:blood_pressure_monitor/services/database_service.dart';
import 'package:blood_pressure_monitor/services/history_service.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:blood_pressure_monitor/services/export_service.dart';
import 'package:blood_pressure_monitor/services/file_manager_service.dart';
import 'package:blood_pressure_monitor/services/import_service.dart';
import 'package:blood_pressure_monitor/services/pdf_report_service.dart';
import 'package:blood_pressure_monitor/services/app_info_service.dart';
import 'package:blood_pressure_monitor/services/theme_persistence_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/sleep_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/weight_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/export_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/file_manager_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/import_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/report_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_intake_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/theme_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home_view.dart';
import 'package:blood_pressure_monitor/views/lock/lock_screen.dart';
import 'package:blood_pressure_monitor/views/profile/profile_picker_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences for auth and settings
  final prefs = await SharedPreferences.getInstance();

  // Initialize database
  final databaseService = DatabaseService();
  await databaseService.database;

  // Initialize shared services once to keep dependencies narrow
  final readingService = ReadingService(databaseService: databaseService);
  final averagingService = AveragingService(
    databaseService: databaseService,
    readingService: readingService,
  );
  final historyService = HistoryService(
    databaseService: databaseService,
    readingService: readingService,
  );
  final weightService = WeightService(databaseService);
  final sleepService = SleepService(databaseService);
  final medicationService = MedicationService(databaseService);
  final intakeService = MedicationIntakeService(databaseService);
  final medicationGroupService = MedicationGroupService(databaseService);
  const appInfoService = AppInfoService();
  final analyticsService = AnalyticsService(
    readingService: readingService,
    sleepService: sleepService,
  );
  final correlationService = CorrelationService(
    readingService: readingService,
    weightService: weightService,
    sleepService: sleepService,
  );
  final exportService = ExportService(
    readingService: readingService,
    weightService: weightService,
    sleepService: sleepService,
    medicationService: medicationService,
    intakeService: intakeService,
    appInfoService: appInfoService,
  );
  final importService = ImportService(
    readingService: readingService,
    weightService: weightService,
    sleepService: sleepService,
    medicationService: medicationService,
    intakeService: intakeService,
  );
  final pdfReportService = PdfReportService(
    analyticsService: analyticsService,
    readingService: readingService,
    medicationService: medicationService,
  );
  final fileManagerService = FileManagerService();

  // Initialize auth service
  final authService = AuthService(prefs: prefs);

  // Initialize theme persistence service and view model
  final themePersistenceService = ThemePersistenceService(prefs);
  final themeViewModel = ThemeViewModel(themePersistenceService);

  // Initialize profile service
  final profileService = ProfileService();

  // Initialize and load active profile
  final activeProfileViewModel = ActiveProfileViewModel(
    profileService: profileService,
    prefs: prefs,
  );
  await activeProfileViewModel.loadInitial();

  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>.value(value: databaseService),
        Provider<ProfileService>.value(value: profileService),
        Provider<ReadingService>.value(value: readingService),
        Provider<AveragingService>.value(value: averagingService),
        Provider<HistoryService>.value(value: historyService),
        Provider<WeightService>.value(value: weightService),
        Provider<SleepService>.value(value: sleepService),
        Provider<MedicationService>.value(value: medicationService),
        Provider<MedicationIntakeService>.value(value: intakeService),
        Provider<MedicationGroupService>.value(value: medicationGroupService),
        Provider<AppInfoService>.value(value: appInfoService),
        Provider<AnalyticsService>.value(value: analyticsService),
        Provider<CorrelationService>.value(value: correlationService),
        Provider<ExportService>.value(value: exportService),
        Provider<FileManagerService>.value(value: fileManagerService),
        Provider<ImportService>.value(value: importService),
        Provider<PdfReportService>.value(value: pdfReportService),
        Provider<SharedPreferences>.value(value: prefs),
        Provider<AuthService>.value(value: authService),
        Provider<ThemePersistenceService>.value(value: themePersistenceService),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeViewModel),
        ChangeNotifierProvider<ActiveProfileViewModel>.value(
          value: activeProfileViewModel,
        ),
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
            context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<HistoryViewModel>(
          create: (context) => HistoryViewModel(
            context.read<HistoryService>(),
            context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<WeightViewModel>(
          create: (context) => WeightViewModel(
            context.read<WeightService>(),
            context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<SleepViewModel>(
          create: (context) => SleepViewModel(
            context.read<SleepService>(),
            context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<AnalyticsViewModel>(
          create: (context) => AnalyticsViewModel(
            analyticsService: context.read<AnalyticsService>(),
            activeProfileViewModel: context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<ExportViewModel>(
          create: (context) => ExportViewModel(
            exportService: context.read<ExportService>(),
          ),
        ),
        ChangeNotifierProvider<FileManagerViewModel>(
          create: (context) => FileManagerViewModel(
            fileManagerService: context.read<FileManagerService>(),
            exportService: context.read<ExportService>(),
            pdfReportService: context.read<PdfReportService>(),
            activeProfileViewModel: context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<ImportViewModel>(
          create: (context) => ImportViewModel(
            importService: context.read<ImportService>(),
          ),
        ),
        ChangeNotifierProvider<ReportViewModel>(
          create: (context) => ReportViewModel(
            pdfReportService: context.read<PdfReportService>(),
          ),
        ),
        ChangeNotifierProvider<MedicationViewModel>(
          create: (context) => MedicationViewModel(
            medicationService: context.read<MedicationService>(),
            medicationGroupService: context.read<MedicationGroupService>(),
            activeProfileViewModel: context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<MedicationIntakeViewModel>(
          create: (context) => MedicationIntakeViewModel(
            intakeService: context.read<MedicationIntakeService>(),
            medicationService: context.read<MedicationService>(),
            activeProfileViewModel: context.read<ActiveProfileViewModel>(),
          ),
        ),
        ChangeNotifierProvider<MedicationGroupViewModel>(
          create: (context) => MedicationGroupViewModel(
            groupService: context.read<MedicationGroupService>(),
            activeProfileViewModel: context.read<ActiveProfileViewModel>(),
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
    final themeViewModel = context.watch<ThemeViewModel>();

    return MaterialApp(
      title: 'HyperTrack',
      theme: themeViewModel.lightTheme,
      darkTheme: themeViewModel.darkTheme,
      themeMode: themeViewModel.materialThemeMode,
      home: const _LockGate(),
    );
  }
}

/// Navigation gate that enforces lock screen when app is locked.
///
/// Also includes a privacy screen overlay that prevents sensitive data from
/// being visible in the app switcher when backgrounded.
///
/// When unlocked, checks if multiple profiles exist and routes to
/// ProfilePickerView if necessary before showing HomeView.
class _LockGate extends StatefulWidget {
  const _LockGate();

  @override
  State<_LockGate> createState() => _LockGateState();
}

class _LockGateState extends State<_LockGate> with WidgetsBindingObserver {
  bool _showPrivacyScreen = false;
  bool _needsProfileSelection = false;
  bool _isCheckingProfiles = false;
  bool _hasCheckedProfiles = false;

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

  Future<void> _checkProfileSelection() async {
    if (_isCheckingProfiles || _hasCheckedProfiles) return;

    setState(() {
      _isCheckingProfiles = true;
    });

    try {
      final profileService = context.read<ProfileService>();
      final profiles = await profileService.getAllProfiles();

      if (!mounted) return;

      setState(() {
        _needsProfileSelection = profiles.length > 1;
        _isCheckingProfiles = false;
        _hasCheckedProfiles = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCheckingProfiles = false;
        _hasCheckedProfiles = true;
      });
    }
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
      // Reset profile selection state when locked
      if (_needsProfileSelection || _hasCheckedProfiles) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _needsProfileSelection = false;
              _hasCheckedProfiles = false;
            });
          }
        });
      }
      mainContent = const LockScreenView();
    } else {
      // Check if profile selection is needed after unlock
      if (!_hasCheckedProfiles && !_isCheckingProfiles) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkProfileSelection();
        });
      }

      // Show ProfilePickerView if multiple profiles exist
      if (_needsProfileSelection) {
        mainContent = Listener(
          onPointerDown: (_) => lockViewModel.recordActivity(),
          onPointerMove: (_) => lockViewModel.recordActivity(),
          child: ProfilePickerView(
            allowBack: false,
            onProfileSelected: () {
              if (mounted) {
                setState(() {
                  _needsProfileSelection = false;
                });
              }
            },
          ),
        );
      } else {
        // Wrap entire app content to track activity globally
        // This ensures navigation to other screens still records user activity
        mainContent = Listener(
          // Listen to all pointer events to catch interactions anywhere in the app
          onPointerDown: (_) => lockViewModel.recordActivity(),
          onPointerMove: (_) => lockViewModel.recordActivity(),
          child: const HomeView(),
        );
      }
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
                    'HyperTrack',
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

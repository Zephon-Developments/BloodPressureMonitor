import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/analytics.dart';
import 'package:blood_pressure_monitor/models/health_data.dart';
import 'package:blood_pressure_monitor/models/lock_state.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/history_home_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home_view.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/views/settings/security_settings_view.dart';
import 'package:blood_pressure_monitor/views/analytics/analytics_view.dart';

@GenerateMocks([BloodPressureViewModel, LockViewModel, HistoryHomeViewModel])
import 'home_view_test.mocks.dart';
import '../test_mocks.mocks.dart'
    show MockHistoryService, MockActiveProfileViewModel;
import '../viewmodels/analytics_viewmodel_test.mocks.dart'
    show MockAnalyticsService;

void main() {
  group('HomeView Widget Tests', () {
    late MockBloodPressureViewModel mockViewModel;
    late MockLockViewModel mockLockViewModel;
    late MockHistoryService mockHistoryService;
    late MockAnalyticsService mockAnalyticsService;
    late MockActiveProfileViewModel mockActiveProfileViewModel;
    late MockHistoryHomeViewModel mockHistoryHomeViewModel;
    late HistoryViewModel historyViewModel;
    late AnalyticsViewModel analyticsViewModel;

    setUp(() {
      mockViewModel = MockBloodPressureViewModel();
      mockLockViewModel = MockLockViewModel();
      mockHistoryService = MockHistoryService();
      mockAnalyticsService = MockAnalyticsService();
      mockActiveProfileViewModel = MockActiveProfileViewModel();
      mockHistoryHomeViewModel = MockHistoryHomeViewModel();
      when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
      when(mockActiveProfileViewModel.activeProfileName).thenReturn('Default');
      when(mockHistoryHomeViewModel.loadAllStats()).thenAnswer((_) async {});
      when(mockHistoryHomeViewModel.isLoading).thenReturn(false);
      when(mockHistoryHomeViewModel.bloodPressureStats).thenReturn(null);
      when(mockHistoryHomeViewModel.weightStats).thenReturn(null);
      when(mockHistoryHomeViewModel.sleepStats).thenReturn(null);
      when(mockHistoryHomeViewModel.medicationStats).thenReturn(null);
      when(mockHistoryHomeViewModel.isLoadingBP).thenReturn(false);
      when(mockHistoryHomeViewModel.isLoadingWeight).thenReturn(false);
      when(mockHistoryHomeViewModel.isLoadingSleep).thenReturn(false);
      when(mockHistoryHomeViewModel.isLoadingMedication).thenReturn(false);
      when(mockHistoryHomeViewModel.errorBP).thenReturn(null);
      when(mockHistoryHomeViewModel.errorWeight).thenReturn(null);
      when(mockHistoryHomeViewModel.errorSleep).thenReturn(null);
      when(mockHistoryHomeViewModel.errorMedication).thenReturn(null);
      when(mockViewModel.loadReadings()).thenAnswer((_) async {});
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([]);
      when(mockLockViewModel.state).thenReturn(AppLockState.initial());
      when(
        mockHistoryService.fetchGroupedHistory(
          profileId: anyNamed('profileId'),
          start: anyNamed('start'),
          end: anyNamed('end'),
          before: anyNamed('before'),
          limit: anyNamed('limit'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((_) async => <ReadingGroup>[]);
      when(
        mockHistoryService.fetchRawHistory(
          profileId: anyNamed('profileId'),
          start: anyNamed('start'),
          end: anyNamed('end'),
          before: anyNamed('before'),
          limit: anyNamed('limit'),
          tags: anyNamed('tags'),
        ),
      ).thenAnswer((_) async => <Reading>[]);
      when(mockHistoryService.fetchGroupMembers(any)).thenAnswer(
        (_) async => <Reading>[],
      );
      historyViewModel = HistoryViewModel(
        mockHistoryService,
        mockActiveProfileViewModel,
        clock: () => DateTime.utc(2025, 1, 1),
      );

      analyticsViewModel = AnalyticsViewModel(
        analyticsService: mockAnalyticsService,
        activeProfileViewModel: mockActiveProfileViewModel,
        clock: () => DateTime.utc(2025, 1, 10),
      );

      when(
        mockAnalyticsService.calculateStats(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        ),
      ).thenAnswer((_) async => _sampleStats());
      when(
        mockAnalyticsService.getChartData(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
          range: anyNamed('range'),
        ),
      ).thenAnswer((_) async => _sampleChart());
      when(
        mockAnalyticsService.getSleepCorrelation(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        ),
      ).thenAnswer((_) async => _sampleSleepCorrelation());
      when(
        mockAnalyticsService.getSleepStageSeries(
          profileId: anyNamed('profileId'),
          startDate: anyNamed('startDate'),
          endDate: anyNamed('endDate'),
        ),
      ).thenAnswer(
        (_) async => const SleepStageSeries(
          stages: [],
          hasIncompleteSessions: false,
        ),
      );
    });

    tearDown(() {
      historyViewModel.dispose();
      analyticsViewModel.dispose();
    });

    Widget createWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<ActiveProfileViewModel>.value(
            value: mockActiveProfileViewModel,
          ),
          ChangeNotifierProvider<BloodPressureViewModel>.value(
            value: mockViewModel,
          ),
          ChangeNotifierProvider<LockViewModel>.value(
            value: mockLockViewModel,
          ),
          ChangeNotifierProvider<HistoryViewModel>.value(
            value: historyViewModel,
          ),
          ChangeNotifierProvider<HistoryHomeViewModel>.value(
            value: mockHistoryHomeViewModel,
          ),
          ChangeNotifierProvider<AnalyticsViewModel>.value(
            value: analyticsViewModel,
          ),
        ],
        child: const MaterialApp(
          home: HomeView(),
        ),
      );
    }

    testWidgets('renders app bar with title', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.text('HealthLog'), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders security settings button in app bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.security), findsOneWidget);
    });

    testWidgets('navigates to security settings when button is tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.security));
      await tester.pumpAndSettle();

      expect(find.byType(SecuritySettingsView), findsOneWidget);
    });

    testWidgets('renders bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('bottom nav has 4 items', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      final bottomNav = tester.widget<BottomNavigationBar>(
        find.byType(BottomNavigationBar),
      );

      expect(bottomNav.items.length, 4);
      expect(bottomNav.items[0].label, 'Home');
      expect(bottomNav.items[1].label, 'History');
      expect(bottomNav.items[2].label, 'Charts');
      expect(bottomNav.items[3].label, 'Settings');
    });

    testWidgets('loads readings on init', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      verify(mockViewModel.loadReadings()).called(1);
    });

    testWidgets('displays home tab by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Should show Profile Homepage buttons
      expect(find.text('Log Blood Pressure / Pulse'), findsOneWidget);
      expect(find.text('Log Medication'), findsOneWidget);
      expect(find.text('Log Sleep'), findsOneWidget);
      expect(find.text('Log Weight'), findsOneWidget);
    });

    testWidgets('switches to history tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsAtLeastNWidgets(2));
      // HistoryHomeView has sections, not "Filters" and "No history yet"
      expect(find.text('Blood Pressure'), findsOneWidget);
      expect(find.text('Weight'), findsOneWidget);
      expect(find.text('Sleep'), findsOneWidget);
    });

    testWidgets('switches to charts tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

      expect(find.byType(AnalyticsView), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
    });

    testWidgets('switches to settings tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsNWidgets(2)); // Nav item + title

      // Scroll to find the items if they are off-screen
      await tester.drag(
        find.byType(ListView),
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('updates app bar title when tab changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially Home
      expect(find.text('HealthLog'), findsOneWidget);

      // Switch to History
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('History'), findsAtLeastNWidgets(2));

      // Switch to Charts
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      expect(find.text('Charts'), findsNWidgets(2));

      // Switch to Settings
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsNWidgets(2));
    });

    testWidgets('quick actions navigates to add reading view',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Blood Pressure / Pulse'));
      await tester.pumpAndSettle();

      expect(find.byType(AddReadingView), findsOneWidget);
    });

    testWidgets('shows history empty state and charts content',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // History stub
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      // HistoryHomeView shows section titles even when empty
      expect(find.text('Blood Pressure'), findsOneWidget);

      // Charts stub
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      expect(find.byType(AnalyticsView), findsOneWidget);
      expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
    });

    testWidgets('settings tab has Appearance and About items enabled',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      // Scroll to bottom to ensure all items are built
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      final appearanceTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Appearance'),
          matching: find.byType(ListTile),
        ),
      );
      final aboutTile = tester.widget<ListTile>(
        find.ancestor(of: find.text('About'), matching: find.byType(ListTile)),
      );

      // Phase 17 enabled these items
      expect(appearanceTile.enabled, isTrue);
      expect(aboutTile.enabled, isTrue);
    });
  });
}

HealthStats _sampleStats() {
  return HealthStats(
    minSystolic: 120,
    avgSystolic: 125,
    maxSystolic: 130,
    minDiastolic: 80,
    avgDiastolic: 82,
    maxDiastolic: 85,
    minPulse: 65,
    avgPulse: 68,
    maxPulse: 72,
    systolicStdDev: 2,
    systolicCv: 1.5,
    diastolicStdDev: 1,
    diastolicCv: 1.2,
    pulseStdDev: 1.5,
    pulseCv: 2,
    split: const MorningEveningSplit(
      morning: ReadingBucketStats(
        count: 1,
        minSystolic: 120,
        avgSystolic: 122,
        maxSystolic: 125,
        minDiastolic: 80,
        avgDiastolic: 82,
        maxDiastolic: 84,
        minPulse: 65,
        avgPulse: 67,
        maxPulse: 70,
      ),
      evening: ReadingBucketStats(
        count: 1,
        minSystolic: 126,
        avgSystolic: 128,
        maxSystolic: 130,
        minDiastolic: 83,
        avgDiastolic: 84,
        maxDiastolic: 85,
        minPulse: 70,
        avgPulse: 71,
        maxPulse: 72,
      ),
      morningCount: 1,
      eveningCount: 1,
    ),
    totalReadings: 2,
    periodStart: DateTime.utc(2025, 1, 1),
    periodEnd: DateTime.utc(2025, 1, 7),
  );
}

ChartDataSet _sampleChart() {
  final now = DateTime.utc(2025, 1, 1);
  return ChartDataSet(
    systolicPoints: [
      ChartPoint(timestamp: now, value: 120),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 125),
    ],
    diastolicPoints: [
      ChartPoint(timestamp: now, value: 80),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 82),
    ],
    pulsePoints: [
      ChartPoint(timestamp: now, value: 68),
      ChartPoint(timestamp: now.add(const Duration(days: 1)), value: 70),
    ],
    minDate: now,
    maxDate: now.add(const Duration(days: 1)),
  );
}

SleepCorrelationData _sampleSleepCorrelation() {
  final date = DateTime(2025, 1, 2);
  final reading = ReadingGroup(
    id: 1,
    profileId: 1,
    groupStartAt: date,
    avgSystolic: 125,
    avgDiastolic: 82,
    avgPulse: 68,
    memberReadingIds: '1',
  );
  final sleep = SleepEntry(
    id: 1,
    profileId: 1,
    startedAt: date.subtract(const Duration(hours: 7)),
    endedAt: date,
    durationMinutes: 420,
    deepMinutes: 100,
    lightMinutes: 200,
    remMinutes: 80,
    awakeMinutes: 40,
    quality: 4,
  );

  return SleepCorrelationData(
    sleepByDate: {date: SleepQualityLevel.good},
    morningReadings: {date: reading},
    correlationPoints: [
      CorrelationPoint(date: date, sleepEntry: sleep, reading: reading),
    ],
  );
}

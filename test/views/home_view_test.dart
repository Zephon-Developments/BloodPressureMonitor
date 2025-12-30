import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/lock_state.dart';
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/history_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/lock_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home_view.dart';
import 'package:blood_pressure_monitor/views/readings/add_reading_view.dart';
import 'package:blood_pressure_monitor/views/settings/security_settings_view.dart';

@GenerateMocks([BloodPressureViewModel, LockViewModel])
import 'home_view_test.mocks.dart';
import '../test_mocks.mocks.dart' show MockHistoryService;

void main() {
  group('HomeView Widget Tests', () {
    late MockBloodPressureViewModel mockViewModel;
    late MockLockViewModel mockLockViewModel;
    late MockHistoryService mockHistoryService;
    late HistoryViewModel historyViewModel;

    setUp(() {
      mockViewModel = MockBloodPressureViewModel();
      mockLockViewModel = MockLockViewModel();
      mockHistoryService = MockHistoryService();
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
        clock: () => DateTime.utc(2025, 1, 1),
      );
    });

    tearDown(() {
      historyViewModel.dispose();
    });

    Widget createWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<BloodPressureViewModel>.value(
            value: mockViewModel,
          ),
          ChangeNotifierProvider<LockViewModel>.value(
            value: mockLockViewModel,
          ),
          ChangeNotifierProvider<HistoryViewModel>.value(
            value: historyViewModel,
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

      expect(find.text('Blood Pressure Monitor'), findsOneWidget);
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

      // Should show Quick Actions and Recent Readings
      expect(find.text('Quick Actions'), findsOneWidget);
      expect(find.text('Recent Readings'), findsOneWidget);
    });

    testWidgets('switches to history tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsAtLeastNWidgets(2));
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('No history yet'), findsOneWidget);
    });

    testWidgets('switches to charts tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();

      expect(find.text('Charts & Analytics'), findsOneWidget);
      expect(find.text('Coming in Phase 8'), findsOneWidget);
    });

    testWidgets('switches to settings tab when tapped',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsNWidgets(2)); // Nav item + title
      expect(find.text('Reminders'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('updates app bar title when tab changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // Initially Home
      expect(find.text('Blood Pressure Monitor'), findsOneWidget);

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

      await tester.tap(find.text('Add Blood Pressure Reading'));
      await tester.pumpAndSettle();

      expect(find.byType(AddReadingView), findsOneWidget);
    });

    testWidgets('shows history empty state and charts stub',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      // History stub
      await tester.tap(find.text('History'));
      await tester.pumpAndSettle();
      expect(find.text('No history yet'), findsOneWidget);

      // Charts stub
      await tester.tap(find.text('Charts'));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.analytics), findsNWidgets(2)); // Nav + stub
    });

    testWidgets('settings tab items are disabled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      final listTiles = tester.widgetList<ListTile>(
        find.byType(ListTile),
      );

      // Security should be enabled, others disabled
      int disabledCount = 0;
      for (final tile in listTiles) {
        if (tile.enabled == false) {
          disabledCount++;
        }
      }

      expect(disabledCount, 3); // Reminders, Appearance, About
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/views/home/widgets/recent_readings_card.dart';

@GenerateMocks([BloodPressureViewModel])
import 'recent_readings_card_test.mocks.dart';

void main() {
  group('RecentReadingsCard Widget Tests', () {
    late MockBloodPressureViewModel mockViewModel;

    setUp(() {
      mockViewModel = MockBloodPressureViewModel();
    });

    Widget createWidget() {
      return ChangeNotifierProvider<BloodPressureViewModel>.value(
        value: mockViewModel,
        child: const MaterialApp(
          home: Scaffold(
            body: RecentReadingsCard(),
          ),
        ),
      );
    }

    testWidgets('renders title', (WidgetTester tester) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([]);

      await tester.pumpWidget(createWidget());

      expect(find.text('Recent Readings'), findsOneWidget);
    });

    testWidgets('shows loading indicator when loading',
        (WidgetTester tester) async {
      when(mockViewModel.isLoading).thenReturn(true);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([]);

      await tester.pumpWidget(createWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message when error occurs',
        (WidgetTester tester) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn('Failed to load readings');
      when(mockViewModel.readings).thenReturn([]);

      await tester.pumpWidget(createWidget());

      expect(find.text('Failed to load readings'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('shows empty state when no readings',
        (WidgetTester tester) async {
      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([]);

      await tester.pumpWidget(createWidget());

      expect(find.text('No readings yet'), findsOneWidget);
      expect(
        find.text('Add your first blood pressure reading'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
    });

    testWidgets('displays up to 5 recent readings',
        (WidgetTester tester) async {
      final readings = List.generate(
        10,
        (i) => Reading(
          id: i,
          profileId: 1,
          systolic: 120 + i,
          diastolic: 80 + i,
          pulse: 70 + i,
          takenAt: DateTime.now().subtract(Duration(hours: i)),
          localOffsetMinutes: 0,
        ),
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn(readings);

      await tester.pumpWidget(createWidget());

      // Should show max 5 readings
      expect(find.byType(ListTile), findsNWidgets(5));
    });

    testWidgets('displays reading values correctly',
        (WidgetTester tester) async {
      final reading = Reading(
        id: 1,
        profileId: 1,
        systolic: 125,
        diastolic: 85,
        pulse: 72,
        takenAt: DateTime(2025, 12, 29, 10, 30),
        localOffsetMinutes: 0,
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([reading]);

      await tester.pumpWidget(createWidget());

      // Should display systolic/diastolic
      expect(find.textContaining('125'), findsOneWidget);
      expect(find.textContaining('85'), findsOneWidget);

      // Should display pulse
      expect(find.textContaining('72'), findsOneWidget);
    });

    testWidgets('shows divider between readings', (WidgetTester tester) async {
      final readings = List.generate(
        3,
        (i) => Reading(
          id: i,
          profileId: 1,
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          takenAt: DateTime.now().subtract(Duration(hours: i)),
          localOffsetMinutes: 0,
        ),
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn(readings);

      await tester.pumpWidget(createWidget());

      // Should have dividers between items (3 readings = 2 dividers)
      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('wraps each reading in a Slidable for delete actions',
        (WidgetTester tester) async {
      final reading = Reading(
        id: 99,
        profileId: 1,
        systolic: 118,
        diastolic: 78,
        pulse: 68,
        takenAt: DateTime(2025, 1, 2, 9, 15),
        localOffsetMinutes: 0,
      );

      when(mockViewModel.isLoading).thenReturn(false);
      when(mockViewModel.error).thenReturn(null);
      when(mockViewModel.readings).thenReturn([reading]);

      await tester.pumpWidget(createWidget());

      expect(find.byType(Slidable), findsOneWidget);
    });
  });
}

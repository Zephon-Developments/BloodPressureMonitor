import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:blood_pressure_monitor/views/about_view.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    // Mock package_info_plus
    PackageInfo.setMockInitialValues(
      appName: 'HyperTrack',
      packageName: 'com.zephondevelopments.hypertrack',
      version: '1.3.0',
      buildNumber: '3',
      buildSignature: '',
      installerStore: null,
    );
  });

  group('AboutView', () {
    testWidgets('displays app name and version info', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // Should show HyperTrack title
      expect(find.text('HyperTrack'), findsAtLeastNWidgets(1));

      // Should show version and build number
      expect(find.textContaining('Version'), findsOneWidget);
      expect(find.textContaining('Build'), findsOneWidget);
    });

    testWidgets('displays About HyperTrack section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('About HyperTrack'), findsOneWidget);
      expect(
        find.textContaining('A private, offline health data logger'),
        findsOneWidget,
      );
    });

    testWidgets('displays Zephon Developments developer section',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Developed by Zephon Developments'),
        findsOneWidget,
      );
      expect(find.text('Website'), findsOneWidget);
    });

    testWidgets('displays medical disclaimer section', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Medical Disclaimer'), findsOneWidget);
      expect(
        find.textContaining('HyperTrack is not a medical device'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
            'Always consult a qualified healthcare professional'),
        findsOneWidget,
      );
    });

    testWidgets('displays copyright notice', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('© 2025 Zephon Developments'), findsOneWidget);
    });

    testWidgets('shows loading indicator initially', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // After settling, loading should be gone
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('website link tile has correct properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      final websiteTile = find.ancestor(
        of: find.text('Website'),
        matching: find.byType(ListTile),
      );

      expect(websiteTile, findsOneWidget);
      expect(
        find.descendant(
          of: websiteTile,
          matching: find.text('www.zephon.org'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('has scrollable content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('displays logo container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have an image widget or error builder icon
      final imageWidgets = find.byType(Image);
      expect(imageWidgets, findsAtLeastNWidgets(1));
    });

    testWidgets('all cards are present', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutView(),
        ),
      );

      await tester.pumpAndSettle();

      // Should have cards for: About, Developer, License
      expect(find.byType(Card), findsAtLeastNWidgets(3));
    });
  });
}

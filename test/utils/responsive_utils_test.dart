import 'package:blood_pressure_monitor/utils/responsive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveUtils', () {
    testWidgets('identifies orientation correctly', (tester) async {
      // Landscape Large
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Placeholder(),
          ),
        ),
      );

      final context = tester.element(find.byType(Placeholder));
      expect(ResponsiveUtils.isLandscape(context), isTrue);
      expect(ResponsiveUtils.isTablet(context), isTrue);
    });

    testWidgets('columnsFor honors width thresholds', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      Future<int> getColumns(Size size) async {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Placeholder(),
            ),
          ),
        );
        final context = tester.element(find.byType(Placeholder));
        return ResponsiveUtils.columnsFor(context, maxColumns: 3);
      }

      expect(await getColumns(const Size(400, 800)), 1);
      expect(await getColumns(const Size(800, 400)), 2);
      expect(await getColumns(const Size(1100, 700)), 3);
    });

    testWidgets('chart height switches with orientation', (tester) async {
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());
      addTearDown(() => tester.view.resetDevicePixelRatio());

      Future<double> getHeight(Size size) async {
        tester.view.physicalSize = size;
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: Placeholder(),
            ),
          ),
        );
        final context = tester.element(find.byType(Placeholder));
        return ResponsiveUtils.chartHeightFor(
          context,
          portraitHeight: 300,
          landscapeHeight: 200,
        );
      }

      expect(await getHeight(const Size(500, 900)), 300);
      expect(await getHeight(const Size(900, 500)), 200);
    });
  });
}

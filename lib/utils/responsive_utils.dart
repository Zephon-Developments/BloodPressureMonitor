import 'package:flutter/material.dart';

/// Responsive helpers for determining orientation, breakpoints, and layout sizing.
class ResponsiveUtils {
  const ResponsiveUtils._();

  /// Tablets and large foldable panes typically expose a shortest side ≥600dp.
  static const double tabletShortestSideThreshold = 600;

  /// Breakpoint at which a third column comfortably fits.
  static const double threeColumnWidthThreshold = 900;

  /// Breakpoint for activating two-column layouts on landscape phones.
  static const double twoColumnWidthThreshold = 720;

  /// Returns true when the provided [context] is currently in landscape.
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  /// Returns true when display shortest side meets the tablet threshold.
  static bool isTablet(BuildContext context) {
    return MediaQuery.sizeOf(context).shortestSide >=
        tabletShortestSideThreshold;
  }

  /// Derives an appropriate column count for the given [context].
  ///
  /// [maxColumns] constrains the upper bound (defaults to 2). A single column
  /// is always returned for narrow layouts.
  static int columnsFor(
    BuildContext context, {
    int maxColumns = 2,
  }) {
    assert(maxColumns >= 1, 'maxColumns must be at least 1');

    final size = MediaQuery.sizeOf(context);
    final width = size.width;
    final landscape = isLandscape(context);
    final tablet = isTablet(context);

    var columns = 1;
    if (maxColumns >= 2 && (tablet || width >= twoColumnWidthThreshold)) {
      columns = 2;
    }

    if (maxColumns >= 3 && landscape && width >= threeColumnWidthThreshold) {
      columns = 3;
    }

    return columns.clamp(1, maxColumns);
  }

  /// Selects a chart height based on orientation.
  static double chartHeightFor(
    BuildContext context, {
    double portraitHeight = 320,
    double landscapeHeight = 240,
  }) {
    return isLandscape(context) ? landscapeHeight : portraitHeight;
  }
}

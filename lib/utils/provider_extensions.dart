import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'package:blood_pressure_monitor/viewmodels/analytics_viewmodel.dart';

/// Extension helpers for safely reading optional providers.
extension ProviderReadExtensions on BuildContext {
  /// Reads a provider if it exists, otherwise returns null without throwing.
  T? readOrNull<T>() {
    try {
      return read<T>();
    } on ProviderNotFoundException {
      return null;
    }
  }

  /// Invalidates cached analytics and eagerly reloads the data pipeline.
  void refreshAnalyticsData({bool forceOverlayRefresh = false}) {
    final analytics = readOrNull<AnalyticsViewModel>();
    if (analytics == null) {
      return;
    }
    analytics.invalidateCache();
    unawaited(
      analytics.loadData(
        forceRefresh: true,
        forceOverlayRefresh: forceOverlayRefresh,
      ),
    );
  }
}

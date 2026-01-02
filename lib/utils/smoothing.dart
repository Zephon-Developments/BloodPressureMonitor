import 'dart:math' as math;

/// Utility class for smoothing data using rolling average algorithm.
class Smoothing {
  /// Applies a rolling average smoothing to the input data.
  ///
  /// Window size is calculated as max(1, ceil(0.1 * data.length)).
  /// Uses centered window with edge padding (replicating edge values).
  ///
  /// Returns a list of the same length as the input with smoothed values.
  static List<double> rollingAverage(List<double> data) {
    if (data.isEmpty) {
      return <double>[];
    }

    if (data.length == 1) {
      return List<double>.from(data);
    }

    final windowSize = calculateWindowSize(data.length);
    final halfWindow = windowSize ~/ 2;
    final n = data.length;
    final smoothed = List<double>.filled(n, 0.0);

    // Initial window sum (centered at index 0)
    // Indices from -halfWindow to +halfWindow
    double currentSum = 0.0;
    for (int j = -halfWindow; j <= halfWindow; j++) {
      currentSum += data[j.clamp(0, n - 1)];
    }

    final divisor = (2 * halfWindow + 1).toDouble();
    smoothed[0] = currentSum / divisor;

    for (int i = 1; i < n; i++) {
      // Slide window: remove (i - 1 - halfWindow), add (i + halfWindow)
      final oldIdx = (i - 1 - halfWindow).clamp(0, n - 1);
      final newIdx = (i + halfWindow).clamp(0, n - 1);
      
      currentSum = currentSum - data[oldIdx] + data[newIdx];
      smoothed[i] = currentSum / divisor;
    }

    return smoothed;
  }

  /// Calculates the optimal window size for given data length.
  ///
  /// Window size = max(1, ceil(0.1 * N))
  static int calculateWindowSize(int dataLength) {
    if (dataLength <= 0) {
      return 1;
    }
    return math.max(1, (0.1 * dataLength).ceil());
  }
}

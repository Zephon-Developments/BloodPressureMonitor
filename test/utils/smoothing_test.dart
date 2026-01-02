import 'package:blood_pressure_monitor/utils/smoothing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Smoothing', () {
    group('calculateWindowSize', () {
      test('returns 1 for very small datasets', () {
        expect(Smoothing.calculateWindowSize(1), 1);
        expect(Smoothing.calculateWindowSize(5), 1);
      });

      test('returns 10% window for typical datasets', () {
        expect(Smoothing.calculateWindowSize(50), 5);
        expect(Smoothing.calculateWindowSize(100), 10);
        expect(Smoothing.calculateWindowSize(200), 20);
      });

      test('handles edge cases correctly', () {
        expect(Smoothing.calculateWindowSize(0), 1);
        expect(Smoothing.calculateWindowSize(9), 1);
        expect(Smoothing.calculateWindowSize(10), 1);
        expect(Smoothing.calculateWindowSize(11), 2);
      });
    });

    group('rollingAverage', () {
      test('returns empty list for empty input', () {
        final result = Smoothing.rollingAverage([]);
        expect(result, isEmpty);
      });

      test('returns single value unchanged', () {
        final result = Smoothing.rollingAverage([5.0]);
        expect(result, [5.0]);
      });

      test('smooths simple dataset correctly', () {
        final data = [1.0, 2.0, 3.0, 4.0, 5.0];
        final result = Smoothing.rollingAverage(data);

        // Window size = ceil(0.1 * 5) = 1, so should be unchanged
        expect(result, [1.0, 2.0, 3.0, 4.0, 5.0]);
      });

      test('smooths larger dataset with proper window', () {
        final data = List.generate(20, (i) => (i + 1).toDouble());
        final result = Smoothing.rollingAverage(data);

        // Window size = ceil(0.1 * 20) = 2, halfWindow = 1
        // First point (i=0): average of indices [-1, 0, 1] = (1 + 1 + 2) / 3 = 1.333
        expect(result[0], closeTo(1.333, 0.001));
        // Middle point (i=10): average of indices [9, 10, 11] = (10 + 11 + 12) / 3 = 11.0
        expect(result[10], closeTo(11.0, 0.001));
        // Last point (i=19): average of indices [18, 19, 20] = (19 + 20 + 20) / 3 = 19.666
        expect(result[19], closeTo(19.666, 0.001));
      });

      test('edge replication works correctly', () {
        final data = [
          10.0,
          20.0,
          30.0,
          40.0,
          50.0,
          60.0,
          70.0,
          80.0,
          90.0,
          100.0,
        ];
        final result = Smoothing.rollingAverage(data);

        // Window size = ceil(0.1 * 10) = 1
        // Since window is 1, all values unchanged
        expect(result, data);
      });

      test('handles datasets requiring larger window', () {
        final data = List.generate(50, (i) => (i + 1).toDouble());
        final result = Smoothing.rollingAverage(data);

        // Window size = ceil(0.1 * 50) = 5, halfWindow = 2
        expect(result.length, data.length);
        // First point: average of indices [-2, -1, 0, 1, 2] = (1 + 1 + 1 + 2 + 3) / 5 = 1.6
        expect(result.first, closeTo(1.6, 0.1));
        // Last point: average of indices [47, 48, 49, 50, 51] = (48 + 49 + 50 + 50 + 50) / 5 = 49.4
        expect(result.last, closeTo(49.4, 0.1));
      });

      test('preserves ascending trend after smoothing', () {
        final data = List.generate(30, (i) => (i + 1).toDouble());
        final result = Smoothing.rollingAverage(data);

        // Check that smoothed data still trends upward
        for (var i = 1; i < result.length; i++) {
          expect(result[i], greaterThan(result[i - 1]));
        }
      });

      test('reduces variance compared to raw data', () {
        final data = [
          5.0,
          15.0,
          10.0,
          20.0,
          15.0,
          25.0,
          20.0,
          30.0,
          25.0,
          35.0,
          30.0,
          40.0,
          35.0,
          45.0,
          40.0,
          50.0,
          45.0,
          55.0,
          50.0,
          60.0,
        ];
        final result = Smoothing.rollingAverage(data);

        // Compute variance for both datasets
        double variance(List<double> values) {
          final mean = values.reduce((a, b) => a + b) / values.length;
          final squaredDiffs = values.map((v) => (v - mean) * (v - mean));
          return squaredDiffs.reduce((a, b) => a + b) / values.length;
        }

        expect(variance(result), lessThan(variance(data)));
      });

      test('handles repeated values correctly', () {
        final data = List.filled(20, 50.0);
        final result = Smoothing.rollingAverage(data);

        // All values should remain 50.0
        expect(result, List.filled(20, 50.0));
      });
    });
  });
}

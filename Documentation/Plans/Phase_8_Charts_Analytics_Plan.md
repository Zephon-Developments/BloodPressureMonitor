# Phase 8 Plan — Charts & Analytics

## Objectives
- Deliver interactive blood pressure charts with clinical banding for systolic, diastolic, and pulse metrics.
- Provide statistical summaries (min/avg/max, variability, morning/evening split) in accessible card format.
- Support time-range filtering (7d, 30d, 90d, 1y, all-time) with smooth data transitions.
- Normalize sleep data to include morning-after date, get-up time, and stage durations (deep, light, REM, awake) for correlation and visualization.
- Deliver a stacked area chart for sleep stages alongside BP charts.
- Maintain performance with large datasets (1000+ readings) through efficient queries and caching.
- Achieve coverage targets: Services/ViewModels ≥85%, Widgets ≥70%.

## Scope & Assumptions
- **In-scope**: Chart widgets with clinical banding, statistics dashboard, time-range selectors, morning/evening split, sleep correlation overlay, sleep stage data prep (date/get-up/stages), analytics service layer, viewmodel orchestration, comprehensive testing.
- **Out-of-scope**: Predictive analytics, health advice, export/PDF generation (Phase 9), medication correlation charts (future enhancement).
- **Assumptions**: 
  - Averaging engine (Phase 2) provides stable grouped data
  - Sleep tracking (Phase 4) available for correlation overlay
  - UI shell (Phase 6) and navigation ready
  - History service (Phase 7) patterns reusable for data access
  - Clinical banding thresholds: NICE HBPM (<135/85 normal, 135-149/85-89 stage 1, 150-169/95-114 stage 2, ≥170/≥115 stage 3)
  - Data store can be reset for Phase 8; no legacy rows require migration or backfill

## Dependencies
- **Phase 2**: Averaging engine and `ReadingGroup` model
- **Phase 4**: `SleepEntry` model and `SleepService` for correlation (requires schema extension for stage breakdown and get-up time)
- **Phase 6**: Navigation shell and Material 3 theme
- **Phase 7**: Pagination patterns and service architecture
- **External**: `fl_chart` package for chart rendering
- **Standards**: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md) compliance; updated sleep schema definitions (no migration required)

---

## Architecture & Data Flow

### Service Layer

#### AnalyticsService
New service at `lib/services/analytics_service.dart`:

**Responsibilities**:
- Query reading groups within time range
- Calculate statistical metrics (min/avg/max, standard deviation)
- Classify readings by time-of-day (morning vs evening)
- Prepare chart data points with efficient sampling
- Correlate sleep data with morning readings
- Aggregate sleep stage breakdowns per session (deep, light, REM, awake),
  aligned to the morning-after date and get-up time
- Produce stacked-area-ready series for sleep stages

**Key Methods**:
```dart
class AnalyticsService {
  final ReadingService _readingService;
  final SleepService _sleepService;
  
  // Statistical calculations
  Future<HealthStats> calculateStats({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
  });
  
  // Chart data preparation
  Future<ChartDataSet> getChartData({
    required int profileId,
    required TimeRange range,
    int maxPoints = 90, // Cap for performance
  });
  
  // Time-of-day classification
  List<ReadingGroup> classifyByTimeOfDay(
    List<ReadingGroup> groups,
    TimeOfDay cutoff, // Default 12:00 PM
  );
  
  // Sleep correlation
  Future<SleepCorrelationData> getSleepCorrelation({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
  });

  // Sleep stage stacked area data
  Future<SleepStageSeries> getSleepStageSeries({
    required int profileId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
```

**Data Structures**:
```dart
class HealthStats {
  final double minSystolic, avgSystolic, maxSystolic;
  final double minDiastolic, avgDiastolic, maxDiastolic;
  final double minPulse, avgPulse, maxPulse;
  final double systolicStdDev, diastolicStdDev, pulseStdDev;
  final MorningEveningStats split;
  final int totalReadings;
  final DateTime periodStart, periodEnd;
}

class MorningEveningStats {
  final HealthStats morning;
  final HealthStats evening;
  final int morningCount;
  final int eveningCount;
}

class ChartDataSet {
  final List<ChartPoint> systolicPoints;
  final List<ChartPoint> diastolicPoints;
  final List<ChartPoint> pulsePoints;
  final DateTime minDate, maxDate;
  final bool isSampled; // True if data was downsampled
}

class ChartPoint {
  final DateTime timestamp;
  final double value;
  final bool isAveraged;
  final int? groupId;
}

class SleepStageBreakdown {
  final DateTime sessionDate; // Morning-after date (endedAt local date)
  final DateTime? getUpTime;  // endedAt timestamp
  final int deepMinutes;
  final int lightMinutes;
  final int remMinutes;
  final int awakeMinutes;
}

class SleepStageSeries {
  final List<SleepStageBreakdown> stages;
  final bool hasIncompleteSessions; // True if any stage data missing
}

class SleepCorrelationData {
  final Map<DateTime, SleepQuality> sleepByDate;
  final Map<DateTime, ReadingGroup> morningReadings;
  final List<CorrelationPoint> correlationPoints;
  final SleepStageSeries stageSeries;
}
```

**Performance Optimization**:
- Use indexed queries on `timestamp` and `profileId`
- Implement smart downsampling for ranges >90 days (daily averages)
- Cache statistics for current time range (invalidate on new data)
- Batch queries for morning/evening split to avoid N+1 queries

### ViewModel Layer

#### AnalyticsViewModel
New viewmodel at `lib/viewmodels/analytics_viewmodel.dart`:

**Responsibilities**:
- Manage time range selection state
- Orchestrate data loading from `AnalyticsService`
- Format data for chart consumption
- Handle loading, error, and empty states
- Cache computed data to minimize recalculations
- Expose user interactions (time range change, chart zoom)

**State Management**:
```dart
class AnalyticsViewModel extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  
  // State
  TimeRange _selectedRange = TimeRange.thirtyDays;
  HealthStats? _stats;
  ChartDataSet? _chartData;
  SleepCorrelationData? _sleepData;
  SleepStageSeries? _sleepStages;
  bool _isLoading = false;
  String? _error;
  bool _showSleepOverlay = false;
  
  // Getters
  TimeRange get selectedRange => _selectedRange;
  HealthStats? get stats => _stats;
  ChartDataSet? get chartData => _chartData;
  SleepStageSeries? get sleepStages => _sleepStages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasData => _chartData?.systolicPoints.isNotEmpty ?? false;
  
  // Actions
  Future<void> loadData(int profileId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final (startDate, endDate) = _selectedRange.toDateRange();
      
      final results = await Future.wait([
        _analyticsService.calculateStats(
          profileId: profileId,
          startDate: startDate,
          endDate: endDate,
        ),
        _analyticsService.getChartData(
          profileId: profileId,
          range: _selectedRange,
        ),
        if (_showSleepOverlay)
          _analyticsService.getSleepCorrelation(
            profileId: profileId,
            startDate: startDate,
            endDate: endDate,
          ),
        if (_showSleepOverlay)
          _analyticsService.getSleepStageSeries(
            profileId: profileId,
            startDate: startDate,
            endDate: endDate,
          ),
      ]);
      
      _stats = results[0] as HealthStats;
      _chartData = results[1] as ChartDataSet;
      if (_showSleepOverlay && results.length > 2) {
        _sleepData = results[2] as SleepCorrelationData;
        _sleepStages = results.length > 3
            ? results[3] as SleepStageSeries
            : null;
      }
    } catch (e) {
      _error = 'Failed to load analytics data';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void setTimeRange(TimeRange range) {
    if (_selectedRange != range) {
      _selectedRange = range;
      _clearCache();
      notifyListeners();
    }
  }
  
  void toggleSleepOverlay() {
    _showSleepOverlay = !_showSleepOverlay;
    notifyListeners();
  }
}

enum TimeRange {
  sevenDays,
  thirtyDays,
  ninetyDays,
  oneYear,
  allTime;
  
  (DateTime, DateTime) toDateRange() {
    final now = DateTime.now();
    switch (this) {
      case TimeRange.sevenDays:
        return (now.subtract(const Duration(days: 7)), now);
      case TimeRange.thirtyDays:
        return (now.subtract(const Duration(days: 30)), now);
      case TimeRange.ninetyDays:
        return (now.subtract(const Duration(days: 90)), now);
      case TimeRange.oneYear:
        return (now.subtract(const Duration(days: 365)), now);
      case TimeRange.allTime:
        return (DateTime(2000), now); // Practical minimum
    }
  }
}
```

**Caching Strategy**:
- Store last-loaded data with timestamp and range key
- Invalidate cache on new reading creation (via listener)
- Reuse cached data when switching back to previously viewed range
- Cache TTL: 5 minutes for real-time accuracy vs performance balance

---

## UI Components

### View Structure
```
lib/views/analytics/
├── analytics_view.dart           # Main analytics screen
├── widgets/
│   ├── time_range_selector.dart  # 7d/30d/90d/1y/all chips
│   ├── stats_card_grid.dart      # Statistics summary cards
│   ├── bp_line_chart.dart        # Systolic + diastolic combo chart
│   ├── pulse_line_chart.dart     # Pulse trend chart
│   ├── sleep_stacked_area_chart.dart # Sleep stages stacked area
│   ├── chart_legend.dart         # Clinical band legend
│   ├── morning_evening_card.dart # AM/PM split stats
│   ├── sleep_overlay_toggle.dart # Toggle for sleep correlation
│   └── analytics_empty_state.dart # No data placeholder
└── painters/
    └── clinical_band_painter.dart # Custom painter for bands
```

### AnalyticsView
Main screen at `lib/views/analytics/analytics_view.dart`:

**Layout**:
```dart
class AnalyticsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          Consumer<AnalyticsViewModel>(
            builder: (context, vm, _) => IconButton(
              icon: Icon(
                vm.showSleepOverlay 
                  ? Icons.bedtime 
                  : Icons.bedtime_outlined,
              ),
              onPressed: vm.toggleSleepOverlay,
              tooltip: 'Sleep Correlation',
            ),
          ),
        ],
      ),
      body: Consumer<AnalyticsViewModel>(
        builder: (context, viewModel, _) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (viewModel.error != null) {
            return Center(child: Text(viewModel.error!));
          }
          
          if (!viewModel.hasData) {
            return const AnalyticsEmptyState();
          }
          
          return RefreshIndicator(
            onRefresh: () => viewModel.loadData(
              context.read<ProfileViewModel>().currentProfile.id,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TimeRangeSelector(),
                  const SizedBox(height: 16),
                  const StatsCardGrid(),
                  const SizedBox(height: 24),
                  const ChartLegend(),
                  const SizedBox(height: 8),
                  const BpLineChart(),
                  const SizedBox(height: 24),
                  const PulseLineChart(),
                  const SizedBox(height: 24),
                  if (viewModel.showSleepOverlay)
                    const SleepStackedAreaChart(),
                  const SizedBox(height: 24),
                  const MorningEveningCard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
```

### TimeRangeSelector
Segmented button group at `lib/views/analytics/widgets/time_range_selector.dart`:

```dart
class TimeRangeSelector extends StatelessWidget {
  const TimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        return SegmentedButton<TimeRange>(
          segments: const [
            ButtonSegment(value: TimeRange.sevenDays, label: Text('7d')),
            ButtonSegment(value: TimeRange.thirtyDays, label: Text('30d')),
            ButtonSegment(value: TimeRange.ninetyDays, label: Text('90d')),
            ButtonSegment(value: TimeRange.oneYear, label: Text('1y')),
            ButtonSegment(value: TimeRange.allTime, label: Text('All')),
          ],
          selected: {viewModel.selectedRange},
          onSelectionChanged: (Set<TimeRange> newSelection) {
            viewModel.setTimeRange(newSelection.first);
            viewModel.loadData(
              context.read<ProfileViewModel>().currentProfile.id,
            );
          },
        );
      },
    );
  }
}
```

### BpLineChart
Combined systolic/diastolic chart with clinical banding:

**Chart Features**:
- Dual lines (systolic solid, diastolic dashed)
- Background bands (green/yellow/red per clinical thresholds)
- Interactive tooltips on tap
- Shared x-axis with formatted date labels
- Smooth curves with cubic interpolation
- Legend overlay

**Implementation**:
```dart
class BpLineChart extends StatelessWidget {
  const BpLineChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        final chartData = viewModel.chartData!;
        
        return AspectRatio(
          aspectRatio: 1.5,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                lineBarsData: [
                  _buildSystolicLine(chartData.systolicPoints),
                  _buildDiastolicLine(chartData.diastolicPoints),
                ],
                titlesData: _buildTitles(chartData),
                gridData: const FlGridData(show: true),
                borderData: FlBorderData(show: true),
                backgroundColor: Colors.transparent,
                minY: 40,
                maxY: 200,
                // Banding via extraLinesData (NICE HBPM)
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    // Green zone (Normal < 135)
                    HorizontalLine(
                      y: 67.5, // Center of 0-135
                      color: Colors.green.withOpacity(0.1),
                      strokeWidth: 135, 
                    ),
                    // Yellow zone (Stage 1: 135-149)
                    HorizontalLine(
                      y: 142, // Center of 135-149
                      color: Colors.yellow.withOpacity(0.1),
                      strokeWidth: 14,
                    ),
                    // Orange zone (Stage 2: 150-169)
                    HorizontalLine(
                      y: 159.5, // Center of 150-169
                      color: Colors.orange.withOpacity(0.1),
                      strokeWidth: 19,
                    ),
                    // Red zone (Stage 3: >= 170)
                    HorizontalLine(
                      y: 185, // Center of 170-200
                      color: Colors.red.withOpacity(0.1),
                      strokeWidth: 30,
                    ),
                  ],
                ),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: _buildTooltips,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  LineChartBarData _buildSystolicLine(List<ChartPoint> points) {
    return LineChartBarData(
      spots: points
          .map((p) => FlSpot(
                p.timestamp.millisecondsSinceEpoch.toDouble(),
                p.value,
              ))
          .toList(),
      isCurved: true,
      color: Colors.red.shade700,
      barWidth: 2,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
  
  LineChartBarData _buildDiastolicLine(List<ChartPoint> points) {
    return LineChartBarData(
      spots: points
          .map((p) => FlSpot(
                p.timestamp.millisecondsSinceEpoch.toDouble(),
                p.value,
              ))
          .toList(),
      isCurved: true,
      color: Colors.blue.shade700,
      barWidth: 2,
      dashArray: [5, 5],
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: false),
    );
  }
}
```

### StatsCardGrid
Statistics summary cards:

```dart
class StatsCardGrid extends StatelessWidget {
  const StatsCardGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        final stats = viewModel.stats!;
        
        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              title: 'Systolic',
              min: stats.minSystolic,
              avg: stats.avgSystolic,
              max: stats.maxSystolic,
              unit: 'mmHg',
              color: Colors.red.shade100,
            ),
            _StatCard(
              title: 'Diastolic',
              min: stats.minDiastolic,
              avg: stats.avgDiastolic,
              max: stats.maxDiastolic,
              unit: 'mmHg',
              color: Colors.blue.shade100,
            ),
            _StatCard(
              title: 'Pulse',
              min: stats.minPulse,
              avg: stats.avgPulse,
              max: stats.maxPulse,
              unit: 'bpm',
              color: Colors.purple.shade100,
            ),
            _VariabilityCard(
              systolicStdDev: stats.systolicStdDev,
              diastolicStdDev: stats.diastolicStdDev,
              pulseStdDev: stats.pulseStdDev,
            ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final double min, avg, max;
  final String unit;
  final Color color;

  const _StatCard({
    required this.title,
    required this.min,
    required this.avg,
    required this.max,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${avg.round()} $unit',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Range: ${min.round()}-${max.round()}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

### MorningEveningCard
AM/PM split statistics:

```dart
class MorningEveningCard extends StatelessWidget {
  const MorningEveningCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        final split = viewModel.stats?.split;
        if (split == null) return const SizedBox.shrink();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Morning vs Evening',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SplitColumn(
                        label: 'Morning',
                        stats: split.morning,
                        count: split.morningCount,
                        icon: Icons.wb_sunny,
                      ),
                    ),
                    const VerticalDivider(),
                    Expanded(
                      child: _SplitColumn(
                        label: 'Evening',
                        stats: split.evening,
                        count: split.eveningCount,
                        icon: Icons.nightlight_round,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

### SleepStackedAreaChart
Stacked area visualization for sleep stages (deep, light, REM, awake), aligned
to the morning-after date and get-up time:

```dart
class SleepStackedAreaChart extends StatelessWidget {
  const SleepStackedAreaChart({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AnalyticsViewModel>(
      builder: (context, viewModel, _) {
        final stages = viewModel.sleepStages;
        if (stages == null) return const SizedBox.shrink();

        return AspectRatio(
          aspectRatio: 1.6,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StackedAreaChart(
                series: stages.stages,
                showLegend: true,
                hasIncompleteData: stages.hasIncompleteSessions,
              ),
            ),
          ),
        );
      },
    );
  }
}
```

**Notes**:
- X-axis uses morning-after date (from `endedAt` local date) and optionally
  renders a marker for get-up time.
- Y-axis uses minutes; stacked to total sleep duration for that session.
- Legend colors: deep (navy), light (blue), REM (purple), awake (red, low
  opacity).
- Supports partial data (imports without stage breakdown) via `hasIncompleteData`
  banner.

### Sleep Correlation Overlay
Optional chart annotation showing sleep quality:

**Implementation**:
- Add vertical line annotations to chart at dates with sleep data
- Color-code by sleep quality (poor red, fair yellow, good green)
- Show tooltip with sleep hours and quality on tap
- Maintain chart readability (semi-transparent markers)
- Drive stacked area series from `SleepStageSeries` (deep/light/REM/awake) and
  align annotations to the morning-after date and get-up time.

---

## Clinical Banding Specifications

### Blood Pressure Categories (NICE HBPM Guidance)

| Category | Systolic (mmHg) | Diastolic (mmHg) | Color | Opacity |
|----------|-----------------|------------------|-------|---------|
| Normal | <135 | <85 | Green | 0.1 |
| Stage 1 | 135-149 | 85-89 | Yellow | 0.15 |
| Stage 2 | 150-169 | 95-114 | Orange | 0.2 |
| Stage 3 | ≥170 | ≥115 | Red | 0.25 |

**Special Cases**:
- **Isolated Systolic Hypertension**: Systolic ≥140 AND Diastolic <90 (NICE definition varies, but for visualization, flag systolic-only elevation)
  - Marker: Orange dot on chart
  - Tooltip annotation: "Isolated systolic elevation"

### Implementation Notes
- Banding applies to background zones, not data point coloring
- Use horizontal line spans in `fl_chart` `extraLinesData`
- Ensure sufficient contrast for accessibility (WCAG AA)
- Include text legend below charts for colorblind users
- **Note**: These thresholds follow NICE HBPM (Home Blood Pressure Monitoring) standards, which are lower than clinic-based thresholds.

---

## Performance Strategy

### Data Optimization
1. **Smart Downsampling**:
   - 7d range: Use all raw points (typically <50)
   - 30d range: Use all points if <100, otherwise daily averages
   - 90d range: Always use daily averages
   - 1y+ range: Use weekly averages
   - Indicate sampling in chart subtitle

2. **Efficient Queries**:
   ```sql
   -- Example query for time range with limit
   SELECT * FROM reading_groups
   WHERE profile_id = ? 
     AND taken_at BETWEEN ? AND ?
   ORDER BY taken_at DESC
   LIMIT 365; -- Cap even for "all time"
   ```

3. **Computation Caching**:
   - Cache statistics in viewmodel with range key
   - Invalidate on new reading via event listener
   - Use `compute()` isolate for std deviation calculation if >500 points

4. **Chart Rendering**:
   - Use `const` constructors for static widgets
   - Implement `RepaintBoundary` around charts
   - Debounce time range changes (300ms) to prevent rapid reloads

### Memory Management
- Dispose chart controllers in widget `dispose()`
- Clear cached data when navigating away from analytics
- Limit `ChartDataSet` retention to current + previous range only

---

## Testing Strategy

### Unit Tests (Target: ≥85% coverage)

#### AnalyticsService Tests
File: `test/services/analytics_service_test.dart`

**Test Cases**:
```dart
group('AnalyticsService', () {
  late AnalyticsService service;
  late MockReadingService mockReadingService;
  late MockSleepService mockSleepService;
  
  setUp(() {
    mockReadingService = MockReadingService();
    mockSleepService = MockSleepService();
    service = AnalyticsService(mockReadingService, mockSleepService);
  });
  
  group('calculateStats', () {
    test('calculates correct min/avg/max for known dataset', () async {
      // Given: 3 readings with known values
      when(mockReadingService.getGroupsInRange(any, any, any))
          .thenAnswer((_) async => [
                ReadingGroup(
                  id: 1,
                  systolic: 120,
                  diastolic: 80,
                  pulse: 70,
                  takenAt: DateTime(2025, 1, 1, 10),
                ),
                ReadingGroup(
                  id: 2,
                  systolic: 130,
                  diastolic: 85,
                  pulse: 75,
                  takenAt: DateTime(2025, 1, 2, 10),
                ),
                ReadingGroup(
                  id: 3,
                  systolic: 140,
                  diastolic: 90,
                  pulse: 80,
                  takenAt: DateTime(2025, 1, 3, 10),
                ),
              ]);
      
      // When
      final stats = await service.calculateStats(
        profileId: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3),
      );
      
      // Then
      expect(stats.minSystolic, 120);
      expect(stats.avgSystolic, 130);
      expect(stats.maxSystolic, 140);
      expect(stats.systolicStdDev, closeTo(10.0, 0.1));
    });
    
    test('handles empty dataset gracefully', () async {
      when(mockReadingService.getGroupsInRange(any, any, any))
          .thenAnswer((_) async => []);
      
      final stats = await service.calculateStats(
        profileId: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3),
      );
      
      expect(stats.totalReadings, 0);
      expect(stats.avgSystolic, 0);
    });
    
    test('handles single reading without errors', () async {
      when(mockReadingService.getGroupsInRange(any, any, any))
          .thenAnswer((_) async => [
                ReadingGroup(
                  id: 1,
                  systolic: 120,
                  diastolic: 80,
                  pulse: 70,
                  takenAt: DateTime(2025, 1, 1, 10),
                ),
              ]);
      
      final stats = await service.calculateStats(
        profileId: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 3),
      );
      
      expect(stats.minSystolic, 120);
      expect(stats.avgSystolic, 120);
      expect(stats.maxSystolic, 120);
      expect(stats.systolicStdDev, 0);
    });
  });
  
  group('classifyByTimeOfDay', () {
    test('correctly splits morning and evening readings', () {
      final groups = [
        ReadingGroup(
          id: 1,
          systolic: 120,
          diastolic: 80,
          pulse: 70,
          takenAt: DateTime(2025, 1, 1, 8), // 8 AM
        ),
        ReadingGroup(
          id: 2,
          systolic: 130,
          diastolic: 85,
          pulse: 75,
          takenAt: DateTime(2025, 1, 1, 14), // 2 PM
        ),
        ReadingGroup(
          id: 3,
          systolic: 140,
          diastolic: 90,
          pulse: 80,
          takenAt: DateTime(2025, 1, 1, 20), // 8 PM
        ),
      ];
      
      final result = service.classifyByTimeOfDay(
        groups,
        const TimeOfDay(hour: 12, minute: 0),
      );
      
      expect(result.morning.length, 1);
      expect(result.evening.length, 2);
      expect(result.morning.first.id, 1);
    });
    
    test('handles boundary case at cutoff time', () {
      final group = ReadingGroup(
        id: 1,
        systolic: 120,
        diastolic: 80,
        pulse: 70,
        takenAt: DateTime(2025, 1, 1, 12, 0), // Exactly 12:00 PM
      );
      
      final result = service.classifyByTimeOfDay(
        [group],
        const TimeOfDay(hour: 12, minute: 0),
      );
      
      expect(result.evening.length, 1); // Boundary goes to evening
    });
  });
  
  group('getChartData', () {
    test('applies downsampling for large datasets', () async {
      // Create 200 daily readings
      final largeDataset = List.generate(
        200,
        (i) => ReadingGroup(
          id: i,
          systolic: 120 + i % 20,
          diastolic: 80,
          pulse: 70,
          takenAt: DateTime(2024, 1, 1).add(Duration(days: i)),
        ),
      );
      
      when(mockReadingService.getGroupsInRange(any, any, any))
          .thenAnswer((_) async => largeDataset);
      
      final chartData = await service.getChartData(
        profileId: 1,
        range: TimeRange.allTime,
        maxPoints: 90,
      );
      
      expect(chartData.systolicPoints.length, lessThanOrEqualTo(90));
      expect(chartData.isSampled, true);
    });
  });
  
  group('getSleepCorrelation', () {
    test('correlates sleep with morning readings', () async {
      when(mockSleepService.getEntriesInRange(any, any, any))
          .thenAnswer((_) async => [
                SleepEntry(
                  id: 1,
                  profileId: 1,
                  date: DateTime(2025, 1, 1),
                  totalMinutes: 420,
                  quality: SleepQuality.good,
                ),
              ]);
      
      when(mockReadingService.getGroupsInRange(any, any, any))
          .thenAnswer((_) async => [
                ReadingGroup(
                  id: 1,
                  systolic: 120,
                  diastolic: 80,
                  pulse: 70,
                  takenAt: DateTime(2025, 1, 1, 8), // Morning after good sleep
                ),
              ]);
      
      final correlation = await service.getSleepCorrelation(
        profileId: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 2),
      );
      
      expect(correlation.sleepByDate.length, 1);
      expect(correlation.morningReadings.length, 1);
      expect(correlation.correlationPoints.length, 1);
    });
  });

  group('getSleepStageSeries', () {
    test('aggregates stage minutes and flags incomplete data', () async {
      when(mockSleepService.getEntriesInRange(any, any, any))
          .thenAnswer((_) async => [
                SleepEntry(
                  id: 1,
                  profileId: 1,
                  startedAt: DateTime(2025, 1, 1, 22),
                  endedAt: DateTime(2025, 1, 2, 6, 30),
                  deepMinutes: 120,
                  lightMinutes: 180,
                  remMinutes: 60,
                  awakeMinutes: 30,
                ),
                SleepEntry(
                  id: 2,
                  profileId: 1,
                  startedAt: DateTime(2025, 1, 2, 23),
                  endedAt: DateTime(2025, 1, 3, 7),
                  durationMinutes: 480, // Missing stages
                ),
              ]);

      final series = await service.getSleepStageSeries(
        profileId: 1,
        startDate: DateTime(2025, 1, 1),
        endDate: DateTime(2025, 1, 4),
      );

      expect(series.stages.length, 2);
      expect(series.stages.first.sessionDate, DateTime(2025, 1, 2));
      expect(series.stages.first.deepMinutes, 120);
      expect(series.hasIncompleteSessions, true);
    });
  });
});
```

### ViewModel Tests (Target: ≥85% coverage)

#### AnalyticsViewModel Tests
File: `test/viewmodels/analytics_viewmodel_test.dart`

**Test Cases**:
- Time range selection triggers data reload
- Loading state managed correctly during data fetch
- Error state exposed when service throws
- Cache invalidation on new reading event
- Sleep overlay toggle updates state
- Sleep stage series available when overlay enabled
- Empty data state handled gracefully

### Widget Tests (Target: ≥70% coverage)

#### AnalyticsView Tests
File: `test/views/analytics/analytics_view_test.dart`

**Test Cases**:
```dart
group('AnalyticsView', () {
  testWidgets('renders loading indicator during data fetch', (tester) async {
    final mockViewModel = MockAnalyticsViewModel();
    when(mockViewModel.isLoading).thenReturn(true);
    when(mockViewModel.error).thenReturn(null);
    
    await tester.pumpWidget(
      _buildTestApp(mockViewModel),
    );
    
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('renders empty state when no data', (tester) async {
    final mockViewModel = MockAnalyticsViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.hasData).thenReturn(false);
    when(mockViewModel.error).thenReturn(null);
    
    await tester.pumpWidget(
      _buildTestApp(mockViewModel),
    );
    
    expect(find.byType(AnalyticsEmptyState), findsOneWidget);
  });
  
  testWidgets('renders charts when data available', (tester) async {
    final mockViewModel = MockAnalyticsViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.hasData).thenReturn(true);
    when(mockViewModel.error).thenReturn(null);
    when(mockViewModel.stats).thenReturn(_createMockStats());
    when(mockViewModel.chartData).thenReturn(_createMockChartData());
    when(mockViewModel.showSleepOverlay).thenReturn(true);
    when(mockViewModel.sleepStages).thenReturn(_createMockSleepStages());
    
    await tester.pumpWidget(
      _buildTestApp(mockViewModel),
    );
    
    expect(find.byType(BpLineChart), findsOneWidget);
    expect(find.byType(PulseLineChart), findsOneWidget);
    expect(find.byType(StatsCardGrid), findsOneWidget);
    expect(find.byType(SleepStackedAreaChart), findsOneWidget);
  });
  
  testWidgets('time range selector triggers data reload', (tester) async {
    final mockViewModel = MockAnalyticsViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.hasData).thenReturn(true);
    when(mockViewModel.selectedRange).thenReturn(TimeRange.thirtyDays);
    when(mockViewModel.stats).thenReturn(_createMockStats());
    when(mockViewModel.chartData).thenReturn(_createMockChartData());
    
    await tester.pumpWidget(
      _buildTestApp(mockViewModel),
    );
    
    await tester.tap(find.text('7d'));
    await tester.pump();
    
    verify(mockViewModel.setTimeRange(TimeRange.sevenDays)).called(1);
  });
  
  testWidgets('sleep overlay toggle updates icon', (tester) async {
    final mockViewModel = MockAnalyticsViewModel();
    when(mockViewModel.isLoading).thenReturn(false);
    when(mockViewModel.hasData).thenReturn(true);
    when(mockViewModel.showSleepOverlay).thenReturn(false);
    when(mockViewModel.stats).thenReturn(_createMockStats());
    when(mockViewModel.chartData).thenReturn(_createMockChartData());
    
    await tester.pumpWidget(
      _buildTestApp(mockViewModel),
    );
    
    expect(find.byIcon(Icons.bedtime_outlined), findsOneWidget);
    
    when(mockViewModel.showSleepOverlay).thenReturn(true);
    await tester.tap(find.byIcon(Icons.bedtime_outlined));
    await tester.pump();
    
    verify(mockViewModel.toggleSleepOverlay()).called(1);
  });
});
```

#### Chart Widget Tests
File: `test/views/analytics/widgets/bp_line_chart_test.dart`

**Test Cases**:
- Chart renders with sample data
- Banding zones render at correct y-values
- Tooltips display on tap
- Legend displays correctly
- Empty data shows placeholder

### Integration Tests (Optional)
File: `integration_test/analytics_flow_test.dart`

**Scenarios**:
- Navigate to analytics → see charts → change time range → data updates
- Add new reading → return to analytics → stats refresh
- Toggle sleep overlay → correlation markers appear

---

## Implementation Sequence

### Phase 1: Foundation (Days 1-2)
1. Extend sleep schema (stage minutes, endedAt as get-up time), update models/validators/services (fresh schema, no migration needed).
2. Add `fl_chart` dependency to `pubspec.yaml`
3. Create data models (`HealthStats`, `ChartDataSet`, `SleepStageSeries`, etc.)
4. Implement `AnalyticsService` with basic stat calculations and sleep stage aggregation
5. Write unit tests for `AnalyticsService`

### Phase 2: ViewModel (Day 3)
6. Implement `AnalyticsViewModel` with state management
7. Add caching logic and invalidation
8. Write unit tests for `AnalyticsViewModel`

### Phase 3: Basic UI (Days 4-5)
9. Create `AnalyticsView` scaffold with navigation
10. Implement `TimeRangeSelector` and `StatsCardGrid`
11. Add loading/error/empty states
12. Write widget tests for basic UI

### Phase 4: Charts (Days 6-7)
13. Implement `BpLineChart` with banding
14. Implement `PulseLineChart`
15. Add `ChartLegend` and tooltips
16. Write widget tests for charts

### Phase 5: Advanced Features (Day 8)
17. Implement `MorningEveningCard` with split stats
18. Add `SleepStackedAreaChart` (stacked stages) and wire to overlay toggle
19. Add sleep correlation overlay (optional annotations)
20. Implement downsampling logic
21. Write tests for advanced features

### Phase 6: Polish & Performance (Day 9)
22. Add chart animations and transitions
23. Optimize query performance
24. Implement caching improvements
25. Conduct performance profiling

### Phase 7: Testing & Documentation (Day 10)
26. Achieve coverage targets (run `flutter test --coverage`)
27. Fix analyzer warnings (`flutter analyze`)
28. Add DartDoc comments to public APIs
29. Update user documentation

---

## Risk Assessment & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Chart performance degrades with large datasets | Medium | High | Implement smart downsampling; cap data points; use `compute()` for heavy calculations |
| Clinical banding colors not accessible | Low | Medium | Add text legend; ensure WCAG AA contrast; test with colorblind simulators |
| fl_chart API changes in updates | Low | Low | Pin version in pubspec; test before upgrading |
| Sleep correlation complexity delays delivery | Medium | Low | Mark as optional; ship without if blocked |
| Statistical calculation errors | Low | High | Use well-tested algorithms; validate with known datasets; add property tests |
| Memory leaks from chart controllers | Medium | Medium | Ensure proper disposal; use DevTools memory profiler |
| Sleep schema implementation gaps | Medium | Medium | Add unit tests for schema/model changes; ensure null-safe stage handling; show incomplete-data banner where fields missing |

---

## Acceptance Criteria

### Functional Requirements
- [x] Charts render systolic, diastolic, and pulse trends
- [x] Clinical banding displays correctly (<130/85 green, 130-139/85-89 yellow, ≥140/90 red)
- [x] Time range selector works (7d/30d/90d/1y/all)
- [x] Statistics cards show min/avg/max, variability, morning/evening split
- [x] Sleep correlation overlay functional (optional)
- [x] Sleep stages stacked area chart renders deep/light/REM/awake, aligned to
  morning-after date and get-up time
- [x] Sleep data includes stage durations and get-up time for each session
- [x] Smooth performance with 1000+ readings

### Technical Requirements
- [x] `flutter analyze` passes with zero warnings
- [x] All tests pass (`flutter test`)
- [x] Coverage: Services ≥85%, ViewModels ≥85%, Widgets ≥70%
- [x] Code follows [Coding_Standards.md](../Standards/Coding_Standards.md)
- [x] DartDoc comments on public APIs
- [x] Proper resource disposal (controllers, subscriptions)
- [x] Sleep schema updated with stage fields; validators enforce stage totals
  and duration alignment

### UX Requirements
- [x] Charts load within 500ms for typical datasets
- [x] Accessible labels and legend for colorblind users
- [x] Responsive layout on phones and tablets
- [x] Clear empty state when no data available
- [x] Pull-to-refresh updates data

---

## Rollback Strategy

If Phase 8 encounters blockers:

1. **Ship without sleep correlation**: Mark overlay as "coming soon" and complete basic charts first
2. **Reduce time range options**: Ship with 7d/30d/90d only; defer 1y/all to Phase 8.5
3. **Simplified statistics**: Ship with min/avg/max only; defer variability and split to Phase 8.5
4. **Feature flag**: Hide analytics tab behind debug flag until fully tested

**Rollback point**: Merge foundation (service/viewmodel) even if UI incomplete; enable when polished.

---

## Dependencies & Packages

### New Dependencies
```yaml
dependencies:
  fl_chart: ^0.68.0  # Chart rendering
  
dev_dependencies:
  mockito: ^5.4.4    # Already present for mocking
  build_runner: ^2.4.8  # For mock generation
```

### Existing Dependencies
- `provider`: State management
- `sqflite_sqlcipher`: Data persistence
- `flutter_test`: Testing framework

---

## Handoff Checklist

Before handing to Clive for review:

- [ ] All sections of this plan complete and detailed
- [ ] Architecture diagrams clear (if added)
- [ ] Acceptance criteria measurable and aligned with schedule
- [ ] Testing strategy covers all components
- [ ] Performance considerations documented
- [ ] Risk assessment complete with mitigations
- [ ] Implementation sequence realistic (10-day estimate)
- [ ] Rollback strategy defined
- [ ] Dependencies identified and justified
- [ ] Plan references Coding_Standards.md throughout

---

**Prepared by**: Tracy (Planning Specialist)  
**Date**: 2025-12-30  
**Next Step**: Hand off to Clive for plan review via [Tracy_to_Clive.md](../Handoffs/Tracy_to_Clive.md)

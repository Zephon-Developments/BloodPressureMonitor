# Phase 23 Plan: Analytics Graph Overhaul

**Objective**: Redesign analytics graphs with dual Y-axis BP charts, smoothing toggle, and improved clarity to replace misleading Bezier curves.

## Current State (Audit)
- **Phase 8**: Analytics view implemented with BP line chart, pulse chart, stats cards, time-range selector.
- **User Feedback**: Bezier curves curl inappropriately and mislead users; want raw line graphs by default with optional smoothing.
- **User Feedback**: BP chart should use dual Y-axis layout (systolic upper, diastolic lower) with color-coded zones and clear separation.
- **Gap**: Current chart uses single Y-axis; Bezier interpolation is default; no smoothing toggle.

## Scope
- Replace Bezier curves with raw line graphs as default for all charts.
- Add smoothing toggle (rolling average, window = 10% of readings) for all graph types.
- Redesign BP graph with dual Y-axis layout:
  - **Upper Y-axis**: Systolic (50-200 mmHg) with color zones (red 180-200, yellow 140-179, green 90-139, yellow 50-89).
  - **Lower Y-axis**: Diastolic (30-150 mmHg) with color zones (red 120-150, yellow 90-119, green 60-89, yellow 30-59).
  - **Clear zone**: Horizontal band between graphs for X-axis labels (date/time).
  - **Plotting**: Each reading plots two points (systolic upper, diastolic lower), connected vertically to show relationship.
- Update chart legend to reflect new layout and smoothing state.
- Performance optimization for chart rendering with large datasets (>500 points).
- Widget tests for smoothing toggle and dual Y-axis layout.

## Architecture & Components

### 1. Chart Rendering Modes
**Enum**: Add to `lib/models/analytics.dart` or new chart settings model:
```dart
enum ChartRenderMode { raw, smoothed }
enum ChartType { bloodPressure, pulse, weight, sleep }
```

**State Management**: Add to `AnalyticsViewModel`:
- `Map<ChartType, ChartRenderMode> chartModes` (default all to `raw`).
- `toggleSmoothingForChart(ChartType type)` method.

### 2. Smoothing Algorithm
**New File**: `lib/utils/chart_smoothing.dart`
- Implement rolling average smoothing:
  ```dart
  List<DataPoint> applyRollingAverage(List<DataPoint> data, {double windowPercent = 0.1}) {
    final windowSize = max(1, (data.length * windowPercent).round());
    // Apply rolling average with window size
  }
  ```
- Window size = 10% of total readings (minimum 1, maximum 20 for performance).

### 3. Dual Y-Axis BP Chart
**Modified File**: `lib/views/analytics/widgets/bp_line_chart.dart`
- Redesign chart layout:
  - Top section: Systolic chart (Y-axis 50-200 mmHg, color zones as background).
  - Middle section: Clear zone with X-axis labels (date/time).
  - Bottom section: Diastolic chart (Y-axis 30-150 mmHg, color zones as background).
- Plot each reading as two points (systolic in upper, diastolic in lower).
- Connect systolic/diastolic points vertically with thin line to show pairing.
- Use `fl_chart` or `charts_flutter` with custom rendering for dual Y-axis.

**Color Zones** (as per user feedback):
- **Systolic Upper**:
  - Red: 180-200 (Hypertensive Crisis)
  - Yellow: 140-179 (High BP)
  - Green: 90-139 (Normal)
  - Yellow: 50-89 (Low)
- **Diastolic Lower**:
  - Red: 120-150 (Hypertensive Crisis)
  - Yellow: 90-119 (High BP)
  - Green: 60-89 (Normal)
  - Yellow: 30-59 (Low)

### 4. Smoothing Toggle UI
**New Widget**: `lib/views/analytics/widgets/chart_controls.dart`
- Add toggle for each chart: "Smoothing" switch or checkbox.
- Display current mode: "Raw Data" or "Smoothed (10% window)".
- Placed above each chart or in chart legend.

### 5. Chart Legend Update
**Modified File**: `lib/views/analytics/widgets/chart_legend.dart`
- Update legend to show:
  - Systolic/Diastolic zones (for BP chart).
  - Smoothing state (Raw or Smoothed).
  - Color coding for zones (red/yellow/green).

### 6. Performance Optimization
- **Downsampling**: For >500 data points, downsample for rendering (show averages per day/week).
- **Debouncing**: Debounce smoothing toggle to avoid rapid re-renders.
- **Caching**: Cache smoothed data to avoid recalculating on every toggle.

## Implementation Tasks (Detailed)

### Task 1: Chart Smoothing Utility
**New File**: `lib/utils/chart_smoothing.dart`
**Subtasks**:
1. Implement `applyRollingAverage` function:
   - Input: List of data points (DateTime, value).
   - Window size: 10% of data length (min 1, max 20).
   - Calculate rolling average for each point (average of windowSize points centered on target).
   - Return smoothed data points.
2. Add edge handling: first/last points may have smaller windows.
3. Add DartDoc explaining algorithm.

**Estimated Lines**: ~80 lines.

### Task 2: AnalyticsViewModel Smoothing State
**Modified File**: `lib/viewmodels/analytics_viewmodel.dart`
**Subtasks**:
1. Add `Map<ChartType, ChartRenderMode> chartModes` to state.
2. Add `toggleSmoothingForChart(ChartType type)` method.
3. Expose smoothed data getters:
   - `List<DataPoint> get smoothedBPData` (apply rolling average if mode is smoothed).
   - Similar for pulse, weight, sleep.
4. Cache smoothed data to avoid recalculating on every build.

**Estimated Changes**: +60 lines.

### Task 3: Dual Y-Axis BP Chart Redesign
**Modified File**: `lib/views/analytics/widgets/bp_line_chart.dart`
**Subtasks**:
1. Create custom chart layout with three sections:
   - Upper: Systolic chart (50-200 mmHg Y-axis).
   - Middle: Clear zone with X-axis labels.
   - Lower: Diastolic chart (30-150 mmHg Y-axis).
2. Render color zones as background gradients/rectangles:
   - Systolic: Red 180-200, Yellow 140-179, Green 90-139, Yellow 50-89.
   - Diastolic: Red 120-150, Yellow 90-119, Green 60-89, Yellow 30-59.
3. Plot systolic data points in upper chart.
4. Plot diastolic data points in lower chart.
5. Draw vertical connector lines between paired systolic/diastolic points (same timestamp).
6. Ensure responsive layout (adjust heights based on screen size).
7. Add semantic labels for accessibility.

**Estimated Changes**: ~250 lines (major refactor).

### Task 4: Smoothing Toggle UI
**New Widget**: `lib/views/analytics/widgets/chart_controls.dart`
**Subtasks**:
1. Create widget accepting `ChartType` and `ChartRenderMode`.
2. Display switch/checkbox: "Smoothing" with current state (On/Off).
3. On toggle, call `ViewModel.toggleSmoothingForChart(type)`.
4. Display explanation tooltip: "Smoothing applies 10% rolling average".

**Estimated Lines**: ~60 lines.

**Modified File**: `lib/views/analytics/analytics_view.dart`
**Subtasks**:
1. Add `ChartControls` widget above each chart.
2. Wire toggle to ViewModel.

**Estimated Changes**: +20 lines.

### Task 5: Raw Line Graph Default
**Modified Files**: All chart widgets (BP, pulse, weight, sleep charts).
**Subtasks**:
1. Remove Bezier curve interpolation (set to `isCurved: false` or equivalent in chart library).
2. Use straight lines between data points (default raw mode).
3. Test visual appearance with sample data.

**Estimated Changes**: ~5 lines per chart × 4 charts = ~20 lines.

### Task 6: Chart Legend Update
**Modified File**: `lib/views/analytics/widgets/chart_legend.dart`
**Subtasks**:
1. Add legend entries for BP zones (Systolic: red/yellow/green; Diastolic: red/yellow/green).
2. Add legend entry for smoothing state (icon or text: "Raw" or "Smoothed").
3. Use color-coded boxes matching chart zones.

**Estimated Changes**: +40 lines.

### Task 7: Performance Optimization
**Modified File**: `lib/services/analytics_service.dart`
**Subtasks**:
1. Add downsampling for >500 data points:
   - For 7-day view: show all points.
   - For 30-day view: show daily averages.
   - For 90-day+ view: show weekly averages.
2. Cache downsampled data.
3. Add DartDoc explaining downsampling strategy.

**Estimated Changes**: +50 lines.

**Modified File**: `lib/viewmodels/analytics_viewmodel.dart`
**Subtasks**:
1. Cache smoothed data after calculation.
2. Invalidate cache on data mutations or time range change.

**Estimated Changes**: +20 lines.

## Acceptance Criteria

### Functional
- ✅ All charts default to raw line graphs (no Bezier curves).
- ✅ Smoothing toggle available for all charts; applies 10% rolling average.
- ✅ BP chart uses dual Y-axis layout with systolic upper, diastolic lower.
- ✅ BP chart displays color zones correctly (red/yellow/green per spec).
- ✅ Clear zone between systolic/diastolic charts shows X-axis labels.
- ✅ Each reading's systolic/diastolic points are visually connected.
- ✅ Chart legend reflects new layout and smoothing state.
- ✅ Performance is smooth with 500+ data points.

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new utilities and widgets (§3.2).
- ✅ Unit tests for smoothing algorithm (≥90% coverage per §8.1).
- ✅ Widget tests for chart rendering modes and dual Y-axis layout (≥70% coverage per §8.1).
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ Smoothing toggle has semantic label ("Toggle smoothing").
- ✅ Color zones have text labels (not color-only distinction).
- ✅ Charts work correctly with high-contrast mode.

## Dependencies
- Phase 8 (Charts & Analytics): Base analytics view and chart widgets exist.
- Phase 22 (History Redesign): History page complete; analytics can focus on chart improvements.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Dual Y-axis chart library doesn't support custom layout | High | Use `fl_chart` with custom painting; fallback to stacked charts if needed |
| Smoothing algorithm slow with large datasets | Medium | Cache smoothed data; use isolates for >1000 points if needed |
| Users confused by dual Y-axis layout | Medium | Add in-app help or tooltip explaining layout; legend with clear zone labels |
| Color zones don't work with high-contrast mode | Low | Provide text labels in addition to colors; test with high-contrast enabled |

## Testing Strategy

### Unit Tests
**New File**: `test/utils/chart_smoothing_test.dart`
- Test rolling average calculation with various window sizes.
- Test edge cases: empty data, single point, two points.
- Test window size calculation (10% of data length).

**Modified File**: `test/viewmodels/analytics_viewmodel_test.dart`
- Test smoothing toggle for each chart type.
- Test smoothed data caching and invalidation.

**Estimated**: 20 unit tests.

### Widget Tests
**New File**: `test/views/analytics/widgets/bp_line_chart_dual_axis_test.dart`
- Test dual Y-axis layout renders correctly.
- Test color zones display.
- Test systolic/diastolic point pairing and vertical connectors.

**New File**: `test/views/analytics/widgets/chart_controls_test.dart`
- Test smoothing toggle changes state.
- Test toggle calls ViewModel method.

**Modified File**: `test/views/analytics/analytics_view_test.dart`
- Test all charts default to raw mode.
- Test smoothing toggle for each chart type.

**Estimated**: 25 widget tests.

### Integration Tests
**New File**: `test_driver/analytics_charts_test.dart`
- Navigate to Analytics view.
- Toggle smoothing for BP chart; verify chart re-renders.
- Verify dual Y-axis BP chart displays correctly.
- Test with large dataset (500+ points); verify performance.

**Estimated**: 5 integration tests.

### Manual Testing
- Visual verification of dual Y-axis layout with real data.
- Color zone accuracy (compare against medical guidelines).
- Smoothing toggle responsiveness.
- High-contrast mode compatibility.

## Branching & Workflow
- **Branch**: `feature/phase-23-analytics-overhaul`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Feature-flag new dual Y-axis chart; fall back to existing single-axis chart if critical rendering issues.
- Smoothing toggle is opt-in; users can continue using raw mode if smoothing has bugs.
- No schema changes; rollback is non-destructive (UI-only change).

## Performance Considerations
- **Smoothing Calculation**: Cache results to avoid recalculating on every build.
- **Downsampling**: For >500 points, show aggregated data (daily/weekly averages) to reduce rendering load.
- **Chart Library**: Use `fl_chart` with optimized rendering settings (disable animations for large datasets).
- **Debouncing**: Debounce smoothing toggle (300ms) to prevent rapid re-renders.

## Documentation Updates
- **User-facing**: Add in-app help explaining dual Y-axis BP chart layout and smoothing toggle.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 23 complete upon merge.
- **Architecture notes**: Document smoothing algorithm and dual Y-axis rendering approach.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 5-7 days (including chart redesign, testing, and review)  
**Target Completion**: TBD based on sprint schedule

# Phase 22 Plan: History Page Redesign

**Objective**: Redesign History page with collapsible sections, mini-stats, and improved UX for quick insights.

## Current State (Audit)
- **Phase 7**: History view implemented with averaged rows primary, expandable to raw readings.
- **User Feedback**: Users want all metric types (BP, Pulse, Medication, Weight, Sleep) in one view with collapsible sections.
- **Gap**: Current history is focused on BP; other metrics require separate navigation.
- **Desired UX**: All sections collapsed by default; each shows button to full history + 10 most recent + mini-stats.

## Scope
- Create unified History page with collapsible sections for: Blood Pressure, Pulse, Medication, Weight, Sleep.
- All sections closed by default (expandable accordion or expansion tiles).
- Each section displays:
  - Button to open full history for that metric.
  - Summary of 10 most recent readings.
  - Mini-stats: latest value, 7-day average, trend indicator (↑↓→).
- Implement mini-stats calculation service (reuse or extend AnalyticsService).
- Optimize performance for large datasets (lazy loading, pagination).
- Widget tests for collapsible sections, mini-stats display, and full history navigation.

## Architecture & Components

### 1. Unified History View
**Modified File**: `lib/views/history/history_view.dart`
- Redesign as single-page view with expansion tiles for each metric type.
- Layout:
  ```
  History
  ├── Blood Pressure ▼
  │   ├── [View Full History] button
  │   ├── Mini-stats: Latest 128/82, 7-day avg 130/85, Trend ↓
  │   └── 10 most recent readings (condensed cards)
  ├── Pulse ▶
  ├── Medication ▶
  ├── Weight ▶
  └── Sleep ▶
  ```
- Use `ExpansionTile` or custom accordion widget for sections.
- All sections collapsed by default; user expands to see summary.

### 2. Mini-Stats Service
**New File**: `lib/services/mini_stats_service.dart`
- Calculate mini-stats for each metric type:
  - **Latest**: Most recent reading value.
  - **7-day average**: Average of readings in last 7 days.
  - **Trend**: Compare last 3 days avg vs prior 4 days avg (↑ increasing, ↓ decreasing, → stable).
- Methods:
  - `Future<MiniStats> getBPMiniStats(int profileId)`
  - `Future<MiniStats> getPulseMiniStats(int profileId)`
  - `Future<MiniStats> getWeightMiniStats(int profileId)`
  - `Future<MiniStats> getSleepMiniStats(int profileId)`
- Cache results with TTL (5 minutes) to avoid redundant queries.

**New File**: `lib/models/mini_stats.dart`
- Model:
  ```dart
  class MiniStats {
    final String latestValue;
    final String sevenDayAverage;
    final TrendDirection trend;
    final DateTime? latestDate;
  }
  
  enum TrendDirection { up, down, stable, insufficient }
  ```

### 3. Section Components
**New Widget**: `lib/views/history/widgets/history_section.dart`
- Reusable widget for each metric section.
- Props:
  - `title`: Section title (e.g., "Blood Pressure").
  - `miniStats`: MiniStats instance.
  - `recentReadings`: List of 10 most recent readings.
  - `onViewFullHistory`: Callback to navigate to full history.
- UI:
  - Expansion tile header shows title + mini-stats preview (collapsed state).
  - Expanded state shows "View Full History" button + 10 reading cards + detailed mini-stats.

### 4. Full History Navigation
**Modified Files**:
- `lib/views/history/bp_full_history_view.dart` (new or modified from existing history view)
- `lib/views/history/pulse_full_history_view.dart`
- `lib/views/history/medication_full_history_view.dart`
- `lib/views/history/weight_full_history_view.dart`
- `lib/views/history/sleep_full_history_view.dart`
- Each full history view shows paginated list with filters (date range, tags, etc.).

### 5. Performance Optimization
- **Lazy Loading**: Only load 10 most recent readings per section on initial view.
- **Pagination**: Full history views use keyset pagination (load 50 at a time, "Load More" button).
- **Caching**: Mini-stats cached for 5 minutes; invalidate on data mutations.

## Implementation Tasks (Detailed)

### Task 1: MiniStats Model & Service
**New File**: `lib/models/mini_stats.dart`
**Subtasks**:
1. Define `MiniStats` class with fields: `latestValue`, `sevenDayAverage`, `trend`, `latestDate`.
2. Define `TrendDirection` enum: `up`, `down`, `stable`, `insufficient`.
3. Add `toJson` / `fromJson` for potential caching (optional).

**Estimated Lines**: ~40 lines.

**New File**: `lib/services/mini_stats_service.dart`
**Subtasks**:
1. Implement `getBPMiniStats`:
   - Query last 7 days of BP readings for profile.
   - Calculate latest, 7-day avg (systolic/diastolic), trend.
2. Implement `getPulseMiniStats`, `getWeightMiniStats`, `getSleepMiniStats` similarly.
3. Add caching with TTL (use in-memory cache or shared cache service).
4. Add DartDoc for all methods.

**Estimated Lines**: ~200 lines.

### Task 2: Unified History View Redesign
**Modified File**: `lib/views/history/history_view.dart`
**Subtasks**:
1. Replace existing history view with expansion tile layout.
2. Create 5 sections: BP, Pulse, Medication, Weight, Sleep.
3. Each section uses `HistorySection` widget (Task 3).
4. Load mini-stats and recent readings on view init (call MiniStatsService + data services).
5. Handle empty states: "No [metric] data yet" for sections with no readings.

**Estimated Changes**: ~150 lines (major refactor).

### Task 3: HistorySection Reusable Widget
**New File**: `lib/views/history/widgets/history_section.dart`
**Subtasks**:
1. Create stateful widget accepting title, miniStats, recentReadings, onViewFullHistory.
2. Header (collapsed): Title + mini-stats preview (e.g., "Latest: 128/82 ↓").
3. Expanded content:
   - "View Full History" button at top.
   - Detailed mini-stats card (latest, 7-day avg, trend with icon).
   - List of 10 most recent readings (condensed cards, 1-2 lines each).
4. Use `ExpansionTile` or custom animated container.

**Estimated Lines**: ~150 lines.

### Task 4: Recent Reading Cards
**New Widgets**:
- `lib/views/history/widgets/bp_reading_card_compact.dart`
- `lib/views/history/widgets/pulse_reading_card_compact.dart`
- `lib/views/history/widgets/medication_reading_card_compact.dart`
- `lib/views/history/widgets/weight_reading_card_compact.dart`
- `lib/views/history/widgets/sleep_reading_card_compact.dart`

**Subtasks**: For each card type:
1. Display key info in 1-2 lines (date/time, value).
2. Tap to navigate to detail view or expand inline.
3. Consistent styling across all cards.

**Estimated Lines**: ~50 lines each × 5 = ~250 lines total.

### Task 5: Full History Views
**New/Modified Files**:
- `lib/views/history/bp_full_history_view.dart`: Paginated BP history with filters.
- `lib/views/history/pulse_full_history_view.dart`: Pulse history.
- `lib/views/history/medication_full_history_view.dart`: Medication intake history.
- `lib/views/history/weight_full_history_view.dart`: Weight history.
- `lib/views/history/sleep_full_history_view.dart`: Sleep history.

**Subtasks** (per view):
1. Implement pagination (load 50 entries, "Load More" button).
2. Add date range filter, search/filter by tags or medication name.
3. Display full reading details (not condensed).
4. Reuse existing history logic from Phase 7 where applicable.

**Estimated Lines**: ~200 lines each × 5 = ~1000 lines total (partially reusing existing code).

### Task 6: ViewModel Integration
**New File**: `lib/viewmodels/unified_history_viewmodel.dart`
**Subtasks**:
1. Manage state for all 5 sections (loading, mini-stats, recent readings).
2. Expose methods to load data for each section.
3. Invalidate cache on data mutations (extend existing refresh hooks).

**Estimated Lines**: ~150 lines.

### Task 7: Performance Optimization
**Subtasks**:
1. Lazy load sections: only fetch data for expanded section (defer until user expands).
2. Pagination: implement keyset pagination for full history views.
3. Caching: ensure mini-stats cached; invalidate on mutations.

**Estimated Changes**: +50 lines (optimization logic).

## Acceptance Criteria

### Functional
- ✅ History page shows 5 collapsible sections: BP, Pulse, Medication, Weight, Sleep.
- ✅ All sections collapsed by default; user can expand to view summary.
- ✅ Each section displays: "View Full History" button, 10 most recent readings, mini-stats.
- ✅ Mini-stats show: latest value, 7-day average, trend indicator (↑↓→).
- ✅ Full history views open from "View Full History" button with pagination and filters.
- ✅ Performance is smooth with large datasets (1000+ readings per metric).

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new services and widgets (§3.2).
- ✅ Unit tests for MiniStatsService (≥85% coverage per §8.1).
- ✅ Widget tests for HistorySection and unified history view (≥70% coverage per §8.1).
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ Expansion tiles have semantic labels for screen readers.
- ✅ Trend indicators have text alternatives (not icon-only).
- ✅ "View Full History" buttons clearly labeled.

## Dependencies
- Phase 7 (History foundation): Existing history logic and data services.
- Phase 21 (Enhanced Sleep): Sleep metrics available for display.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Too many sections make page cluttered | Medium | Keep all collapsed by default; use clean expansion tile design |
| Mini-stats calculation slow with large datasets | Medium | Cache results; use indexed queries; limit to last 7 days only |
| Users confused by new layout (expect single history list) | Low | Provide in-app tutorial or tooltip; allow collapse-all/expand-all option |
| Pagination complexity increases bugs | Medium | Reuse existing pagination patterns from Phase 7; thorough testing |

## Testing Strategy

### Unit Tests
**New File**: `test/services/mini_stats_service_test.dart`
- Test BP mini-stats calculation with various data scenarios.
- Test trend detection (up/down/stable/insufficient).
- Test caching and cache invalidation.
- Test edge cases: no data, single reading, gaps in data.

**New File**: `test/models/mini_stats_test.dart`
- Test model serialization/deserialization.
- Test equality and copyWith.

**Estimated**: 25 unit tests.

### Widget Tests
**New File**: `test/views/history/history_view_test.dart`
- Test all sections render collapsed by default.
- Test expanding section displays mini-stats and recent readings.
- Test "View Full History" button navigates to full history.
- Test empty state for sections with no data.

**New File**: `test/views/history/widgets/history_section_test.dart`
- Test section expansion/collapse animation.
- Test mini-stats display formatting.
- Test recent readings display.

**Estimated**: 20 widget tests.

### Integration Tests
**New File**: `test_driver/unified_history_test.dart`
- Navigate to History page.
- Expand BP section; verify mini-stats and readings display.
- Tap "View Full History"; verify navigation to full BP history.
- Verify pagination in full history view.

**Estimated**: 5 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-22-history-redesign`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Feature-flag new unified history view; fall back to existing Phase 7 history view if critical issues arise.
- Migration: No schema changes; rollback is non-destructive (UI-only change).

## Performance Considerations
- **Lazy Loading**: Defer data fetching until section expanded; reduces initial load time.
- **Mini-Stats Caching**: Cache for 5 minutes; reduces redundant queries.
- **Pagination**: Full history views load 50 entries at a time; smooth scrolling for large datasets.
- **Virtual Scrolling**: Use `ListView.builder` for all lists to handle large datasets efficiently.

## Documentation Updates
- **User-facing**: Add in-app help or tutorial explaining new History page layout.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 22 complete upon merge.
- **Architecture notes**: Document mini-stats calculation logic and caching strategy.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 4-6 days (including UI redesign, testing, and review)  
**Target Completion**: TBD based on sprint schedule

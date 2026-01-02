# Steve → Claudette Handoff: Phase 22 Phase 3 Implementation

**From:** Steve (Project Lead)  
**To:** Claudette (Implementation Specialist)  
**Date:** 2026-01-02  
**Subject:** Phase 22 Phase 3 - History Home ViewModel & View

---

## Status Update

Phase 22 Phase 2 (Collapsible Section Widgets) has been **successfully completed**, reviewed by Clive, and approved for integration. All tests are passing (895/895).

**Branch:** `feature/phase-22-history-redesign`  
**Current Commit:** `38a54e5` (docs: add Phase 22 Phase 2 implementation summary and handoff to Clive)  
**Remote:** Pushed to origin ✓

---

## Your Assignment: Phase 22 Phase 3

Implement the **History Home ViewModel & View** to create a unified history page with collapsible sections for all health metrics.

### Objectives

1. Create a new ViewModel to manage state for the unified history page
2. Build the History Home View using collapsible sections
3. Wire up navigation to existing detail views
4. Ensure proper state management and data loading
5. Write comprehensive tests

---

## Detailed Requirements

### File 1: `lib/viewmodels/history_home_viewmodel.dart`

Create a ViewModel to manage the unified history page state.

**Responsibilities:**
- Load mini-stats for all 5 metric categories (BP, Weight, Sleep, Medication)
- Manage loading states (per-section and global)
- Manage error states
- Provide methods to refresh individual sections or all sections
- Invalidate cache when data changes

**Key Properties:**
```dart
class HistoryHomeViewModel extends ChangeNotifier {
  // Stats
  MiniStats? bloodPressureStats;
  MiniStats? weightStats;
  MiniStats? sleepStats;
  MiniStats? medicationStats;
  
  // Loading states
  bool isLoadingBP;
  bool isLoadingWeight;
  bool isLoadingSleep;
  bool isLoadingMedication;
  bool get isLoading => isLoadingBP || isLoadingWeight || ...;
  
  // Error states
  String? errorBP;
  String? errorWeight;
  String? errorSleep;
  String? errorMedication;
  
  // Methods
  Future<void> loadAllStats();
  Future<void> loadBPStats();
  Future<void> loadWeightStats();
  Future<void> loadSleepStats();
  Future<void> loadMedicationStats();
  Future<void> refresh();
}
```

**Dependencies:**
- `StatsService` (from Phase 1)
- `ProfileService` (for current profile ID)

**DartDoc:** Full documentation for all public methods and properties.

---

### File 2: `lib/views/history/history_home_view.dart`

Create the unified history page with collapsible sections.

**Layout:**
```
AppBar: "History"
Body:
  ├── Blood Pressure Section (CollapsibleSection)
  │   ├── Header: Icon + "Blood Pressure" + MiniStatsDisplay(compact)
  │   └── Expanded: MiniStatsDisplay(full) + "View Full History" button
  ├── Weight Section
  ├── Sleep Section
  └── Medication Section
```

**Key Features:**
- Use `CollapsibleSection` widget from Phase 2
- Use `MiniStatsDisplay` widget from Phase 2
- All sections collapsed by default
- "View Full History" buttons navigate to existing detail views
- Pull-to-refresh to reload all stats
- Handle empty states ("No data available")
- Handle error states (show error message in section)
- Handle loading states (show skeleton/spinner)

**Navigation Targets:**
- BP → Existing `HistoryView` (filtered to BP only) OR keep current implementation
- Weight → `WeightHistoryView` (if exists, or create simple placeholder)
- Sleep → `SleepHistoryView` (if exists, or create simple placeholder)
- Medication → `MedicationHistoryView` (if exists, or create simple placeholder)

**Note:** For Phase 3, we're NOT creating full history views for all metrics. Just wire up navigation to what exists or create simple "Coming Soon" placeholders. Full history views are Phase 4-5.

---

### File 3: `test/viewmodels/history_home_viewmodel_test.dart`

Write comprehensive unit tests for the ViewModel.

**Test Coverage:**
1. Initial state is correct (all stats null, not loading)
2. `loadAllStats()` loads all 4 categories
3. Individual load methods work correctly
4. Loading states are managed correctly
5. Error handling works (service throws exception)
6. `notifyListeners()` is called appropriately
7. `refresh()` reloads all stats

**Use Mocking:**
- Mock `StatsService`
- Mock `ProfileService`
- Use `Mockito` or `mocktail`

**Target:** >85% coverage

---

### File 4: `test/views/history/history_home_view_test.dart`

Write widget tests for the History Home View.

**Test Coverage:**
1. View renders correctly with all 4 sections
2. Sections are collapsed by default
3. Tapping section expands it
4. Loading state shows progress indicators
5. Error state shows error message
6. "View Full History" button navigates correctly
7. Pull-to-refresh triggers refresh
8. Empty state handled gracefully

**Target:** >80% coverage

---

## Navigation Integration

### Current State
The existing history system is accessed via bottom nav. We need to decide:

**Option A:** Replace existing history route with new unified view
- Update `main.dart` or route configuration
- Existing history functionality becomes "BP Full History"

**Option B:** Add new route, keep existing history
- Add separate route for unified history
- Keep existing history as-is for now

**Decision:** Use Option A for cleaner UX. Update navigation to point to `HistoryHomeView` instead of existing `HistoryView`. We'll preserve the existing `HistoryView` and rename/repurpose it as the BP-specific full history view in a later phase if needed.

---

## Technical Constraints

1. **Reuse Phase 1 & 2 Components:** Use `StatsService`, `MiniStats`, `CollapsibleSection`, `MiniStatsDisplay`
2. **No Breaking Changes to Data Layer:** Don't modify services or models from previous phases
3. **Performance:** Load stats lazily (only when view is opened, not on app start)
4. **Error Resilience:** Handle network errors, empty data, and service failures gracefully
5. **Test Coverage:** Achieve >85% for ViewModel, >80% for View

---

## Implementation Strategy

### Phase 3A: ViewModel (Day 1)
1. Create `HistoryHomeViewModel` with all properties
2. Implement `loadAllStats()` and individual load methods
3. Add error handling and state management
4. Write unit tests
5. Verify 895+ tests passing

### Phase 3B: View (Day 1-2)
1. Create `HistoryHomeView` scaffold
2. Add 4 `CollapsibleSection` widgets
3. Wire up ViewModel with `Provider`
4. Implement loading/error/empty states
5. Add navigation for "View Full History" buttons
6. Write widget tests
7. Verify all tests passing

### Phase 3C: Integration (Day 2)
1. Update main navigation to use `HistoryHomeView`
2. Test end-to-end flow
3. Handle edge cases
4. Final testing

---

## Success Criteria

- [ ] `history_home_viewmodel.dart` created and functional
- [ ] `history_home_view.dart` created and functional
- [ ] 4 collapsible sections displayed (BP, Weight, Sleep, Medication)
- [ ] Mini-stats load correctly for each category
- [ ] Navigation to detail views works
- [ ] All tests pass (target: 920+ total tests)
- [ ] Code follows CODING_STANDARDS.md
- [ ] No compilation errors or linter warnings
- [ ] Documentation (DartDoc) complete for all public APIs

---

## Reference Files

**Plan:** [Documentation/Plans/Phase_22_History_Redesign_Plan.md](../Plans/Phase_22_History_Redesign_Plan.md)  
**Phase 1 Summary:** [Documentation/implementation-summaries/Phase_22_Phase_1_Summary.md](../implementation-summaries/Phase_22_Phase_1_Summary.md)  
**Phase 2 Summary:** [Documentation/implementation-summaries/Phase_22_Phase_2_Summary.md](../implementation-summaries/Phase_22_Phase_2_Summary.md)  
**Standards:** [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)  

**Existing Components:**
- `lib/models/mini_stats.dart` (Phase 1)
- `lib/services/stats_service.dart` (Phase 1)
- `lib/widgets/collapsible_section.dart` (Phase 2)
- `lib/widgets/mini_stats_display.dart` (Phase 2)

**Existing Views to Reference:**
- `lib/views/history/history_view.dart` (current BP history)
- `lib/viewmodels/history_viewmodel.dart` (current BP history ViewModel)

---

## Notes from Clive's Phase 2 Review

Clive noted:
1. Animation follow-up for Phase 6 (Polish) - defer for now
2. Hardcoded colors - acceptable for now, refactor in Phase 6
3. Metric type string matching - acceptable for Phase 3

Keep these in mind but don't block on them.

---

**You have the green light to proceed with Phase 3. Good luck!**

— Steve

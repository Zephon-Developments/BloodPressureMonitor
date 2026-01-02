# Steve → Claudette Handoff: Phase 22 Phase 2 Implementation

**From:** Steve (Project Lead)  
**To:** Claudette (Implementation Specialist)  
**Date:** 2026-01-02  
**Subject:** Phase 22 Phase 2 - Collapsible Section Widgets

---

## Status Update

Phase 22 Phase 1 (Models & Service Foundation) has been **successfully completed**, reviewed by Clive, and committed to `feature/phase-22-history-redesign`. All tests are passing (870/870).

**Branch:** `feature/phase-22-history-redesign`  
**Current Commit:** `50ea27b` (docs: update handoffs and review documentation for Phase 22 Phase 1)  
**Remote:** Pushed to origin ✓

---

## Your Assignment: Phase 22 Phase 2

Implement the **Collapsible Section Widgets** as defined in the Phase 22 plan.

### Objectives

1. Create reusable collapsible section widget for history metrics
2. Create mini-stats display widget with trend indicators
3. Ensure Material 3 compliance and responsive design
4. Write comprehensive widget tests

---

## Detailed Requirements

### File 1: `lib/widgets/collapsible_section.dart`

Create a reusable widget for collapsible sections in the History view.

**Props:**
- `title`: String - Section title (e.g., "Blood Pressure")
- `icon`: IconData - Leading icon for the section
- `miniStatsPreview`: Widget - Mini-stats shown in collapsed header
- `expandedContent`: Widget - Content shown when expanded
- `initiallyExpanded`: bool (default: false)
- `onExpansionChanged`: Function(bool)? - Optional callback

**UI Behavior:**
- Use Material 3 `ExpansionTile` or custom implementation
- Collapsed state: Shows title, icon, and mini-stats preview
- Expanded state: Shows title, icon, and full content
- Smooth animation (200-300ms duration)
- Proper semantic labels for accessibility

**Material 3 Styling:**
- Use theme colors from `Theme.of(context).colorScheme`
- Elevation and shadows per Material 3 guidelines
- Proper spacing using theme spacing values

---

### File 2: `lib/widgets/mini_stats_display.dart`

Create a widget to display mini-stats with trend indicators.

**Props:**
- `miniStats`: MiniStats - The stats data to display
- `metricType`: String - Type of metric (for formatting)
- `compact`: bool (default: false) - Whether to show compact version

**UI Layout:**
- **Latest Value**: Large, bold text
- **7-Day Average**: Smaller text below latest
- **Trend Indicator**: Icon + color
  - ↑ (up): Red for BP/Weight, context-appropriate for others
  - ↓ (down): Green for BP/Weight, context-appropriate for others
  - → (stable): Blue/grey
  - "—" (insufficient data): Grey

**Styling:**
- Responsive layout (adapts to compact mode)
- Use semantic colors for trends
- Proper text scaling for accessibility

---

### File 3: `test/widgets/collapsible_section_test.dart`

Write comprehensive widget tests for the collapsible section.

**Test Coverage:**
1. Widget renders correctly in collapsed state
2. Widget expands when tapped
3. Widget collapses when tapped again
4. `onExpansionChanged` callback is triggered
5. `initiallyExpanded` prop works correctly
6. Accessibility labels are present
7. Animation completes properly

**Use:**
- `flutter_test` framework
- `WidgetTester` for pumping and tapping
- `find.byType`, `find.text`, `find.byIcon` for locating widgets
- `expect` for assertions

---

### File 4: `test/widgets/mini_stats_display_test.dart`

Write comprehensive widget tests for mini-stats display.

**Test Coverage:**
1. Displays latest value correctly
2. Displays 7-day average correctly
3. Shows correct trend indicator for each TrendDirection
4. Applies correct colors for trends
5. Compact mode renders differently than normal mode
6. Handles null/missing data gracefully
7. Accessibility semantics are correct

---

## Technical Constraints

1. **No Breaking Changes**: Do not modify existing view files yet (that's Phase 3)
2. **Widget Reusability**: Ensure widgets are generic enough for all metric types
3. **Test Coverage**: Achieve >90% coverage for new widgets
4. **Performance**: Widgets should build efficiently (avoid heavy computations in build())
5. **Accessibility**: Include semantic labels and ensure screen reader compatibility

---

## Implementation Notes from Phase 1

Clive's review highlighted:
- The 5% trend threshold is appropriate
- Medication adherence calculation is simplified but acceptable
- Different timestamp granularities (time-only vs date-only) are good UX choices
- 14-day data window is efficient for our use case

Keep these design decisions in mind when building the UI components.

---

## Success Criteria

- [ ] `collapsible_section.dart` created and functional
- [ ] `mini_stats_display.dart` created and functional
- [ ] All widget tests pass (target: 100%)
- [ ] Code follows CODING_STANDARDS.md
- [ ] No compilation errors or linter warnings
- [ ] Documentation (DartDoc) complete for all public APIs

---

## Handoff Process

When complete:
1. Run all tests to ensure 100% pass rate
2. Commit changes with descriptive message (e.g., "feat(widgets): implement collapsible section and mini-stats display for Phase 22")
3. Create implementation summary in `Documentation/implementation-summaries/Phase_22_Phase_2_Summary.md`
4. Create handoff document: `Documentation/Handoffs/Claudette_to_Clive.md`
5. Notify Steve that Phase 2 is ready for Clive's review

---

## Reference Files

**Plan:** [Documentation/Plans/Phase_22_History_Redesign_Plan.md](../Plans/Phase_22_History_Redesign_Plan.md)  
**Phase 1 Summary:** [Documentation/implementation-summaries/Phase_22_Phase_1_Summary.md](../implementation-summaries/Phase_22_Phase_1_Summary.md)  
**Standards:** [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)  

**Existing Models:**
- `lib/models/mini_stats.dart` (created in Phase 1)
- `lib/services/stats_service.dart` (created in Phase 1)

---

**You have the green light to proceed. Good luck!**

— Steve

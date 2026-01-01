# Handoff: Clive to Claudette

**Project**: HyperTrack (Blood Pressure Monitor)
**Phase**: 19 (UX Polish Pack)
**Status**: Ready for Implementation

## Overview
Phase 19 focuses on UX polish, addressing inconsistencies in idle timeouts, search functionality, numeric validation, and navigation safety.

## Tasks for Claudette
1.  **Global Idle Timeout**:
    - Move the `Listener` from `_LockGate` in `lib/main.dart` to `MaterialApp.builder`.
    - Ensure `lockViewModel.recordActivity()` is called for all pointer events globally.
    - Verify that medication entry screens now trigger the lock screen after the idle period.

2.  **Search Bar Enhancements**:
    - Audit all search bars (Medications, History, etc.).
    - Ensure they have a clear button (X icon) that appears only when text is present.
    - Use `ValueListenableBuilder` or `setState` to ensure the clear button visibility updates immediately.

3.  **Navigation Safety (PopScope)**:
    - Add `PopScope` to all "Add/Edit" views to prevent accidental data loss.
    - Show a confirmation dialog if the form is "dirty" (has unsaved changes).

4.  **Numeric Validation Audit**:
    - Ensure all numeric fields (Weight, BP, Pulse, Dosage) use the correct `keyboardType`.
    - Verify that validators are robust and provide clear error messages.

5.  **Performance & Pagination**:
    - Update `HistoryView` to use 50-item pages and a "Load More" button if requested by the plan, or optimize the existing infinite scroll.
    - Ensure `MedicationListView` handles large datasets efficiently.

6.  **General Polish**:
    - Audit spacing, alignment, and theme consistency across the app.

## Reference Materials
- [Phase 19 Plan](../../Plans/Phase_19_UX_Polish_Pack_Plan.md)
- [Phase 19 Review](../../reviews/2026-01-01-clive-phase-19-plan-review.md)
- [Coding Standards](../../Standards/Coding_Standards.md)

## Success Criteria
- All 844+ tests passing.
- Zero analyzer issues.
- Idle timeout works on all screens.
- Navigation confirmation prevents data loss.
- Search bars are user-friendly.

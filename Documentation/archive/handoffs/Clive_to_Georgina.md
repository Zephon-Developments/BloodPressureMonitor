# Handoff: Clive to Georgina — Phase 9 Implementation

**Date:** 2025-12-30  
**From:** Clive (Review Specialist)  
**To:** Georgina (Implementation Specialist)  
**Plan:** [Documentation/Plans/Phase_9_Edit_Delete_Plan.md](../Plans/Phase_9_Edit_Delete_Plan.md)  
**Review:** [reviews/2025-12-30-clive-phase-9-plan-review.md](../../reviews/2025-12-30-clive-phase-9-plan-review.md)

## Objectives
Implement Edit and Delete functionality for Blood Pressure Readings, Weight Entries, and Sleep Entries.

## Key Requirements
1.  **ViewModel Extensions**:
    *   Add `updateWeightEntry` and `deleteWeightEntry` to `WeightViewModel`.
    *   Add `updateSleepEntry` and `deleteSleepEntry` to `SleepViewModel`.
    *   Ensure `BloodPressureViewModel` correctly triggers averaging recomputation (it should already, but verify).
2.  **Edit Flow (Option A)**:
    *   Modify `AddReadingView`, `AddWeightView`, and `AddSleepView` to accept an optional `editingEntry`.
    *   Pre-populate forms when an entry is provided.
    *   Update the UI (titles, buttons) to reflect "Edit" mode.
3.  **Delete Flow**:
    *   Implement a reusable `ConfirmDeleteDialog`.
    *   **Home Screen**: Tapping the chevron (`>`) on a reading card opens the Edit view.
    *   **Home Screen**: Swiping left on a reading card reveals a "DELETE" button (white text on red background).
    *   **Action**: Tapping the revealed Delete button shows the confirmation dialog.
4.  **Cache Invalidation**:
    *   Invalidate the `AnalyticsViewModel` cache after any edit or delete operation for readings or sleep data.
5.  **Dependencies**:
    *   Add `flutter_slidable: ^3.1.0` to `pubspec.yaml` for the swipe-to-reveal functionality.

## Standards & Quality
*   **Test Coverage**: Target ≥85% for all new/modified code.
*   **Static Analysis**: Zero warnings/errors.
*   **Documentation**: JSDoc for all new public methods.
*   **Formatting**: Run `dart format .` before submission.

## Success Metrics
*   Users can edit and delete readings, weight, and sleep entries.
*   Deletions are always confirmed.
*   Averages and charts update immediately after changes.
*   All tests pass and coverage is maintained.

Please proceed with the implementation of Phase 9A.

---
**Clive**  
Review Specialist

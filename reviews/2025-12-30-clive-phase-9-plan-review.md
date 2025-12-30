# Review: Phase 9 — Edit & Delete Capabilities

**Reviewer:** Clive (Review Specialist)  
**Date:** 2025-12-30  
**Status:** ✅ APPROVED (with recommendations)

## Scope & Acceptance Criteria
The plan covers the implementation of Edit and Delete functionality for Blood Pressure Readings, Weight Entries, and Sleep Entries.

### Objectives:
- [x] ViewModel extensions for Weight and Sleep.
- [x] Form reuse (Option A) for editing.
- [x] Swipe-to-reveal delete affordance on Home screen.
- [x] Confirmation dialogs for all deletions.
- [x] Averaging and Analytics cache invalidation.

## Review Findings

### 1. Architecture & Patterns
- **Option A (Form Reuse)**: Approved. This minimizes code duplication and ensures validation logic remains consistent between Add and Edit flows.
- **ViewModel Integration**: The plan correctly identifies the need to extend `WeightViewModel` and `SleepViewModel`. `BloodPressureViewModel` already handles averaging recomputation on update/delete.

### 2. UX & Interaction
- **Home Screen**: Tapping the chevron (`>`) to edit and swiping left to reveal a "DELETE" button (white on red) matches the user's specific request.
- **Swipe Implementation**: Since the requirement is to "reveal" a button rather than "swipe to action," I recommend adding `flutter_slidable` to `pubspec.yaml`. This provides a more robust implementation than a custom `Dismissible` for this specific behavior.

### 3. Coding Standards Compliance
- **Test Coverage**: The target of ≥85% exceeds the project requirement of ≥80%.
- **Documentation**: JSDoc for public APIs is included in the plan.
- **Typing**: No `any` types are proposed.

### 4. Data Integrity
- **Hard vs Soft Delete**: Approved **Hard Delete** for readings, weight, and sleep. Medication remains soft-delete as per existing implementation.
- **Cache Invalidation**: The plan correctly includes invalidating the `AnalyticsViewModel` cache after edits/deletes to prevent stale data in charts.

## Recommendations & Targeted Follow-ups
1. **Dependency**: Add `flutter_slidable: ^3.1.0` to `pubspec.yaml` to implement the swipe-to-reveal behavior.
2. **Accessibility**: Ensure the `ConfirmDeleteDialog` and the revealed Delete button have appropriate semantic labels for screen readers.
3. **Averaging**: Ensure that if a reading's timestamp is edited, the `AveragingService` correctly handles moving the reading between groups.

## Handoff
I am handing this off to **Georgina** for implementation.

---
**Clive**  
Review Specialist  
2025-12-30

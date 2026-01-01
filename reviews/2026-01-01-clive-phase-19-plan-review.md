# Phase 19 Plan Review: UX Polish Pack

**Reviewer**: Clive (QA Specialist)
**Date**: January 1, 2026
**Status**: APPROVED (with minor guidance)

## Scope & Acceptance Criteria
The plan covers critical UX improvements including security consistency, search usability, data validation, navigation safety, and performance optimizations.

### Restated Acceptance Criteria
- **Idle Timeout**: Works consistently across all screens, including medication entry.
- **Search UX**: All search bars have functional clear buttons.
- **Validation**: All numeric fields have appropriate keyboards and validation.
- **Navigation**: Forms with unsaved changes require confirmation before exit.
- **Performance**: Large datasets (History, Medications) handle smoothly via pagination.
- **General Polish**: Consistent spacing, alignment, and theme usage.

## Findings & Guidance

### 1. Idle Timeout Consistency (Severity: Medium)
- **Current State**: `_LockGate` in `lib/main.dart` wraps `HomeView` in a `Listener`. This fails to catch events on screens pushed via `Navigator`.
- **Guidance**: Move the `Listener` to `MaterialApp.builder` to ensure global activity tracking across all routes.
- **Correction**: The plan refers to `SecurityService`; the actual service is `IdleTimerService`.

### 2. Search Bar Clear Buttons (Severity: Low)
- **Current State**: `MedicationListView` has a clear button, but it may not update its visibility immediately on text change without a `setState` or `ValueListenableBuilder`.
- **Guidance**: Audit `HistoryView` and `AnalyticsView` for missing search clear buttons.

### 3. Numeric Validation & Navigation (Severity: Medium)
- **Current State**: `AddReadingView` and `AddWeightView` have numeric validation, but lack `PopScope` (or `PopScope` in newer Flutter) to prevent data loss.
- **Guidance**: Implement `PopScope` in all `add_edit_*.dart` views. Ensure `keyboardType` is consistently `TextInputType.number` or `numberWithOptions(decimal: true)`.

### 4. Performance Optimization (Severity: Low)
- **Current State**: `HistoryView` already uses keyset pagination with a 20-item limit and infinite scroll.
- **Guidance**: The plan requests a "Load More" button and 50-item pages. This is a valid UX change if preferred over infinite scroll. Ensure `MedicationListView` also uses `ListView.builder` for large lists.

### 5. Coding Standards Compliance
- Ensure all new validators are added to `lib/utils/validators.dart` and unit tested.
- Maintain ≥80% test coverage for new logic.

## Approval
The plan is solid and addresses the identified UX gaps. I approve this plan for implementation.

**Handoff to**: Claudette (Implementation Specialist)

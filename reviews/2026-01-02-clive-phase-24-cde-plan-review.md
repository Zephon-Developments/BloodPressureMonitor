# Review: Phase 24 (C, D, E) Implementation Plan

**Reviewer:** Clive (Review Specialist)  
**Date:** 2026-01-02  
**Scope:** Units UI Integration (24C), Accessibility (24D), Landscape Mode (24E)  
**Status:** ⚠️ **APPROVED WITH BLOCKERS**

---

## Executive Summary

The implementation plan for the remainder of Phase 24 is comprehensive and aligns well with the project's goals for internationalization (units) and inclusivity (accessibility). The landscape mode support is a welcome addition for tablet users. However, there are a few critical omissions and architectural concerns that must be addressed before implementation begins.

---

## Compliance Check (CODING_STANDARDS.md)

| Standard | Status | Notes |
| :--- | :--- | :--- |
| **Architecture (MVVM)** | ⚠️ | Plan suggests conversion logic in Views; must move to ViewModels. |
| **Data Integrity** | ✅ | Canonical SI storage (kg) is maintained. |
| **Testing Coverage** | ✅ | Targets met (Services 85%, Utils 90%, Widgets 70%). |
| **Accessibility** | ✅ | Comprehensive audit included (Semantics, Contrast, HC, Scaling). |
| **DRY Principle** | ❌ | Duplicate `WeightUnit` enums found in `health_data.dart` and `units_preference.dart`. |

---

## Findings & Required Actions

### 1. [BLOCKER] Analytics Resilience (Phase 24C)
- **Finding:** The "Analytics Fix" identified in the Phase 24A audit (keeping `TimeRangeSelector` visible when no data exists) is mentioned in the high-level spec but missing from the detailed task breakdown.
- **Action:** Add a dedicated task to Phase 24C to modify `analytics_view.dart` and `AnalyticsViewModel` to ensure the selector remains interactive and visible across all data states.

### 2. [BLOCKER] ViewModel-Driven Conversion (Phase 24C)
- **Finding:** Task 4 suggests performing unit conversion directly in `add_edit_weight_view.dart`. This violates the MVVM pattern.
- **Action:** Update the plan to include modifications to `WeightViewModel`. The ViewModel should:
    - Listen to `UnitsPreferenceService`.
    - Provide weight values in the preferred unit for display.
    - Accept weight values in the preferred unit and convert to SI (kg) before calling `WeightService`.

### 3. [CRITICAL] Enum Unification
- **Finding:** `lib/models/units_preference.dart` introduces a new `WeightUnit` enum that duplicates the one in `lib/models/health_data.dart`.
- **Action:** Unify these enums. Recommendation: Move `WeightUnit` and the new `TemperatureUnit` to a common location (e.g., `lib/models/units.dart` or keep in `health_data.dart`) and update all references.

### 4. [IMPORTANT] Landscape Orientation Strategy (Phase 24E)
- **Finding:** The plan mentions `OrientationBuilder` for all screens.
- **Action:** Prefer `MediaQuery.of(context).orientation` for top-level layout decisions to keep the widget tree cleaner. Use `LayoutBuilder` for width-based breakpoints (e.g., tablet vs. phone).

### 5. [MINOR] UI Polish (Phase 24C)
- **Finding:** "Units preference saved" snackbar on every radio selection may be intrusive.
- **Action:** Consider if the immediate UI update is sufficient feedback, or use a less intrusive notification method.

---

## Test Plan Review

The test plan is solid, particularly the use of `MediaQuery` overrides for landscape testing. 

**Additional Requirement:**
- Add a widget test specifically for the "Analytics Resilience" fix to ensure the date selector doesn't disappear when the data list is empty.

---

## Approval Status

**Conditional Approval:** Implementation may proceed on Phase 24C **ONLY AFTER** the blockers above are integrated into the task list and the enum duplication is resolved.

**Clive**  
Review Specialist

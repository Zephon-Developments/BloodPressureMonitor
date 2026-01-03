# Handoff: Tracy → Claudette
## Phase 24C/D/E – Units UI, Accessibility, Landscape (Post-Clive Review)

**Date:** 2026-01-03  
**From:** Tracy (Planning & Architecture)  
**To:** Claudette (Implementation)

---

## What Changed After Clive's Review
- Added explicit Analytics selector resilience task (keep `TimeRangeSelector` visible/usable on empty datasets; persist last range).
- Moved unit conversion responsibilities into `WeightViewModel` (views become presentation-only).
- Standardized `WeightUnit` to the existing definition in `lib/models/health_data.dart`; add `TemperatureUnit` alongside it or in a shared units file—no duplicate enums.
- Orientation guidance: use `MediaQuery.of(context).orientation` + `LayoutBuilder` for breakpoints; avoid wrapping whole trees in `OrientationBuilder`.
- Snackbar guidance: avoid per-tap snackbars for unit selection; prefer passive confirmation or throttled feedback.
- Added widget test requirement for Analytics selector empty-state resilience.

---

## Key Files (Plan Alignments)
- Updated plans: [Documentation/Plans/Phase_24_Units_Accessibility_Plan.md](../Plans/Phase_24_Units_Accessibility_Plan.md), [Documentation/Plans/Phase_24_Implementation_Spec.md](../Plans/Phase_24_Implementation_Spec.md)
- Existing model/service/utils from 24B: `lib/models/units_preference.dart`, `lib/services/units_preference_service.dart`, `lib/utils/unit_conversion.dart`

---

## Implementation Tasks (Actionable)
1) **Analytics Selector Resilience (24C)**
   - Files: `lib/views/analytics/analytics_view.dart`, `lib/viewmodels/analytics_viewmodel.dart`
   - Keep `TimeRangeSelector` rendered regardless of data; retain last-selected range even when results are empty.
   - Add widget test: empty dataset still shows selector and allows range change.

2) **Units Conversion in ViewModels (24C)**
   - Files: `lib/viewmodels/weight_viewmodel.dart`, `lib/views/weight/add_edit_weight_view.dart`
   - Inject `UnitsPreferenceService` into the ViewModel; expose display-ready values and accept preferred-unit input, converting to kg before `WeightService`.
   - Remove conversion logic from the view; keep only unit labels/suffixes.

3) **Enum Unification (24C foundation)**
   - Files: `lib/models/health_data.dart`, `lib/models/units_preference.dart` (and any imports)
   - Use single `WeightUnit` definition (from `health_data.dart`); relocate/add `TemperatureUnit` alongside it or in a shared `units.dart`. Update imports accordingly.

4) **Settings UI Feedback (24C)**
   - Files: `lib/views/appearance_view.dart` or `lib/views/units_settings_view.dart`
   - Avoid per-tap snackbars; consider passive state change or throttled confirmation.

5) **Orientation Strategy (24E)**
   - Files: layouts touched for landscape
   - Use `MediaQuery.of(context).orientation` for top-level decisions and `LayoutBuilder` for width breakpoints; avoid wrapping whole trees in `OrientationBuilder`.

6) **Existing Accessibility Tasks (24D)**
   - Semantics, contrast, high-contrast mode, large text—unchanged but proceed per plan.

---

## Tests to Add/Update
- Widget: Analytics view empty dataset keeps `TimeRangeSelector` visible/usable.
- Widget: Units settings selector interaction (no snackbar spam) still persists preference.
- ViewModel: WeightViewModel converts input/output according to `UnitsPreference` and stores kg via `WeightService`.

Coverage targets remain per Coding Standards: Services ≥85%, Utils ≥90%, Widgets ≥70%.

---

## Notes / Risks
- Ensure migration from 24B remains idempotent; do not reintroduce per-entry units.
- When unifying enums, watch for imports in tests and services to avoid name clashes.

---

Please start implementation on 24C tasks once the above is acknowledged; 24D/24E can follow in sequence per the plan.

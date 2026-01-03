# Phase 24 Implementation Specification (Units, Accessibility, Landscape)

## Objectives
- Implement app-wide units preference (kg vs lbs; future-ready for °C vs °F) while storing canonical SI units.
- Ensure every screen is navigable: back affordance on all detail screens; bottom navigation remains visible where expected.
- Preserve date-range selectors even when no data is available.
- Improve accessibility (semantics, contrast, high-contrast mode, large text scaling).
- Add landscape responsiveness for all major screens (phone + tablet).

## Constraints & Standards
- Follow Documentation/Standards/CODING_STANDARDS.md (§2 formatting, §3 Dart/Flutter, §8 testing).
- Avoid breaking existing routes; no dead-end flows.
- Maintain internal storage in SI units; convert only at IO boundaries.

## Scope & Sequencing (Recommended Phases)
1) **24A Navigation & Date-Range Resilience** (highest UX risk)
2) **24B Units Preference (Model/Service/UI + conversions)**
3) **24C Accessibility Pass (semantics, contrast, HC mode, large text)**
4) **24D Landscape Responsiveness (layouts, charts, forms, history)**

## Navigation & Back Functionality Audit (Actionable)
- **Audit targets** (lib/views/**):
  - Shell/navigation: navigation widget(s), bottom nav container, drawer (if any).
  - Home/dashboard: home_view.dart, quick actions.
  - Detail forms: blood_pressure/add_edit_bp_view.dart; weight/add_edit_weight_view.dart; medication views if present.
  - History: history/bp_full_history_view.dart; history/weight_full_history_view.dart; history_home_view.dart.
  - Analytics: analytics_view.dart; analytics/widgets/*.dart (charts, selectors).
  - Settings/Appearance/Units: appearance_view.dart or settings_view.dart (and subviews).
  - Sleep/medication/other feature screens (ensure back affordance).
- **Checks**:
  - Back navigation available on all non-root screens (AppBar leading/back or in-body back button).
  - Bottom nav bar visible on screens that are part of primary nav (ensure it is not hidden on push routes unless explicitly modal).
  - No screen hides navigation without an alternate back route.
- **Fix patterns**:
  - For pushed detail screens: ensure AppBar(automaticallyImplyLeading: true) or explicit BackButton.
  - For nested navigators: confirm root scaffold retains bottom nav; avoid replacing scaffold when pushing.

## Date Range Selector Resilience (Actionable)
- **Audit targets**:
  - Analytics: analytics_view.dart (time range selector), bp/weight chart widgets.
  - History: bp_full_history_view.dart, weight_full_history_view.dart (any date filters).
- **Required behavior**: selectors remain visible regardless of data presence; display a friendly empty state under the selector (e.g., "No data for selected range").
- **Implementation pattern**:
  - Separate selector widget from data body; render selector unconditionally.
  - For empty data, show empty-state panel but keep selector enabled; avoid returning early from build.
  - Ensure viewmodels do not null out range on empty datasets; keep last selection in state/cache.

## Units Preference
- **New model**: lib/models/units_preference.dart (WeightUnit, TemperatureUnit, UnitsPreference with toJson/fromJson).
- **New service**: lib/services/units_preference_service.dart using SharedPreferences; defaults: kg + Celsius.
- **New utils**: lib/utils/unit_conversion.dart (kg↔lbs, °C↔°F, format helpers) with unit tests.
- **UI integration**: add Units section in settings/appearance (radio/dropdown). Temperature control can be disabled/"coming soon". Avoid snackbar spam on every selection; prefer passive confirmation unless the user exits the screen.
- **Data flow**: Service → ViewModel (settings + consumers) → Views/widgets. Store internal weight in kg; convert at display/input in the ViewModel (not in views). Inject UnitsPreferenceService into WeightViewModel and other consumers to provide display-ready values and accept preferred-unit input.
- **Enums**: Use a single WeightUnit definition (existing in lib/models/health_data.dart); add TemperatureUnit alongside it or in a shared units file to avoid duplication.
- **Touchpoints to update**: weight add/edit, weight history, analytics weight chart, any summaries/reports.

## Accessibility
- **Semantics**: Add labels to icons-only buttons (quick actions, chart toggles, FABs, nav icons), form actions, list item actions. Use Semantics/ExcludeSemantics where needed.
- **Contrast**: Audit chart zones, buttons, text-on-surfaces for WCAG AA. Adjust theme colors if any fail (<4.5:1 normal, <3:1 large).
- **High-Contrast Mode**: Provide theme adjustments or conditional styling if system HC enabled (borders, backgrounds, focus states).
- **Large Text**: Verify at 1.5x/2x; fix overflows with Flexible/Expanded/Wrap/SingleChildScrollView.
- **Analytics resilience**: Keep TimeRangeSelector visible and interactive even when datasets are empty; ensure viewmodel retains last-selected range.

## Landscape Responsiveness
- **Utilities**: Add lib/utils/responsive_utils.dart with helpers (isTablet, isLandscape, shouldUseTwoColumns) if not existing.
- **Layouts to adapt**:
  - Forms (BP, Weight, Medication): two-column in landscape/tablet; scroll-safe with SingleChildScrollView.
  - Home/quick actions: grid in landscape.
  - Analytics: horizontal layout for selector + legend; adjust chart height/padding; legends may move to side.
  - History lists: grid on tablets in landscape; single column on phones.
- **Charts**: Allow chart widgets to accept orientation/layout hints to adjust padding/legend placement.
- **Strategy**: Prefer MediaQuery.of(context).orientation for top-level decisions; use LayoutBuilder for width breakpoints. Avoid wrapping entire screens in OrientationBuilder unless needed.

## Files to Create/Modify
- **New**: lib/models/units_preference.dart; lib/services/units_preference_service.dart; lib/utils/unit_conversion.dart; lib/utils/responsive_utils.dart; test/utils/unit_conversion_test.dart; test/services/units_preference_service_test.dart; test/models/units_preference_test.dart; (optional) test/views/units_settings_view_test.dart.
- **Modify** (indicative):
  - Navigation shell/bottom nav container; ensure persistence across routes.
  - appearance_view.dart or settings_view.dart (+ potential units_settings_view.dart)
  - viewmodels/weight_viewmodel.dart to own conversions based on UnitsPreferenceService
  - views/weight/add_edit_weight_view.dart; views/history/weight_full_history_view.dart; analytics/widgets/weight_chart.dart
  - analytics_view.dart (selector resilience + layout)
  - viewmodels/analytics_viewmodel.dart (retain selector state when empty)
  - history views with date filters (keep selectors visible)
  - bp/weight charts/widgets for landscape + semantics
  - theme_viewmodel.dart if contrast/HC adjustments needed
  - quick action widgets, icons-only buttons for semantics

## Test Plan
- **Units**: conversion utils, preference service save/load defaults, settings UI widget tests, weight views display/input in preferred unit.
- **Navigation**: widget tests for back button presence on detail screens; bottom nav visibility on main routes.
- **Date selectors**: widget tests ensuring selectors remain visible on empty data; empty-state messaging.
- **Accessibility**: semantics tests for key widgets; snapshot contrast verification where feasible.
- **Landscape**: widget tests using MediaQuery overrides for landscape/tablet to assert two-column layouts and absence of overflow.
- **Analytics resilience**: widget test where analytics dataset is empty but TimeRangeSelector remains visible and usable.

## Risks & Mitigations
- Navigation regressions: add focused widget tests on critical flows (home → detail → back).
- Selector regression: ensure viewmodels retain range even when data empty; add tests.
- Landscape complexity on small phones: fall back to portrait-style single column when width < breakpoint.
- Contrast/HC changes: keep theme adjustments scoped and toggleable.

## Open Questions
- Existing preference persistence wrapper? If so, reuse for units service.
- Existing responsive utilities? If present, extend instead of duplicating.
- Any screens already using semantics patterns? Reuse conventions for consistency.

## Next Steps
1) Perform the navigation/back audit and date-selector audit; document concrete findings (per screen) before code changes.
2) Confirm whether to place Units controls in appearance_view.dart or a dedicated units_settings_view.dart.
3) Lock breakpoints for landscape/tablet (e.g., shortestSide >= 600 for tablet; landscape by orientation).

# Phase 24B Implementation Specification: Units Preference

**Author:** Tracy (Planning & Architecture)  
**Date:** 2026-01-02

## Objectives
- Deliver app-wide units preference (weight: kg ↔ lbs; temperature: future-ready °C ↔ °F) while storing all persisted data in SI units.
- Migrate existing weight data to SI-only storage so no persisted entry stores non-kg values or per-entry units.
- Apply preference immediately across weight entry, history, analytics displays, and settings without app restart.
- Maintain compliance with CODING_STANDARDS.md (§2 formatting, §3 Dart/Flutter conventions, §8 testing coverage).

## Scope (Included)
- UnitsPreference model, service, and conversion utilities.
- Settings UI to select weight unit (temperature control stub/disabled until needed).
- Weight input/display paths updated to respect preference; storage remains kg.
- Tests: model, service, utils, settings UI, weight views, conversion accuracy, persistence.

## Constraints
- **Storage:** Always persist weight in kg (SI). No non-SI storage. Temperature future-ready only. Storage must be normalized to kg via migration before enabling the preference.
- **Migration required:** Existing weight entries may store a unit (lbs/kg). Add a one-time migration to convert any lbs values to kg and persist only kg values (set unit metadata to kg or drop it post-migration).
- **Immediate effect:** UI must reflect preference change without restart.
- **Performance:** Conversion is lightweight; avoid unnecessary rebuilds by scoping listeners.
- **Standards:** Follow CODING_STANDARDS (§2 formatting, §3 Dart patterns, §8 coverage ≥85% services, ≥70% widgets).

## Success Metrics
- Users can select kg/lbs in settings; selection persists across app restarts.
- All weight displays convert correctly (±0.1 precision) while storage remains kg.
- Weight inputs accept preferred unit but store kg after conversion.
- One-time migration leaves all stored weights normalized to kg with no remaining lbs values or per-entry unit reliance.
- New tests cover conversions, service persistence, and settings UI; all CI gates green.

## Architecture Overview
- **Model:** `UnitsPreference` encapsulates `weightUnit`, `temperatureUnit` with JSON (map) serialization.
- **Service:** `UnitsPreferenceService` wraps SharedPreferences for load/save; provides defaults (kg, Celsius). Expose async methods returning strong types.
- **Conversion Utils:** `unit_conversion.dart` supplies math + formatting helpers; no state.
- **ViewModel (Settings):** Extend existing settings/appearance viewmodel or add lightweight viewmodel to bridge service ↔ UI; exposes current preference, setters, and notifies listeners.
- **UI Integration:** Settings view (appearance_view or dedicated units_settings_view) renders selectors; uses viewmodel; temperature selector disabled with hint.
- **Consumers:** Weight add/edit view(s), weight history view, analytics weight charts read preference (via Provider or injected service) to convert on display/input; storage stays kg.
- **Migration Flow:** One-time migration normalizes stored weights to kg (detect lbs, convert to kg, persist as kg). After migration, all fetch/save operations treat storage as kg-only.
- **Data Flow:**
   1. Run migration at startup before weight services are used (idempotent, logged).
   2. Load preference from service at app start (e.g., via viewmodel init or provider).
   3. UI binds to preference; selector updates preference via viewmodel → service.
   4. Weight entry: display in chosen unit; on submit convert to kg before save.
   5. Weight display: fetch stored kg, convert to preferred unit for UI.

## File Plan
### New Files
1) `lib/models/units_preference.dart`
   - `enum WeightUnit { kg, lbs }`
   - `enum TemperatureUnit { celsius, fahrenheit }`
   - `class UnitsPreference { WeightUnit weightUnit; TemperatureUnit temperatureUnit; Map<String, dynamic> toJson(); factory UnitsPreference.fromJson(Map<String, dynamic>); }`
   - Defaults: kg, celsius.

2) `lib/services/units_preference_service.dart`
   - Depends on SharedPreferences.
   - `Future<UnitsPreference> getUnitsPreference();`
   - `Future<void> saveUnitsPreference(UnitsPreference pref);`
   - Key names constant; handle missing/corrupt data by returning defaults.

3) `lib/utils/unit_conversion.dart`
   - `double kgToLbs(double kg); double lbsToKg(double lbs); double celsiusToFahrenheit(double c); double fahrenheitToCelsius(double f);`
   - `String formatWeight(double valueKg, WeightUnit unit, {int fractionDigits = 1});` (input in kg for consistency)
   - Optional `formatWeightInput(double value, WeightUnit unit)` helper.

4) (Optional helper if needed) `lib/viewmodels/units_viewmodel.dart`
   - Holds current UnitsPreference; loads on init; exposes `setWeightUnit` / `setTemperatureUnit` (temperature change may be disabled in UI but safe to store).

5) Tests:
   - `test/models/units_preference_test.dart`
   - `test/services/units_preference_service_test.dart`
   - `test/utils/unit_conversion_test.dart`
   - `test/viewmodels/units_viewmodel_test.dart` (if viewmodel added)
   - `test/views/units_settings_view_test.dart` or extend appearance view tests.

### Modified Files (indicative)
- `lib/services/weight_service.dart` (or DAO/migration layer): add one-time migration to normalize stored weights to kg and remove reliance on persisted unit column (set all to kg or drop the column if schema supports it).
- `lib/models/health_data.dart`: adjust `WeightEntry` to treat stored values as kg and deprecate persisted unit usage (unit remains for UI-only as needed).
- `lib/views/appearance_view.dart` (or add `lib/views/units_settings_view.dart`): add units section with radio/set of buttons; temperature control disabled with tooltip.
- `lib/viewmodels/appearance_viewmodel.dart` (or new units viewmodel): integrate service.
- Weight flows:
   - `lib/views/weight/add_weight_view.dart` or `add_edit_weight_view.dart`: remove per-entry unit toggle; display unit label, accept input in preferred unit, convert to kg on save.
   - `lib/views/weight/weight_history_view.dart` and any history cards: convert display values.
   - `lib/views/analytics/widgets/weight_chart.dart` (or equivalent weight chart widget): axis labels/legend in preferred unit; data stays kg.
- Shared providers wiring: ensure UnitsPreference available where needed (e.g., Provider multi-provider setup).

## Sequenced Task Breakdown
1) **Migration Planning + Tests**
   - Add migration in weight storage layer to normalize all persisted weights to kg. Detect entries marked lbs and convert value to kg; set persisted unit metadata to kg (or drop column if schema supports). Ensure idempotent and logged.
   - Tests: migration converts lbs to kg correctly, leaves kg unchanged, safe to rerun.

2) **Model + Tests**
   - Implement `UnitsPreference`, enums, JSON helpers.
   - Tests: default values, round-trip JSON, robustness to missing/unknown keys.

3) **Conversion Utilities + Tests**
   - Implement kg↔lbs, °C↔°F, formatting helpers; clamp/round to fractionDigits.
   - Tests: typical values, edge cases (0, negatives, large), symmetry (kgToLbs → lbsToKg within tolerance).

4) **Service + Tests**
   - Implement SharedPreferences-backed service with defaults and corruption handling.
   - Tests: save/load, defaults when empty, corrupted data fallback, idempotency.

5) **ViewModel Layer** (reuse existing settings VM or new units VM)
   - Load preference on init; expose streams/notifiers.
   - Methods to update weight unit (and temperature future-ready).
   - Tests: state changes, persistence calls, notifyListeners.

6) **Settings UI**
   - Add units section with weight radio (kg/lbs); temperature selector disabled with “Coming soon” hint.
   - Bind to viewmodel; on change → update service and notify.
   - Tests: widget test verifying selector updates preference and persists via mock service.

7) **Weight Input Views**
   - Remove per-entry unit toggle; show preferred unit label; prefill using preferred unit.
   - On submit: convert to kg before saving to model/service layer.
   - Tests: widget test with mock viewmodel/service to assert saved value is kg while UI shows preferred unit.

8) **Weight Display Views & Charts**
   - Convert stored kg to preferred unit for history cards, lists, and analytics weight chart axes/legends.
   - Ensure legends/labels include unit abbreviation.
   - Tests: widget/unit tests asserting displayed text uses preferred unit.

9) **Integration Wiring**
   - Register UnitsPreferenceService/provider at app composition root.
   - Ensure weight-related viewmodels can read preference (inject service or read via provider).
   - Smoke test: preference change triggers UI update without restart.

10) **Documentation & QA Checklist**
   - Update QUICKSTART or settings doc to note units preference location.
   - Prepare checklist for Clive covering: selectors, persistence, migration, input conversion, display conversion, tests, coding standards.

## Data Considerations
- Current schema stores a `WeightUnit` per entry in the database. We must migrate to SI-only storage by converting any lbs entries to kg and persisting as kg.
- Migration should also normalize persisted unit metadata (e.g., set to kg or drop the column if schema allows) to avoid future ambiguity.
- After migration, all services and models should assume stored weights are kg; any presentation-layer conversion must use the preference.

## Edge Cases & Error Handling
- Corrupted preference JSON: fallback to defaults; log once (non-fatal).
- SharedPreferences failure: surface non-blocking snackbar/log; continue with defaults.
- Migration: handle unexpected/missing unit data by defaulting to kg; migration should be safe to rerun and skip already-normalized rows.
- Large/small values: conversions handle doubles; formatting clamps to sensible digits.
- Temperature controls disabled but stored safely; ensure UI prevents change until enabled.

## Testing Strategy
- Unit tests: model JSON, conversion math (tolerance-based), service persistence, viewmodel state.
- Widget tests: settings selector updates preference; weight input converts on save; display views show correct unit labels.
- Integration test (optional if infra exists): end-to-end preference change → weight entry → display.
- CI gates: `flutter analyze`, `dart format --set-exit-if-changed`, full `flutter test` per CODING_STANDARDS.

## Open Decisions / Confirmations Needed
- Location of units UI: extend `appearance_view.dart` vs dedicated `units_settings_view.dart`.
- Preference/service consolidation: confirm whether to keep `ThemePersistenceService` separate or wrap under a unified settings service (to avoid fragmentation) per Clive’s note; non-blocking for migration but decide before wiring providers.
- How to expose UnitsPreference to charts/history: via global provider or injected service per viewmodel.

## Timeline (estimate)
- Spec completion: today (this document).
- Implementation effort: ~2–3 dev days, assuming straightforward preference wiring and minor UI changes.

## Handoff Plan
- Deliver this spec to Clive for review.
- After approval, Claudette to implement following the task breakdown and quality gates above.

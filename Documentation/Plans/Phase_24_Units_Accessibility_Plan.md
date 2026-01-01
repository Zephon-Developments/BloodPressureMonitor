# Phase 24 Plan: Units & Accessibility

**Objective**: Add app-wide units preference (kg vs lbs) and comprehensive accessibility support (semantic labels, contrast verification, high-contrast mode).

## Current State (Audit)
- **Units**: Weight is currently hardcoded to kg; no user preference for units.
- **Future**: Temperature fields (if added) would need °C vs °F preference.
- **Accessibility**: Some widgets lack semantic labels; color contrast not verified; high-contrast mode not tested.
- **User Feedback**: Users in US prefer lbs; UK/Europe prefer kg. Accessibility needed for screen reader users.

## Scope
- Add units preference to Settings (kg vs lbs; future-ready for °C vs °F).
- Create UnitsPreferenceService to persist and retrieve unit preferences.
- Update all weight-related UI to respect unit preference (display and input).
- Add unit conversion utilities (kg ↔ lbs).
- Add semantic labels to all large buttons and interactive elements (screen reader support).
- Verify color contrast for all chart zones and UI elements (WCAG AA compliance).
- Add high-contrast mode support (test with system high-contrast enabled).
- Audit all text for readability with large text scaling (1.5x, 2x).
- Unit and widget tests for units preference and accessibility features.

## Architecture & Components

### 1. Units Preference Model
**New File**: `lib/models/units_preference.dart`
- Model:
  ```dart
  class UnitsPreference {
    final WeightUnit weightUnit;
    final TemperatureUnit temperatureUnit; // Future: for body temp tracking
    
    const UnitsPreference({
      this.weightUnit = WeightUnit.kg,
      this.temperatureUnit = TemperatureUnit.celsius,
    });
  }
  
  enum WeightUnit { kg, lbs }
  enum TemperatureUnit { celsius, fahrenheit }
  ```
- Serialization: `toJson`, `fromJson` for SharedPreferences storage.

### 2. Units Preference Service
**New File**: `lib/services/units_preference_service.dart`
- Persist units preference using SharedPreferences.
- Methods:
  - `Future<UnitsPreference> getUnitsPreference()`
  - `Future<void> saveUnitsPreference(UnitsPreference pref)`
- Default: kg for weight, Celsius for temperature.

### 3. Unit Conversion Utilities
**New File**: `lib/utils/unit_conversion.dart`
- Conversion functions:
  ```dart
  double kgToLbs(double kg) => kg * 2.20462;
  double lbsToKg(double lbs) => lbs / 2.20462;
  double celsiusToFahrenheit(double c) => (c * 9/5) + 32;
  double fahrenheitToCelsius(double f) => (f - 32) * 5/9;
  ```
- Display helpers:
  ```dart
  String formatWeight(double value, WeightUnit unit) {
    return unit == WeightUnit.kg
        ? '${value.toStringAsFixed(1)} kg'
        : '${kgToLbs(value).toStringAsFixed(1)} lbs';
  }
  ```

### 4. Settings UI Extension
**Modified File**: `lib/views/appearance_view.dart` OR new `lib/views/units_settings_view.dart`
- Add "Units" section to Settings (or create separate Units settings page).
- Weight unit selector: Radio buttons or dropdown (kg / lbs).
- Temperature unit selector: Radio buttons or dropdown (°C / °F) - greyed out with "Coming soon" if temp tracking not implemented.
- Save preference on selection; apply immediately.

### 5. Weight UI Updates
**Modified Files**:
- `lib/views/weight/add_edit_weight_view.dart`: Display unit next to input field; convert input based on preference.
- `lib/views/history/weight_full_history_view.dart`: Display weights in preferred unit.
- `lib/views/analytics/widgets/weight_chart.dart`: Axis labels in preferred unit.
- PDF report weight display (Phase 25 dependency).

**Input Handling**:
- Store weights internally as kg (canonical unit).
- Display/input in preferred unit (convert on display, convert back on save).

### 6. Accessibility Enhancements
**Semantic Labels**: Add to all interactive elements:
- Large buttons (quick actions, save/cancel, navigation).
- Chart elements (data points, zones).
- Form fields (already have labels, ensure semantic hints).
- Icons-only buttons (add `Semantics` widget with label).

**Color Contrast Verification**:
- Audit all UI colors against WCAG AA standards (4.5:1 for normal text, 3:1 for large text).
- Tools: Use Flutter DevTools accessibility inspector or online contrast checker.
- Focus areas: Chart zones, buttons, form fields, text on backgrounds.

**High-Contrast Mode**:
- Test app with system high-contrast mode enabled (Android/iOS).
- Ensure all text readable, buttons distinguishable.
- Adjust theme if needed (increase contrast for borders, backgrounds).

**Large Text Scaling**:
- Test with system text scaling at 1.5x, 2x.
- Ensure layouts don't break (use `Flexible`, `Expanded`, `FittedBox` appropriately).
- Audit all fixed-size text; prefer `Theme.of(context).textTheme` styles.

## Implementation Tasks (Detailed)

### Task 1: Units Preference Model & Service
**New File**: `lib/models/units_preference.dart`
**Subtasks**:
1. Define `UnitsPreference` class with `weightUnit` and `temperatureUnit`.
2. Define `WeightUnit` and `TemperatureUnit` enums.
3. Add `toJson` / `fromJson` for serialization.
4. Add DartDoc explaining model purpose.

**Estimated Lines**: ~60 lines.

**New File**: `lib/services/units_preference_service.dart`
**Subtasks**:
1. Implement `getUnitsPreference` (load from SharedPreferences).
2. Implement `saveUnitsPreference` (save to SharedPreferences).
3. Default to kg and Celsius if no preference saved.
4. Add DartDoc for all methods.

**Estimated Lines**: ~80 lines.

### Task 2: Unit Conversion Utilities
**New File**: `lib/utils/unit_conversion.dart`
**Subtasks**:
1. Implement `kgToLbs`, `lbsToKg`, `celsiusToFahrenheit`, `fahrenheitToCelsius`.
2. Implement `formatWeight` helper.
3. Add future helper `formatTemperature` (for body temp).
4. Add unit tests for all conversion functions.
5. Add DartDoc explaining conversion formulas.

**Estimated Lines**: ~100 lines.

### Task 3: Units Settings UI
**Modified File**: `lib/views/appearance_view.dart` (or create new `units_settings_view.dart`)
**Subtasks**:
1. Add "Units" section with weight unit selector (radio buttons: kg / lbs).
2. Add temperature unit selector (greyed out with "Coming soon" tooltip).
3. Load current preference on init (call `UnitsPreferenceService.getUnitsPreference`).
4. On selection change, save preference (call `UnitsPreferenceService.saveUnitsPreference`).
5. Display success snackbar: "Units preference saved".

**Estimated Changes**: +60 lines.

### Task 4: Weight UI Updates
**Modified File**: `lib/views/weight/add_edit_weight_view.dart`
**Subtasks**:
1. Load units preference on init.
2. Display unit suffix on weight input field: "kg" or "lbs".
3. On save, convert input to kg (canonical unit) before storing:
   ```dart
   final weightInKg = unitsPreference.weightUnit == WeightUnit.lbs
       ? lbsToKg(double.parse(weightController.text))
       : double.parse(weightController.text);
   ```
4. On edit, convert stored kg to display unit:
   ```dart
   final displayWeight = unitsPreference.weightUnit == WeightUnit.lbs
       ? kgToLbs(weightEntry.weight)
       : weightEntry.weight;
   weightController.text = displayWeight.toStringAsFixed(1);
   ```

**Estimated Changes**: +30 lines.

**Modified File**: `lib/views/history/weight_full_history_view.dart`
**Subtasks**:
1. Load units preference.
2. Format weight display using `formatWeight` helper.

**Estimated Changes**: +15 lines.

**Modified File**: `lib/views/analytics/widgets/weight_chart.dart`
**Subtasks**:
1. Load units preference.
2. Convert Y-axis data to preferred unit for display.
3. Update Y-axis label: "Weight (kg)" or "Weight (lbs)".

**Estimated Changes**: +20 lines.

### Task 5: Semantic Labels Audit
**Files to Audit**: All views and widgets with interactive elements.
**Pattern**: Wrap icons-only buttons with `Semantics`:
```dart
Semantics(
  label: 'Add blood pressure reading',
  child: IconButton(icon: Icon(Icons.add), onPressed: onAdd),
)
```
**Areas**:
- Home quick actions (Phase 16 widgets).
- History section expansion tiles.
- Chart legend toggles.
- Form save/cancel buttons (ensure labels explicit).
- Navigation icons.

**Estimated Changes**: ~10-15 lines per widget × ~20 widgets = ~250 lines.

### Task 6: Color Contrast Verification
**Process**:
1. Use Flutter DevTools accessibility inspector.
2. Check all text/background combinations.
3. Focus on chart zones (red/yellow/green on white/dark backgrounds).
4. Adjust colors if contrast ratio < 4.5:1 for normal text or < 3:1 for large text.

**Files to Modify** (if adjustments needed):
- `lib/viewmodels/theme_viewmodel.dart`: Adjust ColorScheme if needed.
- Chart widgets: Adjust zone colors.

**Estimated Changes**: ~20 lines (color adjustments).

### Task 7: High-Contrast Mode Support
**Testing**:
1. Enable high-contrast mode on Android/iOS.
2. Navigate through app; identify readability issues.
3. Adjust borders, backgrounds, text colors as needed.

**Files to Modify** (if needed):
- `lib/viewmodels/theme_viewmodel.dart`: Add high-contrast theme variant.

**Estimated Changes**: +30 lines (high-contrast theme adjustments).

### Task 8: Large Text Scaling Audit
**Process**:
1. Enable large text scaling (1.5x, 2x) in system settings.
2. Navigate through app; identify layout breaks (text overflow, button clipping).
3. Fix layouts using `Flexible`, `Expanded`, `FittedBox`, `SingleChildScrollView`.

**Files to Modify**: Any views with layout issues.
**Estimated Changes**: ~10 lines per view × ~10 views = ~100 lines.

## Acceptance Criteria

### Functional
- ✅ Users can select kg or lbs in Settings; preference persists across app restarts.
- ✅ Weight display and input respect unit preference app-wide.
- ✅ Unit conversion is accurate (within 0.1 precision).
- ✅ All interactive elements have semantic labels for screen readers.
- ✅ Color contrast meets WCAG AA standards (4.5:1 for normal text, 3:1 for large text).
- ✅ App is usable with system high-contrast mode enabled.
- ✅ App is usable with large text scaling (1.5x, 2x).

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new services and utilities (§3.2).
- ✅ Unit tests for unit conversion utilities (≥90% coverage per §8.1).
- ✅ Unit tests for UnitsPreferenceService (≥85% coverage per §8.1).
- ✅ Widget tests for units settings UI (≥70% coverage per §8.1).
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ All buttons have semantic labels.
- ✅ Chart elements are accessible (color + text labels).
- ✅ Forms work correctly with screen readers (TalkBack/VoiceOver).
- ✅ High-contrast mode displays correctly.
- ✅ Large text scaling doesn't break layouts.

## Dependencies
- Phase 17 (Appearance Settings): Settings UI exists; can extend with units section.
- Phase 23 (Charts complete): Weight chart exists and can be updated.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Unit conversion rounding errors accumulate | Low | Store canonical unit (kg) internally; convert only for display/input |
| Users confused by unit preference location | Low | Place in Settings → Appearance or create dedicated Units section |
| Accessibility audit reveals many issues | Medium | Prioritize critical issues (screen reader, contrast); defer minor polish to Phase 27 |
| High-contrast mode requires theme redesign | Medium | Start with minor adjustments; full redesign if needed can be deferred |

## Testing Strategy

### Unit Tests
**New File**: `test/utils/unit_conversion_test.dart`
- Test kg ↔ lbs conversion accuracy.
- Test Celsius ↔ Fahrenheit conversion (future).
- Test edge cases: 0, negative values, very large values.

**New File**: `test/services/units_preference_service_test.dart`
- Test save/load units preference.
- Test default values (kg, Celsius).

**New File**: `test/models/units_preference_test.dart`
- Test serialization/deserialization.

**Estimated**: 25 unit tests.

### Widget Tests
**New File**: `test/views/units_settings_view_test.dart` (or modified appearance_view_test.dart)
- Test weight unit selector changes preference.
- Test preference persists (mock SharedPreferences).

**Modified Files**: Weight view tests to verify unit display.
**Estimated**: 15 widget tests.

### Accessibility Tests
**Manual Testing**:
- Enable TalkBack (Android) or VoiceOver (iOS); navigate app; verify all elements announced.
- Enable high-contrast mode; verify readability.
- Set text scaling to 2x; verify layouts work.

**Automated** (if tooling available):
- Run Flutter accessibility scanner (flutter_test semantics).

**Estimated**: 10 manual test scenarios.

### Integration Tests
**New File**: `test_driver/units_preference_test.dart`
- Change weight unit to lbs in Settings.
- Add weight entry; verify saved in kg, displayed in lbs.
- Reopen app; verify preference persists.

**Estimated**: 3 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-24-units-accessibility`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Units preference can be feature-flagged; fall back to kg-only if critical issues.
- Accessibility enhancements are additive; can be reverted individually if needed.
- No schema changes; rollback is non-destructive.

## Performance Considerations
- Unit conversion is lightweight (simple arithmetic); no performance impact.
- Semantic labels add minimal overhead.
- High-contrast theme is static; no runtime performance impact.

## Documentation Updates
- **User-facing**: Add note to QUICKSTART.md explaining units preference location.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 24 complete upon merge.
- **Accessibility notes**: Document semantic label patterns for future widget development.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 3-5 days (including accessibility audit, testing, and review)  
**Target Completion**: TBD based on sprint schedule

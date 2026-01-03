# Phase 24 Plan: Units, Accessibility & Landscape Mode

**Objective**: Add app-wide units preference (kg vs lbs), comprehensive accessibility support (semantic labels, contrast verification, high-contrast mode), and proper landscape mode support for all screens.

## Current State (Audit)
- **Units**: Weight is currently hardcoded to kg; no user preference for units.
- **Future**: Temperature fields (if added) would need °C vs °F preference.
- **Accessibility**: Some widgets lack semantic labels; color contrast not verified; high-contrast mode not tested.
- **Landscape Mode**: App likely portrait-only or has suboptimal landscape layouts; charts and forms may not adapt well to landscape orientation.
- **User Feedback**: Users in US prefer lbs; UK/Europe prefer kg. Accessibility needed for screen reader users. Tablet users request better landscape support.

## Scope
- Add units preference to Settings (kg vs lbs; future-ready for °C vs °F).
- Create UnitsPreferenceService to persist and retrieve unit preferences.
- Update all weight-related UI to respect unit preference (display and input).
- Add unit conversion utilities (kg ↔ lbs).
- Add semantic labels to all large buttons and interactive elements (screen reader support).
- Verify color contrast for all chart zones and UI elements (WCAG AA compliance).
- Add high-contrast mode support (test with system high-contrast enabled).
- Audit all text for readability with large text scaling (1.5x, 2x).
- Implement responsive landscape layouts for all screens (adaptive layouts for tablet/phone landscape).
- Ensure charts, forms, and list views work well in both portrait and landscape orientations.
- Unit and widget tests for units preference, accessibility features, and landscape layouts.
- Ensure that all screens have the navigation bar at the bottom

## Architecture & Components

**Unit enum source**: Reuse the existing WeightUnit from lib/models/health_data.dart and add TemperatureUnit alongside it (or in a shared units file) to avoid duplicate enums. All references in the plan below assume a single shared enum definition.

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
- Temperature unit selector: Radio buttons or dropdown (°C / °F) - greyed out 
- Save preference on selection; apply immediately.
 - Consider passive confirmation (state update) instead of a snackbar on every tap to avoid toast spam; if feedback is needed, batch confirmation on page exit.

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
5. Provide feedback without spamming: prefer in-place state change; if snackbar is used, throttle to once per screen session.

**Estimated Changes**: +60 lines.

### Task 4: Weight UI Updates (ViewModel-driven conversions)
**Modified File**: `lib/viewmodels/weight_viewmodel.dart`
**Subtasks**:
1. Inject `UnitsPreferenceService` (or an exposed `UnitsPreference` stream) into the ViewModel.
2. Expose display-ready weights by converting from kg using the preferred unit.
3. Accept user-entered weight in the preferred unit and convert to kg before calling `WeightService`.
4. Notify listeners when unit preference changes to trigger UI rebuilds.

**Modified File**: `lib/views/weight/add_edit_weight_view.dart`
**Subtasks**:
1. Remove conversion logic from the view; consume display-ready values and submit through the ViewModel.
2. Keep only presentation concerns (unit label/suffix).

**Estimated Changes**: +20 lines in ViewModel; minimal in view.

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

### Task 5: Analytics Selector Resilience (Phase 24C)
**Modified Files**: `lib/views/analytics/analytics_view.dart`, `lib/viewmodels/analytics_viewmodel.dart`
**Subtasks**:
1. Keep `TimeRangeSelector` rendered regardless of data availability.
2. Ensure empty states do not short-circuit selector rendering.
3. Persist last-selected range even when result sets are empty.
4. Add widget test covering empty dataset with visible selector.

### Task 6: Semantic Labels Audit
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

### Task 7: Color Contrast Verification
**Process**:
1. Use Flutter DevTools accessibility inspector.
2. Check all text/background combinations.
3. Focus on chart zones (red/yellow/green on white/dark backgrounds).
4. Adjust colors if contrast ratio < 4.5:1 for normal text or < 3:1 for large text.

**Files to Modify** (if adjustments needed):
- `lib/viewmodels/theme_viewmodel.dart`: Adjust ColorScheme if needed.
- Chart widgets: Adjust zone colors.

**Estimated Changes**: ~20 lines (color adjustments).

### Task 8: High-Contrast Mode Support
**Testing**:
1. Enable high-contrast mode on Android/iOS.
2. Navigate through app; identify readability issues.
3. Adjust borders, backgrounds, text colors as needed.

**Files to Modify** (if needed):
- `lib/viewmodels/theme_viewmodel.dart`: Add high-contrast theme variant.

**Estimated Changes**: +30 lines (high-contrast theme adjustments).

### Task 9: Large Text Scaling Audit
**Process**:
1. Enable large text scaling (1.5x, 2x) in system settings.
2. Navigate through app; identify layout breaks (text overflow, button clipping).
3. Fix layouts using `Flexible`, `Expanded`, `FittedBox`, `SingleChildScrollView`.

**Files to Modify**: Any views with layout issues.
**Estimated Changes**: ~10 lines per view × ~10 views = ~100 lines.

### Task 10: Landscape Mode Support
**Objective**: Ensure all screens adapt sensibly to landscape orientation.

**Strategy**:
1. Use `MediaQuery.of(context).orientation` at top-level layout decisions; use `LayoutBuilder` for width breakpoints (e.g., tablet vs phone). Avoid wrapping everything in `OrientationBuilder` unnecessarily.
2. Use `LayoutBuilder` to get available screen dimensions.
3. Adapt layouts based on width/height ratio.

**Key Patterns**:
- **Forms**: Switch from vertical to horizontal or two-column layout in landscape.
- **Charts**: Expand chart width; reduce padding; adjust legend position.
- **Lists**: Consider two-column grid layout for landscape on tablets.
- **Navigation**: Bottom nav remains; consider side nav for tablets in landscape.

**Files to Modify**:

**Modified File**: `lib/views/home/home_view.dart`
**Subtasks**:
1. Detect orientation using `MediaQuery.of(context).orientation`.
2. In landscape, arrange quick actions in 2 rows × 3 columns or single row if space allows.
3. Adjust chart heights to fit screen better (shorter charts in landscape).
4. Test on phone and tablet simulators.

**Estimated Changes**: +40 lines.

**Modified File**: `lib/views/blood_pressure/add_edit_bp_view.dart`
**Subtasks**:
1. In landscape, arrange form fields in two columns:
   - Left column: Systolic, Diastolic, Pulse
   - Right column: Date/Time, Notes, Tags
2. Use `Row` with two `Expanded` widgets containing form sections.
3. Ensure keyboard doesn't obscure input (use `SingleChildScrollView`).

**Estimated Changes**: +60 lines.

**Modified File**: `lib/views/weight/add_edit_weight_view.dart`
**Subtasks**:
1. In landscape, arrange weight and date/time fields horizontally.
2. Notes field remains full-width below.

**Estimated Changes**: +30 lines.

**Modified File**: `lib/views/analytics/analytics_view.dart`
**Subtasks**:
1. In landscape, expand chart width to full screen width (reduce padding).
2. Move time range selector to top row (horizontal layout).
3. Adjust chart height based on available space.

**Estimated Changes**: +50 lines.

**Modified File**: `lib/views/analytics/widgets/bp_chart.dart` and `weight_chart.dart`
**Subtasks**:
1. Accept orientation parameter or detect internally.
2. In landscape, reduce vertical padding; increase horizontal padding.
3. Adjust legend position (move to right side in landscape if space).

**Estimated Changes**: +30 lines per chart widget.

**Modified File**: `lib/views/history/bp_full_history_view.dart` and `weight_full_history_view.dart`
**Subtasks**:
1. In landscape on tablets, consider two-column grid layout using `GridView`.
2. On phones, keep single-column list in landscape.
3. Use `LayoutBuilder` to check available width (>600dp = tablet).

**Estimated Changes**: +40 lines per history view.

**Modified File**: `lib/views/medication/medication_view.dart` (if applicable)
**Subtasks**:
1. In landscape, consider two-column layout for medication cards.
2. Form views use horizontal layout pattern as above.

**Estimated Changes**: +40 lines.

**Modified File**: `lib/views/settings/settings_view.dart` and sub-views
**Subtasks**:
1. Settings list remains single-column (standard pattern).
2. Ensure scrollable in landscape if needed.

**Estimated Changes**: +10 lines.

**New Utility File**: `lib/utils/responsive_utils.dart`
**Subtasks**:
1. Create helper functions:
   ```dart
   bool isTablet(BuildContext context) => MediaQuery.of(context).size.shortestSide >= 600;
   bool isLandscape(BuildContext context) => MediaQuery.of(context).orientation == Orientation.landscape;
   bool shouldUseTwoColumns(BuildContext context) => isLandscape(context) && isTablet(context);
   ```
2. Add DartDoc explaining responsive design patterns.

**Estimated Lines**: ~60 lines.

**Testing**:
- Test all screens in portrait and landscape on phone simulator (iPhone, Pixel).
- Test all screens in portrait and landscape on tablet simulator (iPad, Android tablet).
- Verify no layout overflow errors.
- Verify charts readable in landscape.
- Verify forms usable in landscape (keyboard doesn't obscure fields).

**Estimated Total Changes for Task 9**: ~400 lines.

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

### Landscape Mode
- ✅ All screens adapt sensibly to landscape orientation.
- ✅ Forms use horizontal or two-column layouts in landscape.
- ✅ Charts expand appropriately in landscape without distortion.
- ✅ No layout overflow errors in landscape mode.
- ✅ Keyboard doesn't obscure input fields in landscape.
- ✅ Tablet landscape layouts use available space effectively (two-column where appropriate).

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
| Landscape layouts break on small phones | Medium | Test on multiple device sizes; use `LayoutBuilder` and breakpoints; fallback to portrait-like layout on very small screens |
| Tablet users expect side navigation in landscape | Low | Defer side nav to future phase; bottom nav acceptable for now |

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

### Landscape Mode Tests
**Modified Files**: All widget tests for views with landscape support.
- Mock `MediaQuery` to test portrait and landscape orientations.
- Verify layout switches correctly (e.g., form fields in two columns in landscape).
- Verify no overflow errors in landscape.

**Example Pattern**:
```dart
testWidgets('BP form uses two-column layout in landscape', (tester) async {
  tester.binding.window.physicalSizeTestValue = Size(800, 400); // Landscape
  tester.binding.window.devicePixelRatioTestValue = 1.0;
  addTearDown(tester.binding.window.clearPhysicalSizeTestValue);
  
  await tester.pumpWidget(/* BP form */);
  
  expect(find.byType(Row), findsWidgets); // Expect horizontal layout
});
```

**Estimated**: 20 widget tests (2 per major view).

### Accessibility Tests
**Manual Testing**:
- Enable TalkBack (Android) or VoiceOver (iOS); navigate app; verify all elements announced.
- Enable high-contrast mode; verify readability.
- Set text scaling to 2x; verify layouts work.

**Automated** (if tooling available):
- Run Flutter accessibility scanner (flutter_test semantics).

**Estimated**: 10 manual test scenarios.

### Landscape Mode Manual Testing
**Device Matrix**:
- iPhone SE (small phone): Portrait + Landscape
- iPhone 15 Pro (standard phone): Portrait + Landscape
- iPad (tablet): Portrait + Landscape
- Android Pixel (phone): Portrait + Landscape
- Android tablet: Portrait + Landscape

**Test Scenarios** (per device):
1. Navigate all screens in portrait; verify layouts.
2. Rotate to landscape; verify layouts adapt.
3. Test form entry in landscape (BP, Weight); verify keyboard doesn't obscure fields.
4. Test charts in landscape; verify readable and properly scaled.
5. Test history lists in landscape; verify scrolling works.

**Estimated**: 25 manual test scenarios (5 scenarios × 5 devices).

### Integration Tests
**New File**: `test_driver/units_preference_test.dart`
- Change weight unit to lbs in Settings.
- Add weight entry; verify saved in kg, displayed in lbs.
- Reopen app; verify preference persists.

**Estimated**: 3 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-24-units-accessibility-landscape`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Units preference can be feature-flagged; fall back to kg-only if critical issues.
- Accessibility enhancements are additive; can be reverted individually if needed.
- Landscape layouts are additive; app remains functional in portrait if landscape support needs rollback.
- No schema changes; rollback is non-destructive.

## Performance Considerations
- Unit conversion is lightweight (simple arithmetic); no performance impact.
- Semantic labels add minimal overhead.
- High-contrast theme is static; no runtime performance impact.
- Landscape layout rebuilds on orientation change; standard Flutter behavior, no performance concerns.
- Use `OrientationBuilder` or `MediaQuery` for efficient orientation detection.

## Documentation Updates
- **User-facing**: Add note to QUICKSTART.md explaining units preference location and landscape mode support.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 24 complete upon merge.
- **Accessibility notes**: Document semantic label patterns for future widget development.
- **Responsive design notes**: Document landscape layout patterns and breakpoints in coding standards or dedicated responsive design guide.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 5-7 days (including accessibility audit, landscape implementation, testing, and review)  
**Target Completion**: TBD based on sprint schedule
## Storage Convention
- All values are stored internally in SI units (e.g., weight in kg, temperature in °C).
- Non-SI units (e.g., lbs, °F) are used only for user display and input conversion; conversions are performed on-the-fly without altering stored data.
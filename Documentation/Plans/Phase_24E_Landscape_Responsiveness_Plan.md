# Phase 24E Plan – Landscape Responsiveness

## Objective
Design and implement landscape-responsive layouts for all major HealthLog screens on phones and tablets, preserving portrait UX while ensuring usability, accessibility, and performance in landscape.

## Scope
- **Home & Navigation**: Home dashboard, bottom navigation shell, quick actions grid.
- **Forms**: Add/Edit BP, Weight, Medication, Sleep; shared form widgets.
- **Analytics**: Analytics view, chart widgets, selectors/legends.
- **History**: History home, BP/Weight/Sleep/Medication history lists and detail sheets.
- **Medication**: List, group list, intake logging flows.
- **Exports/Files**: Export/import screens, File Manager.
- **Settings/About**: Appearance/Units/Settings, About screen.
- **Cross-cutting**: Dialogs/sheets where width allows side-by-side controls; ensure fallbacks on narrow widths.

Out of scope: PDF layout (Phase 25), backup UX (Phase 26), new features beyond layout/responsiveness.

## Constraints & Standards
- Follow CODING_STANDARDS (§2 Git workflow, §3 Dart/Flutter conventions, §8 testing, 80-col guidance, trailing commas).
- No regressions in portrait; feature-flag not required but avoid breaking layouts on small phones.
- Maintain accessibility from Phase 24D (semantics, contrast, large text up to 2.0x, high-contrast toggle compatibility).
- Keep internal units/storage unchanged (Phase 24A–24C). No data/model changes.

## Breakpoints & Utilities
- **Orientation**: Use `MediaQuery.orientation` for primary branch.
- **Tablet detection**: `shortestSide >= 600` (LayoutBuilder width fallback for desktop web if relevant).
- **Column heuristics**:
  - `isLandscape && width >= 900`: 2–3 column grids (charts + legend side-by-side, home quick actions 3+ columns if space).
  - `isLandscape && width >= 720`: 2 columns for forms/lists; legend stacked beside charts.
  - Otherwise: single column.
- **New utility**: `lib/utils/responsive_utils.dart`
  - `bool isLandscape(BuildContext)`
  - `bool isTablet(BuildContext)` (shortestSide >= 600)
  - `int columnsFor(BuildContext, {int max})` (returns 1/2/3 based on width/orientation/max)
  - `double chartHeightFor(BuildContext, {double portraitHeight = 320, double landscapeHeight = 240})`
  - Unit tests for these helpers.

## Design Guidelines by Surface
- **Home/Quick Actions**: Switch to `GridView`/`Wrap` with dynamic column count in landscape; ensure card widths stay ≥160dp; preserve semantics.
- **Forms (BP/Weight/Medication/Sleep)**: Two-column layout in landscape/tablet using `LayoutBuilder`; group related fields (e.g., systolic/diastolic/pulse together). Keep `SingleChildScrollView` and `IntrinsicHeight` avoidance (prefer `Wrap`/`Flexible`). Ensure validation/error text wraps.
- **Analytics**:
  - Allow charts to accept `isLandscape`/`isTablet` hints.
  - Place range selector + legend horizontally in landscape; reduce chart height to avoid overflow.
  - Ensure empty-state still shows selector/legend.
- **History Lists**: Use `SliverGridDelegateWithFixedCrossAxisCount` when `columnsFor >= 2`; maintain single column on phones. Preserve swipe/delete affordances and semantics.
- **Medication Screens**: Lists may go two-column only on tablet/large landscape; dialogs remain single column if narrow.
- **File Manager/Exports**: Use responsive grid for file tiles; keep action bars visible.
- **Settings/Appearance/Units**: Form rows can split label/control horizontally in landscape; respect large-text.
- **Dialogs/Sheets**: Widen content with max width guards; avoid side-by-side if width < 560.

## Implementation Plan (sequenced)
1. **Utilities Foundation**
   - Add `responsive_utils.dart` with helpers + tests.
2. **Home/Navigation**
   - Home view: swap quick actions/list cards to responsive grid/wrap.
   - Ensure bottom nav/header spacing remains stable in landscape.
3. **Forms**
   - BP, Weight, Medication, Sleep add/edit views: adopt responsive 2-column groups; maintain scroll safety.
4. **Analytics**
   - Pass orientation hints to chart widgets; adjust heights/padding; place selector+legend side-by-side when width allows; ensure empty-state keeps selector.
5. **History**
   - History home and per-entity lists: enable grid on wide/landscape; verify swipe/delete still works; adjust item padding.
6. **Medication-specific**
   - Medication list/group views and intake sheet layouts: optional multi-column grids on tablets; keep dialogs usable on phones.
7. **Exports/File Manager**
   - File manager tiles and export/import screens: grid on wide layouts; safeguard text wrapping.
8. **Settings/About**
   - Align labels/controls in two-column rows where space permits; ensure large text and semantics remain intact.
9. **Polish & Regression Pass**
   - Verify portrait unchanged; audit for overflows with 2.0x text; ensure semantics still applied.

## Acceptance Criteria
- All major screens render without overflow in landscape on phone and tablet.
- Forms provide two-column layout when width permits; no clipped controls or validation text.
- Analytics charts/legends/selectors adapt horizontally on wide layouts; selectors always visible.
- History and file grids present multi-column on wide screens; gestures unaffected.
- Accessibility preserved (semantics from Phase 24D remain; large text up to 2.0x works; contrast unchanged).
- Tests: new utility tests; widget tests covering landscape/tablet scenarios; coverage ≥ existing targets (Widgets ≥70%, Models/Utils ≥90%, Services/ViewModels ≥85%).
- Analyzer/test suite pass; no portrait regressions observed in smoke tests.

## Test Plan
- **Unit**: responsive_utils tests for breakpoint logic.
- **Widget (MediaQuery overrides)**:
  - Home quick actions grid switches columns in landscape.
  - BP/Weight form renders two columns in landscape, single in portrait; no overflow with long validation messages.
  - Analytics view shows selector + legend horizontally in landscape; empty-state keeps selector.
  - History list uses grid delegate in landscape tablet; swipe/delete still available.
  - File manager/export grids render multi-column when width allows.
- **Accessibility/UX**: Semantics still present on interactive controls; large text (2.0x) runs without overflow; high-contrast mode unaffected.
- **Performance**: Ensure layout calculations are lightweight (no heavy OrientationBuilder nesting); verify scroll perf unchanged.

## Risks & Mitigations
- **Small phone landscape overflows**: Use conservative breakpoints; fall back to single column when width < 720.
- **Chart layout jitter**: Lock chart heights via helper; avoid nested shrinkwrap; cache legend layouts.
- **Gesture conflicts in grids**: Validate swipe/delete remains functional; add tests where feasible.
- **Large text collisions**: Validate with 2.0x; prefer Wrap/Flexible instead of Row with tight constraints.

## Open Questions
- Any existing responsive helpers to reuse? (None found so far.)
- Should analytics legends move to side only on tablet, or also wide phones? (Assume wide phones allowed when width >= 720; can tune during implementation.)
- Any platform-specific constraints for tablets (e.g., Surface/Chromebook sizing)? Use width-based checks to stay flexible.

## Dependencies
- Existing theming and accessibility work from Phase 24D.
- No schema or data migrations required.

## Deliverables
- New utility: lib/utils/responsive_utils.dart + tests.
- Landscape-aware layout updates across targeted views/widgets.
- Widget tests demonstrating landscape/tablet layouts.
- Updated documentation in this plan; no CHANGELOG entry until implementation PR.

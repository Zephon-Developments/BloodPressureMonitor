# Phase 26 Plan — Issues Resolution (Charts, Meds History, Export/Import)

**Author:** Tracy (Planning Specialist)
**Date:** January 20, 2026
**Branch:** `chore/pr47-cleanup`
**Context Source:** Documentation/Handoffs/Steve_to_Tracy.md

---

## Objectives
- Resolve MAJOR BP chart issue by separating systolic/diastolic visuals with correct NICE bands and synchronized timelines.
- Simplify medication history access and fix UI/data defects (last date ordering, remove extraneous metrics).
- Enrich export/import with profile identity and medical metadata, adding safety warning on profile mismatch.
- Align with CODING_STANDARDS (§2.4 CI, §3 style, §1.1 security, §8 testing).

## Scope (What to Change)
1. **Blood Pressure Charts**: Split into two charts, synchronized X-axis, NICE bands per chart, keep performance ≥500 points.
2. **Settings Navigation**: Remove duplicate "Intake History" entry from Settings; retain History path only.
3. **Medication History UI Bugs**: Fix "last date" ordering; remove 7-day average and adherence rating from summary/front card.
4. **Export Enhancements**: Include profile name + medical info (DOB, patientId, doctorName, clinicName) in JSON/CSV; sanitize PHI in CSV.
5. **Import Enhancements**: Parse profile name/medical info; warn on profile mismatch before writing; allow explicit confirm/cancel.

Out of scope: pulse/weight/sleep charts, new features, profile CRUD UI, export format overhauls beyond added profile fields.

---

## Architecture & Design

### 1) Blood Pressure Charts
- **Approach**: Build a stacked two-chart layout using existing data from AnalyticsViewModel; keep shared date domain.
- **Data**: Reuse `ChartDataSet` or `DualAxisBpData`; compute `minDate/maxDate` once and pass to both charts.
- **UI**: New widget (e.g., `BpSplitChart`) or refactor existing `BpDualAxisChart` to render two `LineChart`s vertically with shared X labels in middle band.
- **Bands**: Use NICE colour guidelines (not the current painter palette) per axis:
  - Systolic: Green 90-134, Yellow 135-149, Orange 150-179, Red ≥180.
  - Diastolic: Green 60-84, Yellow 85-94, Orange 95-119, Red ≥120.
- **Axis sync**: Generate X ticks once; feed to both charts; align `minX/maxX` and `titlesData`. Avoid independent auto-scaling.
- **Performance**: Keep downsampling logic from AnalyticsViewModel; no extra iterations; avoid heavy gradients. Target smoothness at 500+ points.
- **Tooltips/Legends**: Ensure diastolic not negated in tooltip; keep consistent colors.

### 2) Settings Navigation
- Remove Settings tile that routes to MedicationHistoryView; verify remaining navigation (History tab, quick actions) still reachable.
- Adjust any tests referencing the removed tile.

### 3) Medication History Bugs
- **Last date ordering**: Ensure `MedicationIntakeService` sorts intakes DESC by `takenAt` in the database query; verify UI uses returned order (no list reversal). Add viewmodel unit test to assert first item is most recent.
- **Summary/front card cleanup**: History page lists cards for Blood Pressure, Weight, Sleep, Medication; remove 7-day average + adherence rating from the Medication card there; keep name, last taken date, status. Remove related calculations if unused.
- **Constants**: Create/update `lib/constants/clinical_constants.dart` to store NICE thresholds and hex colours (per Guidelines), ensuring single source of truth for charts.

### 4) Export: Profile Metadata
- **Model**: Extend `ExportMetadata` (or add `ProfileExportInfo`) with `profileName`, `dateOfBirth`, `patientId`, `doctorName`, `clinicName`.
- **JSON**: Include profile block in metadata section; keep existing versioning. Preserve nulls.
- **CSV**: Add metadata rows (e.g., `Profile Name`, `DOB`, `Patient ID`, `Doctor`, `Clinic`). Run `_sanitizeCsvCell` on all PHI fields.
- **UI**: No change besides ensuring profile name sourced from ActiveProfileViewModel.

### 5) Import: Profile Metadata & Warning
- **Parsing**: Read profile block from JSON/CSV metadata; store in ImportResult or a new `ImportProfileInfo`.
- **Comparison**: In ImportViewModel, compare imported profile name vs active profile name (name-only comparison per guidance).
- **Warning UX**: Before import execution, show dialog with both names, explain risk, offer Cancel/Proceed. Default to cancel on mismatch. If imported name missing (legacy), skip warning but log info; if active profile unnamed, still show mismatch if imported has name. Do not include medical metadata differences in the warning.
- **Write Safety**: Do not mutate DB until user confirms (especially in overwrite mode).

---

## File-Level Change Plan

### Charts
- `lib/views/analytics/widgets/bp_dual_axis_chart.dart` (or new `bp_split_chart.dart`): Implement two-chart layout, shared X domain, band painters per axis, updated tooltips.
- `lib/views/analytics/widgets/bp_line_chart.dart` (if reused): Optionally deprecate or wrap for split view.
- `lib/views/analytics/painters/clinical_band_painter.dart` & `split_clinical_band_painter.dart`: Add per-axis ranges; ensure colors/opacities match NICE.
- `lib/viewmodels/analytics_viewmodel.dart`: Expose shared axis data if needed; ensure downsampling unaffected.
- Tests: new widget tests for axis sync and band rendering; viewmodel tests for domain.

### Settings Navigation
- `lib/views/home_view.dart`: Remove Settings ListTile for Intake History.
- Tests: adjust home_view tests expecting tile.

### Medication History
- `lib/views/medication/medication_history_view.dart`: Verify ordering usage; adjust UI if needed.
- `lib/viewmodels/medication_intake_viewmodel.dart` and `services/medication_intake_service.dart`: Enforce DESC ordering; remove unused summary metrics if present.
- Summary card file (likely in history overview widget): Remove 7-day average/adherence display.
- Tests: add ordering test; adjust widget snapshots.

### Export
- `lib/models/export_import.dart`: Extend metadata with profile fields.
- `lib/services/export_service.dart`: Populate metadata; add CSV header rows with sanitized values; ensure filename generation unaffected.
- `lib/viewmodels/export_viewmodel.dart`: Pass profile name (already) but ensure metadata inclusion.
- Tests: update/export_service_test for new metadata; JSON/CSV assertions; sanitization coverage.

### Import
- `lib/models/export_import.dart`: Add import-side profile info structure.
- `lib/services/import_service.dart`: Parse profile metadata; surface in result; no writes before confirm.
- `lib/viewmodels/import_viewmodel.dart`: Store imported profile info; expose mismatch flag; gate import on confirmation.
- `lib/views/import_view.dart`: Add mismatch dialog; show names; block until user confirms.
- Tests: import_service_test for metadata parsing; import_viewmodel_test for mismatch flag; import_view widget test for dialog flow.

---

### Sequencing & Milestones
1. **Foundations**: Extend models (export/import metadata). Update service signatures; adjust tests for data structures.
2. **Import Warning Flow**: Implement viewmodel + view warning UX; ensure no DB writes pre-confirmation.
3. **Export Metadata**: Add profile fields to JSON/CSV; sanitize; update tests.
4. **Medication History Fixes**: Enforce DESC ordering; remove summary metrics on the History page card; adjust widgets/tests.
5. **Settings Navigation Cleanup**: Remove duplicate tile; fix affected tests.
6. **BP Chart Redesign**: Implement split charts, bands (NICE colours), axis sync; add widget tests; verify performance assumptions.

Parallelizable: (1)-(3) can proceed together; (4)-(5) in parallel; (6) last to leverage existing analytics structures.

---

## Testing & Documentation Strategy
- **Unit**: Models (export/import metadata), services (export/import parsing, sanitization), viewmodels (import mismatch gating, medication ordering). Target ≥85% coverage for ViewModels/Services and ≥90% for Models (§8.1).
- **Widget**: BP split chart axis/band rendering; import warning dialog; home_view tile removal snapshot; medication history list ordering. Target ≥70% coverage (§8.1).
- **Integration**: Export→Import round-trip with profile metadata and mismatch warning (happy path + mismatch path).
- **Performance**: Manual/bench check split charts at 500+ points; ensure no regressions.
- **CI**: flutter analyze; flutter test; dart format.
- **Documentation**: Provide `///` JSDoc for all new public classes, methods, and properties (e.g., in `ExportMetadata`, `ImportService`, and `BpSplitChart`) per §10.1.

---

## Risks & Mitigations
- **Backward compatibility**: Legacy exports without profile info. Mitigation: tolerate missing metadata; no warnings.
- **User friction**: Over-warn on profiles with similar names. Mitigation: clear copy and option to proceed.
- **Chart layout complexity**: X-axis sync misalignments. Mitigation: shared domain + single tick generator; widget test.
- **CSV formatting**: Added header rows may affect consumers. Mitigation: document headers; keep data tables unchanged.
- **DB writes pre-confirm**: Ensure import service not called until user confirms.

---

## Decisions on Previous Open Questions
1) PDF export: Defer; next phase will redesign PDF—no changes now.
2) Bands palette: Use NICE colour guidelines; do not reuse current painter palette.
3) Front card location: History page cards (Blood Pressure, Weight, Sleep, Medication); adjust Medication card there.
4) Mismatch warning: Compare and display **name only**; do not surface medical metadata differences.

---

## Success Criteria
- BP charts show separate systolic/diastolic with correct NICE bands and synchronized timelines; no inverted diastolic values.
- Settings offers a single, unambiguous path to medication history.
- Medication history shows most recent date first; summary card free of 7-day average/adherence.
- Exports include profile name + medical metadata (JSON + CSV) with PHI sanitized in CSV.
- Imports parse profile metadata and warn before mismatched-profile import; user can cancel safely.
- Analyzer/test/format all pass per §2.4; coverage meets §8.1 thresholds.

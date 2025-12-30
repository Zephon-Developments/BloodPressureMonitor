# Tracy → Clive Handoff: Phase 10 Code Review Fix Plan

**Date:** December 30, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Branch:** feature/export-reports  
**Context:** Address 6 code-review issues on Export/Import/Report features before merging PR #21

---

## Objectives & Success Criteria
- Remove hardcoded profile data and align with multi-profile architecture. (Coding Standards §1.1 Security/ Reliability)
- Fix misleading import result messaging and null-safety crash risk. (Coding Standards §1.2 Fail fast/clearly)
- Mitigate CSV formula injection risk in exports. (Coding Standards §1.1 Security First)
- Keep analyzer clean and tests green; add targeted coverage for fixes. (Coding Standards §2.4 CI, §2.5 Pre-Commit)

Success = All six review comments resolved, tests updated, analyzer clean, and multi-profile behavior verified in export/import/report flows.

---

## Scope (what to change)
1) **Profile IDs/Names hardcoded** in [lib/views/export_view.dart](lib/views/export_view.dart), [lib/views/import_view.dart](lib/views/import_view.dart), [lib/views/report_view.dart](lib/views/report_view.dart) → must consume active profile state.
2) **Import result messaging** in [lib/views/import_view.dart](lib/views/import_view.dart) → differentiate success vs partial vs failure when `importResult.errors` present.
3) **Null-safety for chart capture** in [lib/views/report_view.dart](lib/views/report_view.dart) → guard `_chartKey.currentContext` before casting.
4) **CSV formula injection** in [lib/services/export_service.dart](lib/services/export_service.dart) → sanitize user-controlled strings before writing CSV.

Out of scope: feature expansion, UI redesign, profile CRUD; focus only on the review findings.

---

## Architecture & Approach

### A. Active Profile propagation
- **Source**: Use existing [lib/services/profile_service.dart](lib/services/profile_service.dart) plus a lightweight `ActiveProfileViewModel` (ChangeNotifier) that stores `activeProfileId` and `activeProfileName`, with a simple `loadInitial()` that defaults to the first profile or creates a fallback profile if none exists (assumption).
- **Provision**: Register `ActiveProfileViewModel` in `MultiProvider` in [lib/main.dart](lib/main.dart) near other viewmodels. Persist the active profile ID/name in SharedPreferences for session continuity.
- **Consumption**: Export/Import/Report views read the active profile from `ActiveProfileViewModel` (Consumer/Selector) and pass into their viewmodels. Avoid duplicating profile props inside those viewmodels; instead pass them as parameters when invoking export/import/report methods.
- **Tests**: Add viewmodel-level tests (or widget tests with a fake ActiveProfileViewModel) to confirm profile values flow to service calls.

### B. Import result messaging
- Add a simple status classification:
	- **Success**: `errors.isEmpty` and at least one entity imported → show “Import Successful!”.
	- **Partial**: `errors.isNotEmpty` AND some imported counts > 0 → show “Import completed with errors” and render errors list.
	- **Failure**: `errors.isNotEmpty` AND all imported counts == 0 → show “Import failed” and errors list.
- Surface errors list (from `importResult.errors`) in the UI for partial/failure states.

### C. Null-safe chart capture in report
- Before using `_chartKey.currentContext`, guard for null. If null, set a user-facing error (`reportVm`) and skip capture; do not crash.
- Only cast `RenderRepaintBoundary` when context is non-null and mounted.

### D. CSV sanitization against formula injection
- Introduce `_sanitizeCsvCell(String?) -> String?` in [lib/services/export_service.dart](lib/services/export_service.dart) that:
	- Returns null when input is null.
	- Trims leading whitespace for inspection, then if the first non-whitespace char is one of `=`, `+`, `-`, `@`, prefix with a single quote `'`.
	- Preserves original content otherwise.
- Apply to **all user-controlled text fields** across entities before appending to CSV rows:
	- Readings: `tags`, `note`, `medsContext` (if free text), `posture`, `arm` (still sanitize defensively).
	- Weight: `notes`, `saltIntake`, `exerciseLevel`, `stressLevel`, `sleepQuality` (all strings).
	- Sleep: `notes`, `source` string.
	- Medications: `name`, `dosage`, `unit`, `frequency`.
	- Medication intakes: `note`.
- Keep JSON export unchanged to avoid breaking round-trip.
- Document the sanitization behavior in method DartDoc and tests.

---

## Implementation Plan (stepwise)
1) **ActiveProfileViewModel**
	 - Create `ActiveProfileViewModel` with: `int activeProfileId`, `String activeProfileName`, async `loadInitial()`, `setActive(Profile)` persisting to SharedPreferences.
	 - Register provider in [lib/main.dart](lib/main.dart) and ensure `HomeView`/others can later expose profile selection (not in scope to build UI now).
	 - Update Export/Import/Report views to read profile from ActiveProfileViewModel and pass to viewmodel calls. Remove hardcoded literals.

2) **View adjustments**
	 - [lib/views/export_view.dart](lib/views/export_view.dart): `_handleExport` obtains `profileId/profileName` from ActiveProfileViewModel (maybe via `context.read<ActiveProfileViewModel>()`).
	 - [lib/views/import_view.dart](lib/views/import_view.dart): `_handleImport` uses active profile; no hardcoded `1`.
	 - [lib/views/report_view.dart](lib/views/report_view.dart): `_generateReport` uses active profile; add null guard for `_chartKey.currentContext` and surface friendly error if capture skipped.

3) **Import result messaging**
	 - Add helper to compute status (success/partial/failure) based on `importResult` counts and errors; adjust header text and color/icon accordingly.
	 - Render errors list (bulleted) when present.

4) **CSV sanitization**
	 - Add `_sanitizeCsvCell` helper and apply to every string cell before pushing to `rows` in [lib/services/export_service.dart](lib/services/export_service.dart).
	 - Add unit tests for sanitization (e.g., values starting with `=SUM(A1)`, `@cmd`, ` -1`, whitespace-prefixed cases) and ensure normal strings remain unchanged.
	 - Add integration-style test for CSV export to ensure sanitized outputs are present in generated CSV.

5) **Error handling for chart capture**
	 - If context/boundary null, set error on `ReportViewModel` and return early; ensure UI shows message instead of crashing.

6) **Docs & comments**
	 - Update DartDoc for export service to mention CSV sanitization.
	 - Brief inline comment in views where profile is pulled from ActiveProfileViewModel (clarify source of profile context).

---

## Testing Strategy
- **Unit tests**:
	- ExportService sanitization helper: covers leading `= + - @`, whitespace before formula chars, null/empty passthrough.
	- ExportService CSV export includes sanitized values for readings/weights/sleep/meds.
- **Widget tests**:
	- ImportView messaging: scenarios for success, partial (with errors), failure (all errors) to verify titles and error list rendering.
	- ExportView/ReportView: ensure they call viewmodels with active profile (use fake ActiveProfileViewModel).
- **Lifecycle tests**:
	- ReportView chart capture: when `_chartKey.currentContext` is null, no crash and error is shown.
- Maintain analyzer clean; run `flutter test` and `flutter analyze` per Coding Standards §2.4.

---

## Risks / Open Questions
- **Active profile source**: There is no existing active-profile selector in UI; assumption is a single default profile. We will default to the first profile or fallback profile named “User” if none exist. Confirm if a selector is coming soon.
- **Sanitization compatibility**: Prefixing `'` may appear in CSV cells in Excel; acceptable trade-off for security. If not acceptable, need an alternative (e.g., escaping with tab). Recommendation: keep `'`.
- **Chart capture timing**: If users trigger PDF before chart paints, capture might skip; we handle gracefully but UX might show “chart unavailable”. Optionally disable button until a short post-frame delay (not in scope unless requested).

---

## Request for Review
Please review the above plan with focus on:
1. Appropriateness of ActiveProfileViewModel approach and defaulting strategy.
2. CSV sanitization method and coverage scope across entities.
3. Messaging logic for partial imports.
4. Null-safety handling for chart capture.

If approved, I will hand off to implementation immediately on `feature/export-reports` to unblock PR #21.


# Phase 15 Plan: Reminder Removal

**Objective**: Remove all reminder-related schema, code, and UI while preserving existing health data and stability.

## Audit Findings (Dec 31, 2025)
- **Schema**: `DatabaseService` creates `Reminder` table (version 4 schema).
- **Model**: `lib/models/health_data.dart` defines `Reminder` data class (unused elsewhere).
- **UI**: `lib/views/home_view.dart` has a disabled "Reminders" ListTile placeholder.
- **Services/ViewModels/Tests**: No other references found (static search across `lib/` and `test/`).

## Scope
- Database: Remove `Reminder` table and any dependent artifacts; bump schema version.
- Code: Remove reminder model and any unused imports/exports.
- UI: Remove reminder placeholder tile from Settings list.
- Docs: Note removal and data drop in release notes/CHANGELOG (future PR) and architecture docs if needed.

## Implementation Tasks (Detailed)

1) Schema Migration (Coding_Standards §2.1/§2.4, §8.1)
- Bump `_databaseVersion` to **5** in `DatabaseService`.
- `_onCreate`: remove creation of `Reminder` table.
- `_onUpgrade` (oldVersion < 5):
	- Drop `Reminder` table if it exists (`DROP TABLE IF EXISTS Reminder;`).
	- Optional: vacuum is not required; keep migration fast/safe.
- Add migration test fixture with `Reminder` data to validate forward-only drop succeeds without impacting other tables.

2) Model Removal
- Delete `Reminder` class from `lib/models/health_data.dart`; ensure exports/imports unaffected (class is currently unused elsewhere).

3) UI Cleanup
- Remove the disabled Reminders ListTile block from `lib/views/home_view.dart` (Settings section).

4) Documentation
- Update release notes/CHANGELOG entry in implementation PR to state: "Reminder feature removed; reminder data dropped during migration".
- Confirm `Implementation_Schedule.md` reflects Phase 15 scope and completion when done.

## Acceptance Criteria
- App builds and runs with **no reminder references** in schema, models, or UI.
- Migration from v4 → v5 succeeds on legacy databases containing Reminder rows; no impact to other tables.
- Quality gates pass: `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test`.
- Coverage meets Coding_Standards §8.1 minima: Services/ViewModels ≥85%, Models/Utils ≥90%, Widgets ≥70% (unchanged by removals).
- Manual regression: medication intake logging and exports continue to function without reminder context.

## Risks & Mitigations
- **Migration failure on legacy data**: Mitigate with migration test using fixture DB containing Reminder rows; use `DROP TABLE IF EXISTS`.
- **Residual references**: Mitigate with repo-wide search for `Reminder`, `reminder`, `notifications` and full analyzer/test runs.
- **User expectation**: Communicate removal in release notes; data is intentionally dropped.

## Workflow
- Branch: `feature/remove-reminders`.
- Follow Coding_Standards §2.1 (branching) and §2.4 (CI gates); all changes via PR.

## Testing Strategy
- Add a migration test that opens a v4 fixture with Reminder data and verifies v5 schema (table absent, other tables intact, data preserved elsewhere).
- Run full suite: `flutter analyze`, `dart format --set-exit-if-changed lib test`, `flutter test` (target coverage per §8.1).

## Rollback Plan
- If migration issues arise post-merge, ship a hotfix migration (v6) to correct schema. Data loss is acceptable for reminders per scope; no rollback of dropped data.

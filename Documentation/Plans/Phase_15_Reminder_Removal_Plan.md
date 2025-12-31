# Phase 15 Plan: Reminder Removal

**Objective**: Remove all reminder-related schema, code, and UI while preserving existing health data and stability.

## Scope
- Database: Drop Reminder table and related FKs/columns; ensure remaining schema integrity.
- Code: Remove reminder models, services/DAOs, scheduled notification hooks, and UI.
- UX: Remove late/missed indicators derived from reminder schedules; retain manual intake logging.
- Docs: Update help/notes to reflect removal and data impact.

## Tasks
1) Schema Migration
- Add migration to drop Reminder table and any dependent FKs/columns.
- Verify forward-only migration is safe; include defensive checks for legacy installs.

2) Code Deletion
- Remove reminder model/service/DAO files and notification scheduling code.
- Clean up imports, provider registrations, and DI wiring.

3) UI Cleanup
- Remove reminder-related views/widgets and schedule-derived indicators.
- Ensure medication intake flows remain manual timestamp only.

4) Documentation
- Update docs/release notes to state reminders are removed and data is dropped during migration.

## Acceptance Criteria
- App builds and runs with no reminder references; migration succeeds on legacy databases with reminder data.
- Tests/analyzer pass; coverage meets targets (Services/ViewModels ≥85%, Models/Utils ≥90%, Widgets ≥70%).
- Manual regression: medication intake logging works as before without reminder context.

## Dependencies
- Phase 1 schema foundation; features through Phase 13.

## Risks & Mitigations
- Risk: Migration failures on dirty data. Mitigation: Test against fixture DBs containing reminders; add defensive SQL checks.
- Risk: Residual references causing runtime errors. Mitigation: Static search for reminder identifiers and run analyzer/tests.

## Branching & Workflow
- Branch: `feature/remove-reminders`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- Migration test on legacy DB fixtures with Reminder data.
- Unit tests for remaining medication intake flows; ensure no reminder dependencies remain.
- Full test suite + analyzer + format.

## Rollback Plan
- If migration issues arise, hold release; consider gating migration behind a runtime check or shipping a hotfix migration after root-cause.

# Phase 16 Plan: Profile-Centric UI Redesign

**Objective**: Deliver a carer-friendly, profile-first experience with rapid logging and strict profile isolation.

## Scope
- New launch Profile Picker (post security gate) with add/edit/delete, avatars, notes.
- Persistent profile switcher in main shell; clear active-profile indication.
- Home redesign with quick actions (BP, medication intake, weight, sleep) plus links to history, analytics, medications, exports/reports, settings.
- Profile isolation audit and refresh hooks across ViewModels and services.

## Tasks
1) Shell & Navigation
- Add Profile Picker screen; wire to ActiveProfileViewModel.
- Add persistent profile switcher (app bar/avatar/dropdown) and global refresh on change.

2) Home Redesign
- Implement hero quick actions and secondary navigation tiles.
- Ensure accessibility labels and responsive layouts for large text.

3) Profile Management
- CRUD with avatar picker and notes; delete confirmation with data impact warning.
- Ensure profile change propagates to data queries and caches.

4) Data Isolation Audit
- Audit services/ViewModels for active-profile scoping; clear caches on profile switch.
- Add mounted checks for async UI updates.

## Acceptance Criteria
- From unlock to logging any entry ≤2 taps.
- Profile switch updates all views with zero cross-profile leakage.
- Widget tests cover profile switcher, quick actions, profile CRUD.
- Analyzer/tests pass; coverage targets met (Services/ViewModels ≥85%, Widgets ≥70%).

## Dependencies
- Phases 1–13 complete; Phase 14 rebrand strings; Phase 15 reminder removal done.

## Risks & Mitigations
- Risk: Stale data after profile switch. Mitigation: Central refresh hooks and cache invalidation.
- Risk: Layout regressions with large text. Mitigation: Responsive constraints and accessibility testing.

## Branching & Workflow
- Branch: `feature/phase-16-profile-ui`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- Widget tests for Profile Picker, switcher, quick actions, and navigation tiles.
- Unit tests for ActiveProfileViewModel and cache invalidation.
- Regression tests for data queries scoped by active profile.

## Rollback Plan
- Feature-flag the new shell; fall back to existing navigation if critical issues arise.

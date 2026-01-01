# Phase 16 Plan: Profile-Centric UI Redesign

**Objective**: Deliver a carer-friendly, profile-first experience with rapid logging and strict profile isolation.

## Current State (Audit)
- Profiles exist (models/services) but UI is not profile-first; switcher is limited and not persistent.
- Home shows quick actions and navigation cards but lacks profile context and rapid per-profile switching.
- Active profile scoping exists in services/viewmodels; requires refresh + cache invalidation on switch.

## Scope
- New launch Profile Picker (post security gate) with add/edit/delete, avatars, notes.
- Persistent profile switcher in main shell; clear active-profile indication everywhere (app bar + home header).
- Home redesign emphasizing quick actions (BP, medication intake, weight, sleep) plus navigation tiles (history, analytics, medications, exports/reports, settings).
- Profile isolation audit and refresh hooks across ViewModels/services; ensure cache invalidation on switch.

## Architecture & Components
- **Navigation/Shell**: Update main shell to include a profile switcher widget (avatar + name) available on all tabs.
- **Profile Picker**: Modal or full-screen post-lock screen; CRUD flows backed by ProfileService with validation.
- **State Management**: Central `ActiveProfileViewModel` to emit switch events; consumers subscribe and refresh.
- **Home Layout**: Sectioned layout (hero quick actions + secondary tiles) with active profile context header.
- **Accessibility**: Large text support, semantic labels on quick actions and switcher controls.

## Tasks
1) Shell & Navigation
- Add Profile Picker screen; wire to ActiveProfileViewModel; show immediately after the security gate/lock screen when multiple profiles exist.
- Add persistent profile switcher (app bar/avatar/dropdown) and broadcast switch events to dependent ViewModels.

2) Home Redesign
- Implement hero quick actions (BP reading, medication intake, weight, sleep) and secondary navigation tiles (history, analytics, medications, exports/reports, settings).
- Ensure responsive layout for large text and small screens; add semantic labels.

3) Profile Management
- CRUD with avatar picker and notes; delete confirmation warns about data impact (per-profile data deletion risk).
- On save/delete, trigger ActiveProfileViewModel refresh and invalidate caches.

4) Data Isolation Audit
- Audit services/ViewModels for active-profile scoping; clear caches and reload queries on profile switch.
- Add mounted checks for async UI updates; ensure no cross-profile leakage.
- Subscription management: cancel/tear down profile-scoped listeners/streams before attaching new ones on switch.

5) Documentation
- DartDoc for all new public APIs (e.g., Profile Picker UI elements, ActiveProfileViewModel extensions, switcher widgets).

## Acceptance Criteria
- From unlock to logging any entry ≤2 taps for existing profile.
- Profile switch updates all views with zero cross-profile leakage (history, analytics, medications, exports).
- Widget tests cover profile switcher, quick actions, profile CRUD.
- Analyzer/tests pass; coverage targets met (Services/ViewModels ≥85%, Widgets ≥70%).

## Dependencies
- Phases 1–15 complete (schema, security gate, rebrand, reminder removal).

## Risks & Mitigations
- Risk: Stale data after profile switch. Mitigation: Central refresh hooks + cache invalidation, explicit reload on switch.
- Risk: Layout regressions with large text. Mitigation: Responsive constraints + accessibility tests.
- Risk: Accidental cross-profile writes. Mitigation: Enforce active profile ID on all create/update calls; add assertions in ViewModels.

## Branching & Workflow
- Branch: `feature/phase-16-profile-ui`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- Widget tests: Profile Picker, profile switcher, home quick actions/tiles, profile CRUD.
- Unit tests: ActiveProfileViewModel switch handling, cache invalidation hooks, service guards enforcing active profile.
- Regression: Data queries scoped by active profile; ensure history/analytics/medications respect switch.

## Rollback Plan
- Feature-flag the new shell/switcher; fall back to existing navigation if critical issues arise.

# Phase 11 Plan: Medication Records UI

**Author:** Tracy (Planner)  
**Date:** December 30, 2025  
**Status:** Draft for Review  
**Phase:** 11 - Medication Records UI  

## Objectives
- Deliver a complete medication management UI that supports CRUD for medications, intake logging, history browsing, and search/filtering.
- Ensure all flows are profile-scoped using `ActiveProfileViewModel` and existing medication services.
- Maintain security, reliability, and testability per Coding Standards (see Documentation/Standards/Coding_Standards.md).

## Scope
- Medication list view with search, filters (active/inactive/group), add/edit/delete.
- Add/Edit medication form with validation (name, dosage, unit, frequency, schedule metadata, group selection, notes).
- Medication intake logging UI (single and group intake) with scheduled vs unscheduled handling.
- Medication history view (intake timeline with status: on-time/late/missed/unscheduled) and per-medication filter.
- Optional: intake markers overlay on BP charts (align with AnalyticsViewModel hooks).
- Profile-aware: all queries/actions use active profile.

## Constraints & Standards
- Follow provider + ChangeNotifier patterns; avoid global singletons beyond existing services.
- Zero analyzer warnings; code formatted; public APIs with DartDoc.
- Tests: ≥85% service/viewmodel coverage; ≥75% widget coverage for new screens.
- Performance: list views use `ListView.builder`; paginate or lazy-load history if needed.
- Security: validate all user inputs (Validators); guard against null contexts in async UI flows.

## Architecture & Data Flow
- **ViewModels**
  - `MedicationViewModel`
    - Dependencies: MedicationService, ActiveProfileViewModel.
    - State: `List<Medication> medications`, `bool isLoading`, `String? error`, `String searchTerm`, `bool showInactive`, `int? selectedGroupId`.
    - Actions: loadMedications(), search(term), toggleInactive(), create/update/delete (soft delete), refresh after mutations.
  - `MedicationIntakeViewModel`
    - Dependencies: MedicationIntakeService, MedicationService (for metadata/schedule), ActiveProfileViewModel.
    - State: `List<MedicationIntake> intakes`, `bool isLoading`, `String? error`, filters (from/to, medicationId, groupId), status resolution helper using `calculateStatus`.
    - Actions: logIntake(intake), logGroupIntake(ids,...), loadIntakes(filters), compute status for display badges.
  - `MedicationGroupViewModel` (lightweight)
    - Dependencies: MedicationGroupService, ActiveProfileViewModel.
    - State: groups list; create/update/delete; used for filter and group selection.
- **Views**
  - Medication List Screen: search bar, filter chips (active/inactive, group), list tiles with dosage/frequency badges; FAB/add button.
  - Medication Form Screen: fields (name, dosage, unit dropdown, frequency dropdown/custom, schedule metadata editor, group selector, notes), validation messages; supports edit mode.
  - Intake Logging Sheet: select medications (multi-select), takenAt (default now), scheduledFor (optional), note, group; quick action per medication row.
  - History View: reverse-chronological intakes with status chips (on-time/late/missed/unscheduled), filter by medication/group/date; supports share/export via existing ExportService? (optional, future).
  - Optional: BP Chart Overlay: intake markers sourced via MedicationIntakeService.findIntakesAround(anchor: reading time).

## Sequencing
1. **Scaffolding & DI**
   - Wire new viewmodels into `main.dart` providers using existing services and `ActiveProfileViewModel`.
2. **MedicationViewModel + List View**
   - Implement load/search/filter; list UI with active/inactive toggle and group filter; edit/delete actions.
3. **Medication Form**
   - Add form widget with validation; support create/update; integrate with list refresh.
4. **MedicationIntakeViewModel + Logging UI**
   - Implement logIntake/logGroupIntake; build intake logging sheet/modal accessible from list and history.
5. **History View**
   - Implement filtered timeline with status chips using `calculateStatus`; add pagination/lazy load if needed.
6. **Intake Markers (Optional)**
   - Add markers overlay to existing BP chart; ensure toggles and performance.
7. **Testing**
   - Unit tests for viewmodels (CRUD, filters, status calculation).
   - Widget tests for list, form, history, and intake logging flows.
   - Integration smoke test: create med → log intake → verify history and filters.

## UI/UX Notes
- Use consistent patterns from Phase 4/7/9 (list tiles, filter chips, action sheets).
- Emphasize readability: show dosage + frequency as chips; highlight active status.
- Intake status colors: on-time (green), late (amber), missed (red), unscheduled (grey).
- Accessibility: semantic labels for buttons, form fields, and status chips.

## Risks & Mitigations
- **Performance on large histories**: add paging or incremental load; cap default range (e.g., last 90 days) with “Load more”.
- **Validation complexity**: reuse validator functions; surface inline errors; prevent submission until valid.
- **Profile isolation**: ensure all service calls include `activeProfileId`; cover with tests.
- **Chart overlay complexity**: keep optional; behind flag/toggle; guard rendering costs.

## Success Metrics
- Functionality: CRUD + intake logging + history browsing works per acceptance tests.
- Quality: analyzer clean; tests meet coverage targets; no regressions in existing suites.
- UX: search/filter respond under 200ms on typical datasets; forms block invalid submissions; status chips clearly communicate intake state.

## Deliverables
- Code: viewmodels, views, widgets, provider wiring; optional chart overlay.
- Tests: unit, widget, and integration smoke test for med lifecycle.
- Docs: Update Implementation_Schedule when complete; note any new dependencies.

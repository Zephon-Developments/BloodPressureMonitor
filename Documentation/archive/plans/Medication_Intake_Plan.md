# Medication Intake Recording Plan

## Objectives & Scope
- Add a clear, fast path for users to record when a medication dose is taken (single or grouped), leveraging existing medication data.
- Keep MVVM separation intact and respect encrypted local storage.
- Maintain current schema (Medication/MedicationIntake/MedicationGroup) and avoid breaking changes.

## Context & Existing State
- Medication models, services, and intake logging APIs already exist (Medication, MedicationGroup, MedicationIntake, MedicationService, MedicationIntakeService, MedicationGroupService).
- UI screens exist for medication list, history, and an intake bottom sheet, but there is no prominent CTA from the medication list/home to log an intake.
- Home settings menu links to Medications and Intake History, but logging requires finding the intake sheet entrypoint.
- Coding standards to follow: import ordering, const usage, 80-char lines, Provider MVVM pattern, explicit error handling, and test coverage expectations (see Documentation/Standards/Coding_Standards.md).

## Proposed UX/Flows
- Add a "Log intake" affordance per medication row in the medication list (trailing action button or inline pill) opening the existing LogIntakeSheet.
- Optional quick action on Home: "Log medication" opens medication picker then LogIntakeSheet for speed.
- After logging, show success toast/snack and refresh intake history; keep user on current screen.

## Priorities (from handoff)
1) Add a "Log intake" action on each medication row that opens `showLogIntakeSheet` with the selected medication (ensure MedicationIntakeViewModel is in scope).
2) After logging, show success/error feedback and refresh intake history via MedicationIntakeViewModel.loadIntakes; stay on the same screen.
3) Optional stretch: Home quick action to pick a medication then open the intake sheet.
4) Update empty/help text if needed to point to the new log button.
5) Tests: unit for MedicationIntakeService/MedicationIntakeViewModel logging paths (success/error, tz offset captured); widget for medication tile log CTA → sheet submit and success snackbar.

## Architecture & Data Flow
1) UI triggers `LogIntakeSheet` with selected `Medication`.
2) Sheet constructs `MedicationIntake` (records localOffsetMinutes, optional scheduledFor, note).
3) `MedicationIntakeViewModel.logIntake()` calls `MedicationIntakeService.logIntake()` → encrypted DB write via `DatabaseService`.
4) Intake history view reloads list; medication cache resolves names; status computed via schedule metadata when available.

## Changes by Layer
- **UI**: Medication list tile adds CTA to log intake; optional Home quick action; ensure snackbars and loading states are consistent.
- **ViewModels**: Wire sheet launch from list; ensure post-log refresh in MedicationIntakeViewModel and optionally refresh history if visible; reuse existing validation.
- **Services/Models**: No schema changes; ensure local offset is captured (already in model) and schedule metadata respected.
- **Navigation**: Ensure routes use Provider instances already registered (MedicationIntakeViewModel available where sheet is opened).

## Sequenced Work Items
1) Add log-intake trigger on medication list tiles (e.g., icon button that opens `showLogIntakeSheet`).
2) Wire optional Home quick action to pick medication then open intake sheet (skip if time constrained).
3) Ensure intake logging refreshes MedicationIntakeViewModel and shows success/error feedback.
4) Update documentation/help text if needed (e.g., empty states mention log button).
5) Add tests: service/viewmodel/widget coverage (see below).

## Testing Strategy
- Unit: MedicationIntakeService `logIntake` persists with correct tz offset/scheduledFor; group logging happy/empty list error.
- Unit: MedicationIntakeViewModel `logIntake` refreshes list and propagates errors.
- Widget: MedicationListView tile log button opens LogIntakeSheet and calls viewmodel with expected intake data (use mocked services/providers).
- Widget: LogIntakeSheet submits and shows success snackbar.
- Ensure `flutter test` and analyzer stay clean per Coding Standards.

## Risks & Mitigations
- **Provider availability**: Intake viewmodel must be in scope where sheet opens; mitigate by confirming parent provides it (Home or MaterialApp-level MultiProvider).
- **Time zone correctness**: Rely on `MedicationIntake` defaulting localOffsetMinutes; add assertion in tests.
- **UI discoverability**: If quick action omitted, rely on tile CTA placement; ensure icon/text is clear.
- **CTA visibility**: If Home quick action is skipped, make the medication list CTA explicit (icon + label or tooltip).

## Decisions (was Open Questions)
- Quick logging should support medication groups (one tap logs all).
- Do not prompt for missed/late classification; rely on schedule metadata only.
- Log date/time taken; skip linking to latest BP reading for now (correlations can be done later using timing if needed).

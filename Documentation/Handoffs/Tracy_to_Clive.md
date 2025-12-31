## Context
- Goal: enable users to record when medications are taken. Medication models/services and the intake sheet already exist, but there is no obvious CTA from the medication list/home to log intakes.
- Standards: follow Documentation/Standards/Coding_Standards.md (import order, const usage, 80-char lines, Provider MVVM, explicit error handling, tests for new logic).
- Reference plan: Documentation/Plans/Medication_Intake_Plan.md.

## Priorities
1) Add a "Log intake" action on each medication row in the medication list that opens `showLogIntakeSheet` with the selected medication. Ensure MedicationIntakeViewModel is in provider scope when invoking.
2) After logging, show success/error feedback and refresh intake history via MedicationIntakeViewModel.loadIntakes; stay on the current screen.
3) Optional stretch: add a Home quick action to pick a medication then open the intake sheet.
4) Update empty/help text if needed to point to the new log button.
5) Tests: unit for MedicationIntakeService/MedicationIntakeViewModel logging paths (success/error, tz offset captured); widget for medication tile log CTA → sheet submit and success snackbar.

## Risks/Notes
- Provider wiring: confirm MedicationIntakeViewModel is available where the sheet launches; add scoped provider if missing.
- Time zone correctness depends on MedicationIntake.default localOffsetMinutes; cover with a unit test.
- If the Home quick action is skipped, ensure the medication list CTA is discoverable (icon + label or tooltip).

## Open Questions
- Should we support one-tap group logging from a quick action?
- Should logging also link to the latest blood pressure reading via `medsContext` for correlation? (likely future work)# Handoff: Tracy → Clive (Phase 12 Plan)

**Date:** December 31, 2025  
**From:** Tracy (Architecture Planner)  
**To:** Clive (Reviewer)  
**Request:** Implement Phase 12 — Medication Reminders & Notifications

## Objectives
- Deliver per-medication reminders with local notifications (schedule, snooze, dismiss) and a reminder history view. 
- Ensure reminders stay profile-scoped and respect medication active status. 
- Maintain zero analyzer warnings and 100% passing tests per Coding_Standards.md.

## Scope
- **Reminder Scheduling:** Local notifications for each medication instance based on schedule metadata; cancel/reschedule on edits/deletes/inactivation.
- **Snooze/Dismiss:** In-notification actions to snooze (configurable duration) or dismiss; record action to history.
- **Reminder History:** UI to review sent reminders and their outcomes (triggered, snoozed, dismissed, expired/missed).
- **Settings & Permissions:** Global reminder enable/disable, per-medication opt-in/out, permission prompts, and fallback handling when permissions are denied.

## Constraints & Dependencies
- Follow **Coding_Standards.md**: zero analyzer warnings, formatted code, strong typing, DartDoc for public APIs, tests for new logic.
- Platform: local notifications (Android primary; iOS must degrade gracefully if unsupported/permission denied). Use `flutter_local_notifications` + `timezone` packages; ensure tz initialization in `main.dart`.
- Data must remain **profile-scoped** (ActiveProfileViewModel); inactive medications must not schedule reminders.
- Scheduling must survive app restarts (persisted data drives rehydrate-on-launch scheduling).
- Keep builds passing existing 628+ tests; add new coverage for reminder logic.

## Success Metrics
- 0 analyzer errors/warnings; `flutter test` passes.
- Notifications fire at expected local times (incl. DST/timezone changes) for active medications.
- Editing/deleting/inactivating a medication cancels/reschedules associated reminders.
- Snooze/dismiss actions update reminder history and do not duplicate notifications.
- Reminder permissions handled gracefully with clear UX when denied.

## Proposed Architecture
- **Data Model**
  - Extend `Medication.scheduleMetadata` to include reminder config (versioned JSON):
    - `reminders.enabled`, `reminders.times` (HH:mm local), `reminders.daysOfWeek` (1-7), `reminders.leadMinutes` (optional pre-dose alert), `reminders.snoozeMinutes` default, `reminders.channelId`.
  - New model: `MedicationReminderEvent` (id, medicationId, profileId, scheduledFor, firedAt, action: triggered/snoozed/dismissed/expired, snoozeUntil?, localOffsetMinutes, createdAt).
- **Services**
  - `ReminderService` (new): maps medication schedules → notification requests; persists `MedicationReminderEvent`; cancels/reschedules on changes.
  - `NotificationService` (new, wrapper on flutter_local_notifications): init, permission check/request, schedule (with tz), cancel, snooze, action handling callbacks.
- **ViewModels**
  - `ReminderViewModel`: manages reminder settings (global toggle, per-medication enable), triggers reschedule, exposes permission state.
  - `ReminderHistoryViewModel`: loads `MedicationReminderEvent` list (filters: date range, medication), supports clear.
  - Integrations:
    - `MedicationViewModel`: on create/update/delete/inactivate → notify `ReminderService` to sync schedules.
    - `MedicationIntakeViewModel`: when logging intake, optionally mark related reminders as satisfied (avoid repeat the same slot?).
- **Views/UX**
  - Medication detail/settings panel: per-medication reminder toggle, time pickers, snooze default selector, lead-time selector.
  - Global Reminder Settings: enable/disable all reminders, permission status, “Reschedule all” button.
  - Reminder History View: list of `MedicationReminderEvent` with status chips (triggered/snoozed/dismissed/expired), filters by date/medication.
  - Notification actions: “Snooze” (uses configured snoozeMinutes), “Dismiss”; tap opens app to intake logging for that medication.
- **App Startup**
  - Initialize timezone + notifications in `main.dart` before runApp.
  - On launch and profile switch: load active profile meds and reschedule reminders for active ones with reminders enabled.

## Data Flow
1. **Configure**: User sets reminder times per medication → `Medication.scheduleMetadata` updated → `ReminderService` schedules notifications.
2. **Trigger**: Notification fires; action buttons (snooze/dismiss) handled via `NotificationService` callbacks → record `MedicationReminderEvent`; snooze reschedules single notification; dismiss cancels current instance.
3. **Update**: Medication edit/delete/inactivate → `ReminderService` cancels/reschedules relevant notifications.
4. **History**: `ReminderHistoryViewModel` queries events (profile-scoped) for UI.
5. **Permissions**: On-demand prompt; if denied, surface banner/toast and disable scheduling for that profile until granted.

## Affected Files (expected)
- `pubspec.yaml`: add `flutter_local_notifications`, `timezone` (and permissions configs).
- `android/` & `ios/`: notification setup (channels, icons, permission strings for iOS if needed).
- `lib/main.dart`: init tz, `NotificationService`, register providers, app startup reschedule.
- `lib/services/`: add `notification_service.dart`, `reminder_service.dart`; extend `medication_service.dart` to expose reminder metadata helpers (if needed).
- `lib/models/medication.dart`: extend schedule metadata schema; add `MedicationReminderEvent` model (new file or same file section).
- `lib/viewmodels/`: add `reminder_viewmodel.dart`, `reminder_history_viewmodel.dart`; integrate hooks in existing medication/intake viewmodels.
- `lib/views/`: medication detail/settings panel for reminders; global reminder settings; reminder history view; notification action routing entrypoint.
- `test/`: unit tests for services/viewmodels; widget tests for reminder settings UI; permission-denied handling tests.

## Sequencing Plan
1. **Dependencies & Config**: add packages, notification/tz init, Android channel setup, iOS permission strings (if applicable).
2. **Models**: define reminder config schema and `MedicationReminderEvent`.
3. **Services**: implement `NotificationService` (scheduling, actions), `ReminderService` (mapping schedules to notifications, persistence, cancel/reschedule).
4. **ViewModels**: reminder settings + history; wire medication lifecycle hooks to reschedule.
5. **Views**: reminder settings UI (per-med), global settings, history view; hook navigation from Settings/Medications.
6. **Integration**: startup reschedule; notification action callbacks into app (snooze/dismiss → history + optional intake flow).
7. **Testing**: unit tests (schedule mapping, cancel/reschedule, snooze), widget tests for settings; ensure analyzer/test pass.

## Risks & Mitigations
- **Timezone/DST shifts**: use `timezone` package; store wall-clock intent; reschedule on tz init and app resume.
- **Doze/background limits**: document platform caveats; prefer exact alarms only if permitted; otherwise fallback.
- **Permission denied**: surface clear UX; skip scheduling until granted; keep state consistent.
- **Action handling**: ensure callbacks registered early; guard against null context when app not running; log events safely.
- **Profile switching**: always scope to `ActiveProfileViewModel`; cancel reminders from previous profile on switch.

## Open Questions for Review
1. Snooze default: fixed (e.g., 10 min) vs per-med configurable? cap on snooze count?
2. Lead-time alerts: required or optional? default value?
3. iOS support requirements: is iOS a must-have now, or Android-only acceptable with graceful degradation?
4. Should dismiss auto-mark as “missed” in history, or remain neutral?
5. Do we block scheduling for inactive medications automatically (assumed yes)?

## Test Strategy
- Unit tests: schedule mapping (times, daysOfWeek, leadMinutes), cancel/reschedule on edits/deletes, snooze action rescheduling, permission-denied no-op behavior.
- ViewModel tests: reminder enable/disable flows, history filters, profile switch reschedule.
- Widget tests: per-med reminder settings form; global settings banner when permission denied.
- Manual: notification fire, snooze/dismiss actions, DST boundary sanity check.

Please review the scope, architecture, risks, and open questions. Upon approval I’ll proceed to implementation guidance for Claudette.

# Blood Pressure Monitor

Anchored outline for the app across design, build, and QA. Focus: multi-user blood pressure and pulse tracking with clear visuals, sensible defaults, and no medical advice.

## Goals and Scope

- Capture accurate blood pressure and pulse readings for multiple people, timestamped and attributed.
- Average readings taken within 30 minutes of each other, anchored to the first reading time; surface both raw and averaged values. Offer manual session start to group readings from one sitting.
- Provide clear trend visualization against simple bands; highlight out-of-range patterns without prescribing treatment.
- Keep data local-first; provide export/import for portability; prioritize privacy and consent for shared devices.
- Optionally ingest sleep monitor summaries to correlate sleep quality with blood pressure trends; keep non-medical and local-first.

## Core Personas

- Primary user: Individual tracking their own readings.
- Household sharer: Tracks multiple household members.
- Care partner: Records on behalf of another person.

## Functional Features

### Reading Capture
- Manual entry: systolic, diastolic, pulse, optional notes, cuff arm, posture, medication timing.
- Time handling: auto-now with edit; timezone-safe storage (UTC + local offset).
- Averaging rule: any readings within a 30-minute window are averaged at the first reading's timestamp; store both raw readings and derived averages; show which readings were grouped. Allow a "Start new session" control to force a new group when taking multiple readings back-to-back.
- Validation: reasonable bounds (e.g., systolic 70-250, diastolic 40-150, pulse 30-200); inline warnings for out-of-bounds but allow override with confirmation.
- Irregular heartbeat flag: yes/no if the device indicated an irregular pulse/AFib warning.

### Medications and Context
- Per-profile medication list (name, dosage, schedule metadata, optional notes).
- Medication groups: user-defined collections (e.g., "Morning meds", "Hypertension stack") for quick flagging together.
- Intake logging: record time taken per medication (or group) instead of a boolean flag; show late/missed context relative to schedule if provided.
- Lifestyle/context: optional weight readings (timestamped per profile), salt note, exercise note, stress/sleep quality tags, fasting/post-exercise tags.

### Multi-Profile Support
- Create/select profiles; each reading belongs to a profile.
- Optional profile color/avatar for charts; basic demographics (name, year of birth) and preferred units.
- Profile switcher surfaced in top-level UI.

### Tagging and Context
- Optional tags: fasting, post-exercise, medication taken, stress, sleep quality, custom tags.
- Notes per reading and per averaged group.

### Sleep Data (optional)
- Manual entry or import of sleep summaries from a paired device (total sleep, time in bed, wake count, basic sleep score/efficiency).
- Per-profile association; stored locally with source metadata and timestamp of import.
- Correlate in views (e.g., overlay sleep score or total sleep with morning readings) without generating advice.

- Charts: systolic, diastolic, pulse; combined overlay option with toggle.
- Banding: single clear set (e.g., <130/85 green, 130-139/85-89 yellow, >=140/90 red) to avoid overlap confusion; call out isolated systolic hypertension when systolic high but diastolic normal.
- Time ranges: 7d, 30d, 90d, 1y, all.
- Stats: min/avg/max per range, morning vs evening split (e.g., before 12pm), variability indicators.
- Averaged vs raw toggle: default to averaged view with ability to inspect raw readings.
- Morning/evening filters: quick toggle for clinical relevance.
- Averaging display: show averaged value as the primary row; raw readings are one tap away via an expandable row.

### Reports and Exports
- CSV export and import (local-first).
- PDF doctor report: last 30/90 days, profile name, date range, averages, chart snapshot, meds/context notes, irregular heartbeat flags, disclaimer that data is patient-recorded.

### AI Commentary
- Deferred for v1 to avoid medical-claim risk; consider only neutral stats cards (no generated prose).

### Reminders and Notifications
- Optional, off by default; simple daily time per profile; no streaks or gamified nudges.

### Data Management
- Local-first storage with encrypted local database (e.g., sqflite_sqlcipher); optional encrypted export/import (JSON + CSV) and backup to user-chosen location.
- Device sharing: require profile selection; app-level lock with PIN/biometric for entry (no per-profile PIN); auto-lock after idle time.
- Offline-friendly; sync operations retriable (if remote backup is later added).

## Non-Functional

- Privacy: minimal data collection; no cloud by default; clear consent if any remote features are added later; no third-party analytics by default.
- Accessibility: large tap targets, high-contrast palette, screen reader labels for charts (tabular fallback).
- Accessibility: VoiceOver/TalkBack labels for charts, tabular fallback, large text mode support.
- Performance: smooth charting for 5k+ readings; fast list/filter; low memory use on mobile.
- Documentation: all public APIs documented with DartDoc (`///`) comments.

## Data Model (conceptual)

- Profile: id, name, color/avatar, yearOfBirth (optional), preferredUnits, createdAt.
- Reading: id, profileId, systolic, diastolic, pulse, takenAt (UTC), localOffset, posture, arm, medsContext (per-intake references/time notes), irregularFlag (bool), tags[], note.
- ReadingGroup (averaged set): id, profileId, groupStartAt (first reading time), windowMinutes=30, averagedValues, memberReadingIds[], note, sessionId (optional manual session).
- Reminder: id, profileId, schedule, isActive (optional, off by default).
- WeightEntry (optional): id, profileId, takenAt, weight, saltNote, exerciseNote, sleepQuality, stressLevel.
- SleepEntry (optional): id, profileId, nightOf (date), totalSleepMinutes, timeInBedMinutes, wakeCount, sleepScore/efficiency (optional), source (manual/device), importedAt.
- Medication: id, profileId, name, dosage, schedule (optional), notes.
- MedicationGroup: id, profileId, name, memberMedicationIds[].
- MedicationIntake: id, profileId, medicationId, takenAt, groupId (optional), note.

## UX Outline

- Home/Dashboard: profile selector; quick add; latest averaged reading; average shown primary with tap-to-expand raw readings; trend summary; reminder CTA.
- Add Reading: minimal fields up front; advanced fields behind a "More details" expander; validation inline; link to quick medication intake logging.
- History: list with grouped readings; averaged row expanded to show constituent raw readings; filters by date range/tag/profile.
- Charts: tabs for systolic/diastolic/pulse/combined; time-range chips; band legend always visible.
- Insights: stats cards (avg, variability, morning/evening split, isolated systolic note) with clear legend; no generated prose in v1.
- Sleep: simple summary cards (total sleep, wake count, sleep score if available) and optional overlay when viewing morning readings.
- Settings: profiles, reminders, export/import, privacy/disclaimer, units, app lock (PIN/biometric).

## Averaging Logic (behavioral notes)

- Group readings per profile by rolling 30-minute window starting at the first reading's timestamp.
- New reading within 30 minutes joins the current group; otherwise starts a new group. Manual "Start new session" forces new group even inside 30 minutes.
- Display both averaged and individual readings; indicate group membership in UI and exports.

## Edge Cases

- Back-dated entries that fall into prior groups: recompute affected group averages and update displays.
- Timezone changes/ DST: store UTC + offset; grouping uses absolute time.
- Deleting a reading in a group: recompute or dissolve group if only one reading remains.
- PDF export should exclude empty sections and clearly label patient-recorded data; handle offline generation.
- Profile lock/PIN flows on shared devices; fail closed if lock is enabled.

## Testing and Quality Gates

- Unit: averaging logic, validation bounds, grouping edge cases (back-dated, deletion, DST).
- Widget/UI: forms, chart toggles, accessibility labels (charts + table fallback), reminder flows (off-by-default), session start control.
- Integration: export/import round-trip (CSV/PDF), profile isolation, meds/irregular flags, morning/evening filters, PIN lock flows, sleep import/manual entry.
- Coverage targets: meet or exceed Coding Standards (Models/Utils ≥90%, ViewModels/Services ≥85%, Widgets ≥70%).
- Performance: chart rendering with large datasets; list scrolling.

## Future Considerations

- Optional device sync (watch/connected cuff) with explicit consent.
- Optional secure cloud backup with per-profile opt-in and encryption.
- AI commentary if regulatory position clarified; keep strictly non-diagnostic.
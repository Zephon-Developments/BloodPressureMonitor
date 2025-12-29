# Blood Pressure Monitor - Phased Implementation Schedule

## Purpose
Break the implementation into sprint-sized phases with clear tasks, dependencies, acceptance criteria, and a simple progress tracker. Each phase should be reviewable/mergeable independently.

## Progress Tracking
- [x] Phase 1: Core Data Layer ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 2A: Averaging Engine ✅ **COMPLETE** (Dec 29, 2025)
- [ ] Phase 2B: Validation & ViewModel Integration
- [ ] Phase 3: Medication Management
- [ ] Phase 4: Weight & Sleep
- [ ] Phase 5: App Security Gate
- [ ] Phase 6: UI Foundation
- [ ] Phase 7: History (Avg-first with expansion)
- [ ] Phase 8: Charts & Analytics
- [ ] Phase 9: Export & Reports
- [ ] Phase 10: Polish & Comprehensive Testing

---

## Phase Breakdown

### Phase 1: Core Data Layer (Encrypted)
**Scope**: Models (Reading, ReadingGroup, WeightEntry, SleepEntry, Reminder) + encrypted SQLite schema/migrations + base DAOs/services.
**Tasks**
- Define remaining models with DartDoc and equality: Reading, ReadingGroup, WeightEntry, SleepEntry, Reminder.
- Design DB schema (tables, FKs) for Profile, Reading, ReadingGroup, Medication, MedicationGroup, MedicationIntake, WeightEntry, SleepEntry, Reminder.
- Implement encrypted DB provider with `sqflite_sqlcipher`, migrations, and schema init.
- CRUD services for Profile and Reading (skeleton for others).
**Dependencies**: None (foundation).
**Acceptance**
- Schema created and migrated on app start; encryption enabled.
- Models round-trip via toMap/fromMap; unit tests ≥90% coverage for models/utils.
- Analyzer clean.
**Rollback point**: Schema + models + service skeleton behind feature flags (no UI impact yet).

### Phase 2A: Averaging Engine ✅ COMPLETE
**Scope**: 30-minute rolling grouping + manual session override.
**Tasks**
- ✅ Implement Reading service methods: add/read/list/delete.
- ✅ Averaging engine: rolling 30-min window per profile; manual "start new session" to force new group.
- ✅ Unit tests for grouping (back-dated, deletion, DST/offset).
**Dependencies**: Phase 1 schema/services.
**Acceptance**
- ✅ Grouping logic matches spec; recomputes on insert/update/delete/back-date.
- ✅ Tests ≥85% services (96.15% achieved); analyzer clean.
**Status**: Merged to main Dec 29, 2025

### Phase 2B: Validation & ViewModel Integration
**Scope**: Validation bounds, ViewModel integration, automatic averaging triggers.
**Tasks**
- Enhance validators with proper bounds (70–250 sys, 40–150 dia, 30–200 pulse).
- Add override confirmation hooks for out-of-range values.
- Wire AveragingService into BloodPressureViewModel.
- Auto-trigger grouping on create/update/delete operations.
- Unit tests for validation bounds and ViewModel integration.
**Dependencies**: Phase 2A.
**Acceptance**
- Validation enforces medical bounds with override capability.
- CRUD operations automatically trigger averaging recomputation.
- Tests ≥85% viewmodels; analyzer clean.
**Rollback point**: Service-level feature toggle; validation warnings only.

### Phase 3: Medication Management
**Scope**: Medication list, groups, intake logging with timestamps, schedule metadata.
**Tasks**
- CRUD for Medication, MedicationGroup, MedicationIntake.
- Group intake: single action logs multiple meds with individual intake records.
- Late/missed context relative to optional schedule metadata.
- Unit tests for intake associations, group logging, and schedule context.
**Dependencies**: Phase 1 schema; Phase 2 optional for correlation later.
**Acceptance**
- Intakes persisted with timestamps and optional groupId; correlation ready.
- Tests ≥85% for services; analyzer clean.
**Rollback point**: Feature flag for medication UI; services stable.

### Phase 4: Weight & Sleep
**Scope**: WeightEntry and SleepEntry storage + basic retrieval.
**Tasks**
- CRUD for WeightEntry; optional notes (salt, exercise, stress/sleep quality).
- CRUD/import for SleepEntry (manual + device-import hook, stored locally with source metadata).
- Basic correlation hooks for morning readings (no advice).
- Tests for parsing, storage, and date handling.
**Dependencies**: Phase 1 schema.
**Acceptance**
- Data persists and fetches; analyzer clean; tests ≥85% services.
**Rollback point**: Keep UI hooks off if needed.

### Phase 5: App Security Gate
**Scope**: App-level PIN/biometric lock; auto-lock on idle; no per-profile PINs.
**Tasks**
- Secure credential storage (PIN/biometric) using platform-appropriate secure storage.
- Idle timer + resume lock.
- Unit/widget tests for lock/unlock flow (mocking platform where possible).
**Dependencies**: Phases 1–4 not strictly required; can be parallel. Needs navigation shell.
**Acceptance**
- Lock enforced on launch/return; bypass impossible without auth.
- Analyzer clean; targeted tests passing.
**Rollback point**: Feature flag; default locked-paths disabled only in dev.

### Phase 6: UI Foundation (Home, Add Reading)
**Scope**: Base navigation, profile switcher, add-reading form (manual entry with advanced section), reminder stub.
**Tasks**
- Home/dashboard shell with profile selector and quick add.
- Add Reading form with validation, advanced expander (arm, posture, notes, tags), link to quick medication intake.
- Wire to services (create reading, session override trigger).
- Widget tests for form validation and submission.
**Dependencies**: Phases 1–2.
**Acceptance**
- Create/read readings end-to-end; analyzer clean; widget tests ≥70% for new widgets.
**Rollback point**: Hide navigation to unfinished screens.

### Phase 7: History (Avg-first with expansion)
**Scope**: History list showing averaged rows primary; expand to raw readings.
**Tasks**
- History screen with filters (date range, profile, tags), expandable groups.
- Toggle averaged vs raw view; display grouping membership.
- Performance pass for large lists (ListView.builder, pagination/lazy load if needed).
- Widget tests for expand/collapse, filters, and data binding.
**Dependencies**: Phase 2; UI shell from Phase 6.
**Acceptance**
- UX matches spec (avg primary, raw one tap away); smooth scroll with large datasets; widget tests ≥70%.
**Rollback point**: Keep feature behind a toggle if perf not ready.

### Phase 8: Charts & Analytics
**Scope**: Systolic/diastolic/pulse charts, banding, stats cards, morning/evening split.
**Tasks**
- Chart widgets with banding (<130/85 green, 130–139/85–89 yellow, ≥140/90 red), isolated systolic note.
- Time-range chips (7d/30d/90d/1y/all); stats cards (min/avg/max, variability, morning/evening split).
- Optional overlay for sleep correlation.
- Widget tests for rendering with sample data; perf checks.
**Dependencies**: Phases 2, 4 (for sleep overlay), UI shell.
**Acceptance**
- Charts render with correct band shading and stats; tests and analyzer clean.
**Rollback point**: Ship without sleep overlay if blocked.

### Phase 9: Export & Reports
**Scope**: CSV/JSON export/import; PDF doctor report.
**Tasks**
- Local-only CSV/JSON export/import; conflict handling basic (overwrite/append strategy).
- PDF report for last 30/90 days: profile info, date range, averages, chart snapshot, meds/intake notes, irregular flags; disclaimer.
- Integration tests for export/import round-trip; PDF generation smoke tests.
**Dependencies**: Phases 1–4, 7–8 for data/views.
**Acceptance**
- Successful round-trip for CSV/JSON; PDF generated offline; tests pass.
**Rollback point**: Export only (defer PDF) if needed.

### Phase 10: Polish & Comprehensive Testing
**Scope**: Lint, coverage, perf, accessibility, and cleanup.
**Tasks**
- Achieve coverage targets (Models/Utils ≥90%, Services/ViewModels ≥85%, Widgets ≥70%).
- Accessibility labels for charts + table fallback; large text mode pass.
- Performance sweep on lists/charts; fix any analyzer warnings.
- Final docs (DartDoc completeness) and release checklist.
**Dependencies**: All prior phases.
**Acceptance**
- Analyzer clean; coverage targets met; accessibility checks done; ready for Clive greenlight.
**Rollback point**: N/A (release readiness).

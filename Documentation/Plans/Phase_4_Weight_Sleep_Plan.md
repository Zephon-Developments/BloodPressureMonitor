# Phase 4 Implementation Plan: Weight & Sleep

**Author**: Tracy (Planning & Architecture)
**Date**: 2025-12-29
**Scope**: WeightEntry + SleepEntry data capture, storage, and UI entry flows

## Objectives
- Enable manual input and CRUD for weight and sleep data.
- Extend encrypted SQLite schema (Phase 1 foundation) with weight/sleep tables.
- Provide UI forms aligned with Phase 6 patterns (CustomTextField, validation, FormState).
- Lay correlation hooks for BP + weight + sleep (analytics deferred to Phase 8).
- Meet coding standards (see Coding_Standards.md: general principles, commit/test requirements, import order, line length 80, coverage targets).

## Architecture & Data Flow
- **DB Layer**: New tables `weight_entries`, `sleep_entries`; migrations via existing DatabaseService.
- **Models**: `WeightEntry`, `SleepEntry` with toMap/fromMap, value equality, DartDoc.
- **Services**: `WeightService`, `SleepService` using DatabaseService; optional `CorrelationService` stub exposing queries for combined data.
- **ViewModels**: `WeightViewModel`, `SleepViewModel` (ChangeNotifier) for UI binding; extend `BloodPressureViewModel` only for correlation fetch (avoid scope creep).
- **UI**: AddWeightView, AddSleepView, history lists; quick actions from HomeView; reuse CustomTextField, LoadingButton, ValidationMessageWidget.

## Database Schema (SQLite, encrypted)
- `weight_entries`
  - id INTEGER PRIMARY KEY
  - profile_id INTEGER NOT NULL REFERENCES profiles(id)
  - recorded_at INTEGER NOT NULL (ms since epoch, local)
  - weight_kg REAL NOT NULL (store normalized kg)
  - unit TEXT NOT NULL CHECK(unit IN ('kg','lbs'))
  - notes TEXT
  - salt_level TEXT CHECK(salt_level IN ('low','medium','high'))
  - exercise_level TEXT CHECK(exercise_level IN ('none','light','moderate','intense'))
  - stress_level INTEGER CHECK(stress_level BETWEEN 1 AND 5)
  - created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)
  - updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)
- `sleep_entries`
  - id INTEGER PRIMARY KEY
  - profile_id INTEGER NOT NULL REFERENCES profiles(id)
  - sleep_date TEXT NOT NULL (ISO yyyy-MM-dd for the night)
  - sleep_start INTEGER NOT NULL (ms since epoch)
  - sleep_end INTEGER NOT NULL (ms since epoch)
  - duration_minutes INTEGER NOT NULL (computed, enforce >0 and <= 20*60)
  - quality_rating INTEGER CHECK(quality_rating BETWEEN 1 AND 5)
  - notes TEXT
  - source TEXT NOT NULL DEFAULT 'manual' CHECK(source IN ('manual','device'))
  - source_metadata TEXT
  - created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)
  - updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')*1000)

**Migration Strategy**
- Add new migration script with id > latest (Phase 1 base) to create both tables.
- Provide down/rollback helper (if supported) to drop new tables.
- Ensure indices: index on profile_id, recorded_at (weight); profile_id, sleep_date (sleep).

## Models
- `WeightEntry`: id, profileId, recordedAt (DateTime), weightKg (double), unit (enum or string), notes, saltLevel, exerciseLevel, stressLevel, createdAt, updatedAt.
- `SleepEntry`: id, profileId, sleepDate (DateTime only date), sleepStart (DateTime), sleepEnd (DateTime), durationMinutes (int), qualityRating, notes, source (enum manual/device), sourceMetadata, createdAt, updatedAt.
- Implement: const constructors where possible; `copyWith`, `==`/hashCode; `fromMap`/`toMap`; documentation per Coding_Standards.md; validation guards in factories to avoid invalid states.

## Services
- `WeightService`
  - addWeight(WeightEntry raw, {bool convertUnit}) → stores normalized kg; converts from lbs if unit == lbs.
  - listWeights({profileId, DateTime? start, DateTime? end}) sorted desc.
  - updateWeight(WeightEntry)
  - deleteWeight(id)
  - optional: getLatestWeight(profileId)
  - Validation: weight > 0, < 400 kg (medical sanity), recordedAt not future > 1 day grace.
- `SleepService`
  - addSleep(SleepEntry raw) computes duration; reject negative/zero; allow spans over midnight; enforce duration <= 20h.
  - listSleep({profileId, dateRange}) ordered desc by sleep_start.
  - updateSleep(SleepEntry)
  - deleteSleep(id)
  - detect overlaps? Warn but allow (store source in metadata for future dedupe).
- `CorrelationService` (stub)
  - fetchMorningReadingsWithSleep(profileId, dateRange) returning tuple {reading, sleepSummary}
  - fetchWeightsForRange(profileId, dateRange)

## ViewModels
- `WeightViewModel`
  - Expose state: list<WeightEntry>, isLoading, error, submitStatus.
  - Methods: loadWeights(range), addOrUpdateWeight(entry), deleteWeight(id).
- `SleepViewModel`
  - State: list<SleepEntry>, isLoading, error, submitStatus.
  - Methods: loadSleep(range), addOrUpdateSleep(entry), deleteSleep(id).
- Keep business validation in services; ViewModels handle UI-facing errors and busy state.

## UI/UX
- **AddWeightView**: Form fields (weight value, unit toggle kg/lbs, date/time, optional notes, salt/exercise/stress selectors). Use TextFormField validators: required, numeric, bounds; auto-convert lbs→kg on save.
- **WeightHistoryView**: ListView with date, value (display in user-selected unit), optional context chips; pull-to-refresh.
- **AddSleepView**: Fields: date (night), start time, end time, quality (1-5), notes, source (default manual). On submit compute duration; show error if duration invalid or start/end missing.
- **SleepHistoryView**: List with date, duration, quality badge; expand to show notes/source.
- **Navigation**: Add quick actions on HomeView (Phase 6 pattern) to open AddWeightView/AddSleepView. Keep history accessible from drawer or tab if available.
- **Accessibility**: Labels/hints on fields; respect 80-char line guidance; use semantics where custom widgets.

## Validation Rules
- Weight: required, numeric, >0, <400kg; if input in lbs, convert then validate.
- Date/time: cannot exceed now + 1 day (allow slight future for timezones).
- Sleep: start < end; duration > 0 and <= 20h; quality 1-5.
- Notes length bounds (e.g., 500 chars) to avoid bloating storage.

## Sequencing
1. **DB Migration**: Add tables + indices; unit tests for migration/up/down.
2. **Models**: Implement WeightEntry, SleepEntry with tests for map round-trip and validation guards.
3. **Services**: WeightService, SleepService with CRUD + validation + unit conversion; tests ≥85% coverage.
4. **ViewModels**: WeightViewModel, SleepViewModel; mock services in tests; ensure busy/error states.
5. **UI Forms**: AddWeightView, AddSleepView using CustomTextField/TextFormField validators; widget tests for validation and happy paths.
6. **History Views**: Basic list render + empty state tests.
7. **Home Integration**: Quick actions wired; smoke tests to ensure navigation works.
8. **Correlation Stub**: Service method stubs + minimal tests to guard query shape; no UI yet.
9. **Docs**: Update Implementation_Schedule and README/QUICKSTART if needed.

## Test Strategy
- **Unit**: Models (map round-trip, validation), Services (CRUD, unit conversion, duration calc), Correlation stub query assembly.
- **Widget**: AddWeightView, AddSleepView validation (required fields, bounds, duration), history views rendering, quick action navigation.
- **Integration** (light): Service + DB migration smoke (in-memory) to ensure tables exist and basic insert/select works.
- **Coverage Targets**: Services ≥85%, widgets ≥70%, maintain existing 555 passing tests; `flutter analyze` clean (Coding_Standards §2.4/2.5).

## Risks & Mitigations
- **Midnight-crossing sleep**: Ensure duration calc handles end < start by adding 24h when appropriate; test explicitly.
- **Unit conversion drift**: Normalize to kg in DB; display using user unit with precise conversion; tests for round-trip.
- **Large datasets**: Add indices; paginate lists if perf issues (future enhancement).
- **Validation gaps**: Centralize bounds in validators util to avoid divergence.
- **Timezones**: Store ms since epoch with local offset; surface correct local times in UI.

## Acceptance Criteria
- Migrations create `weight_entries` and `sleep_entries`; analyzer clean.
- Users can add/edit/delete weight and sleep entries via UI; validation prevents invalid data.
- Data persisted encrypted; services return expected data with correct conversions/durations.
- Tests meet coverage targets; `flutter test` and `flutter analyze` pass.
- Quick actions from home navigate to weight/sleep forms.
- Plan reviewed/approved by Clive.

## Rollback Points
- Feature-flag navigation to weight/sleep screens.
- If correlation stub blocks, ship without UI dependency (stubbed service only).
- If history perf degrades, limit range or disable history tab temporarily.

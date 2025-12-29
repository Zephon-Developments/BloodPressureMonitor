# Handoff: Tracy > Clive (Phase 4 Planning)

**Date:** 2025-12-29  
**Phase:** Phase 4 6 Weight & Sleep  
**Status:** Plan Ready for Review

---

## Objectives & Constraints
- Deliver Weight & Sleep data capture with BP correlation hooks; no UI in scope.
- Adhere to Coding Standards (refs: Branching/PR rules 2.1; Conventional Commits 2.3; Analyzer/tests required 2.4; Model/service patterns 3, 3.2, 4.x; Coverage targets per Implementation Schedule and Standards).
- Maintain encrypted DB; zero analyzer warnings; tests >=85% for new services.
- Keep feature flag/disabled UI navigation as rollback.

## Architecture & Data Flow
- **DB Version 3 Migration**
  - Add `WeightEntry` table (id, profileId FK, weightValue REAL, unit TEXT, takenAt TEXT, localOffsetMinutes INTEGER, notes TEXT, saltIntake TEXT?, exerciseLevel TEXT?, stressLevel TEXT?, sleepQuality TEXT?, source TEXT DEFAULT 'manual', sourceMetadata TEXT, createdAt TEXT).
  - Add `SleepEntry` table (id, profileId FK, startedAt TEXT, endedAt TEXT, durationMinutes INTEGER, quality INTEGER?, source TEXT DEFAULT 'manual', sourceMetadata TEXT, notes TEXT, createdAt TEXT, localOffsetMinutes INTEGER).
  - Indexes: `WeightEntry(profileId, takenAt DESC)`, `SleepEntry(profileId, endedAt DESC)`, optionally `SleepEntry(profileId, startedAt)` for queries spanning midnight.
  - FKs: both cascade on profile delete.
  - Migration safety: create tables with `IF NOT EXISTS`; guard repeat runs; wrap in transaction.

- **Models**
  - `WeightEntry` model with `toMap/fromMap/copyWith`, unit enum (kg, lbs), conversion helpers (store as entered + unit; conversions done in service/util).
  - `SleepEntry` model with `toMap/fromMap/copyWith`, duration derivation (if endedAt present, compute durationMinutes; allow explicit duration for imported summaries).
  - Include `createdAt`/`localOffsetMinutes` for DST-safe ordering.

- **Validators**
  - Weight: bounds per unit (kg 2510; lbs 5570); reject negatives/zero; require takenAt.
  - Sleep: start < end; durationMinutes between 60440; quality optional but if present 15; source in allowed set {manual, import}; validate ISO8601 parsing with offset.
  - Shared date/time: ensure offset stored; normalize to UTC internally when comparing.

- **Services**
  - `WeightService` (CRUD, list by profile/date range, list latest per profile, optional unit conversion on read, bulk import stub for CSV/JSON).
  - `SleepService` (CRUD, list by profile/date range, import parser hook accepting device payload shape, compute duration if missing, ensure dedup via (profileId, startedAt, source, sourceMetadata?) optional constraint in code).
  - Correlation utilities: 
    - `findWeightForReading(profileId, readingTime)` selects nearest weight within same day 1h window configurable.
    - `findSleepForMorningReading(profileId, readingTime)` selects the sleep that ended before reading and within last 18h; prefer the session with latest `endedAt`.

- **Feature Isolation / Rollback**
  - Keep UI hooks off; services/models behind Phase 4 flag in ViewModel integration (Phase 6 will expose UI).
  - Migration is forward-only; ensure backup/export guidance not required yet (local-only).

## Sequencing
1. **Discovery**: Inspect current models/utils for Weight/Sleep stubs; confirm DB v2 schema baseline.
2. **Migration v3**: Implement `_onUpgrade` path; add tables + indexes; add migration test.
3. **Models & Validators**: Implement/align `WeightEntry`, `SleepEntry`, validators, unit enums/utilities.
4. **Services**: Add `WeightService`, `SleepService`, correlation helpers; ensure transactions where multi-write.
5. **Import Hooks**: Define parser interfaces and sample mapping; minimal stub to satisfy future device imports.
6. **Tests**: Model round-trip, validator bounds, service CRUD/range queries, migration safety, correlation selection, import parser smoke.
7. **Docs**: Update plan and any README/QUICKSTART notes if CLI/dev steps change.

## Test Strategy
- Unit tests:
  - Models: toMap/fromMap/copyWith; unit conversion correctness; duration computation.
  - Validators: weight bounds per unit; sleep start/end, duration, quality, source; date parsing with offsets.
  - Services: CRUD, range queries, ordering, correlation selectors (nearest within window), import parser behavior and dedup logic.
  - Migration: applying v2v3 on fresh and existing DB keeps prior data intact and creates new tables/indexes.
- Ensure `flutter analyze` + `flutter test` green (per Coding_Standards 2.4).

## Risks & Mitigations
- **Migration failure / data loss**: Wrap migration in transaction; use `IF NOT EXISTS`; add migration tests.
- **Timezones/DST drift**: Store offset, use UTC comparisons in correlation helpers; document expectations.
- **Unit conversion errors**: Centralize conversions in util; test round-trip for kg<->lbs.
- **Import variability**: Design parser interface with tolerant validation; capture raw payload in sourceMetadata for traceability.
- **Duplicate sleep entries**: Use code-level dedup on (profileId, startedAt, source, sourceMetadata hash).

## Open Questions for Clive
1. Weight bounds and units: OK with kg 2510 / lbs 5570 defaults?
2. Sleep quality scale: use 15 integer? Any preferred labels?
3. Correlation windows: weight within same-day 1h of reading; sleep ending within 18h before reading. Approve?
4. Source values: acceptable set {manual, import}? Need others (e.g., wearable, healthConnect)?

## Deliverables
- Plan document: `Documentation/Plans/Phase-4-Weight-Sleep.md` (to be authored after Clive feedback if needed).
- Post-approval implementation branch: `feature/phase-4-weight-sleep` (per Coding_Standards 2.1).


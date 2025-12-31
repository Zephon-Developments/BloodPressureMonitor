# Phase 3 Plan – Medication Management

## Goals and Scope
- Deliver Medication, MedicationGroup, and MedicationIntake CRUD services with atomic group intake logging.
- Track late/missed context based on optional schedule metadata.
- Prepare correlation hooks for linking intakes to blood pressure readings without UI changes.

**In scope (Must):** Medication CRUD, MedicationGroup CRUD, intake logging (single + group), schedule metadata handling, late/missed evaluation, tests ≥85% services, analyzer clean, DartDoc.  
**Should:** Serialization helpers, DI-friendly constructors, correlation hooks, error handling/validation.  
**Nice:** Search/filter by profile, intake history by date range, reminder metadata placeholder.  
**Out:** UI, reminders delivery, interaction checking, dosage validation rules depth, import/export.

## Constraints and Standards
- Follow branching/PR rules: protected `main`, feature branches, CI green (Coding Standards §2.1–2.4).  
- Formatting/analyzer/tests required before merge (Coding Standards §2.5).  
- Line length ≤80, import ordering, const usage, DI via Provider (Coding Standards §§3–4).  
- Sensitive data: no logging of health details; prefer generic logs (Coding Standards §7.3).
- Test coverage targets: services ≥85% (Implementation Schedule Phase 3 acceptance); models/utils aim ≥90% consistent with Phase 1.

## Domain Model Shapes
(Stored in existing schema; models expose toMap/fromMap + equality.)

- **Medication**
  - Fields: id, profileId, name (required), dosage?, unit?, frequency?, scheduleMetadata?, createdAt.
  - `scheduleMetadata`: JSON string encoded map (see format below), keep nullable.
  - Equality by id + value fields; `createdAt` stored ISO8601 with offset.

- **MedicationGroup**
  - Fields: id, profileId, name (required), memberMedicationIds (List<int>), createdAt.
  - Persist `memberMedicationIds` as JSON array string to match existing schema string column.

- **MedicationIntake**
  - Fields: id, medicationId, profileId, takenAt (ISO8601), localOffsetMinutes, scheduledFor? (ISO8601 or partial per metadata), groupId?, note?.
  - Late/missed classification computed in service, not stored (no schema change).

### Schedule Metadata Format (JSON string)
```json
{
  "v": 1,
  "frequency": "daily" | "twice-daily" | "as-needed" | "custom",
  "times": ["08:00", "20:00"],
  "daysOfWeek": [1,2,3,4,5,6,7],
  "graceMinutesLate": 120,
  "graceMinutesMissed": 240
}
```
- `times`: HH:mm 24h local time markers.  
- `daysOfWeek`: 1=Mon … 7=Sun.  
- Grace windows allow late/missed evaluation without schema change.

## Service Architecture
- **MedicationService**
  - CRUD by id/profileId; list by profile; search/filter (profile, name substring) as Nice-to-have.
  - Validation: non-empty name, profileId required; optional dosage/unit/frequency lengths capped (e.g., 120 chars) using existing ValidationResult pattern.

- **MedicationGroupService**
  - CRUD; update membership; list by profile.
  - Ensure member ids belong to same profile; reject cross-profile membership.
  - Keep `memberMedicationIds` sorted/unique before storing JSON string.

- **MedicationIntakeService**
  - `logIntake(MedicationIntake intake)`: insert single intake.
  - `logGroupIntake({required int groupId, required List<int> medicationIds, required ProfileId, DateTime takenAt, DateTime? scheduledFor, String? note})`: wraps inserts in a DB transaction; returns created intake rows.
  - `listIntakes(profileId, {DateTime? from, DateTime? to, int? medicationId, int? groupId})` with ordering by takenAt desc.
  - Late/missed evaluation: helper computes status per intake using schedule metadata + scheduledFor vs takenAt + grace windows. Returned DTO can include `lateStatus` (onTime|late|missed|unscheduled) without persisting.

- **Correlation Hooks**
  - Provide `findIntakesAround(DateTime anchor, {Duration window})` to support future reading correlation.
  - Optionally expose `intakesByIds(List<int> ids)` to resolve `medsContext` references if used later.

## Data Flow & Transactions
- Group intake uses a single transaction (atomic all-or-nothing) to prevent partial logs (addresses Technical Consideration #1).
- Service methods receive `DatabaseService` via DI; reuse test in-memory DB for integration tests.
- Late/missed is computed in service layer to avoid schema change; UI/ViewModels can consume computed status later.

## Implementation Steps (Sequenced)
1. **Models**: Add Medication, MedicationGroup, MedicationIntake classes with toMap/fromMap, equality, copyWith, DartDoc; include schedule metadata encoder/decoder helper.
2. **Validation utilities**: Light validators using existing ValidationResult pattern for medication names/membership; share in utils/validators if small, else dedicated validator helper.
3. **MedicationService**: CRUD + list by profile; tests with in-memory DB.
4. **MedicationGroupService**: CRUD + membership update (sort/unique + same-profile guard); tests for membership integrity.
5. **MedicationIntakeService**: Single intake logging; group intake transaction; list/filter; late/missed computation helper; tests for atomicity and status classification.
6. **Correlation hooks**: Implement `findIntakesAround` and `intakesByIds`; tests proving window filtering.
7. **Docs**: Update any README/QUICKSTART snippets if needed; ensure DartDoc for public APIs.

## Testing Strategy
- **Unit tests**: Model serialization round-trip (toMap/fromMap), scheduleMetadata encode/decode, validation helpers.
- **Integration tests (sqflite_common_ffi)**:
  - Medication CRUD per profile, isolation between profiles.
  - Group CRUD + membership validation (reject cross-profile, ensure uniqueness).
  - Single intake logging and retrieval ordering.
  - Group intake transaction: fail one insert → rollback all; succeed → all rows present.
  - Late/missed classification across scenarios (on-time, late within grace, missed after grace, unscheduled).
  - Correlation queries around anchor time windows.
- Coverage: target ≥90% models; ≥85% services. Analyzer clean per Coding Standards §2.4.

## Acceptance Criteria (Aligned to Implementation Schedule)
- CRUD for Medication/Group/Intake functional with DI-capable services; analyzer clean.
- Group intake is atomic; no partial writes on failure.
- Late/missed status computed correctly from schedule metadata and `scheduledFor`.
- Correlation hooks available for future ViewModel/UI integration.
- Tests meet coverage targets; all pass in CI.

## Risks and Mitigations
- **Schedule metadata complexity**: Keep v1 minimal JSON; document; validate on parse; default grace minutes if absent.
- **Data integrity (cross-profile)**: Enforce profile consistency in services and tests; rely on FK plus explicit checks.
- **Time zone/offset errors**: Always store ISO8601 with offset + `localOffsetMinutes`; use helpers to compare in local time context.
- **Atomicity**: Use DB transactions for group logging; test rollback paths.
- **Stringified lists**: Member medication IDs stored as JSON string—ensure stable sort to minimize diffs and ease comparisons.

## Open Questions for Clive
1. Approve the schedule metadata JSON shape and default grace windows (`late=120m`, `missed=240m`).
2. Confirm group intake must be strictly atomic (transaction) vs any best-effort tolerance (plan assumes atomic).
3. Should validation use the existing ValidationResult pattern for medication fields, or is minimal null/empty check acceptable for Phase 3?
4. Is a dedicated correlation helper (`findIntakesAround`) sufficient, or do you want ingestion-time linking to readings now?

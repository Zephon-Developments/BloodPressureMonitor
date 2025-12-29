# Handoff: Tracy to Clive
## Phase 3 Plan – Medication Management (Ready for Review)

### Context
- Phase 1–2B are merged; Phase 3 focuses on medication CRUD, groups, and intake logging.
- Schema for Medication/MedicationGroup/MedicationIntake already exists (Phase 1).
- Plan authored per Coding Standards requirements (branching, analyzer clean, tests) and Implementation Schedule acceptance targets.

### Plan Location
- Full plan: [Documentation/Plans/Phase-3-Medication-Management.md](Documentation/Plans/Phase-3-Medication-Management.md)
- Standards reference: [Documentation/Standards/Coding_Standards.md](Documentation/Standards/Coding_Standards.md)

### Key Architecture Decisions
- **Models**: Medication, MedicationGroup, MedicationIntake with toMap/fromMap, equality, DartDoc; memberMedicationIds stored as sorted/unique JSON string.
- **Schedule metadata**: JSON string v1 `{v, frequency, times, daysOfWeek, graceMinutesLate, graceMinutesMissed}` enabling late/missed evaluation without schema change.
- **Services**:
	- MedicationService: CRUD + profile-scoped listing; lightweight validation (non-empty name; length caps) using ValidationResult pattern.
	- MedicationGroupService: CRUD + membership update; enforce same-profile members; normalize/sort member IDs.
	- MedicationIntakeService: single intake logging; group intake via DB transaction (atomic); list/filter; late/missed computation helper; correlation helpers (findIntakesAround, intakesByIds).
- **Transactions**: Group intake is all-or-nothing within one transaction.
- **Correlation hooks**: Provided as queries; no UI/ViewModel wiring yet.

### Implementation Sequence
1) Models + metadata helper; 2) Validation helpers; 3) MedicationService; 4) MedicationGroupService; 5) MedicationIntakeService (single + group + late/missed); 6) Correlation helpers; 7) Docs/DartDoc cleanup.

### Testing Strategy
- Unit: model serialization, schedule metadata encode/decode, validation helpers.
- Integration (sqflite_common_ffi): medication CRUD isolation, group membership integrity, single/group intake logging with transaction rollback on failure, late/missed classification, correlation window queries. Targets: models ≥90% coverage; services ≥85%; analyzer clean.

### Acceptance Criteria
- CRUD for Medication/Group/Intake functional with DI-capable services; analyzer clean.
- Group intake atomic; no partial writes.
- Late/missed status computed from schedule metadata and scheduledFor.
- Correlation helpers available for future ViewModel/UI work.
- Tests meet coverage targets and pass in CI.

### Open Questions for Approval
1. Approve schedule metadata shape and default grace windows (late=120m, missed=240m).
2. Confirm group intake must be strictly atomic (transaction) vs any best-effort tolerance.
3. Should medication field validation use ValidationResult pattern or minimal null/empty checks for Phase 3?
4. Is findIntakesAround sufficient for correlation, or should ingestion-time linking to readings be included now?

— Tracy

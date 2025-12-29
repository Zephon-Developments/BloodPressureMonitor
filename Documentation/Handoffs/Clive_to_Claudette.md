# Handoff: Clive to Claudette
## Phase 3 Implementation – Medication Management

**Date:** December 29, 2025  
**From:** Clive (Review Specialist)  
**To:** Claudette (Implementer)  
**Phase:** 3 - Medication Management

---

## Context

The planning for **Phase 3: Medication Management** is complete and approved. You are now tasked with the implementation. This phase builds on the core data layer (Phase 1) and the validation/ViewModel patterns established in Phase 2B.

## Objectives

1. Implement CRUD operations for `Medication`, `MedicationGroup`, and `MedicationIntake`.
2. Implement atomic group intake logging using database transactions.
3. Implement late/missed intake classification logic based on schedule metadata.
4. Provide correlation hooks for future integration with blood pressure readings.

## Reference Materials

- **Implementation Plan**: [Documentation/Plans/Phase-3-Medication-Management.md](../Plans/Phase-3-Medication-Management.md)
- **Review Summary**: [reviews/2025-12-29-clive-phase-3-plan-review.md](../../reviews/2025-12-29-clive-phase-3-plan-review.md)
- **Coding Standards**: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)

## Key Implementation Details

### 1. Data Models
- Implement `Medication`, `MedicationGroup`, and `MedicationIntake` in `lib/models/`.
- Ensure `toMap`/`fromMap`, equality, and `copyWith` are implemented.
- `MedicationGroup.memberMedicationIds` should be stored as a JSON array string.
- `Medication.scheduleMetadata` should be a JSON string following the approved format in the plan.

### 3. Services
- **`MedicationService`**: Standard CRUD. Use `ValidationResult` for field validation.
- **`MedicationGroupService`**: CRUD + membership management. Enforce same-profile constraints.
- **`MedicationIntakeService`**: 
    - `logIntake`: Single entry.
    - `logGroupIntake`: **Must use a database transaction** for atomicity.
    - `listIntakes`: Filtered by profile/date/medication.
    - `calculateStatus`: Helper to determine `onTime|late|missed|unscheduled`.

### 4. Testing Requirements
- **Unit Tests**: Model serialization and metadata parsing.
- **Integration Tests**: Use `sqflite_common_ffi` for in-memory database testing.
- **Coverage Targets**: 
    - Models/Utils: ≥90%
    - Services: ≥85%
- **Specific Test Cases**: Ensure you test the transaction rollback for group intakes by forcing a failure on the second or third medication in a group.

## Success Criteria

- All 3 services implemented and fully tested.
- 0 analyzer warnings.
- All tests passing.
- DartDoc present for all public members.
- Code formatted according to project standards.

---

## Next Steps

1. Create a new feature branch: `feature/phase-3-medication-management`.
2. Follow the sequenced implementation steps in the plan.
3. Once complete, run all tests and analyzer.
4. Hand off back to **Clive** for review.

**Suggested Prompt to continue:**
"Claudette, please implement Phase 3: Medication Management as per the handoff from Clive in Documentation/Handoffs/Clive_to_Claudette.md."

— Clive  
*Review Specialist*

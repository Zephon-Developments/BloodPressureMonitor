# Handoff: Steve to Tracy
## Phase 3 Planning Request - Medication Management

**Date:** December 29, 2025  
**From:** Steve (Workflow Conductor)  
**To:** Tracy (Planning Architect)  
**Phase:** 3 - Medication Management

---

## Context

Phases 1, 2A, and 2B are now complete and merged to `main`:
- ✅ **Phase 1**: Core data layer with encrypted SQLite
- ✅ **Phase 2A**: Averaging engine (96.15% test coverage)
- ✅ **Phase 2B**: Validation & ViewModel integration (124 tests passing)

We're ready to proceed to **Phase 3: Medication Management**.

---

## Current State

### Available Infrastructure
- **Database**: Encrypted SQLite with tables for Medication, MedicationGroup, and MedicationIntake already defined in schema
- **Services**: `DatabaseService` with dependency injection support
- **Testing**: In-memory database testing pattern established with `sqflite_common_ffi`
- **Validation**: Three-tier validation system (valid/warning/error) ready for extension
- **ViewModel Pattern**: MVVM established with Provider state management

### Existing Schema (from Phase 1)
```sql
-- Medication table (already exists)
CREATE TABLE Medication (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profileId INTEGER NOT NULL,
  name TEXT NOT NULL,
  dosage TEXT,
  unit TEXT,
  frequency TEXT,
  scheduleMetadata TEXT,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
)

-- MedicationGroup table (already exists)
CREATE TABLE MedicationGroup (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profileId INTEGER NOT NULL,
  name TEXT NOT NULL,
  memberMedicationIds TEXT NOT NULL,
  createdAt TEXT NOT NULL,
  FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE
)

-- MedicationIntake table (already exists)
CREATE TABLE MedicationIntake (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  medicationId INTEGER NOT NULL,
  profileId INTEGER NOT NULL,
  takenAt TEXT NOT NULL,
  localOffsetMinutes INTEGER NOT NULL,
  scheduledFor TEXT,
  groupId INTEGER,
  note TEXT,
  FOREIGN KEY (medicationId) REFERENCES Medication(id) ON DELETE CASCADE,
  FOREIGN KEY (profileId) REFERENCES Profile(id) ON DELETE CASCADE,
  FOREIGN KEY (groupId) REFERENCES MedicationGroup(id) ON DELETE SET NULL
)
```

---

## Scope for Phase 3

From the Implementation Schedule:

### Objectives
1. Implement CRUD operations for Medication, MedicationGroup, and MedicationIntake
2. Enable group intake logging (single action logs multiple medications)
3. Track late/missed context relative to optional schedule metadata
4. Prepare for future correlation with blood pressure readings

### Must Have
- **Medication CRUD**: Create, read, update, delete medications
- **MedicationGroup CRUD**: Create and manage medication groups
- **Intake Logging**: Log individual and group intakes with timestamps
- **Schedule Context**: Optional schedule metadata with late/missed tracking
- **Tests**: ≥85% coverage for all services
- **Code Quality**: 0 analyzer warnings, proper DartDoc

### Should Have
- Data models with proper serialization (toMap/fromMap)
- Dependency injection for testability
- Correlation hooks for linking intakes to blood pressure readings
- Proper error handling and validation

### Nice to Have
- Medication search/filtering by profile
- Intake history retrieval by date range
- Reminder metadata (for future Phase with reminders)

### Out of Scope (for Phase 3)
- UI components (deferred to Phase 6+)
- Reminder notifications (separate phase)
- Medication interaction checking
- Dosage validation rules
- Import/export functionality

---

## Planning Requirements

Please create a detailed plan for Phase 3 that includes:

### 1. Data Models
- `Medication` class with all properties, toMap/fromMap, equality
- `MedicationGroup` class with member tracking
- `MedicationIntake` class with schedule context

### 2. Services Architecture
- `MedicationService` for medication CRUD
- `MedicationGroupService` for group management
- `MedicationIntakeService` for intake logging
- Consider: Should group intake be a method on `MedicationIntakeService` or a separate concern?

### 3. Testing Strategy
- Unit tests for each model's serialization
- Integration tests using in-memory database (following Phase 2B pattern)
- Test cases for:
  - Individual medication CRUD
  - Group creation and member management
  - Individual intake logging
  - Group intake logging (atomic operation for multiple meds)
  - Late/missed intake detection
  - Correlation hooks for linking to readings

### 4. Implementation Approach
- Step-by-step implementation order
- Dependencies between components
- Rollback/feature flag strategy if needed

### 5. Acceptance Criteria
- Clear, testable acceptance criteria for each component
- Performance considerations for large medication lists
- Data integrity rules (cascading deletes, constraints)

---

## Technical Considerations

### Questions for Tracy to Address

1. **Group Intake Atomicity**: Should group intake use a database transaction to ensure all intakes are logged atomically, or is best-effort acceptable?

2. **Schedule Metadata Format**: What format should `scheduleMetadata` use? JSON string? Consider:
   - Time of day (e.g., "08:00", "20:00")
   - Frequency (e.g., "daily", "twice-daily", "as-needed")
   - Days of week for non-daily schedules

3. **Late/Missed Context**: How should we calculate "late" vs "missed"?
   - Threshold for considering an intake "late" (e.g., within 2 hours of scheduled time)
   - When does a scheduled intake become "missed" (e.g., after 4 hours)?
   - Should this be configurable or hard-coded?

4. **Correlation Design**: How should medications link to blood pressure readings?
   - Via `medsContext` field on Reading (already exists - comma-separated intake IDs)?
   - Should correlation happen at intake-time or be computed on-demand?
   - Should we build correlation into Phase 3 or defer to ViewModel integration?

5. **Validation**: Do medications need validation (e.g., name length, dosage format)?
   - If yes, should we use the existing three-tier ValidationResult pattern?
   - Or is simple null/empty checking sufficient for Phase 3?

---

## Success Criteria

Phase 3 is successful when:
1. All medication, group, and intake models are implemented with ≥90% test coverage
2. All CRUD services are implemented with ≥85% test coverage
3. Group intake logging works atomically (all or nothing)
4. Late/missed context is trackable (even if UI doesn't display it yet)
5. Correlation hooks are in place for future integration with blood pressure readings
6. 0 analyzer warnings, all tests passing
7. Clive approves the implementation

---

## References

- **Implementation Schedule**: [Documentation/Plans/Implementation_Schedule.md](../Plans/Implementation_Schedule.md)
- **Database Schema**: [lib/services/database_service.dart](../../lib/services/database_service.dart)
- **Phase 2B Pattern**: [Documentation/Handoffs/Claudette_to_Clive.md](Claudette_to_Clive.md)
- **Coding Standards**: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)

---

## Next Steps

1. Create detailed Phase 3 plan at `Documentation/Plans/Phase-3-Medication-Management.md`
2. Define data models with DartDoc
3. Outline service interfaces and responsibilities
4. Specify test cases and acceptance criteria
5. Create handoff to Clive for plan review at `Documentation/Handoffs/Tracy_to_Clive.md`

---

**Action Required**: Please create the Phase 3 plan and hand off to Clive for review.

— Steve  
*Workflow Conductor*


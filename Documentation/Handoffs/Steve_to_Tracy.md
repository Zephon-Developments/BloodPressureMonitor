# Handoff: Steve → Tracy

**Date:** 2025-12-29  
**Phase:** Phase 4 - Weight & Sleep  
**Status:** Planning Required  

---

## Context

Phase 3 (Medication Management) has been successfully completed and merged into main. We are now ready to proceed with Phase 4: Weight & Sleep tracking.

## Phase 4 Objectives

Implement comprehensive weight and sleep data management to support correlation with blood pressure readings.

### Scope (from Implementation Schedule)

**Weight & Sleep Entry storage + basic retrieval**

**Key Requirements:**
1. **WeightEntry CRUD**: 
   - Weight measurements with timestamps
   - Optional contextual notes: salt intake, exercise, stress level, sleep quality
   - Support for multiple units (kg, lbs) with conversion
   
2. **SleepEntry CRUD/Import**:
   - Manual entry capability
   - Device import hook for future integration
   - Store locally with source metadata (manual vs imported)
   - Track sleep duration, quality, and timing
   
3. **Basic Correlation Hooks**:
   - Enable correlation with morning BP readings
   - No advice generation yet - just data association
   - Prepare infrastructure for future analytics

4. **Data Handling**:
   - Robust date/time parsing
   - Proper timezone handling
   - Support for import from common formats

### Dependencies
- Phase 1 schema (already complete - database infrastructure exists)
- No dependencies on Phases 2 or 3

### Acceptance Criteria
- Data persists correctly and can be retrieved
- Analyzer clean (0 issues)
- Test coverage ≥85% for services
- Rollback point: Keep UI hooks disabled if needed

---

## Current State

### Database Schema
The database is currently at **version 2** with the following medication-related tables:
- Medication
- MedicationGroup  
- MedicationIntake

### Existing Models & Services
- ✅ Profile (CRUD complete)
- ✅ Reading, ReadingGroup (CRUD + averaging complete)
- ✅ Medication, MedicationGroup, MedicationIntake (CRUD complete)
- ⏳ WeightEntry (model exists, needs service implementation)
- ⏳ SleepEntry (model exists, needs service implementation)

### Standards & Patterns to Follow
Refer to [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md) for:
- Model structure with `toMap`/`fromMap`/`copyWith`
- Service patterns with validation
- Test coverage requirements
- JSDoc documentation standards

---

## Task for Tracy

**Please create a detailed implementation plan for Phase 4 that includes:**

1. **Schema Updates**
   - Determine if WeightEntry and SleepEntry tables already exist or need to be added
   - Define migration path to database version 3 (if needed)
   - Specify indexes for efficient queries
   - Define foreign key relationships

2. **Models**
   - Review and enhance WeightEntry model if needed
   - Review and enhance SleepEntry model if needed
   - Define unit conversion logic
   - Specify metadata structure for import sources

3. **Validators**
   - Weight validation (reasonable bounds, unit handling)
   - Sleep duration validation (reasonable bounds)
   - Date/time validation for entries

4. **Services**
   - WeightService: CRUD operations, unit conversions, queries by date range
   - SleepService: CRUD operations, import parsing, queries by date range
   - Correlation utilities: link entries to morning BP readings

5. **Testing Strategy**
   - Unit tests for models
   - Service tests covering CRUD operations
   - Validation tests
   - Import parsing tests
   - Correlation tests

6. **Rollback Strategy**
   - How to isolate this feature during development
   - Feature flags if needed

---

## Deliverables

Once you have analyzed the requirements and current codebase:

1. Create a detailed plan in `Documentation/Plans/Phase-4-Weight-Sleep.md`
2. Update `Documentation/Handoffs/Tracy_to_Clive.md` with the plan summary for Clive's review
3. Include:
   - Detailed task breakdown
   - Schema migration strategy
   - Testing approach
   - Risk assessment
   - Timeline estimate

---

**Steve**  
*Workflow Conductor*


# Handoff: Steve to Tracy

**Project**: HyperTrack (Blood Pressure Monitor)  
**Phase**: 20 (Profile Model Extensions)  
**Date**: January 1, 2026  
**Status**: 🎯 Ready for Planning

---

## Context

Phases 18 and 19 have been successfully completed and merged to main:
- ✅ **Phase 18**: Medication Grouping UI (groups, unit management, multi-select)
- ✅ **Phase 19**: UX Polish Pack (global idle timeout, PopScope navigation safety)
- ✅ **Profile Homepage**: Landing page with 4 action buttons

**Current Status**: 844/844 tests passing, zero analyzer issues, ≥80% coverage

---

## Phase 20 Scope: Profile Model Extensions

**Objective**: Extend the Profile model with patient metadata for enhanced PDF reports and clinical documentation.

### Required Fields (from User_to_Steve.md):
1. **Date of Birth** (DOB) - Age calculation, demographic tracking  
2. **Patient ID** - External medical records identifier (e.g., NHS number)  
3. **Doctor Name** - Assigned physician/healthcare provider  
4. **Clinic Name** - Healthcare facility/practice name  

All fields are **optional/nullable** to maintain backward compatibility.

---

## Planning Requirements

Tracy, create a comprehensive Phase 20 plan addressing:

### 1. Database Migration
- Add columns to `profiles` table: `date_of_birth`, `patient_id`, `doctor_name`, `clinic_name`
- Migration version bump with ALTER TABLE statements
- Backward compatibility (existing profiles work without new fields)
- Test migration on databases with existing data

### 2. Model Updates
- Extend `Profile` class with new nullable fields
- Update `toMap()` / `fromMap()` for serialization
- Update `copyWith()` method
- Add DartDoc for all new fields

### 3. Service Layer
- Update `ProfileService` CRUD to handle new fields
- Validation rules for new data
- Ensure null safety throughout

### 4. UI Forms
**Add/Edit Profile View:**
- DOB field: Date picker (must be in past if provided)
- Patient ID: Text input (max 50 chars, alphanumeric)
- Doctor Name: Text input (max 200 chars)
- Clinic Name: Text input (max 200 chars)
- All fields optional with proper labels

**Profile Display:**
- Consider showing age (calculated from DOB) in picker
- Privacy considerations for sensitive data

### 5. PDF Report Integration
- Update report header with patient metadata
- Format DOB as "Age: XX years" or full date
- Include Patient ID, Doctor, Clinic in report
- Handle missing fields gracefully (show "N/A")

### 6. Export/Import Compatibility
- Update JSON export schema with new fields
- Import old exports without new fields (set to null)
- Version export schema appropriately

### 7. Testing Strategy
- Unit tests: Profile model, ProfileService
- Widget tests: Add/edit form, validation
- Integration tests: Migration, export/import
- PDF tests: New fields appear correctly
- Target: ≥850 total tests

### 8. Privacy & Security
- DOB and Patient ID are **PHI** (Protected Health Information)
- Already encrypted via sqflite_sqlcipher
- Consider UI masking for Patient ID
- Document compliance implications

### 9. Acceptance Criteria
- [ ] Migration succeeds on existing databases
- [ ] New fields persist/retrieve correctly
- [ ] UI forms include all fields with validation
- [ ] PDF reports show patient metadata
- [ ] Export/import handles old & new schemas
- [ ] All tests passing (≥850)
- [ ] Zero analyzer issues
- [ ] Coverage ≥80%

---

## Dependencies

**Blocked by**: None  
**Blocks**: Phase 25 (PDF Report v2 enhancements)  
**Related**: Phase 10 (Export & Reports)

---

## Design Decisions Needed

1. **DOB Format**: Date picker vs age calculator?  
   **Recommendation**: Date picker with age display

2. **Patient ID Format**: Enforce format or free-text?  
   **Recommendation**: Free-text, max 50 chars

3. **UI Grouping**:
   - Basic Info: Name
   - Patient Info: DOB, Patient ID
   - Healthcare: Doctor, Clinic

---

## Reference Files

- [lib/models/profile.dart](../../lib/models/profile.dart)
- [lib/services/database_service.dart](../../lib/services/database_service.dart)
- [lib/services/profile_service.dart](../../lib/services/profile_service.dart)
- [lib/views/profile/add_edit_profile_view.dart](../../lib/views/profile/add_edit_profile_view.dart)
- [lib/services/pdf_report_service.dart](../../lib/services/pdf_report_service.dart)
- [Documentation/Handoffs/User_to_Steve.md](../Handoffs/User_to_Steve.md)

---

## Success Metrics

- Migration: <100ms on 100+ profiles
- Form responsiveness maintained
- PDF render with metadata: <500ms
- Zero data loss
- CRUD operations: <50ms

---

**Steve**  
Workflow Conductor  
January 1, 2026

**Tracy, please create the Phase 20 implementation plan.**


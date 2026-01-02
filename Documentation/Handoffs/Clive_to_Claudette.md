# Handoff: Phase 20 - Profile Model Extensions

**From:** Clive (Reviewer)
**To:** Claudette (Implementation)
**Status:** Approved for Implementation

## Scope
Extend the `Profile` model to include medical metadata (Date of Birth, Patient ID, Doctor Name, Clinic Name) and update the database, services, and UI to support these new fields.

## Technical Requirements

### 1. Model Extension ([lib/models/profile.dart](lib/models/profile.dart))
- Add the following fields to the `Profile` class:
    - `dateOfBirth` (DateTime?)
    - `patientId` (String?)
    - `doctorName` (String?)
    - `clinicName` (String?)
- Update `fromMap`, `toMap`, `copyWith`, and equality operators.
- Ensure `yearOfBirth` is still handled (can be derived from `dateOfBirth` if provided).

### 2. Database Migration ([lib/services/database_service.dart](lib/services/database_service.dart))
- Bump `_databaseVersion` from `5` to `6`.
- Implement migration in `_onUpgrade` for `oldVersion < 6`:
    - Add columns to `Profile` table: `dateOfBirth` (TEXT), `patientId` (TEXT), `doctorName` (TEXT), `clinicName` (TEXT).
- Update `_onCreate` to include these columns in the initial table definition.

### 3. Service Updates ([lib/services/profile_service.dart](lib/services/profile_service.dart))
- Ensure CRUD operations correctly handle the new fields (should be automatic if `toMap`/`fromMap` are updated).

### 4. ViewModel Updates ([lib/viewmodels/active_profile_viewmodel.dart](lib/viewmodels/active_profile_viewmodel.dart))
- Ensure the `ActiveProfileViewModel` correctly propagates updates to the UI when profile metadata changes.

### 5. UI Implementation ([lib/views/profile/profile_form_view.dart](lib/views/profile/profile_form_view.dart))
- Add input fields for the new metadata:
    - `dateOfBirth`: Use a `DatePicker`.
    - `patientId`, `doctorName`, `clinicName`: Use `TextFormField`s.
- Ensure validation and proper saving logic.

## Standards Compliance
- **Test Coverage:** Ensure new logic is covered by unit tests in `test/models/profile_test.dart` and `test/viewmodels/active_profile_viewmodel_test.dart`.
- **Documentation:** Add JSDoc-style comments for all new fields and methods.
- **Typing:** No `any` types. Use explicit Dart types.

## Blockers/Notes
- None identified. The database is already encrypted, so PHI security is inherited.

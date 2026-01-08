# Phase 20 Plan: Profile Model Extensions

**Objective**: Extend Profile model with medical metadata fields for enhanced PDF reports and doctor coordination.

## Current State (Audit)
- **Profile Model**: Currently includes id, name, gender, notes, dateCreated, dateUpdated (basic fields).
- **PDF Reports**: Phase 10 generates reports but lacks patient-specific medical metadata (DOB, patient ID, doctor info).
- **User Feedback**: Doctors require DOB, patient ID (e.g., NHS number), doctor name, and clinic name for proper medical reports.

## Scope
- Add new Profile model fields: `dateOfBirth` (required), `patientId` (optional), `doctorName` (optional), `clinicName` (optional).
- Create database migration to add new columns to Profile table (schema version bump).
- Update ProfileService with CRUD for new fields.
- Update ProfileViewModel and profile management UI to support new fields.
- Add date picker for DOB with validation (must be in past, reasonable age range).
- Update profile forms with optional fields (graceful empty states).
- Unit and widget tests for new fields and validation.

## Architecture & Components

### 1. Profile Model Extension
**Modified File**: `lib/models/profile.dart`
- Add new fields:
  ```dart
  final DateTime? dateOfBirth;
  final String? patientId;
  final String? doctorName;
  final String? clinicName;
  ```
- Update `copyWith`, `toMap`, `fromMap`, `==`, `hashCode` methods.
- Add DartDoc for each new field:
  - `dateOfBirth`: User's date of birth for medical reports (required for PDF generation).
  - `patientId`: Optional patient identifier (e.g., NHS number, medical record number).
  - `doctorName`: Optional doctor's full name for PDF report header.
  - `clinicName`: Optional clinic or hospital name for PDF report header.

### 2. Database Migration
**Modified File**: `lib/services/database_service.dart`
- Bump schema version to **6** (or next available version).
- Add migration in `_onUpgrade`:
  ```sql
  ALTER TABLE Profile ADD COLUMN dateOfBirth INTEGER; -- Store as Unix timestamp (milliseconds)
  ALTER TABLE Profile ADD COLUMN patientId TEXT;
  ALTER TABLE Profile ADD COLUMN doctorName TEXT;
  ALTER TABLE Profile ADD COLUMN clinicName TEXT;
  ```
- Ensure backward compatibility: new columns are nullable; existing profiles continue to work.
- Add migration test: open v5 database, upgrade to v6, verify new columns exist and data preserved.

### 3. ProfileService Extension
**Modified File**: `lib/services/profile_service.dart`
- Update `createProfile`, `updateProfile` methods to handle new fields.
- Update `getProfile`, `getAllProfiles` queries to include new columns.
- Validation:
  - `dateOfBirth`: Must be in the past; reasonable age (e.g., 0-150 years old).
  - `patientId`, `doctorName`, `clinicName`: Free text (no validation beyond length limits).

### 4. ProfileViewModel Extension
**Modified File**: `lib/viewmodels/profile_viewmodel.dart`
- Expose new fields in state.
- Add validation logic for DOB (call service validation).
- Update create/update methods to pass new fields to service.

### 5. Profile Management UI Updates
**Modified File**: `lib/views/profile/add_edit_profile_view.dart`
- Add date picker for `dateOfBirth`:
  - Label: "Date of Birth *" (required indicator).
  - Tap to open date picker; format display as "MM/DD/YYYY" or locale-appropriate format.
  - Validation: Must be in past; reasonable age (0-150 years).
  - Error message: "Date of birth must be in the past" or "Invalid date of birth".
- Add optional text fields:
  - `patientId`: Label "Patient ID (optional)", hint "e.g., NHS number".
  - `doctorName`: Label "Doctor's Name (optional)", hint "e.g., Dr. Jane Smith".
  - `clinicName`: Label "Clinic Name (optional)", hint "e.g., City General Hospital".
- Layout: Group medical fields under "Medical Information" section header.
- Save button: Disabled until required fields (name, DOB) are valid.

**Modified File**: `lib/views/profile/profile_picker.dart`
- Display DOB under profile name (if set): "Born: MM/DD/YYYY" or age (e.g., "Age 45").
- Display patient ID if set: "ID: [patientId]" (small text below name).

## Implementation Tasks (Detailed)

### Task 1: Profile Model Extension
**File**: `lib/models/profile.dart`
**Subtasks**:
1. Add new fields: `dateOfBirth`, `patientId`, `doctorName`, `clinicName`.
2. Update constructor with new optional parameters.
3. Update `copyWith` to handle new fields.
4. Update `toMap` to serialize new fields (dateOfBirth as milliseconds timestamp).
5. Update `fromMap` to deserialize new fields (parse timestamp to DateTime).
6. Update `==` and `hashCode` to include new fields.
7. Add DartDoc comments for each new field.

**Estimated Changes**: +40 lines.

### Task 2: Database Migration
**File**: `lib/services/database_service.dart`
**Subtasks**:
1. Bump `_databaseVersion` to 6.
2. Add migration in `_onUpgrade`:
   ```dart
   if (oldVersion < 6) {
     await db.execute('ALTER TABLE Profile ADD COLUMN dateOfBirth INTEGER');
     await db.execute('ALTER TABLE Profile ADD COLUMN patientId TEXT');
     await db.execute('ALTER TABLE Profile ADD COLUMN doctorName TEXT');
     await db.execute('ALTER TABLE Profile ADD COLUMN clinicName TEXT');
   }
   ```
3. Update `_onCreate` to include new columns in initial Profile table creation.
4. Add migration test fixture (v5 database with test profiles).

**Estimated Changes**: +20 lines.

### Task 3: ProfileService Extension
**File**: `lib/services/profile_service.dart`
**Subtasks**:
1. Update `createProfile` to accept new fields.
2. Update `updateProfile` to accept new fields.
3. Add DOB validation:
   ```dart
   DateTime? validateDateOfBirth(DateTime? dob) {
     if (dob == null) return null;
     final now = DateTime.now();
     if (dob.isAfter(now)) throw ArgumentError('Date of birth must be in the past');
     final age = now.year - dob.year;
     if (age < 0 || age > 150) throw ArgumentError('Invalid date of birth');
     return dob;
   }
   ```
4. Update SQL queries to include new columns.
5. Add DartDoc for validation logic.

**Estimated Changes**: +30 lines.

### Task 4: ProfileViewModel Extension
**File**: `lib/viewmodels/profile_viewmodel.dart`
**Subtasks**:
1. Add new fields to ViewModel state.
2. Expose DOB validation method (call service validation).
3. Update `createProfile` and `updateProfile` methods to pass new fields.
4. Update state on profile load to include new fields.

**Estimated Changes**: +25 lines.

### Task 5: Profile Management UI Updates
**File**: `lib/views/profile/add_edit_profile_view.dart`
**Subtasks**:
1. Add "Medical Information" section header.
2. Add DOB date picker field:
   ```dart
   InkWell(
     onTap: () async {
       final picked = await showDatePicker(
         context: context,
         initialDate: dateOfBirth ?? DateTime.now().subtract(Duration(days: 365 * 30)),
         firstDate: DateTime(1900),
         lastDate: DateTime.now(),
       );
       if (picked != null) setState(() => dateOfBirth = picked);
     },
     child: InputDecorator(
       decoration: InputDecoration(
         labelText: 'Date of Birth *',
         errorText: dobError,
       ),
       child: Text(dateOfBirth != null ? DateFormat.yMd().format(dateOfBirth!) : 'Tap to select'),
     ),
   )
   ```
3. Add optional text fields for `patientId`, `doctorName`, `clinicName` with hints.
4. Add DOB validation on save:
   ```dart
   if (dateOfBirth == null) {
     setState(() => dobError = 'Date of birth is required');
     return;
   }
   if (dateOfBirth!.isAfter(DateTime.now())) {
     setState(() => dobError = 'Date of birth must be in the past');
     return;
   }
   ```
5. Update save method to pass new fields to ViewModel.

**Estimated Changes**: +80 lines.

### Task 6: Profile Picker Display Enhancement
**File**: `lib/views/profile/profile_picker.dart`
**Subtasks**:
1. Display DOB or age under profile name:
   ```dart
   if (profile.dateOfBirth != null) {
     final age = DateTime.now().year - profile.dateOfBirth!.year;
     Text('Age $age', style: Theme.of(context).textTheme.bodySmall);
   }
   ```
2. Display patient ID if set:
   ```dart
   if (profile.patientId != null && profile.patientId!.isNotEmpty) {
     Text('ID: ${profile.patientId}', style: Theme.of(context).textTheme.bodySmall);
   }
   ```

**Estimated Changes**: +15 lines.

## Acceptance Criteria

### Functional
- ✅ Profile model includes `dateOfBirth`, `patientId`, `doctorName`, `clinicName` fields.
- ✅ Database migration from v5 to v6 succeeds without data loss.
- ✅ UI allows editing new fields with appropriate controls (date picker for DOB, text fields for others).
- ✅ DOB validation ensures date is in past and reasonable age (0-150 years).
- ✅ Profile picker displays DOB/age and patient ID when available.
- ✅ Existing profiles continue to work; new fields are optional except DOB (required for new profiles).

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new model fields and service methods (§3.2).
- ✅ Unit tests for Profile model serialization/deserialization with new fields (≥90% coverage per §8.1).
- ✅ Unit tests for ProfileService validation logic (≥85% coverage per §8.1).
- ✅ Widget tests for profile form with new fields (≥70% coverage per §8.1).
- ✅ Migration test verifies v5 → v6 upgrade succeeds with existing data.
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ Date picker is accessible to screen readers.
- ✅ All text fields have proper labels and hints.
- ✅ Form validation errors are announced to screen readers.

## Dependencies
- Phase 16 (Profile-Centric UI Redesign): Profile management UI exists and is stable.
- Phase 10 (Export & Reports): PDF report generation exists; will be extended in Phase 25.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Migration fails on edge cases (corrupted databases) | High | Extensive migration testing with various database states; add error handling |
| DOB validation too strict (e.g., users born in 1800s?) | Low | Set reasonable range (1900-today); adjust if users report issues |
| Users confused by required DOB for existing profiles | Medium | Make DOB required only for new profiles; allow existing profiles to skip DOB (nullable) |
| Date picker UX differs across platforms (Android/iOS) | Low | Use Flutter's platform-adaptive date picker; test on both platforms |

## Testing Strategy

### Unit Tests
**Modified File**: `test/models/profile_test.dart`
- Test serialization/deserialization with new fields.
- Test `copyWith` with new fields.
- Test equality with new fields.

**Modified File**: `test/services/profile_service_test.dart`
- Test DOB validation (valid, future date, ancient date).
- Test create/update with new fields.
- Test profile retrieval includes new fields.

**New File**: `test/services/database_migration_v6_test.dart`
- Test migration from v5 to v6 with existing profiles.
- Verify new columns exist and are nullable.
- Verify existing profile data is preserved.

**Estimated**: 25 unit tests.

### Widget Tests
**Modified File**: `test/views/profile/add_edit_profile_view_test.dart`
- Test date picker opens and sets DOB.
- Test DOB validation error messages.
- Test optional fields can be empty.
- Test save button disabled until required fields valid.

**Modified File**: `test/views/profile/profile_picker_test.dart`
- Test DOB/age display when DOB is set.
- Test patient ID display when set.
- Test graceful empty state when fields not set.

**Estimated**: 15 widget tests.

### Integration Tests
**New File**: `test_driver/profile_migration_test.dart`
- Create v5 database with test profiles.
- Open app (triggers migration to v6).
- Verify profiles load correctly with new fields.
- Create new profile with DOB; verify persistence.

**Estimated**: 3 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-20-profile-extensions`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Migration adds nullable columns; existing profiles continue to work without new fields.
- If critical migration issues occur, can revert to v5 and address issues before re-releasing v6.
- Feature-flag new profile fields in UI if needed; users can continue using profiles without filling new fields.

## Performance Considerations
- Migration adds 4 columns; minimal performance impact (Profile table is small, typically <10 rows per user).
- Date picker is standard Flutter widget; no performance concerns.
- Profile queries unchanged (SELECT * pattern); new columns add negligible overhead.

## Documentation Updates
- **User-facing**: Add note to QUICKSTART.md or in-app help: "Date of Birth is required for PDF reports".
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 20 complete upon merge.
- **Migration notes**: Document v5 → v6 migration in CHANGELOG.md for future reference.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 2-3 days (including migration testing and review)  
**Target Completion**: TBD based on sprint schedule

# Phase 21 Plan: Enhanced Sleep Tracking

**Objective**: Redesign sleep tracking to support dual-mode entry (detailed REM/Light/Deep metrics or basic total hours + notes) with schema changes.

## Current State (Audit)
- **Sleep Model**: Phase 4 implemented basic `SleepEntry` with hours, quality notes, and timestamps.
- **User Feedback**: Users want option to log detailed sleep metrics (REM, Light, Deep) from sleep trackers OR simple total hours + notes.
- **Gap**: Current schema only supports total hours; no breakdown of sleep stages.

## Scope
- Redesign SleepEntry schema: add optional fields for `remHours`, `remMinutes`, `lightHours`, `lightMinutes`, `deepHours`, `deepMinutes`, `textualNotes`.
- Create database migration to add new columns to SleepEntry table (schema version bump).
- Update SleepService to support new fields.
- Update SleepViewModel with dual-mode logic.
- Create new Add/Edit Sleep UI with mode toggle: **Detailed** (REM/Light/Deep sliders or pickers) vs **Basic** (total hours + notes).
- Validation: ensure sleep metrics are reasonable (0-24 hours total; components sum correctly in detailed mode).
- Update sleep history and analytics to display new metrics when available.
- Unit and widget tests for dual-mode entry and validation.

## Architecture & Components

### 1. SleepEntry Model Extension
**Modified File**: `lib/models/health_data.dart`
- Add new optional fields:
  ```dart
  final int? remHours;
  final int? remMinutes;
  final int? lightHours;
  final int? lightMinutes;
  final int? deepHours;
  final int? deepMinutes;
  final String? textualNotes; // Replaces or supplements existing notes
  ```
- Update `copyWith`, `toMap`, `fromMap`, `==`, `hashCode` methods.
- Add computed property for total sleep duration when using detailed mode:
  ```dart
  Duration get totalDuration {
    if (remHours != null) {
      // Detailed mode: sum all components
      return Duration(
        hours: (remHours ?? 0) + (lightHours ?? 0) + (deepHours ?? 0),
        minutes: (remMinutes ?? 0) + (lightMinutes ?? 0) + (deepMinutes ?? 0),
      );
    } else {
      // Basic mode: use existing hours field
      return Duration(hours: hours);
    }
  }
  ```
- Add DartDoc for new fields and mode distinction.

### 2. Database Migration
**Modified File**: `lib/services/database_service.dart`
- Bump schema version to **7** (or next available version).
- Add migration in `_onUpgrade`:
  ```sql
  ALTER TABLE SleepEntry ADD COLUMN remHours INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN remMinutes INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN lightHours INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN lightMinutes INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN deepHours INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN deepMinutes INTEGER;
  ALTER TABLE SleepEntry ADD COLUMN textualNotes TEXT;
  ```
- Ensure backward compatibility: new columns are nullable; existing sleep entries continue to work in basic mode.
- Add migration test: open v6 database, upgrade to v7, verify new columns exist and data preserved.

### 3. SleepService Extension
**Modified File**: `lib/services/sleep_service.dart`
- Update `createSleepEntry`, `updateSleepEntry` methods to handle new fields.
- Add validation:
  - **Basic mode**: Total hours must be 0-24.
  - **Detailed mode**: Sum of REM + Light + Deep must be ≤24 hours.
  - Individual components: 0-24 hours each; minutes 0-59.
- Update SQL queries to include new columns.

### 4. SleepViewModel Extension
**Modified File**: `lib/viewmodels/sleep_viewmodel.dart`
- Add mode state: `enum SleepEntryMode { basic, detailed }`.
- Expose validation logic for both modes.
- Update create/update methods to pass new fields to service.

### 5. Add/Edit Sleep UI Redesign
**Modified File**: `lib/views/sleep/add_edit_sleep_view.dart`
- Add mode toggle (segmented button or switch): **Basic** | **Detailed**.
- **Basic Mode UI**:
  - Total hours picker (0-24).
  - Textual notes field (multi-line).
- **Detailed Mode UI**:
  - REM sleep: Hours (0-24) + Minutes (0-59) pickers.
  - Light sleep: Hours (0-24) + Minutes (0-59) pickers.
  - Deep sleep: Hours (0-24) + Minutes (0-59) pickers.
  - Display total: "Total: X hours Y minutes" (computed from components).
  - Optional textual notes field.
- Validation:
  - Basic: total hours 0-24.
  - Detailed: sum of components ≤24 hours; display error if exceeded.
- Layout: Use expandable sections or tabs for clean UX.

### 6. Sleep History & Analytics Display
**Modified File**: `lib/views/history/sleep_history_view.dart` (or equivalent)
- Display sleep breakdown if detailed mode:
  - "REM: Xh Ym | Light: Xh Ym | Deep: Xh Ym"
- Display total hours if basic mode:
  - "Total: X hours"
- Include notes in both modes.

**Modified File**: `lib/services/analytics_service.dart`
- Update sleep analytics to handle dual-mode data:
  - Chart: Stacked area for REM/Light/Deep when available; single bar for basic mode.
  - Stats: Average REM/Light/Deep percentages for detailed entries.

## Implementation Tasks (Detailed)

### Task 1: SleepEntry Model Extension
**File**: `lib/models/health_data.dart`
**Subtasks**:
1. Add new fields: `remHours`, `remMinutes`, `lightHours`, `lightMinutes`, `deepHours`, `deepMinutes`, `textualNotes`.
2. Update constructor with new optional parameters.
3. Update `copyWith`, `toMap`, `fromMap`, `==`, `hashCode`.
4. Add `totalDuration` computed property.
5. Add DartDoc comments.

**Estimated Changes**: +60 lines.

### Task 2: Database Migration
**File**: `lib/services/database_service.dart`
**Subtasks**:
1. Bump `_databaseVersion` to 7.
2. Add migration in `_onUpgrade` (7 new columns).
3. Update `_onCreate` to include new columns.
4. Add migration test fixture.

**Estimated Changes**: +25 lines.

### Task 3: SleepService Extension
**File**: `lib/services/sleep_service.dart`
**Subtasks**:
1. Update `createSleepEntry` and `updateSleepEntry` to handle new fields.
2. Add validation logic for basic and detailed modes.
3. Update SQL queries to include new columns.
4. Add DartDoc for validation rules.

**Estimated Changes**: +40 lines.

### Task 4: SleepViewModel Extension
**File**: `lib/viewmodels/sleep_viewmodel.dart`
**Subtasks**:
1. Add `SleepEntryMode` enum to state.
2. Add mode toggle method.
3. Expose validation for both modes.
4. Update create/update methods to pass new fields.

**Estimated Changes**: +30 lines.

### Task 5: Add/Edit Sleep UI Redesign
**File**: `lib/views/sleep/add_edit_sleep_view.dart`
**Subtasks**:
1. Add mode toggle UI (segmented button at top).
2. Implement basic mode UI (total hours picker + notes).
3. Implement detailed mode UI (REM/Light/Deep pickers + computed total + notes).
4. Add validation display (error messages for invalid totals).
5. Update save logic to handle mode-specific fields.

**Estimated Changes**: +150 lines.

### Task 6: Sleep History Display Enhancement
**File**: `lib/views/history/sleep_history_view.dart` (or create if not exists)
**Subtasks**:
1. Detect sleep entry mode (detailed if REM/Light/Deep fields present).
2. Display breakdown for detailed entries.
3. Display total for basic entries.
4. Include notes in both modes.

**Estimated Changes**: +40 lines.

### Task 7: Sleep Analytics Enhancement
**File**: `lib/services/analytics_service.dart`
**Subtasks**:
1. Update sleep data aggregation to handle dual-mode entries.
2. Create stacked area chart data for detailed entries (REM/Light/Deep).
3. Create single bar/line chart for basic entries.
4. Calculate average sleep stage percentages for detailed entries.

**Modified File**: `lib/views/analytics/widgets/sleep_stacked_area_chart.dart`
- Update to handle optional REM/Light/Deep data.
- Fall back to total hours if detailed data not available.

**Estimated Changes**: +60 lines.

## Acceptance Criteria

### Functional
- ✅ Users can toggle between Basic and Detailed sleep entry modes.
- ✅ Basic mode captures total hours + notes.
- ✅ Detailed mode captures REM/Light/Deep hours and minutes + optional notes.
- ✅ Validation ensures total sleep ≤24 hours in both modes.
- ✅ Detailed mode components sum correctly; error displayed if total >24 hours.
- ✅ Migration from v6 to v7 succeeds without data loss.
- ✅ Sleep history displays mode-appropriate data (breakdown or total).
- ✅ Sleep analytics charts handle dual-mode data correctly.

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new model fields and service methods (§3.2).
- ✅ Unit tests for SleepEntry model with new fields (≥90% coverage per §8.1).
- ✅ Unit tests for SleepService validation logic (≥85% coverage per §8.1).
- ✅ Widget tests for dual-mode sleep form (≥70% coverage per §8.1).
- ✅ Migration test verifies v6 → v7 upgrade succeeds.
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ Mode toggle is accessible to screen readers with semantic labels.
- ✅ All pickers have proper labels and hints.
- ✅ Validation errors are announced to screen readers.

## Dependencies
- Phase 4 (Weight & Sleep): Basic sleep tracking exists.
- Phase 20 (Profile Model Extensions): Migration pattern established.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Users confused by two modes | Medium | Default to Basic mode; provide in-app help explaining modes |
| Detailed mode UI is cluttered | Medium | Use expandable sections or tabs; show total prominently |
| Validation too strict (e.g., naps >24 hours with multiple entries?) | Low | Validation is per-entry (0-24 hours); users can create multiple entries for multi-day sleep tracking |
| Migration fails on edge cases | High | Extensive migration testing with various sleep entry states |

## Testing Strategy

### Unit Tests
**Modified File**: `test/models/health_data_test.dart`
- Test SleepEntry serialization/deserialization with new fields.
- Test `totalDuration` computed property for both modes.
- Test equality with new fields.

**Modified File**: `test/services/sleep_service_test.dart`
- Test basic mode validation (total hours 0-24).
- Test detailed mode validation (sum ≤24 hours, components valid).
- Test create/update with new fields.

**New File**: `test/services/database_migration_v7_test.dart`
- Test migration from v6 to v7 with existing sleep entries.
- Verify new columns exist and are nullable.
- Verify existing data preserved.

**Estimated**: 30 unit tests.

### Widget Tests
**Modified File**: `test/views/sleep/add_edit_sleep_view_test.dart`
- Test mode toggle switches between Basic and Detailed UIs.
- Test basic mode saves total hours + notes.
- Test detailed mode saves REM/Light/Deep + notes.
- Test validation errors for both modes.

**Estimated**: 20 widget tests.

### Integration Tests
**New File**: `test_driver/sleep_entry_test.dart`
- Create sleep entry in basic mode; verify persistence.
- Create sleep entry in detailed mode; verify persistence.
- Edit basic entry → switch to detailed; verify data migration.
- Edit detailed entry → switch to basic; verify total calculation.

**Estimated**: 5 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-21-enhanced-sleep`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Migration adds nullable columns; existing sleep entries continue to work in basic mode.
- If critical issues occur, can revert to v6 and address issues before re-releasing v7.
- Feature-flag detailed mode in UI if needed; users can continue using basic mode only.

## Performance Considerations
- Migration adds 7 columns; minimal performance impact (SleepEntry table is small).
- Detailed mode UI has 6 pickers; use optimized picker widgets to avoid lag.
- Analytics charts: stacked area chart for detailed mode may be more complex; optimize rendering for >100 entries.

## Documentation Updates
- **User-facing**: Add in-app help or tooltip explaining Basic vs Detailed modes.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 21 complete upon merge.
- **Migration notes**: Document v6 → v7 migration in CHANGELOG.md.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 3-5 days (including migration testing and review)  
**Target Completion**: TBD based on sprint schedule

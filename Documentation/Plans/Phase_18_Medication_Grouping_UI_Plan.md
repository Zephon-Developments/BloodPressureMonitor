# Phase 18 Plan: Medication Grouping UI

**Objective**: Expose existing medication grouping backend with intuitive UI for group management and quick logging.

## Current State (Audit)
- **Backend**: `MedicationGroup` model and `MedicationGroupService` exist with full CRUD support (Phase 3).
- **Backend**: `MedicationGroupViewModel` exists with state management (Phase 11).
- **UI**: No UI currently exposes medication groups to users.
- **Gap**: Users cannot create groups or log entire groups with one action.
- **Additional Issues**: Dosage field lacks numeric validation; unit field is free-text (should be combo box); search bar lacks clear button.

## Scope
- Create UI for viewing, creating, editing, and deleting medication groups.
- Add group picker to Log Medication flow; support logging entire group with one tap.
- Add dosage field numeric validation (prevent non-numeric input with helpful error messages).
- Convert unit field to combo box with common units (mg, ml, IU, mcg, units) + custom entry option.
- Add clear button (X icon) to all medication search bars.
- Widget tests for group management and group logging flows.

## Architecture & Components

### 1. Medication Group Management UI
**New File**: `lib/views/medication/medication_group_list_view.dart`
- List view showing all medication groups for active profile.
- Each group card displays: group name, member count, optional description.
- Actions: Add group (FAB), edit group (tap card), delete group (swipe or context menu).
- Empty state with helpful message encouraging group creation.

**New File**: `lib/views/medication/add_edit_medication_group_view.dart`
- Form for creating/editing groups.
- Fields: group name (required), description (optional), member medications (multi-select).
- Multi-select medication picker with search and checkboxes.
- Validation: group name required, at least one medication in group.
- Save/cancel actions.

### 2. Group Logging Integration
**Modified File**: `lib/views/medication/log_intake_sheet.dart`
- Add toggle/tab to switch between "Individual Medication" and "Medication Group" modes.
- Group mode: group picker (dropdown or sheet) → select group → log entire group with one timestamp.
- Backend already supports group logging via `MedicationIntakeService.logGroupIntake()`.

**Modified File**: `lib/widgets/medication/medication_picker_dialog.dart`
- Add "Log as Group" section at top if groups exist.
- Display groups with member counts; tap to select entire group.
- Fallback to individual picker if no groups or user prefers individual selection.

### 3. Dosage & Unit Field Enhancements
**Modified File**: `lib/views/medication/add_edit_medication_view.dart`
- Dosage field: Change `TextInputType` to `number` or `numberWithOptions(decimal: true)`.
- Add validator: `RegExp(r'^\d+(\.\d+)?$')` to ensure numeric input; display error "Dosage must be a number" on failure.

**New Widget**: `lib/widgets/medication/unit_combo_box.dart`
- Dropdown or combo box with predefined units: `['mg', 'ml', 'IU', 'mcg', 'units', 'tablets', 'capsules', 'Custom']`.
- If "Custom" selected, show text field for free-form entry.
- Persist custom units to allow reuse in future selections.

### 4. Search Bar Clear Button
**Modified Files**: 
- `lib/widgets/medication/medication_picker_dialog.dart`
- Any other search bars in medication views.

- Add `suffixIcon` to `TextField`: `IconButton` with `Icons.clear` icon.
- On tap, clear the search controller and refocus the field (optional).
- Show clear button only when search text is non-empty.

## Implementation Tasks (Detailed)

### Task 1: Medication Group List View
**File**: `lib/views/medication/medication_group_list_view.dart`
- Create stateful widget consuming `MedicationGroupViewModel`.
- Use `StreamBuilder` or `watch` to display groups for active profile.
- Card layout with group name, member count, optional description.
- Swipe-to-delete using `flutter_slidable` (consistent with existing delete patterns).
- Empty state: "No medication groups yet. Create one to log multiple medications at once."
- DartDoc: Document widget purpose, state management, and accessibility.

**Estimated Lines**: ~250 lines.

### Task 2: Add/Edit Medication Group Form
**File**: `lib/views/medication/add_edit_medication_group_view.dart`
- Form with `TextFormField` for name and description.
- Multi-select medication picker: show all active medications with checkboxes.
- Validation: require name, require at least one medication.
- Save: call `MedicationGroupViewModel.createGroup()` or `updateGroup()`.
- Cancel: pop navigation.
- DartDoc: Document form fields, validation rules, and save flow.

**Estimated Lines**: ~300 lines.

### Task 3: Multi-Select Medication Picker
**File**: `lib/widgets/medication/multi_select_medication_picker.dart`
- Modal bottom sheet or dialog with search bar + checkbox list.
- Filter medications by search query.
- Return `List<Medication>` on confirmation.
- Include clear button on search bar (Task 6).

**Estimated Lines**: ~200 lines.

### Task 4: Group Logging Integration
**Modified File**: `lib/views/medication/log_intake_sheet.dart`
- Add tab/toggle to switch between "Individual" and "Group" modes.
- Group mode: display group picker (dropdown or bottom sheet).
- On group selection, call `MedicationIntakeViewModel.logGroupIntake(groupId, timestamp, notes)`.
- Show success snackbar: "Logged [group name] ([count] medications)".
- Clear selection after successful log.

**Estimated Changes**: +100 lines.

### Task 5: Dosage Numeric Validation
**Modified File**: `lib/views/medication/add_edit_medication_view.dart`
- Update dosage `TextFormField`:
  - `keyboardType: TextInputType.numberWithOptions(decimal: true)`
  - `validator: (value) => value == null || value.isEmpty || RegExp(r'^\d+(\.\d+)?$').hasMatch(value) ? null : 'Dosage must be a number'`
- DartDoc: Update field documentation to note numeric validation.

**Estimated Changes**: +10 lines (validator + keyboard type).

### Task 6: Unit Combo Box
**New File**: `lib/widgets/medication/unit_combo_box.dart`
- `DropdownButtonFormField` with predefined units: `['mg', 'ml', 'IU', 'mcg', 'units', 'tablets', 'capsules', 'Custom']`.
- On "Custom" selection, show `TextFormField` for free-form entry.
- Expose `onChanged(String unit)` callback to parent.
- DartDoc: Document predefined units, custom entry flow, and callback.

**Estimated Lines**: ~100 lines.

**Modified File**: `lib/views/medication/add_edit_medication_view.dart`
- Replace unit `TextFormField` with `UnitComboBox`.
- Pass current unit value and update on change.

**Estimated Changes**: +10 lines (widget swap).

### Task 7: Search Bar Clear Buttons
**Modified Files**: 
- `lib/widgets/medication/medication_picker_dialog.dart`
- `lib/widgets/medication/multi_select_medication_picker.dart`

- Add `suffixIcon` to search `TextField`: 
  ```dart
  suffixIcon: searchController.text.isNotEmpty
      ? IconButton(
          icon: Icon(Icons.clear),
          onPressed: () {
            searchController.clear();
            // Trigger rebuild or refocus
          },
        )
      : null,
  ```
- Use `ValueListenableBuilder` or `setState` to show/hide clear button based on text.

**Estimated Changes**: +15 lines per file.

### Task 8: Navigation Integration
**Modified File**: `lib/views/medication/medication_list_view.dart`
- Add "Manage Groups" menu item or button to navigate to `MedicationGroupListView`.

**Modified File**: `lib/views/home/widgets/quick_actions.dart` (optional)
- Modify "Log Medication" quick action to open group picker if groups exist.

**Estimated Changes**: +20 lines.

## Acceptance Criteria

### Functional
- ✅ Users can create medication groups with name, description, and member medications.
- ✅ Users can edit and delete medication groups.
- ✅ Users can log entire groups with one action via Log Medication flow.
- ✅ Dosage field enforces numeric input with helpful error messages.
- ✅ Unit field offers combo box with common units + custom entry option.
- ✅ All medication search bars include functional clear button (X icon).

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all public APIs (§3.2).
- ✅ Widget tests for group management UI (≥70% coverage per §8.1).
- ✅ Unit tests for validation logic (dosage numeric, group name required).
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ All interactive elements have semantic labels for screen readers (§7.2).
- ✅ Forms work correctly with large text scaling (1.5x, 2x).
- ✅ Color contrast meets WCAG AA standards for all UI elements.

## Dependencies
- Phase 11 (Medication UI foundation): `MedicationViewModel`, `medication_list_view.dart`.
- Phase 12 (Intake logging): `LogIntakeSheet`, `MedicationIntakeViewModel`.
- Existing backend: `MedicationGroupService`, `MedicationGroupViewModel`.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Group logging UI confuses users (too many modes) | Medium | User testing; consider defaulting to group picker if groups exist |
| Multi-select picker performance degrades with many medications | Low | Lazy loading; pagination for >100 medications |
| Custom unit persistence creates data bloat | Low | Store custom units in a separate table (future enhancement) |
| Dosage validation too strict (e.g., fractions like "1/2") | Medium | Consider supporting fractions or relaxing validation to allow text with guidance |

## Testing Strategy

### Unit Tests
**New File**: `test/widgets/medication/unit_combo_box_test.dart`
- Test predefined units display correctly.
- Test custom unit entry flow.
- Test callback invocation on selection.

**New File**: `test/viewmodels/medication_group_viewmodel_test.dart` (if not exists)
- Test group CRUD operations.
- Test group loading for active profile.

**Estimated**: 20 unit tests.

### Widget Tests
**New File**: `test/views/medication/medication_group_list_view_test.dart`
- Test empty state display.
- Test group list rendering.
- Test navigation to add/edit forms.
- Test swipe-to-delete confirmation.

**New File**: `test/views/medication/add_edit_medication_group_view_test.dart`
- Test form validation (name required, at least one medication).
- Test save/cancel flows.
- Test multi-select medication picker.

**New File**: `test/views/medication/log_intake_sheet_group_test.dart`
- Test group mode toggle.
- Test group selection and logging.
- Test success snackbar.

**Estimated**: 25 widget tests.

### Integration Tests
**Modified File**: `test_driver/medication_flow_test.dart` (if exists)
- End-to-end: Create group → Log group → Verify intake records.

**Estimated**: 3 integration tests.

## Branching & Workflow
- **Branch**: `feature/phase-18-medication-grouping-ui`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Feature-flag group UI components; disable via remote config or build flag if critical issues arise.
- Existing individual medication logging remains functional; users can continue logging without groups.
- Migration: No schema changes in this phase; rollback is non-destructive.

## Performance Considerations
- **Multi-select picker**: Lazy load medications if count >100; use `ListView.builder` with virtual scrolling.
- **Group logging**: Backend already optimized (single transaction for group intake); UI should be responsive.
- **Search bar filtering**: Debounce search input (e.g., 300ms delay) to reduce unnecessary rebuilds.

## Documentation Updates
- **User-facing**: Add "Medication Groups" section to in-app help or QUICKSTART.md.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 18 complete upon merge.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 3-5 days (including testing and review)  
**Target Completion**: TBD based on sprint schedule

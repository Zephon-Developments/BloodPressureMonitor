# Handoff: Steve to Tracy

**Date:** 2025-12-30
**Subject:** Plan for Edit/Delete UI Implementation (Phase 9)

## Context

The user has requested the ability to edit and delete data within the app. Currently, while backend services support update and delete operations for most data types, the UI layer does not expose these capabilities to users.

## Current State Analysis

### Backend Capabilities (Already Implemented)

| Data Type | Service | Update Method | Delete Method | Status |
|-----------|---------|---------------|---------------|--------|
| Blood Pressure Reading | `ReadingService` | `updateReading()` ✅ | `deleteReading()` ✅ | Backend ready |
| Weight Entry | `WeightService` | `updateWeightEntry()` ✅ | `deleteWeightEntry()` ✅ | Backend ready |
| Sleep Entry | `SleepService` | `updateSleepEntry()` ✅ | `deleteSleepEntry()` ✅ | Backend ready |
| Medication | `MedicationService` | `updateMedication()` ✅ | `deleteMedication()` ✅ (soft delete) | Backend ready |
| Medication Intake | `MedicationIntakeService` | `updateIntake()` ❌ | `deleteIntake()` ✅ | Partial |
| Profile | `ProfileService` | `updateProfile()` ✅ | ❌ | Partial |

### ViewModel Support

| ViewModel | Update Support | Delete Support |
|-----------|----------------|----------------|
| `BloodPressureViewModel` | `updateReading()` ✅ | `deleteReading()` ✅ |
| `WeightViewModel` | ❌ Missing | ❌ Missing |
| `SleepViewModel` | ❌ Missing | ❌ Missing |
| `HistoryViewModel` | ❌ (View-only) | ❌ (View-only) |
| `AnalyticsViewModel` | ❌ (View-only) | ❌ (View-only) |

### UI Gaps

Currently, the app has:
- ✅ Add views for: Readings, Weight, Sleep
- ❌ NO edit views for any data type
- ❌ NO delete UI for any data type
- ❌ NO detail views with edit/delete actions

The `HistoryView` displays data but provides no interaction mechanisms for editing or deleting entries.

## Requirements

### User Stories

1. **As a user, I want to edit a blood pressure reading** so I can correct mistakes or add notes.
2. **As a user, I want to delete a blood pressure reading** so I can remove accidental or incorrect entries.
3. **As a user, I want to edit weight entries** to correct typos or update notes.
4. **As a user, I want to delete weight entries** to remove duplicates or errors.
5. **As a user, I want to edit sleep entries** to refine duration or quality scores.
6. **As a user, I want to delete sleep entries** to remove incorrect data.
7. **As a user, I want confirmation before deleting** to prevent accidental data loss.

### Scope

**In Scope:**
- Edit/Delete for Blood Pressure Readings
- Edit/Delete for Weight Entries
- Edit/Delete for Sleep Entries
- Confirmation dialogs for delete operations
- Proper error handling and user feedback
- Auto-refresh of views after edit/delete
- Triggering averaging recomputation for BP readings

**Out of Scope (Future Enhancements):**
- Bulk delete operations
- Undo functionality
- Edit history/audit trail
- Medication intake editing (complexity with groups)
- Profile deletion (requires data cascade handling)

## Task Breakdown

### Task 1: Extend ViewModels
**Priority:** High
**Estimated Effort:** 2-3 hours

Add update/delete methods to ViewModels that are missing them:

1. **WeightViewModel**
   - Add `updateWeightEntry(WeightEntry entry)` method
   - Add `deleteWeightEntry(int id)` method
   - Follow the pattern from `BloodPressureViewModel`
   - Include proper error handling and loading states

2. **SleepViewModel**
   - Add `updateSleepEntry(SleepEntry entry)` method
   - Add `deleteSleepEntry(int id)` method
   - Include validation if needed
   - Proper error handling and loading states

**Acceptance Criteria:**
- ViewModels expose update/delete methods
- Methods handle errors gracefully
- Loading states are properly managed
- Unit tests added for new methods (≥85% coverage)

### Task 2: Create Edit Views
**Priority:** High
**Estimated Effort:** 4-5 hours

Create dedicated edit views that reuse the add view forms:

1. **Edit Reading View**
   - Extend or create variant of `AddReadingView`
   - Pre-populate fields with existing reading data
   - Support validation with override confirmations
   - Save button triggers `updateReading()` instead of `addReading()`

2. **Edit Weight View**
   - Extend or create variant of `AddWeightView`
   - Pre-populate weight value, unit, notes
   - Save triggers `updateWeightEntry()`

3. **Edit Sleep View**
   - Extend or create variant of `AddSleepView`
   - Pre-populate sleep duration, quality, timestamps
   - Save triggers `updateSleepEntry()`

**Design Patterns:**
- Option A: Modify existing add views to accept optional `editingId` parameter
- Option B: Create separate edit views that share form widgets
- **Recommendation:** Option A (simpler, less duplication)

**Acceptance Criteria:**
- Forms pre-populate with existing data
- Validation works correctly
- Save operations update existing records
- Navigation returns to previous screen on success
- Error messages displayed on failure

### Task 3: Add Delete Functionality
**Priority:** High
**Estimated Effort:** 2-3 hours

Implement delete actions with confirmations:

1. **Confirmation Dialog Widget**
   - Create reusable `ConfirmDeleteDialog`
   - Shows item details (e.g., "Delete reading from Jan 1, 2025?")
   - Two buttons: "Cancel" and "Delete"
   - Red/destructive styling for Delete button

2. **Delete Integration**
   - Add delete action to reading cards/list items
   - Add delete action to weight history items
   - Add delete action to sleep history items
   - Show confirmation dialog before executing
   - Display success/error messages via SnackBar

**Acceptance Criteria:**
- Delete requires confirmation
- Confirmation shows relevant item details
- Successful delete refreshes the view
- Error handling with user-friendly messages
- SnackBar feedback for success/failure

### Task 4: Enhance History View
**Priority:** Medium
**Estimated Effort:** 3-4 hours

Add edit/delete actions to the History View:

1. **Reading Group Cards**
   - Add "Expand to Edit Members" option
   - Show individual readings in expanded state
   - Each reading has Edit and Delete actions
   - Maintain grouped view when editing/deleting

2. **Raw Reading View**
   - Add Edit and Delete actions to each reading card
   - Swipe-to-delete gesture (optional, nice-to-have)
   - Long-press menu with Edit/Delete options

3. **Detail View** (Optional Enhancement)
   - Create a detail dialog/bottom sheet
   - Shows full reading details
   - Includes Edit and Delete buttons
   - Better for small screens

**Acceptance Criteria:**
- Actions accessible from history view
- Grouped view properly handles member edits/deletes
- Recomputes averages after BP reading changes
- UI updates automatically after operations

### Task 5: Testing & Polish
**Priority:** High
**Estimated Effort:** 3-4 hours

1. **Unit Tests**
   - Test ViewModel update/delete methods
   - Test validation edge cases
   - Test error handling paths
   - Target ≥85% coverage for new code

2. **Widget Tests**
   - Test edit view pre-population
   - Test delete confirmation dialog
   - Test error state rendering
   - Test success state navigation

3. **Integration Testing**
   - Test full edit flow: tap → edit → save → verify
   - Test full delete flow: tap → confirm → verify
   - Test averaging recomputation after BP edits
   - Test error scenarios (network, database)

**Acceptance Criteria:**
- All tests passing
- Coverage meets project standards (≥85%)
- Manual testing checklist completed
- No analyzer warnings

## Technical Considerations

### 1. Averaging Impact
When a BP reading is edited or deleted:
- `AveragingService.createOrUpdateGroupsForReading()` must run
- May affect multiple groups if timestamp changes significantly
- Need to handle potential averaging failures gracefully

### 2. Analytics Cache Invalidation
After edits/deletes:
- `AnalyticsViewModel` cache should be invalidated
- User should see updated stats after changes
- Consider adding `analyticsViewModel.invalidateCache()` calls

### 3. Navigation Patterns
- Edit: Navigate to edit view → Save → Pop back
- Delete: Show dialog → Confirm → Refresh current view
- Consider using `Navigator.pop(context, true)` to signal changes

### 4. Data Consistency
- Ensure reading updates don't orphan averaging groups
- Sleep/Weight deletes should be straightforward (no cascades)
- Consider soft deletes for readings (with permanent delete later)

### 5. Performance
- Deleting from large lists: ensure smooth UX
- Batch operations if deleting multiple items (future)
- Consider optimistic UI updates

## UI/UX Recommendations

### Visual Design
- Use trailing `PopupMenuButton` for Edit/Delete actions
- Use `Icons.edit` and `Icons.delete` consistently
- Delete button should use `Colors.red` or error theme color
- Show loading spinner during operations

### Confirmation Dialog
```dart
ConfirmDeleteDialog(
  title: "Delete Reading?",
  message: "This will permanently delete the reading from 
           Jan 1, 2025 at 8:30 AM (120/80 mmHg).",
  onConfirm: () => viewModel.deleteReading(id),
)
```

### Feedback
- Success: Green SnackBar "Reading deleted successfully"
- Error: Red SnackBar with error message
- Loading: Show progress indicator on card/button

## Standards Compliance

### Code Quality
- Follow [CODING_STANDARDS.md](../Standards/Coding_Standards.md)
- Use proper error handling patterns
- Document public APIs with JSDoc comments
- Use `const` constructors where applicable

### Testing
- Unit tests for all ViewModel methods
- Widget tests for edit views and dialogs
- Integration tests for critical flows
- Target ≥85% coverage

### Security
- No sensitive data in logs
- Validate user input on edits
- Prevent SQL injection (use parameterized queries)

## Success Metrics

- [ ] All data types support edit operations
- [ ] All data types support delete operations (with confirmation)
- [ ] Zero analyzer warnings
- [ ] All tests passing (≥85% coverage)
- [ ] Manual testing checklist completed
- [ ] Code review approved by Clive

## Questions for Tracy

1. Should we use Option A (extend add views) or Option B (separate edit views)?
2. Should we implement swipe-to-delete gestures or stick with explicit buttons?
3. Should deletes be soft (mark as deleted) or hard (permanent removal)?
4. Should we create a detail view or use edit view for viewing details?
5. Priority: Should this be Phase 9 or split into smaller phases?

## Recommended Plan Structure

**Phase 9A: Core Edit/Delete (MVP)**
- Task 1: Extend ViewModels
- Task 2: Create Edit Views (BP, Weight, Sleep)
- Task 3: Add Delete Functionality (with confirmations)
- Task 5: Testing

**Phase 9B: History Integration & Polish**
- Task 4: Enhance History View with edit/delete actions
- Additional polish and UX improvements
- Edge case handling

## Next Steps

Tracy, please:
1. Review this handoff and the current codebase structure
2. Answer the questions above
3. Create a detailed implementation plan following the Phase structure
4. Document the plan in `Documentation/Plans/Phase_9_Edit_Delete_Plan.md`
5. Identify any technical blockers or dependencies
6. Hand off to Clive for review before implementation begins

---

**Steve**
Workflow Conductor
2025-12-30

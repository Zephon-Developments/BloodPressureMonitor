# Handoff: Clive → Claudette

**Date**: December 31, 2025  
**From**: Clive (Review Specialist)  
**To**: Claudette (Implementation Engineer)  
**Task**: Phase 15 - Reminder Removal Implementation

---

## 1. Task Overview

You are assigned to implement **Phase 15: Reminder Removal**. The goal is to completely remove the reminder feature, including its database schema, data models, and UI placeholders, while ensuring a smooth migration for existing users.

## 2. Reference Documents

- **Implementation Plan**: [Documentation/Plans/Phase_15_Reminder_Removal_Plan.md](../Plans/Phase_15_Reminder_Removal_Plan.md)
- **Review Approval**: [reviews/2025-12-31-clive-phase-15-plan-review.md](../../reviews/2025-12-31-clive-phase-15-plan-review.md)
- **Coding Standards**: [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)

## 3. Implementation Steps

### 3.1 Database Migration
1.  Open `lib/services/database_service.dart`.
2.  Increment `_databaseVersion` from `4` to `5`.
3.  In `_onCreate`, remove the `CREATE TABLE Reminder` block.
4.  In `_onUpgrade`, add a migration for `oldVersion < 5`:
    ```dart
    if (oldVersion < 5) {
      await db.execute('DROP TABLE IF EXISTS Reminder');
    }
    ```

### 3.2 Model Removal
1.  Open `lib/models/health_data.dart`.
2.  Delete the `Reminder` class and its associated DartDoc.
3.  Verify no unused imports remain in other files (though audit suggests none exist).

### 3.3 UI Cleanup
1.  Open `lib/views/home_view.dart`.
2.  Locate and remove the `ListTile` for "Reminders" (currently disabled with "Coming soon" subtitle).

### 3.4 Documentation
1.  Update `CHANGELOG.md` (if applicable) or prepare the commit message to clearly state the removal of the reminder feature and the associated data drop.

## 4. Quality Requirements

- **Static Analysis**: Run `flutter analyze` and ensure zero issues.
- **Formatting**: Run `dart format --set-exit-if-changed lib test`.
- **Testing**:
    - **Migration Test**: Create a test case that uses a v4 database fixture (containing `Reminder` data) and verify that upgrading to v5 succeeds and other data is preserved.
    - **Regression**: Ensure all 667 existing tests still pass.
- **Coverage**: Maintain targets (Services/ViewModels ≥85%, Models/Utils ≥90%, Widgets ≥70%).

## 5. Branching & Commits

- **Branch**: `feature/remove-reminders`
- **Commit Message**: Follow conventional commits, e.g., `feat(database): remove reminder feature and migrate schema to v5`

---

**Status**: 🟢 **READY FOR IMPLEMENTATION**

Please proceed with the implementation. If you encounter any unexpected dependencies during the removal, stop and consult with Tracy or myself.

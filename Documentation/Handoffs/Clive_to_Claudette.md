# Handoff: Clive → Claudette

**Date:** December 31, 2025  
**From:** Clive (Reviewer)  
**To:** Claudette (Implementer)  
**Subject:** Phase 13 – Export/PDF Management, Sharing, and Automated Cleanup

---

## 1. Scope & Acceptance Criteria

Implement a comprehensive file management system for health data exports (JSON/CSV) and doctor reports (PDF).

### Acceptance Criteria:
- **File Management:** A new `FileManagerView` to list, share, and delete files in the app's documents directory.
- **Sharing:** Enable platform share sheets for JSON/CSV exports (matching existing PDF sharing).
- **Automated Cleanup:** Implement logic to prune old/excess files based on age (default 90 days) and count (default 50 per type).
- **UI Integration:** 
    - Update `ExportView` to show a "Share" button and "Manage Files" link after export.
    - Add a "File Manager" entry point in Settings/Main Menu.
- **Safety:** Mandatory confirmation dialogs for all deletion operations.
- **Quality:** 90%+ test coverage for new logic; zero analyzer issues; strict adherence to `Coding_Standards.md`.

---

## 2. Technical Architecture

Follow the MVVM pattern as outlined in Tracy's plan:

### Models
- `ManagedFile`: Metadata for files (path, name, size, date, type).
- `AutoCleanupPolicy`: Configuration for cleanup thresholds.

### Services
- `FileManagerService`: 
    - Scan `getApplicationDocumentsDirectory()` for `bp_export_*` and `bp_report_*`.
    - Handle file deletion and bulk cleanup logic.
    - Calculate total storage usage.
- `ExportService` (Update): Add `shareExport(File file)` using `share_plus`.

### ViewModels
- `FileManagerViewModel`: Manage state for the file list, loading, and cleanup actions.
- `ExportViewModel` (Update): Support sharing the last generated export.

### Views
- `FileManagerView`: Grouped list of files with metadata and actions (Share/Delete).
- `ExportView` (Update): Post-export UX improvements.

---

## 3. Implementation Details & Defaults

- **Auto-Cleanup Defaults:** 
    - Age: 90 days.
    - Count: 50 files per type.
    - Enabled by default: Yes (provide a toggle in the File Manager).
- **Sharing Text:** Use "Sensitive health data – Blood Pressure Export" in the share sheet.
- **Error Handling:** Gracefully handle missing files (e.g., if deleted via OS) and I/O errors.
- **Performance:** Ensure directory scanning and cleanup are non-blocking (async).

---

## 4. Reviewer's Focus Points

- **Typing:** No `any` or `dynamic` where specific types can be used.
- **Documentation:** JSDoc/DartDoc for all new public methods in services and viewmodels.
- **Tests:** 
    - Unit tests for `FileManagerService` (mocking `FileSystem`).
    - ViewModel tests for state transitions.
    - Widget tests for the new `FileManagerView` and updated `ExportView`.
- **Security:** Verify that files are never moved to public/external storage without explicit user share action.

---

## 5. Reference Documents
- [Tracy's Plan](../Handoffs/Tracy_to_Clive.md)
- [Coding Standards](../Standards/Coding_Standards.md)

---

**Status:** APPROVED FOR IMPLEMENTATION  
**Implementer:** Claudette  
**Branch:** `feature/export-file-management`

Please proceed with implementation. Reach out to Steve if you encounter blockers.

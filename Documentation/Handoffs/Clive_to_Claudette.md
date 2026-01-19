# Review: Phase 26 — Export Modernization (Part 1) - Revised with Scope Change

**Reviewer:** Clive (Lead Reviewer)  
**Date:** January 15, 2026  
**Status:** ❌ **BLOCKERS REMAIN & NEW SCOPE CHANGE**

---

## Summary of Scope Change
The user has confirmed that **backwards compatibility for CSV import can be removed**. This simplifies the modernization effort by allowing the application to transition to a JSON-only import/export architecture.

---

## Scope vs. Acceptance Criteria

| Criteria | Status | Notes |
|----------|--------|-------|
| Indented JSON Export | ✅ PASS | Implemented in `ExportService`. |
| CSV Export Removal | ✅ PASS | UI and ViewModel paths removed. |
| CSV Import Removal | 🆕 PENDING | **New Task**: Systematically remove all CSV import logic. |
| Result Pattern (§5.2) | ⚠️ PARTIAL | Pattern exists but `AppError` needs alignment with §5.3. |
| Code Quality | ⚠️ PARTIAL | Build is clean, but missing coverage for new logic. |
| Test Coverage (≥80%) | ❌ FAIL | `ExportViewModel` has 0% coverage. |

---

## Findings & Required Actions

### 🔴 NEW TASK: Remove CSV Import Functionality
- **Logic Removal**: Delete `importFromCsv` and its helpers from [lib/services/import_service.dart](lib/services/import_service.dart).
- **ViewModel Update**: Update [lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart) to remove CSV file extension support and CSV-specific branches.
- **UI Update**: Update [lib/views/import_view.dart](lib/views/import_view.dart) to only allow `.json` file selection.
- **Documentation Update**: Remove CSV sections from [Documentation/ImportFormat.md](Documentation/ImportFormat.md).
- **Cleanup**: Delete CSV-related import tests in [test/services/import_service_test.dart](test/services/import_service_test.dart).

### 🔴 Blocker: Insufficient Test Coverage (Standard §3.2)
- **File:** [lib/viewmodels/export_viewmodel.dart](lib/viewmodels/export_viewmodel.dart)
- **Issue:** Modernized `ExportViewModel` has **0% coverage**.
- **Requirement:** Create `test/viewmodels/export_viewmodel_test.dart` to reach ≥80% coverage.

### 🟡 Medium: AppError Specification Deviation (Standard §5.3)
- **File:** [lib/models/result.dart](lib/models/result.dart)
- **Requirement:**
  - Add `userMessage` getter to `AppError` mapping `AppErrorType` to friendly strings.
  - Rename/ensure `debugInfo` availability.
  - Display `userMessage` in [lib/views/export_view.dart](lib/views/export_view.dart).

### 🔵 Minor: Missing JSDoc (Standard §3.1)
- **Requirement:** Add doc comments to all public members in `ExportViewModel`.

---

## Next Steps for Claudette

1.  **Remove CSV Import**: Purge all remaining CSV logic from the codebase.
2.  **ViewModel Tests**: Achieve ≥80% coverage for `ExportViewModel`.
3.  **AppError Alignment**: Refactor `AppError` and update UI to use `userMessage`.
4.  **Verification**: Ensure `flutter analyze` and all tests pass.

**Clive's Note**: This scope change significantly simplifies Part 1. Ensure all residue of the `csv` package and CSV-related logic is removed.

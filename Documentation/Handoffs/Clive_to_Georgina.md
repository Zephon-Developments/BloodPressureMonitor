# Review Feedback: Phase 10 - Export & Reports

**Reviewer:** Clive
**Date:** December 30, 2025
**Status:** **BLOCKERS REMAINING**

## Summary
The implementation of Phase 10 provides the core UI and service structure, but several critical logic gaps and quality issues must be addressed before merge. Most notably, the "Overwrite" import mode is not implemented, and test coverage for the new services is insufficient.

## Findings

### 1. Blockers (Must be resolved)

#### 1.1 Missing Overwrite Logic in `ImportService`
- **File:** [lib/services/import_service.dart](lib/services/import_service.dart)
- **Issue:** The `conflictMode == ImportConflictMode.overwrite` logic is not implemented in `importFromJson` or `importFromCsv`.
- **Impact:** Users selecting "Overwrite" will have data appended without duplicate checking, leading to a corrupted state instead of a clean restoration.
- **Requirement:** Implement bulk deletion of existing data for the target profile before importing when `overwrite` is selected. You may need to add `deleteAllByProfile` methods to the respective services (`ReadingService`, `WeightService`, etc.).

#### 1.2 Insufficient Test Coverage
- **Files:** [test/services/export_service_test.dart](test/services/export_service_test.dart), `test/services/import_service_test.dart` (missing), `test/services/pdf_report_service_test.dart` (missing).
- **Issue:** The new services have almost no functional tests. `export_service_test.dart` only contains initialization stubs.
- **Impact:** High risk of regressions in parsing logic, file generation, and conflict resolution.
- **Requirement:** 
    - Add comprehensive unit tests for `ImportService` (JSON/CSV parsing, duplicate detection, conflict resolution).
    - Add functional tests for `ExportService` (verify JSON/CSV structure).
    - Add unit tests for `PdfReportService` (verify data aggregation for the report).

### 2. Minor Issues (Should be resolved)

#### 2.1 Static Analysis Warnings
- **File:** [test/views/home_view_test.dart](test/views/home_view_test.dart)
- **Issue:** Two `require_trailing_commas` info issues.
- **Requirement:** Fix these to achieve a completely clean `dart analyze` output.

#### 2.2 Hardcoded App Version
- **File:** [lib/services/export_service.dart](lib/services/export_service.dart)
- **Issue:** `appVersion` is hardcoded as `'1.1.0'`.
- **Requirement:** Use `package_info_plus` or a central configuration constant.

#### 2.3 Date Formatting in PDF
- **File:** [lib/services/pdf_report_service.dart](lib/services/pdf_report_service.dart)
- **Issue:** Uses `DateTime.now().toLocal().toString()` which is not user-friendly.
- **Requirement:** Use `DateFormat` from `lib/utils/date_formats.dart` for consistency.

## Next Steps
Georgina, please address the blockers above. Specifically, ensure the `overwrite` logic is fully functional and that we have at least 80% test coverage for the new services. Once fixed, please update the handoff for another review.

# Handoff: Clive → Georgina

**Date:** December 30, 2025  
**From:** Clive (Review Specialist)  
**To:** Georgina (Implementer)  
**Branch:** `feature/export-reports`  
**Context:** Phase 10 Code Review Fixes (PR #21)

---

## Objective

Implement the 6 fixes identified during the Phase 10 code review. These fixes address security vulnerabilities (CSV injection), stability issues (null pointer risks), and architectural debt (hardcoded profile IDs).

---

## Tasks

### 1. Profile State Management
- **Implement `ActiveProfileViewModel`**:
  - Create `lib/viewmodels/active_profile_viewmodel.dart`.
  - Manage `activeProfileId` and `activeProfileName`.
  - Persist selection in `SharedPreferences`.
  - Register in `MultiProvider` in `lib/main.dart`.
- **Refactor Views**:
  - Update `ExportView`, `ImportView`, and `ReportView` to consume `ActiveProfileViewModel`.
  - Remove all hardcoded `profileId: 1` and `profileName: 'User'` literals.

### 2. CSV Security (High Priority)
- **Implement Sanitization**:
  - Add `_sanitizeCsvCell(String?)` helper in `ExportService`.
  - Prefix values starting with `=`, `+`, `-`, or `@` with a single quote `'`.
  - Apply to all user-controlled text fields in CSV export (notes, tags, names, etc.).
- **Unit Tests**:
  - Add tests in `test/services/export_service_test.dart` specifically for formula injection cases.

### 3. Import UX Improvements
- **Update `ImportView`**:
  - Differentiate between Success, Partial Success (some errors), and Failure (all errors).
  - Display the list of errors from `ImportResult.errors` when applicable.
  - Use appropriate colors/icons for each state (Green/Yellow/Red).

### 4. Stability & Null Safety
- **Update `ReportView`**:
  - Add null checks for `_chartKey.currentContext` before attempting to capture the chart image.
  - Gracefully handle cases where the chart is not yet rendered (e.g., show a SnackBar or error message instead of crashing).

---

## Constraints & Standards

- **Coding Standards**: Adhere strictly to [Documentation/Standards/Coding_Standards.md](Documentation/Standards/Coding_Standards.md).
- **Testing**: Maintain or improve current test coverage. Ensure new logic is covered by unit or widget tests.
- **Analyzer**: Zero warnings or errors.
- **Branch**: Work on the existing `feature/export-reports` branch.

---

## Reference Materials

- **Fix Plan**: [Documentation/Handoffs/Tracy_to_Clive.md](Documentation/Handoffs/Tracy_to_Clive.md)
- **Review Summary**: [reviews/2025-12-30-clive-phase-10-fix-plan-review.md](reviews/2025-12-30-clive-phase-10-fix-plan-review.md)
- **Original PR**: [PR #21](https://github.com/Zephon-Development/BloodPressureMonitor/pull/21)

---

## Success Metrics

1. All 6 code review comments are addressed and verified.
2. CSV exports are safe from formula injection.
3. Multi-profile support is functional in export/import/report flows.
4. Import results are clear and accurate.
5. No runtime crashes during PDF generation.

---

**Next Action:** Georgina to implement the fixes as outlined.

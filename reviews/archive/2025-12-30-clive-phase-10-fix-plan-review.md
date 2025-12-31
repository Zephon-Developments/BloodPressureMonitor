# Review: Phase 10 Code Review Fix Plan

**Date:** December 30, 2025  
**Reviewer:** Clive (Review Specialist)  
**Status:** ✅ **APPROVED**  
**Plan Source:** [Documentation/Handoffs/Tracy_to_Clive.md](Documentation/Handoffs/Tracy_to_Clive.md)

---

## Scope & Acceptance Criteria

The plan addresses 6 critical findings from the Phase 10 code review:
1. **Hardcoded Profile IDs**: 4 occurrences in Import, Export, and Report views.
2. **Inconsistent Import Messaging**: Misleading "Success" on partial imports.
3. **Null Pointer Risk**: Unsafe `!` operator on `_chartKey.currentContext`.
4. **CSV Formula Injection**: Lack of sanitization for user-controlled text fields.

**Acceptance Criteria:**
- [ ] `ActiveProfileViewModel` implemented and used for all profile-dependent operations.
- [ ] Import UI correctly identifies and displays Success, Partial Success, and Failure states.
- [ ] PDF generation includes null-guards for chart capture with user-facing error handling.
- [ ] CSV export sanitizes all user-controlled strings (prefixing with `'` for risky characters).
- [ ] Unit tests for CSV sanitization and widget tests for import messaging.
- [ ] Zero analyzer warnings and all tests passing.

---

## Standards Compliance Check

| Standard | Status | Notes |
| :--- | :--- | :--- |
| **Security** | ✅ Pass | CSV sanitization directly addresses formula injection risks. |
| **Reliability** | ✅ Pass | Null-guards for chart capture prevent runtime crashes. |
| **State Management** | ✅ Pass | `ActiveProfileViewModel` follows the Provider pattern established in standards. |
| **Testing** | ✅ Pass | Plan includes unit, widget, and lifecycle tests. |
| **Documentation** | ✅ Pass | Plan includes DartDoc updates for new sanitization logic. |

---

## Findings & Feedback

### 1. Profile Management (Minor)
The plan to create `ActiveProfileViewModel` is excellent. Ensure that `loadInitial()` handles the case where no profiles exist by creating a default "User" profile via `ProfileService` to maintain app stability.

### 2. CSV Sanitization (Security)
The proposed `_sanitizeCsvCell` logic (prefixing with `'`) is the industry standard for mitigating CSV injection. Ensure this is applied to **all** string fields, including those that might seem "safe" (like units or categories), as these could be manipulated via import.

### 3. Import UX (Usability)
The differentiation between "Partial Success" and "Failure" is a significant improvement. Ensure the error list is scrollable if many errors occur during a large import.

---

## Conclusion

The plan is comprehensive, architecturally sound, and fully compliant with [Documentation/Standards/Coding_Standards.md](Documentation/Standards/Coding_Standards.md). No blockers identified.

**Proceed to implementation.**

---

**Handoff Target:** Georgina (Implementer)  
**Next Action:** Implement fixes on `feature/export-reports` branch.

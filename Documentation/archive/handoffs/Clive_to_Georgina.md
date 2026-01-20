# Handoff: Clive to Georgina — Phase 26 Implementation

**Author:** Clive (Review Specialist)
**Date:** January 20, 2026
**Subject:** Implementation of BP Chart Split, Med History Fixes, and Secure Import/Export
**Target Agent:** Georgina (Implementer)
**Status:** **APPROVED FOR IMPLEMENTATION**

---

## Context
Tracy has developed a comprehensive implementation plan for Phase 26, which resolves critical UX and data integrity issues. I have reviewed the plan against `Documentation/Standards/CODING_STANDARDS.md` and added specific requirements for documentation and test coverage.

## Core Objectives
1.  **BP Chart Revolution**: Split the current dual-axis chart into two stacked charts (Systolic/Diastolic) with synchronized X-axes and NICE guidelines colour bands. Fix the diastolic inversion.
2.  **Medication History Integrity**: Fix the sorting order (most recent first) and clean up the Medication card on the History page (remove averages/adherence).
3.  **Data Portability Safety**: Add profile metadata (Name, DOB, Patient ID, etc.) to JSON/CSV exports. Implement a name-mismatch warning during import to prevent accidental data overwrites to wrong profiles.

## Technical Guidance
- **Standards Compliance**: 
    - Ensure all new public APIs have `///` JSDoc (§10.1).
    - Maintain high test coverage: 90% for Models/Utils, 85% for ViewModels/Services, 70% for Widgets (§8.1).
    - Use the `Result` pattern for the new import verification logic (§5.2).
- **Constants**: Centralize NICE thresholds and colors in `lib/constants/clinical_constants.dart` instead of hardcoding in painters.
- **UI/UX**: The profile mismatch warning must be clear and offer a "Cancel" action as the default/safe choice.
- **Performance**: Monitor frame rates on the BP charts when rendering ~500 points; ensure `fl_chart` is utilized efficiently.

## Reference Materials
- **Implementation Plan**: [Documentation/Plans/Phase_26_Issues_Resolution_Plan.md](Documentation/Plans/Phase_26_Issues_Resolution_Plan.md)
- **Coding Standards**: [Documentation/Standards/CODING_STANDARDS.md](Documentation/Standards/CODING_STANDARDS.md)
- **Clinical Sources**: NICE Home Monitoring Guidelines for BP.

## Ready to Proceed
Georgina, you are green-lit to begin implementation. I recommend starting with the **Export/Import Metadata** and **Safety Warning** flow, as this establishes the data foundation, then moving to the **Medication History** fixes, and finally the **BP Chart** redesign.

Inform the user once you have established the new project branch and started the foundation work.

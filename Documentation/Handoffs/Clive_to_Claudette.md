# Handoff: Clive → Claudette

**Date**: January 1, 2026  
**Phase**: Phase 18 - Medication Grouping UI  
**Status**: Approved for Implementation

---

## 1. Objective
Implement the Medication Grouping UI and associated UX polish items as defined in the [Phase 18 Plan](../Plans/Phase_18_Medication_Grouping_UI_Plan.md).

## 2. Scope
- **Medication Groups**: Full UI for viewing, creating, editing, and deleting groups.
- **Group Logging**: Integration into `LogIntakeSheet` and `MedicationPickerDialog`.
- **Dosage Validation**: Numeric-only validation in `AddEditMedicationView`.
- **Unit Combo Box**: New `UnitComboBox` widget with predefined and custom units.
- **Search Polish**: Clear (X) buttons on all medication search bars.

## 3. Standards & Requirements
- **Coding Standards**: Strict adherence to [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md).
- **Typing**: No `any` types; strict Dart typing throughout.
- **Documentation**: DartDoc for all new public APIs, classes, and methods.
- **Test Coverage**: 
    - Models/Utils: ≥90%
    - Services/ViewModels: ≥85%
    - Widgets: ≥70%
- **Accessibility**: Semantic labels for all new buttons; WCAG AA contrast compliance.

## 4. Implementation Notes
- Leverage the existing `MedicationGroupService` and `MedicationGroupViewModel`.
- Ensure the `UnitComboBox` persists custom units for the session or profile.
- Use `flutter_slidable` for group deletion to maintain consistency with the History page.

## 5. Deliverables
- Implementation of all UI components and logic.
- Complete test suite (Unit, Widget, and Integration).
- `flutter analyze` and `dart format` compliance.

---
**Reviewer**: Clive (Review Specialist)  
**Assigned To**: Claudette (Implementation Agent)

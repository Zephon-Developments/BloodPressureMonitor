# Handoff: Clive → Claudette (Medication Intake Implementation)

**Date:** December 31, 2025  
**From:** Clive (Reviewer)  
**To:** Claudette (Implementation Specialist)  
**Status:** APPROVED

## Scope & Objectives
Implement the "Medication Intake Recording" feature as outlined in [Documentation/Plans/Medication_Intake_Plan.md](Documentation/Plans/Medication_Intake_Plan.md). The goal is to provide a clear and fast way for users to log medication intakes (single or grouped).

## Key Requirements
1.  **Medication List CTA**: Add a "Log intake" icon button to each medication tile in `MedicationListView`. This should open the existing `LogIntakeSheet`.
2.  **Group Logging**: Ensure the implementation supports logging multiple medications at once if they belong to a group (as per Decision 1 in the plan).
3.  **Home Quick Action**: Add a "Log Medication" quick action to the `HomeView` that allows users to pick a medication and log an intake.
4.  **Feedback & Refresh**: Show success/error snackbars after logging. Ensure `MedicationIntakeViewModel.loadIntakes()` is called to refresh history.
5.  **Timing Correlation**: Log the exact date/time taken. Do not prompt for missed/late status; rely on existing schedule metadata logic.

## Technical Constraints
-   **MVVM**: Follow the established Provider pattern.
-   **Coding Standards**: 
    -   Strictly follow [Documentation/Standards/Coding_Standards.md](Documentation/Standards/Coding_Standards.md).
    -   Maintain 80-character line limits.
    -   Use `const` constructors where possible.
    -   Organize imports correctly.
-   **Security**: All data must be persisted via the encrypted `DatabaseService`.
-   **Testing**: 
    -   Unit tests for `MedicationIntakeService` and `MedicationIntakeViewModel`.
    -   Widget tests for the new CTAs and the `LogIntakeSheet` flow.
    -   Maintain ≥80% coverage.

## Affected Files
-   `lib/views/medication/medication_list_view.dart`: Add log CTA to tiles.
-   `lib/views/home_view.dart`: Add quick action.
-   `lib/views/home/widgets/quick_actions.dart`: (If applicable) Add medication log action.
-   `lib/viewmodels/medication_intake_viewmodel.dart`: Ensure refresh logic is robust.
-   `test/`: Add corresponding unit and widget tests.

## Handoff Instructions
Claudette, please proceed with the implementation. Ensure you run `flutter analyze` and `flutter test` before submitting your changes. If you encounter any architectural blockers, consult with Tracy.

---
**Reviewer Note**: The plan is solid. Focus on the UX of the quick action to ensure it's truly "fast" for the user.

# Handoff: Clive to Claudette

## Context
Approval of Phase 24B (Units Preference) Implementation Plan.

## Status
**APPROVED**

## Scope
Implementation of app-wide units preference (kg/lbs) with mandatory SI-only storage normalization.

## Key Tasks (Refer to Phase_24B_Units_Preference_Spec.md for details)
1.  **Data Migration:** Implement a one-time, idempotent migration in `WeightService` to convert all existing `lbs` entries to `kg` and normalize the database schema/metadata.
2.  **Units Service:** Create `UnitsPreferenceService` (SharedPreferences) and `UnitsPreference` model.
3.  **Conversion Utils:** Implement robust `unit_conversion.dart` with full test coverage.
4.  **UI Updates:**
    *   Add global unit selection to Settings (Appearance or new Units view).
    *   Remove per-entry unit toggle from `AddWeightView`.
    *   Update all weight displays (History, Analytics) to respect the global preference.
5.  **Integration:** Ensure immediate UI updates upon preference change using `Provider`.

## Standards & Requirements
- **SI Storage Only:** All data persisted to the database MUST be in `kg`. No exceptions.
- **Test Coverage:** 
    - Services/Utils: ≥85%
    - Widgets: ≥70%
- **Documentation:** All new public classes and methods must have JSDoc.
- **Formatting:** Run `dart format` before submission.

## Reference Documents
- [Phase_24B_Units_Preference_Spec.md](../Plans/Phase_24B_Units_Preference_Spec.md)
- [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)

## Next Steps
1. Initialize the feature branch `feature/units-preference`.
2. Begin with the migration logic and tests as the foundation.
3. Proceed through the sequenced task breakdown in the spec.

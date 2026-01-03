# Handoff: Clive to Tracy

## Context
Review of Phase 24B (Units Preference) Implementation Plan.

## Status
**REJECTED / NEEDS REVISION**

## Findings

### 1. Storage Model Conflict (Blocker)
- **Current State:** `WeightEntry` in `lib/models/health_data.dart` stores a `WeightUnit`. `WeightService` persists this unit to the database.
- **Requirement:** Steve's directive: "All data stored internally in SI units (kg, °C) — never convert storage layer."
- **Spec Issue:** Your spec says "No migration expected." This is incorrect if we are to move to SI-only storage.
- **Action:** Update the spec to include a migration path (converting existing `lbs` entries to `kg`) or provide a technical justification for maintaining the current per-entry unit storage.

### 2. UI Consistency
- **Current State:** `AddWeightView` has a per-entry unit toggle.
- **Action:** Explicitly include the removal of this toggle in the "UI Changes" section of the spec.

### 3. Service Consolidation
- **Observation:** We already have `ThemePersistenceService` and `ThemeViewModel`.
- **Recommendation:** Consider if `SettingsService` should eventually absorb `ThemePersistenceService` to avoid fragmented preference management, or confirm they should remain separate.

## Next Steps
1. Revise `Phase_24B_Units_Preference_Spec.md` to address the storage migration.
2. Update the UI section to reflect the removal of per-entry unit selection.
3. Hand back to Clive for final approval.

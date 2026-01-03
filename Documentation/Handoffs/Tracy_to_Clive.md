# Handoff: Tracy → Clive
## Phase 24B Units Preference – Revised Spec (Migration Included)

**Date:** 2026-01-02  
**From:** Tracy (Planning & Architecture)  
**To:** Clive (QA & Review Lead)

---

## Deliverables
- **Updated spec:** [Documentation/Plans/Phase_24B_Units_Preference_Spec.md](../Plans/Phase_24B_Units_Preference_Spec.md)
	- Added mandatory migration to normalize all stored weights to kg and stop relying on per-entry units.
	- Added removal of per-entry unit toggle in weight entry UI; preference drives input/display.
	- Expanded task breakdown to start with migration, then model → utils → service → viewmodel → settings UI → weight IO → charts/history → docs.
	- Updated success metrics, constraints, edge cases, and data considerations to reflect SI-only storage and migration.
	- Open decision: whether to keep `ThemePersistenceService` standalone or unify under a broader settings service (non-blocking for migration).

## Review Focus
1. **Migration plan:** One-time lbs→kg conversion, unit metadata normalized (set to kg or drop column), idempotent and logged.
2. **Storage convention:** Post-migration, storage is kg-only; conversions happen only at UI boundaries.
3. **UI changes:** Remove per-entry unit toggle; settings selector applies globally with immediate effect; temperature selector remains disabled but future-ready.
4. **Coverage/standards:** Per CODING_STANDARDS (§2 formatting, §3 patterns, §8 coverage: services ≥85%, widgets ≥70%).
5. **Provider wiring:** Confirm approach for exposing UnitsPreference to weight/history/chart viewmodels; ensure no duplicate preference services.

## Next Steps
- Please review the updated spec and confirm the migration approach and UI removal scope.
- After approval, Claudette can implement per the revised sequence and tests.

---

**Tracy**
Planning & Architecture

# Handoff: Tracy to Clive
## Phase 2B Plan – Revised per Feedback
**Context**: Phase 2A (Averaging Engine) is merged. Phase 2B covers validation bounds and ViewModel integration. This revision addresses your four blockers.

### What Changed
- **Behavioral definitions**: `ValidationLevel.error` = hard block (no persistence). `ValidationLevel.warning` = soft block requiring explicit user confirmation. `ValidationLevel.valid` = proceed.
- **Explicit ranges**: Added clear mappings for each metric and the systolic/diastolic relationship (systolic < diastolic → error; systolic == diastolic → warning). See plan for full table.
- **ViewModel contract**: `addReading` now returns `ValidationResult` and stores `_lastValidation` for the UI to read; warnings short-circuit until `confirmOverride=true` is supplied. Errors never persist.
- **Docs updated**: Plan text reflects override semantics, UI feedback channel, and range tables.

### Current Plan Snapshot
- Validation API: `ValidationResult` with `requiresConfirmation` true for warnings; errors block. Ranges: sys <70 error, 70–89 warn, 90–180 valid, 181–250 warn, >250 error; dia <40 error, 40–59 warn, 60–100 valid, 101–150 warn, >150 error; pulse <30 error, 30–59 warn, 60–100 valid, 101–200 warn, >200 error; relationship rule as above.
- ViewModel: validate → (block on error/warn without override) → persist → averaging recompute → reload. Returns `ValidationResult` and exposes `lastValidation` for UI dialogs.
- Provider wiring and tests remain as previously outlined (validators ≥90% coverage; viewmodel ≥85%).

### Open Items for Approval
- Confirm best-effort recompute (persist first, averaging may fail separately) remains acceptable to avoid data loss.
- Confirm UI handshake is sufficient: ViewModel returns `ValidationResult` + `lastValidation` getter; UI shows blocker dialog on error and confirm dialog on warning.

### References
- Plan: [Documentation/Plans/Phase-2B-Validation-Integration.md](../Plans/Phase-2B-Validation-Integration.md)
- Coding standards: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)

### Next Step
Please review and, if acceptable, approve so we can proceed with implementation (recommend assigning Claudette).

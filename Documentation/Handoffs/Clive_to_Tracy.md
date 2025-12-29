# Clive to Tracy: Phase 2B Plan Revision Request

**Date:** December 29, 2025  
**Status:** Awaiting Revision  
**Original Plan:** Phase-2B-Validation-Integration.md

Tracy,

The Phase 2B plan is well-structured but contains blockers that must be resolved before implementation can proceed.

Please revise the plan to explicitly address the following:

1. **ValidationLevel Behavioral Definitions**
   - Clearly state: `ValidationLevel.error` = hard block (prevents persistence entirely).
   - `ValidationLevel.warning` = soft block (allows persistence only if user confirms override).

2. **Explicit Range Mappings**
   Add a clear table or list for each reading type:
   - Systolic, Diastolic, Pulse → exact numeric ranges mapped to `valid`, `warning`, or `error`.
   Example for Systolic:
   - < 70 → error
   - 70–89 → warning
   - 90–180 → valid
   - 181–250 → warning
   - > 250 → error

3. **ViewModel API Contract**
   Update the proposed `addReading` flow to specify how the UI receives feedback:
   - Recommend returning a `ValidationResult` enum/object from `addReading` (or exposing a stream/property) so the UI can distinguish between hard errors (show blocker) and warnings (show confirmation dialog).

4. **Systolic vs Diastolic Relationship**
   Explicitly define: if systolic == diastolic → trigger `warning` (clinically rare and potentially critical).

Once these are incorporated, the plan will be solid for implementation.

After revision, notify me for final approval.

— Clive
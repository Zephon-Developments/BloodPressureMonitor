# Handoff: Tracy to Clive — Phase 9 Edit/Delete Plan

**Date:** 2025-12-30  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Plan:** Documentation/Plans/Phase_9_Edit_Delete_Plan.md

## Summary
- Objective: Add UI support to edit and delete blood pressure readings, weight entries, and sleep entries, with confirmations and proper cache/averaging refresh. 
- Backend services already support update/delete for these data types; UI and some ViewModels lack hooks. 
- Proposed two-phase rollout: **Phase 9A (MVP)** for core edit/delete flows and **Phase 9B** for history polish (grouped edits, optional swipe, detail sheets).

## Key Points
- ViewModels to extend: add update/delete to WeightViewModel and SleepViewModel; ensure averaging recompute + analytics cache invalidation after BP/sleep edits/deletes. 
- Edit UX: reuse existing add forms via `editingEntry` to prefill and submit updates (Option A recommended). 
- Delete UX: reusable ConfirmDeleteDialog; actions via popup menus; SnackBar feedback; confirmation mandatory. 
- History entry points: minimally add Edit/Delete to raw items; Phase 9B adds grouped member actions and optional swipe.

## Risks / Mitigations
- Averaging drift after edits → recompute in ViewModel; tests covering timestamp changes. 
- Analytics staleness → explicit cache invalidation hook; add integration test. 
- UI duplication → reuse forms (Option A). 
- Accidental deletes → confirmation dialog; consider future soft delete if requested.

## Decisions / Updates
- Option A approved: reuse add forms with `editingEntry` to prefill and submit updates (no separate edit screens).
- UX: On the home reading list, tapping the chevron (`>`) opens edit; swipe left reveals a `DELETE` button (white text on red). Tapping delete shows confirmation before removal. Menus remain acceptable where swipe is not available (e.g., history lists).

## Open Questions
1) Hard delete vs soft delete for readings/weight/sleep? (Recommend hard delete; meds already soft).  
2) Auto-invalidate analytics cache on any reading/sleep edit/delete? (Recommend yes; weight optional).  
3) Scope swipe-to-delete in history: include in 9A or defer to 9B polish? (Plan marks history swipe as optional; home swipe is required.)

## Success Criteria
- Edit and delete available for BP/Weight/Sleep with confirmations. 
- Analyzer clean; `dart format` clean. 
- Tests added (unit + widget) with ≥85% coverage for touched areas; full suite stays green. 
- Averages/analytics reflect edits/deletes (cache invalidation verified).

## Artifacts
- Plan: Documentation/Plans/Phase_9_Edit_Delete_Plan.md
- Source handoff: Documentation/Handoffs/Steve_to_Tracy.md

Ready for your review and approval guidance on the open questions.


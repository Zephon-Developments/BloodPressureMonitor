# Phase 9: Edit & Delete Capabilities

**Author:** Tracy (Planning)  
**Date:** 2025-12-30  
**Related Handoff:** Documentation/Handoffs/Steve_to_Tracy.md  
**Targets:** Blood Pressure Readings, Weight Entries, Sleep Entries  
**Out of Scope for this phase:** Medication intake editing, profile deletion, bulk delete, undo/history

## Objectives
- Expose edit and delete flows in the UI for readings, weight, and sleep data. 
- Ensure averaging/analytics refresh correctly after data changes. 
- Maintain compliance with Coding Standards (see Documentation/Standards/Coding_Standards.md): analyzer clean, `dart format`, tests ≥85% coverage for new/changed ViewModels and widgets.

## Scope
- Edit existing: Blood Pressure readings, Weight entries, Sleep entries. 
- Delete with confirmation: same three data types. 
- History view actions to reach edit/delete. 
- Cache/derivation refresh: averaging, analytics cache invalidation. 

## Non-Goals
- Medication intake edit (complex grouping). 
- Profile deletion. 
- Bulk delete or undo/audit trail. 
- Export/Report features (separate phase).

## Architecture & Data Flow
- **Services (already support):** `ReadingService.update/delete`, `WeightService.update/delete`, `SleepService.update/delete`. No schema change required. 
- **ViewModels:** Add update/delete to `WeightViewModel`, `SleepViewModel`; ensure `BloodPressureViewModel` uses averaging service after edits; add analytics cache invalidation hook (call into `AnalyticsViewModel.invalidateCache()` from UI when edits/deletes occur). 
- **UI composition (Option A approved):** Reuse existing add forms via an `editingEntry`/`editingId` param and initial data to prefill; avoid duplicate edit screens. 
- **Navigation:** `Navigator.push` to edit screen with the model; on success `Navigator.pop(context, true)` to signal refresh. 
- **Delete flow:** `ConfirmDeleteDialog` reusable widget; on confirm call ViewModel delete; show SnackBar; refresh lists; support swipe-to-delete affordance per UX below.

## Detailed Plan

### Phase 9A (MVP: Core Edit/Delete)
1. **ViewModel extensions**  
   - Weight: `updateWeightEntry`, `deleteWeightEntry`, loading/error flags.  
   - Sleep: `updateSleepEntry`, `deleteSleepEntry`, loading/error flags.  
   - Add unit tests ≥85% for new methods and error paths.

2. **Edit views (reuse add forms) — Option A**  
   - Add optional `editingEntry` (or `editingId`) param to `AddReadingView`, `AddWeightView`, `AddSleepView`.  
   - Pre-fill controllers from the entry.  
   - Submit invokes update method; preserve validation/override flows.  
   - Distinguish title/CTA text (e.g., "Update Reading").  
   - Widget tests: prefill, validation, successful submit, error surface.

3. **Delete UX (includes swipe)**  
   - Create `ConfirmDeleteDialog` (title, message, cancel/delete buttons; destructive styling).  
   - Primary affordances:
     - Reading list on Home: tap the chevron (`>`) to edit the reading.
     - Swipe left to reveal a `DELETE` button (white text on red background); tap triggers confirm dialog, then delete.
   - Other surfaces: trailing `PopupMenuButton` with Edit/Delete remains acceptable where swipe is not present (e.g., history lists).  
   - SnackBar feedback success/error; disable buttons during in-flight ops.  
   - Tests: dialog renders, confirm triggers delete, swipe-to-reveal shows the delete button, error path shows message.

4. **Refresh + cache invalidation**  
   - After BP edit/delete: trigger averaging recompute (already in `BloodPressureViewModel`), then invalidate analytics cache if `AnalyticsViewModel` present.  
   - After Weight/Sleep edit/delete: refresh respective lists; if analytics overlay depends on sleep, also invalidate analytics cache.  

5. **History view entry points (minimal)**  
   - In `HistoryView` raw mode items: add menu with Edit/Delete → navigate to edit view / show confirm delete.  
   - Swipe-to-delete optional in history; if added, mirror the white-on-red button and still require confirmation.  
   - After actions, refresh history data; keep paging state consistent (re-fetch page 1).  

### Phase 9B (Polish & Interaction)
- Grouped history: allow expand → member-level edit/delete; ensure averaging recompute and list refresh.  
- Optional swipe-to-delete in history (if not completed in 9A) with white-on-red button and confirmation.  
- Optional detail bottom sheet with Edit/Delete actions.  
- UI polish and empty/error states.

## Success Criteria
- Edit & delete available for BP, Weight, Sleep entries from at least one primary surface (History/raw or detail). 
- Delete is always confirmed; errors surfaced; success toasts/SnackBars. 
- Analyzer clean; `dart format` clean. 
- Tests: new ViewModel + widget tests added, coverage ≥85% for touched areas; existing suite remains green. 
- Averages and analytics reflect changes after edits/deletes (cache invalidation working). 

## Risks & Mitigations
- **Averaging drift after edits:** Mitigate by calling recompute in ViewModel; add tests covering timestamp changes. 
- **Analytics staleness:** Add explicit cache invalidation hook and integration test for edited reading updating stats. 
- **UI duplication:** Reuse forms via `editingEntry` to avoid separate edit screens. 
- **User error/deletes:** Confirmation dialog; consider future soft-delete if requested. 

## Testing Strategy
- **Unit:** ViewModels update/delete (success, error, loading flags), averaging recompute invoked.  
- **Widget:** Edit forms prefill and submit, delete dialog confirm/cancel, SnackBar messages.  
- **Integration (widget-level):** History entry → edit → verify updated values displayed; delete → item removed.  
- **Regression:** Run full `flutter test`; ensure analyzer clean.

## Open Questions (for Clive/User)
1. Approve **Option A** (reuse add views with `editingEntry`) vs separate edit screens? (Recommend A) 
2. Hard delete vs introduce soft delete for readings/weight/sleep? (Recommend hard delete for now; meds already soft-delete). 
3. Enable swipe-to-delete or stick to explicit menu actions? (Recommend explicit + optional swipe in Phase 9B). 
4. Should analytics cache be auto-invalidated on any data edit/delete? (Recommend yes for readings and sleep; weight optional).

## Estimated Timeline
- Phase 9A: ~2–3 days (dev + tests). 
- Phase 9B: ~2 days (polish/history grouping/swipe + tests). 

## Dependencies
- None on backend/schema; services already support update/delete. 
- Requires adherence to Coding Standards and test coverage policy. 

## Rollback
- Feature-flag UI entry points if instability arises; services unchanged.

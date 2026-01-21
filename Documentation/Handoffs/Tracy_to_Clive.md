# Tracy → Clive Handoff: Conditional Background Lock Plan

## Objective
Implement conditional background locking so the app **does not lock** when the user backgrounds the app from import/export screens, while keeping idle-timeout behavior unchanged and preserving security defaults elsewhere.

## Scope
- **In-scope:** Background lock gating based on current screen; import/export screens exempt. Idle timeout unchanged. Unit/widget test updates for lock logic.
- **Out-of-scope:** UI/UX changes, new navigation flows, changes to idle timeout configuration, privacy overlay behavior.

## Constraints & Standards
- **Security First** (Coding Standards §1.1): Default to locking unless explicitly exempted; avoid widening exemptions.
- **Separation of Concerns** (CS §4.2): Lock policy stays in ViewModel/service, not in views beyond signaling intent.
- **Naming & Clarity** (CS §3.1): Clear method/flag names, avoid ambiguity (e.g., `allowBackgroundLock`).
- **Testability** (CS §1.1, §5.1): Add unit/widget tests covering new branches; keep logic deterministic.

## Chosen Approach (Option A: Explicit View Signals)
Minimal, explicit, low-risk: views that require exemption (Import/Export) signal the `LockViewModel` to disable background lock while mounted, re-enabling on dispose. `LockViewModel` consults this flag before locking on lifecycle changes. Idle timeout flow untouched.

## Architecture & Data Flow
- **Flag storage:** `LockViewModel` holds `bool _allowBackgroundLock = true;` with setter `setBackgroundLockAllowed(bool)`.
- **Lifecycle handling:** `LockViewModel.didChangeAppLifecycleState` (delegating to `IdleTimerService`) checks the flag before invoking `lock()` when state is backgrounded.
- **View hooks:** `ImportView` and `ExportView` set `setBackgroundLockAllowed(false)` in `initState` (or `didChangeDependencies` for Stateless via `WidgetsBinding.instance.addPostFrameCallback`) and restore `true` in `dispose`/`deactivate`.
- **Default behavior:** All other screens keep default `true`, so background lock continues everywhere else. Idle timeout remains global via existing `Listener` in `MaterialApp.builder`.

## Files to Modify
- [lib/viewmodels/lock_viewmodel.dart](lib/viewmodels/lock_viewmodel.dart): Add flag, setter, and guard in lifecycle/background lock path.
- [lib/services/idle_timer_service.dart](lib/services/idle_timer_service.dart): Optionally accept allow-lock override from ViewModel or expose a hook; simplest is ViewModel guard before calling service lock.
- [lib/views/import_view.dart](lib/views/import_view.dart): Signal disable/enable around lifecycle.
- [lib/views/export_view.dart](lib/views/export_view.dart): Same signaling.
- [lib/main.dart](lib/main.dart): Verify no changes needed to idle tracking; if desired, expose helper to future-proof route-based exemptions (comment/doc only).
- Tests: [test/viewmodels/lock_viewmodel_test.dart](test/viewmodels/lock_viewmodel_test.dart), possible light widget test for import/export integration if needed.

## Step-by-Step Plan
1. **Add flag to LockViewModel**
   - Private `_allowBackgroundLock = true;` with public `setBackgroundLockAllowed(bool allowed)`; notifyListeners only if value changes.
   - Update `didChangeAppLifecycleState` / background-lock path to no-op if `!_allowBackgroundLock` and state is backgrounded; still stop monitoring to avoid leaks if appropriate.
2. **Guard lifecycle-triggered lock**
   - Before invoking `_idleTimerService.handleLifecycleChange(state)` (or inside lock callback), check `allowBackgroundLock` so background lock is skipped when false. Keep idle-timeout timer behavior intact.
3. **Wire Import/Export views**
   - On mount, call `context.read<LockViewModel>().setBackgroundLockAllowed(false);`
   - On dispose (or using `deactivate` safeguard), call `...setBackgroundLockAllowed(true);`
   - Add concise comment noting security rationale.
4. **Testing**
   - Add unit test: when `allowBackgroundLock` is false, `didChangeAppLifecycleState(paused)` does not set `state.isLocked`.
   - Add unit test: when `allowBackgroundLock` is true, `didChangeAppLifecycleState(paused)` locks.
   - (Optional) Widget test: pump ImportView, simulate lifecycle pause via ViewModel call, assert remains unlocked; when popped (flag restored), pause locks.
5. **Docs & guards**
   - Inline doc in `LockViewModel` about default-true policy and limited exemptions.
   - (Optional) TODO note for future route-based observer if exemptions expand.

## Acceptance Criteria
- Backgrounding on Import/Export does **not** trigger lock; other screens still lock on background.
- Idle timeout continues to function on all screens (existing behavior unchanged).
- Default behavior remains locked-on-background for all non-exempt screens.
- New tests cover allow/deny paths; all existing tests still pass.
- No analyzer warnings; code follows CS §3.1 naming and CS §4.2 separation.

## Risks & Mitigations
- **Risk:** Forgetting to re-enable lock on dispose → lock disabled afterward. *Mitigation:* Always reset to true in dispose/deactivate; add test.
- **Risk:** Future screens needing exemption might be missed. *Mitigation:* Add inline doc/TODO; consider route-observer refactor later if exemptions grow.
- **Risk:** Idle timer stop on background could be skipped if guard is too broad. *Mitigation:* Ensure monitoring stop still occurs even when skipping lock.

## Open Questions
- Are there any other flows (e.g., backup/restore, report share) that should also be exempt? If yes, add them now.
- Should exemption also apply when a share sheet is open from ExportView (likely yes, covered by view-mounted flag)?

## Effort & Sequencing
- Effort: Small (≈1 dev day including tests).
- Sequence: ViewModel flag → lifecycle guard → wire Import/Export → tests → sanity run (`flutter test`, analyzer).

## Handoff
Please review the plan and confirm scope (only Import/Export exempt) and the chosen explicit-flag approach. Once approved, implementation can proceed.

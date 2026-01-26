# Steve → Tracy Handoff: Conditional Lock Screen Behavior

## Date
January 21, 2026

## Context
User has reported that the application's lock screen behavior needs to be refined based on the current screen context. Currently, the app locks unconditionally in two scenarios:
1. When the idle timeout expires without user interaction
2. When the user swaps to another application (app lifecycle becomes paused/inactive)

## Problem Statement
The current implementation in [IdleTimerService.handleLifecycleChange()](lib/services/idle_timer_service.dart#L62-L76) **unconditionally** locks the app whenever it goes into the background, regardless of which screen the user is on. However, the requirement is:

- **Lock on background**: YES for most screens (home, history, analytics, settings, etc.)
- **Lock on background**: NO when user is on import/export screens

The exception for import/export screens is necessary because users may need to switch to another app to:
- Locate a file to import
- Share an exported file via email/messaging
- Access cloud storage for import/export operations
- Use a file manager while performing import/export tasks

## Current Implementation Analysis

### Key Files
1. **[IdleTimerService](lib/services/idle_timer_service.dart)**: 
   - Line 62-76: `handleLifecycleChange()` method that triggers `_onIdleTimeout()` (which calls `LockViewModel.lock()`) on paused/inactive/detached/hidden states
   - No conditional logic based on current route/screen

2. **[LockViewModel](lib/viewmodels/lock_viewmodel.dart)**:
   - Line 43-45: `didChangeAppLifecycleState()` delegates to `_idleTimerService.handleLifecycleChange()`
   - Line 122-131: `lock()` method that sets `isLocked = true`

3. **[MaterialApp.builder](lib/main.dart)**:
   - Line 270-276: Global `Listener` that calls `lockViewModel.recordActivity()` for pointer events
   - This handles idle timeout (scenario #1) but does not address background locking (scenario #2)

4. **[_LockGateState](lib/main.dart)**:
   - Line 299-341: `WidgetsBindingObserver` that handles privacy screen but delegates locking to `LockViewModel`
   - Line 345: `didChangeAppLifecycleState()` only manages privacy screen overlay, not actual locking

### The Issue
- `IdleTimerService` has no awareness of which route/screen is currently active
- It unconditionally locks on all background events
- Import/Export screens are at:
  - [ExportView](lib/views/export_view.dart) 
  - [ImportView](lib/views/import_view.dart)

## Requirements for Tracy

### Objective
Design a solution that allows `IdleTimerService` or `LockViewModel` to conditionally lock based on the current active route, specifically:
- **Enable** background locking for all screens EXCEPT import/export
- **Disable** background locking when on [ExportView](lib/views/export_view.dart) or [ImportView](lib/views/import_view.dart)
- **Maintain** idle timeout behavior (scenario #1) across all screens without changes

### Design Constraints
1. **Adhere to CODING_STANDARDS.md**: 
   - Single Responsibility Principle: Services should not manage UI state directly
   - Maintain separation of concerns between services and viewmodels
   - Follow existing patterns in the codebase

2. **Minimal Changes**:
   - Prefer solution that requires minimal modification to existing tests
   - Avoid breaking changes to public APIs
   - Maintain backward compatibility with current lock behavior for non-import/export screens

3. **Route Awareness**:
   - Need mechanism to track current route/screen
   - Should work with Flutter's Navigator and routing system
   - Consider that import/export screens are pushed via `Navigator.push()` from [HomeView](lib/views/home_view.dart)

### Suggested Approaches (for Tracy to evaluate)

#### Option A: Route-Based Flag in LockViewModel
- Add `setAllowBackgroundLock(bool)` method to `LockViewModel`
- Import/Export views call this in `initState()` / `dispose()`
- Modify `handleLifecycleChange()` to check this flag before locking
- **Pros**: Simple, minimal changes
- **Cons**: Requires views to manage lock policy, could be forgotten

#### Option B: NavigatorObserver Pattern
- Create a custom `NavigatorObserver` that tracks current route
- Register observer in `MaterialApp`
- `IdleTimerService` or `LockViewModel` checks current route before locking
- **Pros**: Centralized, automatic, follows Flutter patterns
- **Cons**: More complex, requires route name constants

#### Option C: Context-Aware Lock Policy
- Create a `LockPolicy` interface with `shouldLockOnBackground(Route)` method
- Default policy locks all screens except import/export
- `IdleTimerService` consults policy before locking
- **Pros**: Extensible, testable, follows SOLID principles
- **Cons**: Most complex, may be over-engineering

### Deliverable
Tracy should produce a detailed plan document that:
1. **Selects** one of the above approaches (or proposes an alternative)
2. **Justifies** the selection based on CODING_STANDARDS.md and project patterns
3. **Lists** all files to be modified with specific changes
4. **Defines** acceptance criteria and test cases
5. **Estimates** implementation effort and risk level
6. **Identifies** any potential edge cases or breaking changes

### Files for Tracy to Review
- [Documentation/Standards/CODING_STANDARDS.md](Documentation/Standards/CODING_STANDARDS.md)
- [lib/services/idle_timer_service.dart](lib/services/idle_timer_service.dart)
- [lib/viewmodels/lock_viewmodel.dart](lib/viewmodels/lock_viewmodel.dart)
- [lib/views/export_view.dart](lib/views/export_view.dart)
- [lib/views/import_view.dart](lib/views/import_view.dart)
- [lib/main.dart](lib/main.dart)
- [test/services/idle_timer_service_test.dart](test/services/idle_timer_service_test.dart)
- [test/viewmodels/lock_viewmodel_test.dart](test/viewmodels/lock_viewmodel_test.dart)

### Success Metrics
- App locks on background for all screens EXCEPT import/export
- Idle timeout continues to work on ALL screens (including import/export)
- All existing tests pass (777 tests currently passing)
- New tests added for conditional locking behavior
- No analyzer warnings or errors
- Implementation follows CODING_STANDARDS.md §3.1, §4.2, §5.1

## Idle Timeout Validation ✅

### Current Implementation Status
The idle timeout mechanism (scenario #1) is **correctly implemented** and works across all screens:

#### Global Coverage
- **[MaterialApp.builder](lib/main.dart#L271-L276)**: Wraps the entire app with a `Listener` widget that captures:
  - `onPointerDown`: All tap/touch events
  - `onPointerMove`: All scroll/drag events
- This Listener calls `lockViewModel.recordActivity()` which resets the idle timer
- Coverage includes:
  - All navigated routes (via `Navigator.push`)
  - All modal dialogs (via `showDialog`)
  - All bottom sheets (via `showModalBottomSheet`)
  - All overlays and popups

#### Timer Lifecycle
- **Started**: When user successfully unlocks (`unlockWithPin`, `unlockWithBiometric`)
- **Reset**: On any pointer interaction (taps, scrolls) via global Listener
- **Stopped**: When app locks or goes to background
- **Triggered**: After configured timeout period (default 2 minutes)

#### Test Coverage
Existing tests validate idle timeout behavior:
- [idle_timer_service_test.dart](test/services/idle_timer_service_test.dart):
  - ✅ Timer starts monitoring when unlocked
  - ✅ Activity resets the timer (line 81-95)
  - ✅ Timeout triggers lock after configured duration (line 97-121)
  - ✅ Timer stops when app is backgrounded
- [lock_viewmodel_test.dart](test/viewmodels/lock_viewmodel_test.dart):
  - ✅ `recordActivity()` delegates to IdleTimerService (line 407-412)
  - ✅ Idle monitoring starts on successful unlock (line 95, 116)
  - ✅ Idle monitoring stops when locked

### Conclusion
**No changes needed for idle timeout behavior.** The existing global Listener in MaterialApp.builder ensures that user activity on ANY screen (including import/export) will reset the idle timer. The only issue is the **background locking behavior** (scenario #2), which is addressed in this handoff.

---

## Next Steps
1. Tracy reviews the context and files
2. Tracy produces a detailed implementation plan
3. Steve reviews plan for alignment with requirements
4. Plan handed to Clive for technical review
5. Upon approval, plan handed to appropriate implementer (Claudette or Georgina)

---

**Steve's Notes**:
- This is a focused enhancement, not a major feature
- Priority: Medium (not blocking, but user-visible behavior issue)
- Estimated complexity: Low-to-Medium
- No UI changes required beyond behavioral modification
- Should be completed in single implementation cycle
- **Idle timeout (scenario #1) validated and working correctly across all screens**

# Clive → Georgina Handoff: Conditional Background Lock Implementation

## Overview
Implement a security refinement to prevent the application from locking when it is backgrounded while the user is on the **Import** or **Export** screens. This allows users to switch apps to find files or share exports without being forced back to the lock screen. **Idle timeout must remain strictly enforced on all screens.**

## Reference
- **Plan**: [Documentation/Handoffs/Tracy_to_Clive.md](Documentation/Handoffs/Tracy_to_Clive.md)
- **Standards**: [Documentation/Standards/CODING_STANDARDS.md](Documentation/Standards/CODING_STANDARDS.md)

## Implementation Guidance (Clive's Review)

### 1. LockViewModel Enhancements
- Add a transient boolean field `_isBackgroundLockExempt` (default: `false`).
- Provide a method `setBackgroundLockExemption(bool exempt)` that updates this field.
- **Crucial**: In `didChangeAppLifecycleState`, if the state is backgrounded (paused/inactive/hidden) and `_isBackgroundLockExempt` is `true`, **skip the call to `lock()`**, but **ensure `_idleTimerService.stopMonitoring()` is still called** to prevent unnecessary background timer execution.

### 2. View Conversion
- Both [lib/views/import_view.dart](lib/views/import_view.dart) and [lib/views/export_view.dart](lib/views/export_view.dart) are currently `StatelessWidget`.
- **Convert them to `StatefulWidget`** to gain access to lifecycle hooks:
    - `initState()`: Set exemption to `true`.
    - `dispose()`: Reset exemption to `false` (Mandatory for security).

### 3. Idle Timeout (No Change)
- Do NOT modify the global activity listener in `main.dart`.
- Ensure that `IdleTimerService` continues to trigger `lock()` normally if the 2-minute timeout expires while the user is idle on the Import/Export screens.

## Acceptance Criteria
- [ ] Backgrounding the app from `ImportView` or `ExportView` does NOT trigger the lock screen.
- [ ] Backgrounding from any other screen (Home, History, Settings, etc.) DOES trigger the lock screen.
- [ ] Idle timeout (2 minutes) still triggers atomic lock on ALL screens, including Import/Export.
- [ ] Returning to the app from a backgrounded Import/Export screen correctly resumes interaction without PIN entry.
- [ ] All 777+ existing tests pass.
- [ ] New unit tests in `test/viewmodels/lock_viewmodel_test.dart` verify the exemption logic.

## Security Note
"Security First" (§1.1) requires that we never leak the exemption. Ensure `dispose()` in the views is bulletproof in resetting the flag.

## Handoff
Georgina, please implement these changes. Start with the `LockViewModel` logic and then update the views. Verify with unit tests before manual smoke testing.

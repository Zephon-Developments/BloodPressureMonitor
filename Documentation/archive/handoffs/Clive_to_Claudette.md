# Review: Phase 5 - App Security Gate

**Reviewer**: Clive  
**Date**: 2025-12-29  
**Status**: ❌ BLOCKERS REMAINING

---

## Scope & Acceptance Criteria

**Scope**: Implementation of PIN/Biometric authentication, database encryption migration, and auto-lock functionality.

**Acceptance Criteria**:
- [x] PBKDF2-based PIN hashing (10,000 iterations)
- [x] Tiered lockout policy (5/10/15 attempts)
- [x] Database migration from placeholder to secure password
- [x] Auto-lock on idle timeout and backgrounding
- [x] Privacy screen in app switcher
- [x] Zero linting issues and all tests passing
- [ ] Production-ready UI integration (Blocker)

---

## Findings

### 🔴 Critical Blockers

#### 1. Unreachable Security Settings
The `SecuritySettingsView` is implemented but not integrated into the application's navigation. There is no button or menu item in `HomeView` to access security settings.
- **File**: [lib/views/home_view.dart](../../lib/views/home_view.dart)
- **Impact**: Users cannot set up PINs, enable biometrics, or change timeout settings.

#### 2. Aggressive Auto-Lock (UX/Security Bug)
The app triggers a lock immediately upon backgrounding even if no PIN has been set.
- **File**: [lib/viewmodels/lock_viewmodel.dart](../../lib/viewmodels/lock_viewmodel.dart#L118)
- **Impact**: New users who haven't opted into security are forced into a PIN setup flow the first time they background the app.
- **Required Fix**: `LockViewModel.lock()` should only set `isLocked = true` if `isPinSet` is true.

#### 3. Broken PIN Setup Flow in LockScreen
If a user sets a PIN via the `LockScreenView` (e.g., after being forced there by the backgrounding bug), the app remains locked after the PIN is set.
- **File**: [lib/viewmodels/lock_viewmodel.dart](../../lib/viewmodels/lock_viewmodel.dart#L131)
- **Impact**: User must enter their new PIN twice: once to set it, and once to unlock.
- **Required Fix**: `LockViewModel.setPin()` should also set `isLocked = false` and start the idle timer if it's being called to "unlock" the app.

### 🟡 Minor Issues & Standards Compliance

#### 1. Missing Explicit Types (Standards Violation)
Several methods in `LockScreenView` use untyped `state` parameters, which defaults to `dynamic`.
- **File**: [lib/views/lock/lock_screen.dart](../../lib/views/lock/lock_screen.dart#L178) (and others: `_buildKeypad`, `_buildKeypadRow`, `_buildNumberButton`, `_onNumberPressed`, `_submitPin`)
- **Requirement**: All parameters must have explicit types (e.g., `AppLockState state`).

#### 2. Use of `stderr.writeln`
The `DatabaseService` uses `stderr.writeln` for logging errors and migration status.
- **File**: [lib/services/database_service.dart](../../lib/services/database_service.dart#L56)
- **Requirement**: Use `debugPrint` or a dedicated logging service to ensure logs are captured correctly in Flutter environments.

#### 3. Incomplete Implementation Comment
- **File**: [lib/views/lock/lock_screen.dart](../../lib/views/lock/lock_screen.dart#L285)
- **Comment**: `// Setting up initial PIN - would need confirmation flow. For now, just set it`
- **Requirement**: Either implement the confirmation flow in `LockScreenView` or ensure that PIN setup only happens in `SecuritySettingsView` (which already has confirmation).

---

## Next Steps for Claudette

1. **Integrate Navigation**: Add a settings icon to the `HomeView` AppBar that navigates to `SecuritySettingsView`.
2. **Fix Lock Logic**: Update `LockViewModel.lock()` to check `isPinSet` before locking.
3. **Fix Setup Flow**: Ensure `setPin` or the caller in `LockScreenView` unlocks the app after successful setup.
4. **Type Safety**: Add explicit `AppLockState` types to all parameters in `LockScreenView`.
5. **Logging**: Replace `stderr.writeln` with `debugPrint`.

---

## Approval Status
**Green-light**: 🔴 NO  
**Blockers**: 3  
**Follow-ups**: 2

Please address these blockers and resubmit for review.

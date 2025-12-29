# Tracy  Clive: Phase 5 Implementation Plan (App Security Gate)

**Date:** December 29, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Reviewer)  
**Phase:** 5 - App Security Gate  
**Status:** Plan Ready for Review

---

## Objectives & Context
- Deliver app-level security gate: PIN + biometric, idle auto-lock, secure credential storage, and DB password migration (per [Documentation/Handoffs/Steve_to_Tracy.md](Steve_to_Tracy.md)).
- Replace placeholder SQLCipher password with per-installation secure password stored in platform keychain/keystore (see [SECURITY.md](../../SECURITY.md)).
- Align with Coding Standards: testing coverage (services 5%, widgets 70%, utilities 90% per [Coding_Standards.md 78](../Standards/Coding_Standards.md#L542-L620)), CI cleanliness, and branch/PR workflow.
- Acceptance from Implementation Schedule: lock enforced on launch/return; bypass impossible; analyzer clean; targeted tests passing ([Implementation_Schedule.md](../Plans/Implementation_Schedule.md#L89-L120)).

---

## Scope (In / Out)
- **In:** Secure DB credential management; PIN+biometric auth; lock on launch/resume; idle timeout; lock settings UI; migration from placeholder password; logging/hardening; tests (unit, widget, integration with platform mocks).
- **Out:** Per-profile secrets, account recovery, remote wipe, multi-device sync, cloud backup encryption, analytics.

---

## Architecture & Components
- **SecurePasswordManager (service)**
  - Responsibilities: generate cryptographically secure DB password; store/retrieve via `flutter_secure_storage`; expose `getOrCreatePassword()`; rotate/migrate from placeholder.
  - Implementation: use `Random.secure()`; 32-byte base64; platform-specific options (Android strongbox if available, iOS accessible-after-first-unlock); redact logs.
- **DatabaseService integration**
  - On init: fetch password from `SecurePasswordManager`; if old placeholder detected, perform SQLCipher rekey (`PRAGMA rekey`); ensure idempotent.
  - Failures: surface fatal errors with safe messaging; avoid partial migrations (wrap in transaction where possible).
- **AuthService (service)**
  - Store PIN hash+salt (PBKDF2 or SHA256 with salt) in `flutter_secure_storage` / `shared_preferences` for non-secret prefs (enabled flags, timeout minutes).
  - Track attempt count; lockout thresholds (e.g., 5 attempts, exponential backoff 30s/60s/300s); provide `verifyPin`, `setPin`, `changePin` flows.
  - Biometric: check availability via `local_auth`; prompt for auth; fallback to PIN; handle revoked biometrics.
- **IdleTimerService (service)**
  - Tracks foreground activity timestamps; listens to app lifecycle & user activity pings; triggers lock after configurable idle period (default 2 minutes per handoff).
- **LockState (model) & LockViewModel**
  - Holds lock status, lockout timers, remaining attempts, biometric availability, idle timeout config; orchestrates AuthService + IdleTimerService.
- **LockScreenView (widget)**
  - PIN keypad entry, biometric button, error/lockout messaging; disable app switcher preview (blur/placeholder if needed); respects accessibility (screen reader labels, focus order).
- **Settings: Security screen**
  - Configure PIN (set/change), toggle biometrics, set idle timeout (predefined options), view lockout info; minimal UI acceptable if Phase 6 shell not ready.
- **Navigation Gate**
  - Wrap root navigator with guard: app starts locked; app resumes locked if IdleTimer or background; block access to main content until unlock.
- **Config & Persistence**
  - `shared_preferences` for non-secret prefs: biometrics enabled flag, idle timeout minutes, last-lock timestamp; secure storage for secrets (PIN hash/salt, DB password).

---

## Data Flow & Sequences
1. **App Launch**: SecurePasswordManager retrieves/creates DB password  -> DatabaseService opens/rekeys if needed  -> LockViewModel sets state to locked  -> LockScreen shown.
2. **Unlock (PIN)**: user enters PIN  AuthService verifies hash/salt  on success, resets attempts, unlocks; on failure, increment attempts, apply lockout/backoff.
3. **Unlock (Biometric)**: user taps biometric  local_auth prompt  on success, unlock; on failure/cancel, stay locked and show guidance.
4. **Idle Auto-Lock**: IdleTimerService tracks last activity; when timeout reached or app goes background, LockViewModel transitions to locked; on resume, lock screen appears.
5. **Settings Updates**: changes to PIN/biometric/timeout persisted; LockViewModel reloads config; existing sessions may be forced to relock depending on setting changes (e.g., PIN change).
6. **DB Password Migration**: first post-update launch detects placeholder password; SecurePasswordManager generates new password; DatabaseService rekeys within a single connection; success path persists new password; failure path restores placeholder and surfaces fatal error.

---

## File/Package Changes
- **New packages (pubspec.yaml)**: `flutter_secure_storage`, `local_auth`, `shared_preferences` (versions per handoff). Run `flutter pub get`.
- **New code (proposed paths):**
  - `lib/services/secure_password_manager.dart`
  - `lib/services/auth_service.dart`
  - `lib/services/idle_timer_service.dart`
  - `lib/viewmodels/lock_viewmodel.dart`
  - `lib/views/lock/lock_screen.dart`
  - `lib/views/settings/security_settings_view.dart`
  - `lib/models/lock_state.dart`
- **Updates:**
  - `lib/services/database_service.dart` (integrate SecurePasswordManager, rekey logic)
  - `lib/main.dart` / navigation shell (gate to LockScreen)
  - `android/app/src/main/AndroidManifest.xml` (biometric permissions if required), `ios/Runner/Info.plist` (Face ID usage description), platform setup per `local_auth` docs.
  - `Documentation/` (update SECURITY.md, CHANGELOG.md, PROJECT_SUMMARY.md if needed).
- **Tests:**
  - `test/services/secure_password_manager_test.dart`
  - `test/services/auth_service_test.dart`
  - `test/services/idle_timer_service_test.dart`
  - `test/viewmodels/lock_viewmodel_test.dart`
  - `test/widgets/lock_screen_test.dart`
  - `test/widgets/security_settings_view_test.dart`
  - Integration: `test/integration/lock_flow_test.dart` (using `local_auth`/secure storage mocks).

---

## Implementation Sequence
1. **Branch & deps**: create `feature/phase-5-security-gate`; add pubspec deps; configure platform permissions/entitlements.
2. **SecurePasswordManager**: implement secure generation/storage, migration helpers; unit tests (crypto quality, persistence, rekey path).
3. **DatabaseService wiring**: inject SecurePasswordManager; implement `rekeyIfNeeded` from placeholder to new password; add tests (mock sqlcipher, verify rekey PRAGMA executed once, failure rollback).
4. **AuthService**: PIN lifecycle (set/verify/change), salt+hash, attempt tracking, lockout math, biometric availability/prompt wrappers; tests with mocks for storage/local_auth.
5. **IdleTimerService**: lifecycle hooks + activity pings; timeout scheduler; tests for timeout/resume/background scenarios.
6. **LockState/LockViewModel**: orchestrate auth + idle; expose streams/notifiers; handle lock/unlock/lockout; tests.
7. **UI**: LockScreen and SecuritySettings views; wire to ViewModel; accessibility and error states; widget tests with mock viewmodel.
8. **Navigation Gate**: wrap app shell to present LockScreen when locked; ensure back navigation cannot bypass; add integration tests for launch/resume/idle flows.
9. **Docs & configs**: update SECURITY.md (placeholder removal), PROJECT_SUMMARY.md (Phase 5), CHANGELOG.md entry; ensure analyzer/test passing.
10. **Review & PR**: Clive review against Coding Standards & handoff; ensure coverage thresholds met; prepare PR notes.

---

## Testing Strategy (aligns with Coding Standards 78)
- **Coverage targets**: Services 85%, Utilities 90%, Widgets 070% (hand-off minimum 80% overall for new code is satisfied by these).
- **Unit tests**: password generation randomness/length; storage round-trip; rekey path; PIN hash/verify; lockout escalation; idle timer scheduling; biometric availability handling with mocks.
- **Widget tests**: LockScreen keypad flow, biometric button states, error/lockout messaging, accessibility labels; SecuritySettings toggles and validation.
- **Integration tests**: end-to-end launch  lock  unlock (PIN and biometric), resume lock, idle timeout lock; ensure navigation bypass impossible.
- **Platform mocks**: mock `flutter_secure_storage`, `local_auth`, `shared_preferences`, lifecycle events; simulate biometric denied, removed biometrics, secure storage failure.
- **Performance checks**: ensure lock screen render <200ms (measure with `WidgetTester.pump` timings); biometric within 3s path.

---

## Migration Plan (DB password)
- Detect placeholder password usage; generate new password via SecurePasswordManager.
- Use SQLCipher `PRAGMA rekey` within single connection; wrap in transaction-equivalent flow.
- On failure: revert to placeholder, log securely (no secrets), present fatal error screen; do NOT proceed to app content.
- On success: persist new password and mark migration complete; subsequent launches reuse password without rekey.
- Fresh installs: generate password on first launch; no migration needed.

---

## Risks & Mitigations
- **Biometric edge cases**: revoked/changed biometrics  fallback to PIN; prompt user to re-enable.
- **Lockout UX**: avoid permanent lock; use backoff timers; show remaining attempts/time.
- **Storage failures**: secure storage unavailable  block app with clear message; offer retry; log without secrets.
- **Navigation bypass**: ensure all routes gated; block deep links when locked; guard background tasks.
- **Performance**: avoid heavy crypto on UI thread; precompute salts/hashes async.
- **Platform parity**: align Android/iOS permissions and behavior; test both.

---

## Open Decisions / Questions (for Clive & PO)
1. PIN length: enforce fixed 6 or allow 46 digits? (default to 6 if unspecified)
2. Lockout policy: attempts before backoff (proposal: 5 attempts; backoff 30s/60s/300s); max lockout cap?
3. Idle timeout options: fixed choices (e.g., 30s, 1m, 2m default, 5m, 10m) vs custom slider?
4. Should app auto-lock immediately when backgrounded regardless of idle timer? (proposal: yes)
5. Minimum OS support for biometrics (e.g., Android API 23+, iOS 11+); what fallback for unsupported? (PIN-only).
6. Should we blur app switcher preview on lock screen to avoid data leakage?

---

## Acceptance Criteria (mapped)
- App launches/resumes locked; no bypass to content without auth.
- PIN and biometric unlock succeed; failures enforced with lockout.
- Idle timeout triggers lock; backgrounding locks immediately (if accepted).
- Database password migrated to per-installation secure value; no hardcoded secrets remain.
- Tests meet coverage targets; `flutter analyze` clean; CI green.
- Security docs updated; CHANGELOG entry for Phase 5.

---

## Next Step
Clive: please review this plan for alignment with Coding Standards and the Phase 5 handoff. After approval, Steve can assign implementation to Claudette or Georgina.


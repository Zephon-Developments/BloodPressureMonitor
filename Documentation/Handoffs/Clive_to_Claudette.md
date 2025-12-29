# Clive → Claudette: Phase 5 Implementation Handoff

**Date:** December 29, 2025  
**From:** Clive (Reviewer)  
**To:** Claudette (Implementer)  
**Phase:** 5 - App Security Gate  
**Status:** Approved for Implementation

---

## Scope & Objectives

Implement the **App Security Gate** as defined in Tracy's plan ([Documentation/Handoffs/Tracy_to_Clive.md](Tracy_to_Clive.md)). This phase is critical for making the app production-ready by securing the database and protecting user data with a lock screen.

### Key Deliverables
1. **SecurePasswordManager:** Per-installation unique DB password using `flutter_secure_storage`.
2. **Database Migration:** Rekey SQLCipher from placeholder to secure password.
3. **AuthService:** PIN (hash+salt) and Biometric authentication logic.
4. **IdleTimerService:** Auto-lock after 2 minutes of inactivity or backgrounding.
5. **LockScreenView:** Secure UI for authentication.
6. **Security Settings:** UI to manage PIN, biometrics, and timeout.

---

## Reviewer's Refinements (Mandatory)

During my review of Tracy's plan, I've added the following requirements to ensure compliance with `CODING_STANDARDS.md`:

1. **PIN Hashing:** Use **PBKDF2** (with a minimum of 10,000 iterations) for PIN hashing instead of simple SHA256. This provides significantly better protection against brute-force attacks on the local storage.
2. **Lockout Policy:** 
   - 5 failed attempts -> 30s lockout.
   - 10 failed attempts -> 5m lockout.
   - 15+ failed attempts -> 30m lockout (Cap at 30m).
   - Ensure the lockout timer persists across app restarts.
3. **Idle Timer:** The `IdleTimerService` must listen for *any* user interaction (taps, scrolls) to reset the timer. You may need a global listener or a mixin for views to "ping" the service.
4. **App Switcher Privacy:** Implement a "Privacy Screen" (blur or logo overlay) that activates when the app is backgrounded to prevent sensitive data from appearing in the OS app switcher.
5. **Biometric Revocation:** If the user removes all biometrics from their device settings, the app must detect this on the next launch/resume and fallback to PIN, disabling the biometric toggle in settings until re-enrolled.

---

## Technical Constraints

- **Dependencies:** 
  - `flutter_secure_storage: ^9.2.2`
  - `local_auth: ^2.3.0`
  - `shared_preferences: ^2.3.3`
- **Testing:** 
  - Services: ≥85% coverage.
  - Utilities: ≥90% coverage.
  - Widgets: ≥70% coverage.
  - **Total New Code Coverage: ≥80%**.
- **Performance:** 
  - Lock screen must render in <200ms.
  - Biometric auth must complete in <3s.
- **Database:** The `rekey` operation must be idempotent and atomic. If it fails, the app must not be accessible.

---

## Implementation Sequence

1. **Setup:** Branch `feature/phase-5-security-gate`, add dependencies, and configure platform permissions (FaceID, Fingerprint).
2. **Security Foundation:** Implement `SecurePasswordManager` and `AuthService` (PBKDF2).
3. **DB Migration:** Update `DatabaseService` to use the secure password and perform the one-time rekey. **Test this thoroughly with a mock database.**
4. **Logic Layer:** Implement `IdleTimerService` and `LockViewModel`.
5. **UI Layer:** Build `LockScreenView` and `SecuritySettingsView`.
6. **Integration:** Wrap the app's root with the lock gate.
7. **Hardening:** Implement the app switcher privacy screen and lockout persistence.

---

## Acceptance Criteria

- [ ] App launches to lock screen; no bypass possible.
- [ ] Database is encrypted with a unique, non-placeholder password.
- [ ] PIN and Biometric unlock work as expected.
- [ ] Lockout triggers correctly and persists across restarts.
- [ ] Auto-lock triggers after 2 minutes of idle time.
- [ ] App switcher preview is obscured.
- [ ] All tests pass with required coverage.
- [ ] `flutter analyze` reports 0 issues.

---

## References

- **Implementation Plan:** [Documentation/Handoffs/Tracy_to_Clive.md](Tracy_to_Clive.md)
- **Coding Standards:** [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)
- **Security Policy:** [SECURITY.md](../../SECURITY.md)

**Claudette, your work on Phase 4 was excellent. Please maintain that high standard for testing and documentation here. This is the most sensitive part of the application.**

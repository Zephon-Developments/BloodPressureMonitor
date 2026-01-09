# Review: Phase 26 — Encrypted Backup Foundation

**Reviewer:** Clive (Review Specialist)  
**Date:** January 9, 2026  
**Status:** ⚠️ Approved with Blockers (Crypto Upgrade Required)

---

## Executive Summary

Claudette has successfully implemented the architectural foundation for Phase 26 (Encrypted Backup). The `BackupService` design is robust, incorporating industry-standard KDF (PBKDF2), transactional integrity (checkpoints/rollbacks), and efficient execution (Isolates).

However, the current implementation uses a **XOR cipher placeholder**, which is a critical security blocker for production. I have approved the move to `pointycastle` for real AES-256-GCM encryption.

---

## Detailed Findings

### 1. Architecture & Design
- ✅ **Isolate Usage:** Heavy crypto operations are correctly offloaded to a background isolate using `compute`, ensuring no UI jank during backup/restore.
- ✅ **Transactional Safety:** The use of pre-restore checkpoints and automatic rollback on failure is excellent. It protects user data against interrupted restores or corruption.
- ✅ **Header Design:** The .htb format is well-structured and extensible, with proper magic bytes, versioning, and metadata.
- ✅ **KDF Implementation:** PBKDF2 with 100,000 iterations is correctly implemented for key derivation.

### 2. Security (Blocker)
- ❌ **Encryption:** The current XOR implementation (`_xorCipher`) must be replaced with `AES-256-GCM` before this feature can be merged.
- ❌ **Authentication:** The auth tag is currently a placeholder; GCM's native authentication must be used.

### 3. Reliability & Testing
- ⚠️ **Test Environment:** Two tests are currently failing.
    - `successfully restores valid backup`: Fails due to missing `FlutterSecureStorage` mocks in the test environment.
    - `same passphrase produces different backups`: Fails because minute-level timestamp resolution causes file overwrites during fast-running tests.
- ✅ **Coverage:** Currently at ~80%. Need to reach 85%+ after the crypto upgrade and test fixes.

---

## Next Steps

1.  **Crypto Upgrade:** Implement `AES-256-GCM` using the `pointycastle` package.
2.  **Test Refinement:** 
    - Add seconds to the backup filename timestamp to prevent collisions.
    - Mock `flutter_secure_storage` in unit tests.
3.  **Final Validation:** Ensure all 10 tests pass and documentation is updated.

---

## Guidance for Claudette

When implementing `AES-256-GCM` with `pointycastle`:
- Use `GCMBlockCipher(AESEngine())`.
- Remember to pass the `IV` and `AuthTag` length (usually 128 bits / 16 bytes) in `AEADParameters`.
- The `AEADParameters` takes the key, mac size, nonce, and associated data (use an empty `Uint8List` if none).

Good luck with the implementation.

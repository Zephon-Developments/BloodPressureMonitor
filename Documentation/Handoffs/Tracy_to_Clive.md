# Handoff: Tracy → Clive

**Date:** January 9, 2026  
**From:** Tracy (Planning & Architecture)  
**To:** Clive (Plan Review)  
**Status:** Plan Ready for Review  
**Phase:** 26 — Encrypted Full-App Backup

---

## Objective & Scope
Deliver a secure, user-friendly full-app backup/restore that exports the SQLCipher database into an encrypted backup file and restores it safely with rollback guarantees.

---

## Constraints & Standards
- **Coding standards:** Adhere to Documentation/Standards/Coding_Standards.md (import order, const correctness, doc comments, 80-char lines). Coverage targets: Services ≥85%, Widgets ≥70%. Analyzer clean and formatted.
- **Security:** No passphrase persistence. Require strong passphrase (min 8, recommend 12+). Use authenticated encryption (AES-256-GCM) with KDF (PBKDF2-HMAC-SHA256 ≥100k iterations or Argon2id). Unique salts per backup; separate salts for encryption and checksum.
- **Compatibility:** Only restore when backup schema version ≤ current app schema. Reject newer-schema backups. Allow restore then migrate if older but compatible.
- **Data integrity:** Validate checksum before apply. Restore must be transactional with rollback to pre-restore DB on failure.
- **User safety:** Explicit confirmation before destructive restore; clear errors for wrong passphrase, corruption, version mismatch, insufficient space; progress indicators for long operations.
- **Performance:** Target <50MB DB, avoid UI thread blocking; heavy crypto/KDF in isolates/compute; stream I/O to avoid memory spikes.

---

## Architecture & Components

### 1) BackupService (new)
- **Responsibilities:**
  - Create backup: read SQLCipher DB file, wrap in container, encrypt with passphrase-derived key, write `.htb` file.
  - Restore backup: decrypt, validate header/checksum/version, safely swap DB with rollback.
- **Key APIs (proposed):**
  - `Future<BackupResult> createBackup({required String passphrase})`
  - `Future<RestoreResult> restoreBackup({required String passphrase, required Uri source})`
  - `Future<bool> validateBackup(Uri source)` (header/checksum preflight)
- **Implementation notes:**
  - Run KDF + encryption in isolates to keep UI responsive.
  - Stream file I/O to cap memory.
  - Salts: `saltEnc` (KDF), `saltChk` (checksum); store non-secret salts in header.
  - KDF: PBKDF2-HMAC-SHA256 (≥100k) or Argon2id (if acceptable dependency); document parameters.
  - Encryption: AES-256-GCM; store IV/nonce and auth tag in header.
  - Checksum: SHA-256 over plaintext DB (preferred) or encrypted payload; verify before apply.

### 2) Backup File Format (`.htb`)
- **Header fields:** magic (`HTB1`), app version, schema version, createdAt, device/model (optional), profile count (optional), `saltEnc`, `saltChk`, iv/nonce, authTag length, checksum, payload length.
- **Payload:** AES-GCM encrypted SQLCipher DB blob.
- **Naming:** `HealthLog_backup_YYYYMMDD_HHMM.htb` (24h clock).

### 3) UI/UX (Settings > Backup & Restore)
- **Backup flow:** passphrase + confirm, strength hint, show/hide toggle; progress indicator; success snackbar with path/share action.
- **Restore flow:** file picker/managed list; passphrase entry; header/version validation; warning dialog for destructive restore; progress; success prompt to restart/reload; failure shows reason.
- **States:** idle, validating, encrypting/decrypting, writing, success, error.

### 4) File Management
- Store backups in app-managed files directory; integrate with FileManagerService (list/delete) if present.
- Ensure platform-safe paths/permissions (Android/iOS). Optional share sheet to export backup file.

### 5) Restore Safety & Rollback
- Pre-check free space (≥2x backup size) before restore.
- Create pre-restore checkpoint: copy current DB to temp; revert on failure.
- Apply restore only after decrypt + checksum + version validation.
- Prefer atomic swap (move new DB into place) or transactional reopen.

### 2) Backup File Format (`.htb`)
- **Header Fields:** magic (`HTB1`), app version, schema version, createdAt, device/model (optional), profile count (optional), saltEnc, saltChk, iv/nonce, authTag length, checksum, payload length.
- **Payload:** AES-GCM encrypted SQLCipher DB blob.
- **Naming:** `HealthLog_backup_YYYYMMDD_HHMM.htb` (24h clock).

### 3) UI/UX (Settings > Backup & Restore)
- **Backup Flow:** passphrase + confirm, strength hint, show/hide toggle; progress indicator; success snackbar with path/share action.
- **Restore Flow:** file picker/managed list; passphrase entry; header/version validation; warning dialog for destructive restore; progress; success prompt to restart/reload; failure shows reason.
- **States:** idle, validating, encrypting/decrypting, writing, success, error.

### 4) File Management
- Store backups in managed files directory; integrate with FileManagerService if available for list/delete.
- Ensure platform-safe paths/permissions (Android/iOS). Optional share sheet to export backup file.

### 5) Restore Safety & Rollback
- Pre-check free space (>=2x backup size) before restore.
- Create pre-restore checkpoint: copy current DB to temp; revert on failure.
- Apply restore only after decrypt + checksum + version validation.
- Prefer atomic file swap (move new DB into place) or transactionally reopen DB.

---

## Testing Strategy
- **Unit:** KDF determinism and weak-passphrase rejection; AES-GCM round-trip with salts/IV/auth tag; header parse/serialize; checksum validation; version gating (reject newer schema, allow compatible older).
- **Integration:** Full backup/restore round-trip with sample DB; data equality; wrong passphrase fails with intact DB; corrupt file/bad checksum fails cleanly; insufficient space simulation (if feasible) fails pre-mutation.
- **Widget/Flow:** Backup UI validation/progress/success; restore UI file selection, confirm dialog, error messaging for wrong passphrase/version mismatch.
- **Non-functional:** Performance smoke on ~50MB DB; analyzer + format; coverage targets met.

---

## Sequencing & Deliverables
1) Finalize header/KDF parameters and acceptance tests (review checkpoint).
2) Implement BackupService (format, KDF, AES-GCM, checksum, version gating, rollback hooks).
3) Integrate Settings UI for backup/restore with progress and confirmations.
4) File management + optional sharing from managed directory.
5) Testing pass: unit + integration + widget; performance smoke; analyzer/format compliance.

---

## Risks & Mitigations
- **KDF performance on low-end devices:** Use isolates; tune iterations with benchmarks; document chosen parameters.
- **Schema incompatibility:** Strict version gating; clear user messaging; refuse newer-schema backups.
- **Corruption during restore:** Validate checksum pre-apply; atomic swap; rollback to checkpoint.
- **Passphrase loss:** Warn passphrase unrecoverable; advise secure storage.
- **Storage constraints:** Pre-flight space check; abort before mutation.

---

## Acceptance Criteria
- Backup uses AES-256-GCM with KDF-derived key; salts/IV/auth tag stored in header.
- Restore rejects wrong passphrase, corrupt checksum, or newer schema; preserves existing data on failure.
- Successful round-trip restores data identically (integration test).
- UI shows progress and confirmations; destructive actions require explicit consent.
- Analyzer clean; tests/coverage targets met; code formatted per standards.

---

**Ready for your review, Clive.**

## Open Questions for Clive
1) Any objection to PBKDF2-HMAC-SHA256 (≥100k iterations) as the baseline, deferring Argon2id unless benchmarks demand it?
2) Prefer checksum over plaintext DB (stronger corruption signal) vs. encrypted payload (smaller header leak surface)?
3) Minimum Android free-space threshold multiplier acceptable (2x vs 2.5x) for restore preflight?

---

## Artifacts to Update (Phase 26)
- lib/services/backup_service.dart
- lib/viewmodels/settings/backup_view_model.dart (or equivalent ViewModel)
- lib/views/settings/backup_view.dart (flows for backup/restore)
- lib/services/file_manager_service.dart (extend if needed for listing/deleting backups)
- test/services/backup_service_test.dart
- test/viewmodels/backup_view_model_test.dart
- test/views/settings/backup_view_test.dart
- Documentation/Deployment_Summary_2026-01-06.md (add backup feature notes)

---

Ready for your review, Clive. Cleaned per feedback—no Phase 24 content remains.

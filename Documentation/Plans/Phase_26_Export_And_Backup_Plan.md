# Phase 26 Plan: Export Modernization & Encrypted Full-App Backup

**Owner:** Tracy (Planning)  
**Date:** 2026-01-15  
**Scope:** Remove CSV exports, format JSON exports for readability, deliver encrypted full-app backup/restore.  
**Standards:** Follow Coding_Standards §2.1 (branch/PR), §2.4 (analyze/test/format/build gates).

---

## Objectives & Decisions
- Remove CSV export (keep CSV import for legacy). **Decision:** remove immediately; no deprecation UI, keep import-only.
- Format JSON exports with 2-space indent via `JsonEncoder.withIndent('  ')`.
- Apply Result pattern (§5.2) for backup/create/restore service methods (`Future<Result<T>>`) so failures are explicit and typed.
- Deliver encrypted full-app backup (`.htb`) using AES-256-GCM + PBKDF2 (100k iterations, 256-bit key, per-backup salt, random 12-byte nonce). Backup header stores version, schema, checksum, salt, iterations, createdAt.
- Backup storage: app documents directory by default; allow share sheet post-create. (Future: optional picker.)
- Restore mode: replace-all only for v1; no merge mode.
- Manual backups only; no scheduled auto-backup in this phase.
- UI messaging clarifies difference: JSON export (readable, selective) vs Encrypted Backup (full DB, passphrase-protected).

---

## Architecture Overview
- **Export Modernization:**
  - `ExportService.exportToJson`: switch to indented encoder; keep data shape.
  - Remove CSV export code paths; retain CSV import only.
  - File manager: keep `FileKind.exportCsv` recognition for legacy files (read-only); mark as legacy in UI copy.
- **Encrypted Backup:**
  - `BackupService` (new):
    - `createBackup(passphrase)`:
      1) Resolve SQLCipher DB path; copy to temp.
      2) Derive key with PBKDF2 (HMAC-SHA256, salt 16 bytes, iterations 100k, keyLen 32).
      3) Encrypt DB bytes with AES-256-GCM (nonce 12 bytes, tag 16 bytes).
      4) Compute SHA-256 checksum of plaintext DB (store in header).
      5) Serialize header + ciphertext into `.htb` container.
    - `restoreBackup(file, passphrase)`:
      1) Parse header; validate version/schema; verify checksum after decrypt.
      2) Decrypt with derived key; write to temp DB file.
      3) Atomic swap: close DB handles, replace active DB with temp, reopen; always delete temp on success/failure.
      4) On any failure, preserve existing DB.
  - **HTB container format (v1):**
    - Magic: `HTB1` (4 bytes)
    - Header length (u32)
    - Header JSON (utf8) with: version, appVersion, schemaVersion, createdAt, checksum (sha256 hex), salt (b64), iterations, nonce (b64), tagLength, dbBytesLength. Use a typed header model (no `dynamic`).
    - Ciphertext bytes
  - **Versioning:** Reject backups with schemaVersion > current. If equal/older, allow and run migrations after restore.
  - **Security:** Use `package:cryptography` (preferred) or `pointycastle` for PBKDF2 + AES-256-GCM; passphrase never stored; clear key/nonce buffers after use (best-effort in Dart); no PII/health data logging.

---

## Affected Components (files to touch)
- Remove CSV export paths:
  - `lib/services/export_service.dart`
  - `lib/viewmodels/export_viewmodel.dart`
  - `lib/views/export_view.dart`
  - `lib/models/managed_file.dart` (FileKind, labeling)
  - `lib/viewmodels/file_manager_viewmodel.dart`
  - `lib/views/file_manager_view.dart`
  - Tests: `test/services/export_service_test.dart`, any widget/viewmodel tests referencing CSV.
- JSON formatting: `lib/services/export_service.dart` (encoder change), update tests.
- Encrypted backup (new/expanded):
  - `lib/services/backup_service.dart` (new or upgrade if exists)
  - `lib/viewmodels/backup_viewmodel.dart` (new)
  - `lib/views/backup_view.dart` / settings integration
  - `lib/models/managed_file.dart` add `backupHtb` kind; file manager UI
  - Integration with app initialization to reopen DB after restore
  - Tests: service + viewmodel + widget tests
- Docs: README/QUICKSTART, import/export help, in-app copy (strings), Implementation Schedule reference.

---

## Work Plan & Sequencing
1) **Export Modernization (fast, low-risk; can ship independently)**
   - Update JSON formatting encoder; adjust tests for pretty output.
   - Remove CSV export code/UI; keep CSV import paths; update enums/file kinds and UI copy.
   - Update docs/help strings to remove CSV export mention; note legacy CSV import.
   - Tests: adjust export tests; ensure import tests still pass.

2) **Encrypted Backup Core (service + format)**
   - Define HTB v1 serializer/deserializer, header schema, checksum logic.
   - Implement `BackupService` create/restore with atomic swap and rollback.
   - Add version/schema guards and corruption detection.
   - Unit tests: key derivation, encrypt/decrypt, header parse/serialize, checksum mismatch, wrong passphrase.

3) **UI/ViewModel Integration**
   - Add settings entry "Backup & Restore" with two actions: Create Backup, Restore Backup.
   - Passphrase dialogs (with confirmation on create), warnings on restore.
   - Progress + success/failure states; share-sheet trigger post-backup.
   - File picker limited to `.htb`; file manager lists backups.

4) **End-to-End & Hardening**
   - Integration test: create backup → restore → verify data parity (service-level with fixture DB copy due to SQLCipher constraints).
   - Error-path tests: wrong passphrase, corrupt header, bad checksum, schema too new, insufficient storage (mock failure), mid-restore failure triggers rollback.
   - Performance check on large DB fixture; ensure UI remains responsive (async, progress updates).

5) **Docs & Release Prep**
   - Update user docs (backup vs export messaging), add warning about passphrase irrecoverability.
   - Update Implementation Schedule status notes; ensure CODING_STANDARDS compliance checks (analyze/test/format).
   - Prepare rollout notes; ensure feature flags not required.

---

## Testing Strategy
- **Unit (Services/Utils)**: PBKDF2 params, AES-GCM round-trip, header parse/serialize, checksum validation, wrong passphrase, corrupt file, version guard, rollback behavior (mock FS).
- **ViewModel**: success/failure states, progress flags, error surfacing, share trigger path.
- **Widget**: backup/restore dialogs render, validation (min 8 chars), disabled buttons during work, progress indicator.
- **Integration**: backup + restore cycle using temp DB copy; verify data equality (counts + sample rows); ensure DB reopened.
- **Import/Export Regression**: JSON export/import round-trip with pretty JSON; CSV import still works.
- **Performance**: Time budget for backup/restore on large fixture; ensure no UI thread blocking.
- **Security**: Confirm no passphrase persistence; salts/nonces unique; checksum prevents tampering; analyzer warnings resolved; assert no PII/health data is logged during export/backup; ensure Result-path failures map to user-safe messages.

---

## Risks & Mitigations
- **Data loss on restore failure**: Use temp copy + atomic rename; rollback on any exception; close DB handles before swap.
- **Performance on large DB**: Stream read/write; show progress; consider chunked read to avoid memory spikes.
- **Passphrase loss**: Prominent UI warning; advise password manager; no recovery by design.
- **Version incompatibility**: Enforce schema/app version checks; clear error messaging; document policy.
- **Legacy CSV imports**: Keep import path; test with sample legacy CSV; label CSV as legacy in UI copy.

---

## Open Items (to confirm before implementation)
- Whether to allow user-chosen backup destination in v1 (default: app docs + share).
- Final strings for user education (Export vs Backup messaging) and warnings.
- Expected minimum entropy for passphrases beyond length (e.g., require mix?) – recommend length-only with guidance.

---

## Acceptance Criteria
- Export: JSON files pretty-printed; CSV export removed; CSV import still functional; UI shows single export option; tests/analyzer pass.
- Backup: `.htb` created with AES-256-GCM + PBKDF2; restore replaces DB atomically; wrong passphrase/corrupt/incompatible files fail safely; rollback verified; UI flows complete with progress/warnings; coverage meets targets (Services/ViewModels ≥85%, Models/Utils ≥90%, Widgets ≥70%); `flutter analyze`, `flutter test`, `dart format` clean.

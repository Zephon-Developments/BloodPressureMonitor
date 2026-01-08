# Phase 26 Plan: Encrypted Full-App Backup

**Objective**: Deliver passphrase-protected, reliable full-app backup/restore with authenticity.

## Scope
- Export entire SQLCipher DB as a single encrypted blob with added AES-GCM layer using user passphrase.
- Settings → Backup & Restore UI with progress, warnings, and passphrase entry.
- Restore modes: replace-all (default) with rollback on failure; merge optional later.
- Versioning and integrity: version stamp + checksum; reject incompatible/corrupt files.

## Tasks
1) Backup Export
- Implement backup service to copy DB to temp, then encrypt with AES-GCM using key from PBKDF2/Argon2 (salted).
- Name files `healthlog_backup_YYYYMMDD_HHMM.htb`; store in app docs or user-picked path.

2) Restore Import
- Prompt for file + passphrase; decrypt and validate version/checksum.
- Restore by replacing DB atomically (temp file + swap); rollback on failure.
- Clear caches and re-open DB after restore.

3) UI/UX
- Settings screen entries: Export Backup, Import Backup.
- Warnings about overwrite risk, manual storage responsibility, and lost passphrase.
- Progress indicators and success/failure toasts/dialogs.

4) Validation & Hardening
- Verify passphrase failure path leaves existing data intact.
- Handle corrupt/foreign files gracefully.

## Acceptance Criteria
- Successful round-trip backup/restore with sample data; data matches pre-backup.
- Wrong passphrase or corrupt file fails cleanly with no partial writes.
- Analyzer/tests pass; coverage meets targets (Services/ViewModels ≥85%, Models/Utils ≥90%, Widgets ≥70%).

## Dependencies
- Phase 14 naming; stable schema through Phase 17.

## Risks & Mitigations
- Risk: Data loss on failed restore. Mitigation: temp copy + atomic swap + rollback on error.
- Risk: Performance on large DB. Mitigation: stream IO and surface progress.

## Branching & Workflow
- Branch: `feature/phase-18-encrypted-backup`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- Service tests: encrypt/decrypt, checksum/version validation, bad passphrase, corrupt file.
- Integration test: full round-trip backup/restore on test data.
- UI tests: basic widget tests for backup/restore flows; manual smoke on device/emulator.

## Rollback Plan
- If restore proves unstable, ship export-only mode (feature-flag restore) until reliability proven.

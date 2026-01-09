# Handoff: Steve to Tracy

**Phase:** Phase 26 - Encrypted Full-App Backup  
**Date:** January 9, 2026  
**From:** Steve (Deployment Specialist)  
**To:** Tracy (Planning Specialist)  
**Status:** 🔵 Planning Request

---

## Context

Phase 24E (Landscape Responsiveness) is complete and awaiting PR merge. Phase 25 (PDF Report v2) has been placed on hold per user direction.

The user has requested we proceed with **Phase 26: Encrypted Full-App Backup** as the next priority.

## Phase 26 Overview (From Implementation Schedule)

**Scope:** Passphrase-protected backup/restore of the full encrypted database.

**High-Level Tasks:**
- Export SQLCipher DB as a single blob with an added AES layer using a user passphrase
- Name files `HealthLog_backup_YYYYMMDD_HHMM.htb`
- Backup/Restore UI in Settings with progress, warnings, and passphrase entry
- Restore modes: replace all (default) with rollback on failure; merge mode optional if feasible
- Version stamps and checksums to validate compatibility and corruption

**Dependencies:**
- Phase 14 naming (HealthLog rebrand) ✅ Complete
- Stable schema through Phase 25 features ✅ Current schema is stable

**Acceptance Criteria (From Schedule):**
- Round-trip backup/restore succeeds with test data
- Wrong passphrase or corrupt file fails cleanly without partial writes
- Service/widget tests for happy path and failure paths
- Analyzer/tests pass

## Strategic Considerations

### 1. Data Protection Layer
The app already uses SQLCipher for at-rest encryption. Phase 26 adds a second encryption layer:
- **Layer 1:** SQLCipher (transparent to app code)
- **Layer 2:** User passphrase-based AES encryption of the entire DB file

**Rationale:** Allows secure backup files that can be stored/transferred without device-specific encryption keys.

### 2. Backup Format
**Proposed Format:** `.htb` (HealthLog Encrypted Backup)
- Binary format containing:
  - Version header (app version, schema version)
  - Checksum/hash for integrity validation
  - AES-encrypted SQLCipher database blob
  - Metadata (creation timestamp, device info, profile count)

### 3. User Experience Flow
**Backup:**
1. User navigates to Settings > Backup & Restore
2. Taps "Create Backup"
3. Enters passphrase (with confirmation)
4. Progress indicator while DB is encrypted
5. File saved to app's managed files directory
6. Option to share backup file via share sheet

**Restore:**
1. User selects backup file (via file picker or from managed files)
2. Enters passphrase
3. System validates format, version compatibility, checksum
4. Warning dialog: "This will replace all current data. Continue?"
5. Progress indicator during restore
6. On success: restart app to reload data
7. On failure: rollback, show error, preserve existing data

### 4. Security Requirements
- **Passphrase Strength:** Minimum 8 characters (recommend 12+)
- **Key Derivation:** Use PBKDF2 or Argon2 to derive AES key from passphrase
- **Iterations:** High iteration count (100k+) to resist brute force
- **Salt:** Unique per backup to prevent rainbow table attacks
- **Encryption:** AES-256-GCM for authenticated encryption
- **No Storage:** Never persist the backup passphrase

### 5. Version Compatibility
**Challenge:** Schema may evolve across app versions.
**Strategy:**
- Embed schema version in backup header
- Only allow restore if backup schema ≤ current app schema
- If schema upgrade is needed, run migrations after restore
- Reject restore if backup is from a newer app version

### 6. Error Handling
**Critical Scenarios:**
- Wrong passphrase → Clear error, no data modification
- Corrupt file → Validate checksum before decryption attempt
- Incompatible version → Clear error explaining version mismatch
- Restore failure mid-process → Rollback to pre-restore state
- Insufficient storage → Check space before starting

## Planning Request

Tracy, please develop a comprehensive architecture and implementation plan for Phase 26 that addresses:

### Required Plan Sections

1. **Service Architecture**
   - `BackupService` class design and responsibilities
   - Integration with existing `DatabaseService`
   - Encryption/decryption flow and key derivation
   - File format specification

2. **UI Components**
   - Settings screen integration
   - Backup creation flow (passphrase entry, progress, completion)
   - Restore flow (file selection, validation, confirmation, progress)
   - Error handling and user feedback

3. **File Management**
   - Where backups are stored (app's managed files directory)
   - Integration with existing `FileManagerService`
   - Backup file lifecycle (creation, deletion, sharing)

4. **Security Implementation**
   - Passphrase validation rules
   - Key derivation function selection and parameters
   - AES encryption configuration (algorithm, mode, padding)
   - Salt generation and storage

5. **Testing Strategy**
   - Unit tests: encryption/decryption, key derivation, version validation
   - Integration tests: full backup/restore cycle
   - Error scenario tests: wrong passphrase, corrupt file, version mismatch
   - Widget tests: UI flows, progress indicators, error dialogs

6. **Rollback Strategy**
   - Transaction-based restore process
   - Checkpoint creation before restore
   - Recovery mechanism if restore fails

7. **Dependencies & External Packages**
   - Evaluate need for additional packages (e.g., `encrypt`, `crypto` extensions)
   - Confirm compatibility with existing dependencies

8. **Acceptance Criteria**
   - Specific test cases that must pass
   - Performance targets (backup/restore time for typical DB sizes)
   - Security validation checklist

## Constraints & Standards

- **Follow CODING_STANDARDS.md:** All code must adhere to project standards
- **Test Coverage:** Services ≥85%, Widgets ≥70%
- **No Medical Claims:** This is a data backup feature, not a medical safeguard
- **User Control:** User must always confirm destructive actions (restore)
- **Transparency:** Clear progress indicators and error messages

## Success Metrics

A successful plan will:
- Provide a clear, step-by-step implementation roadmap
- Address all security concerns comprehensively
- Include detailed error handling and rollback strategies
- Specify testable acceptance criteria
- Consider UX at every step

## Next Steps

1. Tracy develops comprehensive plan
2. Steve reviews plan for deployment feasibility
3. Clive reviews plan for quality standards compliance
4. Appropriate implementer (Claudette or Georgina) executes plan
5. Clive reviews implementation
6. Steve handles final deployment

---

**Steve (Deployment Specialist)**  
*Initiating Phase 26 Planning*

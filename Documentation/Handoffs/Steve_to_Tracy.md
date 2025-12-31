# Handoff: Steve → Tracy

**Date**: December 31, 2025  
**From**: Steve (Workflow Conductor)  
**To**: Tracy (Planning Agent)  
**Task**: Plan Phases 15-17 + App Rebrand + Reminder Removal

---

## Context

The user has requested significant evolution of the Blood Pressure Monitor application to better support multi-profile use cases (particularly carers managing multiple individuals) and align with Zephon Development branding.

## User Requirements Summary

### 1. App Rebrand: HyperTrack
**Rationale**: 
- Broader scope than "Blood Pressure Monitor"
- Subtle tie to hypertension while supporting multi-metric tracking
- Unique positioning in health app space
- Future-proof for expansion

**Required Changes**:
- Update app name in all locations (pubspec.yaml, Android manifest, iOS info.plist)
- Update package identifiers (if feasible without breaking installs)
- Update all UI text references
- Update documentation and README
- Update repository/project references

**Standards Reference**: CODING_STANDARDS.md §2 (Git workflow, branching)

---

### 2. Phase 15: Profile-Centric UI Redesign

**Scope**: Restructure navigation to prioritize profiles and quick logging actions for carer workflows.

**Key Features**:
1. **Profile Launch Screen** (post-security gate)
   - Grid/list of existing profiles with avatars/names
   - Quick "Add New Profile" action
   - Profile selection leads to main home screen

2. **Enhanced Profile Management**
   - Full CRUD for profiles (add/edit/delete)
   - Avatar selection or custom images
   - Profile notes/metadata (e.g., relationship, care context)
   - Confirmation dialogs for deletion with data impact warnings

3. **Redesigned Main Home Screen**
   - Large quick-logging buttons:
     - Log Blood Pressure
     - Log Medication Intake
     - Log Weight
     - Log Sleep
   - Secondary navigation to:
     - History
     - Analytics
     - Medications List
     - Exports/Reports
     - Settings
   - Persistent profile switcher (e.g., dropdown or avatar in app bar)
   - Active profile indication throughout app

4. **Profile-Scoped Data Integrity**
   - All data queries strictly filtered by active profile ID
   - Profile context maintained across app lifecycle
   - Profile switching triggers data refresh in all views

**Dependencies**: 
- Current profile system (Phase 1, enhanced in Phase 10)
- All existing ViewModels (must respect active profile)

**Success Metrics**:
- Reduced taps for daily logging (target: 2 taps from launch to log entry)
- Clear profile context at all times
- Seamless profile switching without data leakage
- Intuitive carer workflow

**Constraints**:
- Must maintain data isolation per CODING_STANDARDS.md security principles
- Must preserve all existing functionality
- UI must follow Material Design 3 guidelines

---

### 3. Phase 16: Encrypted Full-App Backup

**Scope**: Secure off-device backup of entire app database for disaster recovery.

**Key Features**:
1. **Export Encrypted Backup**
   - Export entire SQLite database (all profiles + encrypted data)
   - Additional AES encryption layer with user-provided passphrase
   - File format: `.hypertrack.backup` (or similar)
   - Save to device storage for manual transfer/cloud upload by user

2. **Import/Restore Backup**
   - Passphrase prompt for decryption
   - Conflict handling options:
     - Replace all data (with confirmation)
     - Merge/append data (with duplicate detection)
   - Progress indicators for large datasets
   - Rollback capability if restore fails

3. **UI Integration**
   - Settings → Backup & Restore section
   - Clear warnings about data overwrite risks
   - Export success message with file location
   - Import pre-checks (version compatibility, corruption detection)

**Security Considerations**:
- Passphrase strength validation (minimum complexity)
- No passphrase storage (user must remember or store securely)
- Encrypted at rest (backup file is AES-encrypted blob)
- Clear user warnings about manual backup storage responsibility

**Dependencies**:
- Existing database encryption (sqflite_sqlcipher)
- File system access (path_provider)
- Encryption libraries (crypto package or similar)

**Success Metrics**:
- Successful round-trip backup/restore with zero data loss
- Decryption failure on incorrect passphrase (no silent corruption)
- User-friendly error messages for all failure scenarios

**Standards Reference**: CODING_STANDARDS.md §1.1 (Security First, Reliability)

---

### 4. Phase 17: Zephon Branding + Appearance Settings

**Scope**: Integrate Zephon Development branding and provide user customization options.

**Part A: About Screen**
1. **Content**:
   - App name: HyperTrack
   - Version number (from package_info_plus)
   - Brief description: "HyperTrack is a private, offline health data logger designed to help you collate and share accurate records with your healthcare professional."
   - Zephon Development branding:
     - Logo (if available) or text: "Developed under Zephon Development"
     - Clickable link to https://www.zephon.org
     - Tagline: "Empowering optimization and analytics through focused, user-centric projects."
   - Privacy disclaimer: "Not a medical device. No data is transmitted or shared without your explicit action."

2. **UI Location**: Settings → About HyperTrack

**Part B: Appearance Settings**
1. **Theme Selection**:
   - Light mode
   - Dark mode
   - System default (follow device)
   - Persist selection in SharedPreferences
   - Live preview on change

2. **Accent Color**:
   - Palette of 5-8 health-appropriate colors
   - Material Design 3 color scheme generation
   - Preview in real-time

3. **Accessibility Options**:
   - Font size scaling: Normal / Large / Extra Large
   - Optional: High contrast mode toggle
   - Immediate UI updates on change

4. **UI Location**: Settings → Appearance

**Dependencies**:
- Material Design 3 theming (already in use)
- SharedPreferences for persistence
- package_info_plus for version info

**Success Metrics**:
- Professional, clean About screen matching Zephon aesthetic
- Smooth theme switching without app restart
- Accessibility options improve readability for all users

**Standards Reference**: CODING_STANDARDS.md §3 (Material Design conventions)

---

### 5. Reminder Removal

**Scope**: Remove all reminder-related code and schema.

**Required Changes**:
1. **Database Schema**:
   - Remove `Reminder` table
   - Database migration to drop table (preserve data integrity for existing users)

2. **Models**:
   - Delete `lib/models/reminder.dart`

3. **Services**:
   - Delete reminder service and DAO
   - Remove any scheduled notification code

4. **UI**:
   - Remove any reminder-related views/widgets
   - Remove medication schedule metadata UI (if tied to reminders)

5. **Medication Intake**:
   - Keep manual timestamp logging
   - Remove "late/missed" indicators based on schedules
   - Keep simple intake history view

**Migration Strategy**:
- For existing users: schema migration will drop reminder data
- No user-facing migration UI needed (reminders weren't user-facing per existing schedule)

**Standards Reference**: CODING_STANDARDS.md §2.3 (Commit messages for deletions)

---

## Regulatory & Positioning Notes

- **Non-Medical Device**: No diagnoses, recommendations, or alerts
- **Privacy-First**: Offline-first, no automatic cloud sync, user controls all sharing
- **Disclaimers**: Required in About screen, store listings, and app launch
- **Google Play Compliance**: Health Apps category declaration, privacy policy link

---

## Your Task (Tracy)

1. **Review Requirements**: Analyze all five scope areas against current codebase and CODING_STANDARDS.md.

2. **Create Implementation Plans**:
   - **Plan A**: App Rebrand (HyperTrack) - impact assessment, file changes, testing strategy
   - **Plan B**: Phase 15 (Profile-Centric UI) - detailed wireframes, component breakdown, migration path
   - **Plan C**: Phase 16 (Encrypted Backup) - encryption approach, UX flow, error handling
   - **Plan D**: Phase 17 (Zephon Branding + Appearance) - design specifications, theme architecture
   - **Plan E**: Reminder Removal - deletion checklist, migration script, impact analysis

3. **Sequencing Recommendation**: Propose optimal implementation order considering dependencies and risk.

4. **Risk Assessment**: Identify potential breaking changes, data migration risks, and user impact.

5. **Standards Alignment**: Ensure all plans comply with CODING_STANDARDS.md security, testing, and architectural requirements.

---

## Expected Deliverables

For each scope area, provide:
- Detailed implementation plan (tasks, acceptance criteria, rollback points)
- File change manifest (new/modified/deleted files)
- Test strategy (unit/widget/integration coverage targets)
- Migration considerations (for existing users)
- Estimated complexity (hours/days)

## Next Steps

After completing plans:
1. Save all plans to `Documentation/Plans/` with clear naming (e.g., `Phase_15_Profile_UI_Plan.md`)
2. Create handoff document: `Documentation/Handoffs/Tracy_to_Clive.md` for plan review
3. Clive will review plans against CODING_STANDARDS.md before implementation begins

---

**Handoff Complete.** Please proceed with comprehensive planning for all five scope areas.


# HyperTrack - Phased Implementation Schedule

## Purpose
Break the implementation into sprint-sized phases with clear tasks, dependencies, acceptance criteria, and a simple progress tracker. Each phase should be reviewable/mergeable independently.

## Progress Tracking
- [x] Phase 1: Core Data Layer ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 2A: Averaging Engine ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 2B: Validation & ViewModel Integration ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 3: Medication Management ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 4: Weight & Sleep ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 5: App Security Gate ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 6: UI Foundation ✅ **COMPLETE** (Dec 29, 2025)
- [x] Phase 7: History (Avg-first with expansion) ✅ **COMPLETE** (Dec 30, 2025)
- [x] Phase 8: Charts & Analytics ✅ **COMPLETE** (Dec 30, 2025)
- [x] Phase 9: Edit & Delete Functionality ✅ **COMPLETE** (Dec 30, 2025)
- [x] Phase 10: Export & Reports ✅ **COMPLETE** (Dec 30, 2025)
- [x] Phase 11: Medication Records UI ✅ **COMPLETE** (Dec 31, 2025)
- [x] Phase 12: Medication Intake Recording UI ✅ **COMPLETE** (Dec 31, 2025)
- [x] Phase 13: File Management & Export Sharing ✅ **COMPLETE** (Dec 31, 2025)
- [ ] Phase 14: App Rebrand (HyperTrack)
- [ ] Phase 15: Reminder Removal
- [ ] Phase 16: Profile-Centric UI Redesign
- [ ] Phase 17: Zephon Branding & Appearance Settings
- [ ] Phase 18: Encrypted Full-App Backup
- [ ] Phase 19: Polish & Comprehensive Testing

---

## Phase Breakdown

### Phase 1: Core Data Layer (Encrypted)
**Scope**: Models (Reading, ReadingGroup, WeightEntry, SleepEntry, Reminder) + encrypted SQLite schema/migrations + base DAOs/services.
**Tasks**
- Define remaining models with DartDoc and equality: Reading, ReadingGroup, WeightEntry, SleepEntry, Reminder.
- Design DB schema (tables, FKs) for Profile, Reading, ReadingGroup, Medication, MedicationGroup, MedicationIntake, WeightEntry, SleepEntry, Reminder.
- Implement encrypted DB provider with `sqflite_sqlcipher`, migrations, and schema init.
- CRUD services for Profile and Reading (skeleton for others).
**Dependencies**: None (foundation).
**Acceptance**
- Schema created and migrated on app start; encryption enabled.
- Models round-trip via toMap/fromMap; unit tests ≥90% coverage for models/utils.
- Analyzer clean.
**Rollback point**: Schema + models + service skeleton behind feature flags (no UI impact yet).

### Phase 2A: Averaging Engine ✅ COMPLETE
**Scope**: 30-minute rolling grouping + manual session override.
**Tasks**
- ✅ Implement Reading service methods: add/read/list/delete.
- ✅ Averaging engine: rolling 30-min window per profile; manual "start new session" to force new group.
- ✅ Unit tests for grouping (back-dated, deletion, DST/offset).
**Dependencies**: Phase 1 schema/services.
**Acceptance**
- ✅ Grouping logic matches spec; recomputes on insert/update/delete/back-date.
- ✅ Tests ≥85% services (96.15% achieved); analyzer clean.
**Status**: Merged to main Dec 29, 2025

### Phase 2B: Validation & ViewModel Integration ✅ COMPLETE
**Scope**: Validation bounds, ViewModel integration, automatic averaging triggers.
**Tasks**
- ✅ Enhance validators with proper bounds (70–250 sys, 40–150 dia, 30–200 pulse).
- ✅ Add override confirmation hooks for out-of-range values.
- ✅ Wire AveragingService into BloodPressureViewModel.
- ✅ Auto-trigger grouping on create/update/delete operations.
- ✅ Unit tests for validation bounds and ViewModel integration.
**Dependencies**: Phase 2A.
**Acceptance**
- ✅ Validation enforces medical bounds with override capability.
- ✅ CRUD operations automatically trigger averaging recomputation.
- ✅ Tests ≥85% viewmodels (88%+ achieved); analyzer clean.
**Status**: Merged to main Dec 29, 2025

### Phase 3: Medication Management ✅ COMPLETE
**Scope**: Medication list, groups, intake logging with timestamps, schedule metadata.
**Tasks**
- ✅ CRUD for Medication, MedicationGroup, MedicationIntake.
- ✅ Group intake: single action logs multiple meds with individual intake records.
- ✅ Late/missed context relative to optional schedule metadata.
- ✅ Unit tests for intake associations, group logging, and schedule context.
**Dependencies**: Phase 1 schema; Phase 2 optional for correlation later.
**Acceptance**
- ✅ Intakes persisted with timestamps and optional groupId; correlation ready.
- ✅ Tests ≥85% for services; analyzer clean.
**Status**: Merged to main Dec 29, 2025

### Phase 4: Weight & Sleep
**Scope**: WeightEntry and SleepEntry storage + basic retrieval.
**Tasks**
- CRUD for WeightEntry; optional notes (salt, exercise, stress/sleep quality).
- CRUD/import for SleepEntry (manual + device-import hook, stored locally with source metadata).
- Basic correlation hooks for morning readings (no advice).
- Tests for parsing, storage, and date handling.
**Dependencies**: Phase 1 schema.
**Acceptance**
- Data persists and fetches; analyzer clean; tests ≥85% services.
**Rollback point**: Keep UI hooks off if needed.

### Phase 5: App Security Gate ✅ COMPLETE
**Scope**: App-level PIN/biometric lock; auto-lock on idle; no per-profile PINs.
**Tasks**
- ✅ Secure credential storage (PIN/biometric) using platform-appropriate secure storage.
- ✅ Idle timer + resume lock.
- ✅ Unit/widget tests for lock/unlock flow (mocking platform where possible).
**Dependencies**: Phases 1–4 not strictly required; can be parallel. Needs navigation shell.
**Acceptance**
- ✅ Lock enforced on launch/return; bypass impossible without auth.
- ✅ Analyzer clean; targeted tests passing.
**Status**: Merged to main Dec 29, 2025

### Phase 6: UI Foundation (Home, Add Reading) ✅ COMPLETE
**Scope**: Base navigation, profile switcher, add-reading form (manual entry with advanced section), reminder stub.
**Tasks**
- ✅ Home/dashboard shell with profile selector and quick add.
- ✅ Add Reading form with validation, advanced expander (arm, posture, notes, tags), link to quick medication intake.
- ✅ Wire to services (create reading, session override trigger).
- ✅ Widget tests for form validation and submission.
**Dependencies**: Phases 1–2.
**Acceptance**
- ✅ Create/read readings end-to-end; analyzer clean; widget tests ≥70% for new widgets.
- ✅ 555/555 tests passing; zero static analysis issues.
**Status**: Ready for PR merge to main Dec 29, 2025

### Phase 7: History (Avg-first with expansion) ✅ COMPLETE
**Scope**: History list showing averaged rows primary; expand to raw readings.
**Tasks**
- ✅ History screen with filters (date range, profile, tags), expandable groups.
- ✅ Toggle averaged vs raw view; display grouping membership.
- ✅ Performance pass for large lists (keyset pagination, ListView.builder).
- ✅ Widget tests for expand/collapse, filters, and data binding.
**Dependencies**: Phase 2; UI shell from Phase 6.
**Acceptance**
- ✅ UX matches spec (avg primary, raw one tap away); smooth scroll with large datasets; widget tests ≥70% (76.87% achieved).
- ✅ Service coverage 83.67%; all tests passing; analyzer clean.
**Status**: Merged to main Dec 30, 2025

### Phase 8: Charts & Analytics ✅ COMPLETE
**Scope**: Systolic/diastolic/pulse charts, banding, stats cards, morning/evening split.
**Completion Date**: Dec 30, 2025
**Tasks**
- ✅ BP line chart with color banding (<130/85 green, 130–139/85–89 yellow, ≥140/90 red)
- ✅ Pulse line chart with dedicated series
- ✅ Time-range selector (7d/30d/90d/1y/all) with chip UI
- ✅ Stats card grid (min/avg/max, variability with CV%)
- ✅ Morning/evening split comparison
- ✅ Sleep correlation overlay with stacked area chart
- ✅ Chart legend with toggle controls
- ✅ Analytics caching with TTL (5 minutes default)
- ✅ Widget tests for all chart components
**Dependencies**: Phases 2, 4 (for sleep overlay), UI shell.
**Acceptance**
- ✅ Charts render with correct band shading and stats
- ✅ Sleep overlay toggles on/off with correlation data
- ✅ Cache invalidation on data mutations via refreshAnalyticsData()
- ✅ Tests and analyzer clean
**Implementation Details**
- Created `lib/models/analytics.dart` with ChartDataSet, HealthStats, etc.
- Created `lib/services/analytics_service.dart` for data aggregation
- Created `lib/viewmodels/analytics_viewmodel.dart` with caching and range management
- Created `lib/views/analytics/analytics_view.dart` with chart composition
- Chart widgets: BpLineChart, PulseLineChart, SleepStackedAreaChart
- Supporting widgets: StatsCardGrid, MorningEveningCard, TimeRangeSelector, ChartLegend
**Status**: Implemented and integrated with Phase 9 cache invalidation

### Phase 9: Edit & Delete Functionality ✅ COMPLETE
**Scope**: Edit and delete capabilities for Blood Pressure, Weight, and Sleep entries with consistent UX.
**Completion Date**: Dec 30, 2025
**Tasks**
- ✅ Extend WeightViewModel and SleepViewModel with update/delete methods
- ✅ Modify Add forms to support edit mode (pre-populate fields, update UI labels)
- ✅ Implement swipe-to-delete on Home and History views using flutter_slidable
- ✅ Create reusable ConfirmDeleteDialog with accessibility support
- ✅ Add refreshAnalyticsData() extension for consistent cache invalidation
- ✅ Ensure proper BuildContext lifecycle handling across async operations
- ✅ Add detail bottom sheet for history entry actions
**Dependencies**: Phases 2, 4, 6, 7 (requires ViewModels, forms, and history view)
**Acceptance**
- ✅ Users can edit and delete all health entries with confirmation dialogs
- ✅ Swipe-to-delete reveals DELETE button on relevant cards
- ✅ Analytics cache invalidates and reloads after mutations
- ✅ All 612 tests passing; zero static analysis issues
- ✅ Full accessibility support with semantic labels
**Implementation Details**
- Added `flutter_slidable: ^3.1.0` dependency
- Created `lib/utils/provider_extensions.dart` for analytics refresh
- Created `lib/widgets/common/confirm_delete_dialog.dart`
- Modified 14 files, added 10 new files (24 total changes)
**Status**: Merged to `chore/phase-8-cleanup` branch; PR #20 pending merge to main

### Phase 10: Export & Reports ✅ COMPLETE
**Scope**: CSV/JSON export/import; PDF doctor report.
**Completion Date**: Dec 30, 2025
**Status**: ✅ **COMPLETE** - Merged to main (PR #21)
**Tasks**
- ✅ Local-only CSV/JSON export with configurable date ranges
- ✅ Data import with conflict resolution UI (overwrite/append strategy)
- ✅ PDF report for last 30/90 days with profile info, averages, chart snapshot, meds/intake notes
- ✅ Integration tests for export/import round-trip
- ✅ PDF generation tests with mock data
**Dependencies**: Phases 1–4, 7–9 for data/views.
**Acceptance**
- ✅ Successful round-trip for CSV/JSON with conflict resolution
- ✅ PDF generated offline with chart snapshots
- ✅ All 617 tests passing; analyzer clean
**Implementation Details**
- Created `lib/services/export_service.dart` for CSV/JSON export
- Created `lib/services/import_service.dart` with conflict detection
- Created `lib/services/pdf_report_service.dart` for PDF generation
- Created `lib/viewmodels/export_viewmodel.dart` for export logic
- Created `lib/viewmodels/import_viewmodel.dart` with conflict state management
- Created `lib/views/export/export_view.dart` with date range selector
- Created `lib/views/export/import_view.dart` with conflict resolution UI
- Added dependencies: csv ^6.0.0, pdf ^3.11.0, printing ^5.12.0, file_picker ^8.1.0, package_info_plus ^8.0.0
**Status**: Merged to main via PR #21 (Dec 30, 2025)

### Phase 11: Medication Records UI ✅ COMPLETE
**Scope**: User interface for viewing, editing, and managing medication records and intake history.
**Completion Date**: Dec 31, 2025
**Status**: ✅ **COMPLETE** - Merged to main (PR #22)
**Tasks**
- ✅ Create MedicationViewModel with CRUD operations
- ✅ Create MedicationIntakeViewModel for logging and tracking intake history
- ✅ Create MedicationGroupViewModel for managing medication groups
- ✅ Build medication list view with add/edit/delete capabilities
- ✅ Build medication intake logging view with timestamp and group support
- ✅ Build medication history view showing intake timeline with late/missed indicators
- ✅ Implement search and filtering (active/inactive, by group)
- ✅ Widget tests for all medication views and ViewModels
**Dependencies**: Phase 3 (medication backend services), Phase 8 (charts)
**Acceptance**
- ✅ Users can create, view, edit, and delete medications
- ✅ Users can log medication intakes individually or as groups
- ✅ Intake history displays with proper schedule context (on-time/late/missed)
- ✅ All 628 tests passing; analyzer clean
**Implementation Details**
- Created `lib/viewmodels/medication_viewmodel.dart` (166 lines)
- Created `lib/viewmodels/medication_intake_viewmodel.dart` (216 lines)
- Created `lib/viewmodels/medication_group_viewmodel.dart` (100 lines)
- Created `lib/views/medication/medication_list_view.dart` (299 lines)
- Created `lib/views/medication/add_edit_medication_view.dart` (205 lines)
- Created `lib/views/medication/log_intake_sheet.dart` (218 lines)
- Created `lib/views/medication/medication_history_view.dart` (333 lines)
- 9 unit tests for MedicationViewModel
- Profile-scoped queries with medication caching optimization
**Status**: Merged to main via PR #22 (Dec 31, 2025)

### Phase 12: Medication Intake Recording UI ✅ COMPLETE
**Scope**: UI entry points for medication intake recording from list and home screen.
**Completion Date**: Dec 31, 2025
**Status**: ✅ **COMPLETE** - Merged to main (PR #24)
**Tasks**
- ✅ Create searchable medication picker dialog
- ✅ Add "Log intake" button to medication list view for active medications
- ✅ Add "Log Medication Intake" quick action to home screen
- ✅ Widget tests for medication intake flows
**Dependencies**: Phase 11 (medication backend and LogIntakeSheet)
**Acceptance**
- ✅ Users can log intake from medication list with pre-selection
- ✅ Users can log intake from home quick actions via picker
- ✅ All 634 tests passing; analyzer clean
**Implementation Details**
- Created `lib/widgets/medication/medication_picker_dialog.dart` (202 lines)
- Modified `lib/views/medication/medication_list_view.dart` (added log button)
- Modified `lib/views/home/widgets/quick_actions.dart` (added quick action)
- 10 new widget tests
- Reuses existing `LogIntakeSheet` from Phase 11
**Status**: Merged to main via PR #24 (Dec 31, 2025)

### Phase 13: File Management & Export Sharing ✅ COMPLETE
**Scope**: File manager for exports/PDFs with auto-cleanup and sharing capabilities.
**Completion Date**: Dec 31, 2025
**Status**: ✅ **COMPLETE** - Merged to main
**Tasks**
- ✅ Create FileManagerService for scanning, filtering, deletion
- ✅ Implement auto-cleanup policies (age-based and count-based)
- ✅ Build File Manager UI with selection mode and bulk deletion
- ✅ Add profile-isolated file filtering
- ✅ Add sharing capability to export files
- ✅ Create settings dialog for configurable cleanup policies
**Dependencies**: Phase 10 (export/report services)
**Acceptance**
- ✅ Users can view all exports/PDFs for active profile
- ✅ Users can delete files individually, by selection, or by section
- ✅ Auto-cleanup runs with configurable policies (default: 90 days OR 5 files)
- ✅ All 23 new tests passing (total suite passing); analyzer clean
**Implementation Details**
- Created `lib/models/auto_cleanup_policy.dart` (default: 90 days, 5 files per type)
- Created `lib/models/managed_file.dart` (file metadata model)
- Created `lib/services/file_manager_service.dart` (scanning, cleanup logic)
- Created `lib/viewmodels/file_manager_viewmodel.dart` (state management)
- Created `lib/views/file_manager_view.dart` (selection mode, settings dialog)
- Modified `lib/main.dart` (FileManagerViewModel provider)
- Modified `lib/views/home_view.dart` (File Manager menu item)
- Modified `lib/services/export_service.dart` (added shareExport method)
- 23 new unit tests for file management
- Profile isolation via filename parsing
**Status**: Merged to main (Dec 31, 2025)

### Phase 14: App Rebrand (HyperTrack)
**Scope**: Rename product end-to-end while keeping install continuity.
**Tasks**
- Update app name strings in pubspec, Android manifest, iOS Info.plist, and user-facing UI copy.
- Keep existing package/bundle IDs to preserve upgrade path unless a breaking change is approved.
- Refresh documentation (README, QUICKSTART, CHANGELOG) and About text with HyperTrack branding.
- Run full build/analyze/test to verify no regressions in platform configs.
**Dependencies**: Completed core features through Phase 13.
**Acceptance**
- All user-visible references show "HyperTrack"; installs/upgrades succeed on Android/iOS.
- Analyzer/tests/CI green; store-facing disclaimers updated.

### Phase 15: Reminder Removal
**Scope**: Remove all reminder-related data, services, and UI.
**Tasks**
- Add migration to drop the Reminder table and related FKs/columns.
- Delete reminder models, services/DAOs, scheduled notification code, and reminder UI.
- Remove schedule-derived late/missed indicators; keep manual intake logging only.
- Update documentation to note removal and data impact.
**Dependencies**: Phase 1 schema; completed features through Phase 13.
**Acceptance**
- App builds and runs with no reminder references; migration succeeds on legacy data.
- Tests/analyzer pass; coverage meets targets.

### Phase 16: Profile-Centric UI Redesign
**Scope**: Profile-first navigation and quick logging for carer workflows.
**Tasks**
- Add launch profile picker (post security gate) with add/edit/delete, avatars, and notes.
- Add persistent profile switcher in the main shell; refresh data on profile change.
- Redesign home with quick actions (BP, medication intake, weight, sleep) and links to history,
  analytics, medications, exports/reports, settings.
- Audit ViewModels/queries for active-profile scoping; add refresh hooks to avoid leaks.
**Dependencies**: Phases 1–13; rebrand strings from Phase 14; reminder removal complete.
**Acceptance**
- From unlock to logging any entry takes ≤2 taps; profile switch updates all views without
  cross-profile leakage.
- Widget tests cover profile switch, quick actions, and profile CRUD; analyzer/tests pass.

### Phase 17: Zephon Branding & Appearance Settings
**Scope**: About screen with Zephon branding and customizable appearance.
**Tasks**
- Add Settings → About HyperTrack with app name/version, Zephon link/tagline, and privacy
  disclaimer.
- Add Settings → Appearance: theme mode (light/dark/system), accent palette, font scaling
  (normal/large/XL), optional high-contrast toggle.
- Centralize theming in a ThemeViewModel; persist settings in SharedPreferences.
**Dependencies**: Phase 14 rebrand complete; Phase 16 shell available for settings entry.
**Acceptance**
- Theme/accent/font changes apply live and persist across restarts; About screen shows Zephon
  branding and opens link safely.
- Widget/unit tests for toggles and persistence; analyzer/tests pass.

### Phase 18: Encrypted Full-App Backup
**Scope**: Passphrase-protected backup/restore of the full encrypted database.
**Tasks**
- Export SQLCipher DB as a single blob with an added AES layer using a user passphrase; name
  files `hypertrack_backup_YYYYMMDD_HHMM.htb`.
- Backup/Restore UI in Settings with progress, warnings, and passphrase entry.
- Restore modes: replace all (default) with rollback on failure; merge mode optional if feasible.
- Version stamps and checksums to validate compatibility and corruption.
**Dependencies**: Phase 14 naming; stable schema through Phase 17 features.
**Acceptance**
- Round-trip backup/restore succeeds with test data; wrong passphrase or corrupt file fails
  cleanly without partial writes.
- Service/widget tests for happy path and failure paths; analyzer/tests pass.

### Phase 19: Polish & Comprehensive Testing
**Scope**: Lint, coverage, performance, accessibility, and release readiness.
**Tasks**
- Achieve coverage targets (Models/Utils ≥90%, Services/ViewModels ≥85%, Widgets ≥70%).
- Accessibility labels for charts + table fallback; verify large text/high-contrast modes.
- Performance sweep on lists/charts; fix remaining analyzer warnings; finalize docs and release
  checklist.
**Dependencies**: All prior phases (14–18).
**Acceptance**
- Analyzer clean; coverage targets met; accessibility checks complete; ready for Clive
  greenlight.
**Rollback point**: N/A (release readiness).

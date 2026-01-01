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
- [x] Phase 14: App Rebrand (HyperTrack) ✅ **COMPLETE** (Dec 31, 2025)
- [x] Phase 15: Reminder Removal ✅ **COMPLETE** (Dec 31, 2025)
- [x] Phase 16: Profile-Centric UI Redesign ✅ **COMPLETE** (Dec 31, 2025)
- [x] Phase 17: Zephon Branding & Appearance Settings ✅ **COMPLETE** (Jan 1, 2026)
- [x] Phase 18: Medication Grouping UI ✅ **COMPLETE** (Jan 1, 2026)
- [x] Phase 19: UX Polish Pack ✅ **COMPLETE** (Jan 1, 2026)
- [ ] Phase 20: Profile Model Extensions
- [ ] Phase 21: Enhanced Sleep Tracking
- [ ] Phase 22: History Page Redesign
- [ ] Phase 23: Analytics Graph Overhaul
- [ ] Phase 24: Units & Accessibility
- [ ] Phase 25: PDF Report v2
- [ ] Phase 26: Encrypted Full-App Backup
- [ ] Phase 27: Polish & Comprehensive Testing

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

### Phase 17: Zephon Branding & Appearance Settings ✅ COMPLETE
**Scope**: About screen with Zephon branding and customizable appearance.
**Completion Date**: Jan 1, 2026
**Status**: ✅ **COMPLETE** - Merged to main (PR pending)
**Tasks**
- ✅ Add Settings → About HyperTrack with app name/version, Zephon link/tagline, and medical disclaimer.
- ✅ Add Settings → Appearance: theme mode (light/dark/system), 8 accent colors, font scaling (normal/large/XL), high-contrast toggle.
- ✅ Centralize theming in ThemeViewModel with Material 3 ColorScheme.fromSeed; persist settings in SharedPreferences.
- ✅ Widget tests for all theme components and persistence
- ✅ Upgrade Android build system (AGP 8.9.1, Gradle 8.11.1) to support modern dependencies
**Dependencies**: Phase 14 rebrand complete; Phase 16 shell available for settings entry.
**Acceptance**
- ✅ Theme/accent/font changes apply live and persist across restarts; About screen shows Zephon branding and opens link safely.
- ✅ All 777 tests passing; zero static analysis issues; analyzer/tests pass.
- ✅ Full Material 3 integration with dynamic theming
**Implementation Details**
- Created `lib/models/theme_settings.dart` (immutable model with enums)
- Created `lib/services/theme_persistence_service.dart` (SharedPreferences)
- Created `lib/viewmodels/theme_viewmodel.dart` (Material 3 theme generation)
- Created `lib/views/appearance_view.dart` (theme customization UI)
- Created `lib/views/about_view.dart` (Zephon branding + medical disclaimer)
- Created `lib/widgets/theme_widgets.dart` (reusable theme controls)
- Upgraded `android/build.gradle` and `android/settings.gradle` to AGP 8.9.1
- Upgraded `android/gradle/wrapper/gradle-wrapper.properties` to Gradle 8.11.1
- Added dependencies: url_launcher ^6.2.0, package_info_plus ^8.0.0
- Test Coverage: 100% on model, >80% on services/viewmodels/views
- Fixed 11 initial test failures via PackageInfo.setMockInitialValues()
- Resolved 143 compile errors by regenerating mocks with build_runner
- Fixed 22 analyzer warnings (deprecated Material 3 properties)
- Resolved critical Android build failure with AGP/Gradle upgrade
**Status**: Ready for PR merge to main (Jan 1, 2026)

### Phase 18: Medication Grouping UI ✅ COMPLETE
**Scope**: Expose existing medication grouping backend with UI for group management and quick logging.
**Completion Date**: Jan 1, 2026
**Status**: ✅ **COMPLETE** - Committed to feature/phase-18-medication-grouping-ui
**Tasks**
- ✅ Create UI for viewing, creating, editing, and deleting medication groups.
- ✅ Add group picker to Log Medication flow; support logging entire group with one tap.
- ✅ Add dosage field numeric validation (prevent non-numeric input).
- ✅ Convert unit field to combo box with common units (mg, ml, IU, mcg, units) + custom entry option.
- ✅ Add clear button (X icon) to medication search bar.
- ✅ Widget tests for group management and group logging flows.
**Dependencies**: Phase 11 (medication UI foundation); Phase 12 (intake logging).
**Acceptance**
- ✅ Users can create medication groups and log entire groups with one action.
- ✅ Dosage field enforces numeric input; unit field offers suggestions via combo box.
- ✅ Search bar includes functional clear button.
- ✅ All 844 tests passing; analyzer clean; coverage ≥80%.
**Implementation Details**
- Created `lib/views/medication/medication_group_list_view.dart` (285 lines)
- Created `lib/views/medication/add_edit_medication_group_view.dart` (299 lines)
- Created `lib/widgets/medication/multi_select_medication_picker.dart` (259 lines)
- Created `lib/widgets/medication/unit_combo_box.dart` (167 lines)
- Created `test/viewmodels/medication_group_viewmodel_test.dart` (110 lines)
- Created `test/views/medication_group_list_view_test.dart` (15 tests)
- Created `test/views/add_edit_medication_group_view_test.dart` (15 tests)
- Created `test/widgets/multi_select_medication_picker_test.dart` (15 tests)
- Created `test/widgets/unit_combo_box_test.dart` (10 tests)
- Modified `lib/views/medication/log_intake_sheet.dart` (group logging support)
- Modified `lib/widgets/medication/medication_picker_dialog.dart` (group selection)
- 67 new/modified tests; performance optimizations (removed redundant ViewModel calls)
**Status**: Ready for PR merge to main (Jan 1, 2026)

### Phase 19: UX Polish Pack
**Scope**: Address UX inconsistencies and minor validation/usability issues across the app.
**Tasks**
- Fix idle timeout inconsistency: ensure medications entry screen times out like other screens.
- Add clear buttons (X icons) to all search bars across the app.
- Add numeric validation to all numeric input fields (dosage, weight, BP values).
- Audit and fix any inconsistent navigation patterns.
- Performance optimization pass for large datasets (medications, history).
**Dependencies**: Phase 18 (medication UI complete).
**Acceptance**
- Idle timeout works consistently across all screens.
- All search bars have clear buttons.
- Numeric fields reject non-numeric input with helpful error messages.
- Navigation is consistent and intuitive.
- All tests passing; analyzer clean.
**Rollback point**: Individual fixes can be feature-flagged if needed.

### Phase 20: Profile Model Extensions
**Scope**: Extend Profile model with medical metadata fields for PDF reports and doctor coordination.
**Tasks**
- Add new Profile model fields: dateOfBirth (required), patientId (optional), doctorName (optional), clinicName (optional).
- Create migration to add new columns to Profile table (schema version bump).
- Update ProfileService with CRUD for new fields.
- Update ProfileViewModel and profile management UI to support new fields.
- Add date picker for DOB; validation to ensure DOB is in the past and reasonable (e.g., not future, not >150 years ago).
- Update profile forms with optional fields (graceful empty states).
- Unit and widget tests for new fields and validation.
**Dependencies**: Phase 16 (profile UI complete).
**Acceptance**
- Profile model includes all new fields with proper validation.
- Migration succeeds on existing databases without data loss.
- UI allows editing new fields with appropriate controls.
- All tests passing; analyzer clean; coverage ≥85% for services/viewmodels.
**Rollback point**: Migration includes fallback; fields are nullable (optional) to allow gradual adoption.

### Phase 21: Enhanced Sleep Tracking
**Scope**: Redesign sleep tracking to support dual-mode entry (detailed metrics or basic) with schema changes.
**Tasks**
- Redesign SleepEntry schema: add optional fields for remHours, remMinutes, lightHours, lightMinutes, deepHours, deepMinutes, textualNotes.
- Create migration to add new columns to SleepEntry table (schema version bump).
- Update SleepService to support new fields.
- Update SleepViewModel with dual-mode logic.
- Create new Add/Edit Sleep UI with mode toggle: Detailed (REM/Light/Deep sliders or pickers) vs Basic (total hours + notes).
- Validation: ensure sleep metrics are reasonable (0-24 hours total; components sum correctly in detailed mode).
- Update sleep history and analytics to display new metrics when available.
- Unit and widget tests for dual-mode entry and validation.
**Dependencies**: Phase 4 (basic sleep tracking); Phase 20 (migration pattern established).
**Acceptance**
- Users can choose detailed or basic sleep entry mode.
- Detailed mode captures REM, Light, Deep sleep metrics; basic mode captures total + notes.
- Migration succeeds without data loss.
- Analytics and history display new metrics when available.
- All tests passing; analyzer clean; coverage targets met.
**Rollback point**: Default to basic mode if detailed mode has issues; migration includes rollback support.

### Phase 22: History Page Redesign
**Scope**: Redesign History page with collapsible sections, mini-stats, and improved UX.
**Tasks**
- Create collapsible section UI for History page: Blood Pressure, Pulse, Medication, Weight, Sleep (all closed by default).
- Each section displays button to open full history + summary of 10 most recent readings + mini-stats (e.g., "Latest: 128/82 (avg last 7 days)").
- Implement mini-stats calculation service (latest value, 7-day average, trend indicator).
- Optimize performance for large datasets (lazy loading, pagination).
- Widget tests for collapsible sections, mini-stats display, and full history navigation.
**Dependencies**: Phase 7 (history foundation); Phase 21 (sleep metrics for display).
**Acceptance**
- History page shows collapsible sections with mini-stats.
- Performance is smooth with large datasets (1000+ readings).
- Full history opens from section button.
- All tests passing; analyzer clean; widget coverage ≥70%.
**Rollback point**: Feature-flag new layout; fall back to existing history view if critical issues.

### Phase 23: Analytics Graph Overhaul
**Scope**: Redesign analytics graphs with dual Y-axis BP charts, smoothing toggle, and improved clarity.
**Tasks**
- Replace Bezier curves with raw line graphs as default.
- Add smoothing toggle (rolling average, window = 10% of readings) for all graphs.
- Redesign BP graph with dual Y-axis layout:
  - Upper Y-axis: Systolic (50-200 mmHg) with color zones (red 180-200, yellow 140-179, green 90-139, yellow 50-89).
  - Lower Y-axis: Diastolic (30-150 mmHg) with color zones (red 120-150, yellow 90-119, green 60-89, yellow 30-59).
  - Clear zone: Horizontal band between graphs for X-axis labels.
  - Plotting: Each reading plots two points (systolic upper, diastolic lower), connected vertically.
- Update chart legend to reflect new layout.
- Performance optimization for chart rendering with large datasets.
- Widget tests for smoothing toggle and dual Y-axis layout.
**Dependencies**: Phase 8 (analytics foundation); Phase 22 (history complete).
**Acceptance**
- BP charts use dual Y-axis layout with proper color zones.
- Smoothing toggle works for all graph types.
- Default graph style is raw line (no Bezier).
- Performance is smooth with 1000+ data points.
- All tests passing; analyzer clean; widget coverage ≥70%.
**Rollback point**: Feature-flag new chart layout; fall back to existing charts if rendering issues arise.

### Phase 24: Units & Accessibility
**Scope**: Add app-wide units preference and comprehensive accessibility support.
**Tasks**
- Add units preference to Settings (kg vs lbs; future-ready for °C vs °F).
- Create UnitsPreferenceService to persist and retrieve unit preferences.
- Update all weight-related UI to respect unit preference (display and input).
- Add semantic labels to all large buttons and interactive elements (screen reader support).
- Verify color contrast for all chart zones and UI elements (WCAG AA compliance).
- Add high-contrast mode support (test with system high-contrast enabled).
- Audit all text for readability with large text scaling (1.5x, 2x).
- Unit and widget tests for units preference and accessibility features.
**Dependencies**: Phase 17 (appearance settings); Phase 23 (charts complete).
**Acceptance**
- Users can select kg or lbs in Settings; preference persists and applies app-wide.
- All interactive elements have semantic labels for screen readers.
- Color contrast meets WCAG AA standards; high-contrast mode works correctly.
- App is usable with large text scaling (up to 2x).
- All tests passing; analyzer clean; coverage targets met.
**Rollback point**: Units preference can be feature-flagged; accessibility labels can be added incrementally.

### Phase 25: PDF Report v2
**Scope**: Enhanced PDF report layout with new profile fields, time period selector, and improved formatting.
**Tasks**
- Update PDF report to include new profile fields: DOB, Patient ID, Doctor Name, Clinic Name.
- Add time period selector to PDF generation UI (7/30/90 days).
- Implement enhanced report layout:
  - Front page: Patient details (name, DOB, gender, patient ID, report date, doctor, clinic).
  - Summary: Most recent readings (BP, pulse, medication, weight, sleep) with proper rounding.
  - Detailed readings: Time period-filtered data with graphs and tables.
  - Notes section: Space for doctor annotations.
  - Footer: Disclaimer (informational only, not medical advice).
- Proper rounding: BP/pulse to nearest integer; weight to 0.1kg or 0.05lb.
- Medication grouping in report: Group by medication name; show last date for each.
- Sleep metrics: Display REM/Light/Deep when available; fall back to total + notes for basic entries.
- Unit tests for PDF generation with new fields and rounding logic.
**Dependencies**: Phase 20 (profile extensions); Phase 21 (sleep metrics); Phase 24 (units).
**Acceptance**
- PDF report includes all new profile fields with graceful empty states.
- Time period selector allows filtering data (7/30/90 days).
- Rounding is correct for all metrics per spec.
- Medication grouping and sleep metrics display correctly.
- All tests passing; analyzer clean; coverage ≥85% for services.
**Rollback point**: Feature-flag new report layout; fall back to existing PDF format if generation issues arise.

### Phase 26: Encrypted Full-App Backup
**Scope**: Passphrase-protected backup/restore of the full encrypted database.
**Tasks**
- Export SQLCipher DB as a single blob with an added AES layer using a user passphrase; name
  files `hypertrack_backup_YYYYMMDD_HHMM.htb`.
- Backup/Restore UI in Settings with progress, warnings, and passphrase entry.
- Restore modes: replace all (default) with rollback on failure; merge mode optional if feasible.
- Version stamps and checksums to validate compatibility and corruption.
**Dependencies**: Phase 14 naming; stable schema through Phase 25 features.
**Acceptance**
- Round-trip backup/restore succeeds with test data; wrong passphrase or corrupt file fails
  cleanly without partial writes.
- Service/widget tests for happy path and failure paths; analyzer/tests pass.

### Phase 27: Polish & Comprehensive Testing
**Scope**: Final lint, coverage, performance, accessibility, and release readiness sweep.
**Tasks**
- Achieve coverage targets (Models/Utils ≥90%, Services/ViewModels ≥85%, Widgets ≥70%).
- Accessibility labels for charts + table fallback; verify large text/high-contrast modes.
- Performance sweep on lists/charts; fix remaining analyzer warnings; finalize docs and release
  checklist.
- Comprehensive regression testing across all features with multiple profiles and large datasets.
- Release build testing on Android (ProGuard/R8 validation) and iOS.
- Update all documentation (README, QUICKSTART, CHANGELOG) for release.
**Dependencies**: All prior phases (18–26).
**Acceptance**
- Analyzer clean; coverage targets met; accessibility checks complete; ready for production release.
- All 777+ tests passing; zero static analysis issues.
- Release builds succeed on Android and iOS without ProGuard/R8 errors.
**Rollback point**: N/A (release readiness).

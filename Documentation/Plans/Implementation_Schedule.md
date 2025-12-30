# Blood Pressure Monitor - Phased Implementation Schedule

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
- [ ] Phase 10: Export & Reports
- [ ] Phase 11: Polish & Comprehensive Testing

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

### Phase 10: Export & Reports
**Scope**: CSV/JSON export/import; PDF doctor report.
**Status**: 📋 **PLANNED** - Not yet started
**Tasks**
- Local-only CSV/JSON export/import; conflict handling basic (overwrite/append strategy).
- PDF report for last 30/90 days: profile info, date range, averages, chart snapshot, meds/intake notes, irregular flags; disclaimer.
- Integration tests for export/import round-trip; PDF generation smoke tests.
**Dependencies**: Phases 1–4, 7–9 for data/views.
**Acceptance**
- Successful round-trip for CSV/JSON; PDF generated offline; tests pass.
**Rollback point**: Export only (defer PDF) if needed.

### Phase 11: Polish & Comprehensive Testing
**Scope**: Lint, coverage, perf, accessibility, and cleanup.
**Tasks**
- Achieve coverage targets (Models/Utils ≥90%, Services/ViewModels ≥85%, Widgets ≥70%).
- Accessibility labels for charts + table fallback; large text mode pass.
- Performance sweep on lists/charts; fix any analyzer warnings.
- Final docs (DartDoc completeness) and release checklist.
**Dependencies**: All prior phases.
**Acceptance**
- Analyzer clean; coverage targets met; accessibility checks done; ready for Clive greenlight.
**Rollback point**: N/A (release readiness).

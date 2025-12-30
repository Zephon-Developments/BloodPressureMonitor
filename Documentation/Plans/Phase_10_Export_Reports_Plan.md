# Phase 10: Export & Reports
**Author:** Tracy (Planning)
**Date:** 2025-12-30
**Related Handoff:** Documentation/Handoffs/Steve_to_Tracy.md
**Target Branch for implementation:** `feature/export-reports`

## 1) Overview
- **Objective:** Deliver offline CSV/JSON export & import plus PDF doctor report (30/90 days) with conflict handling and sharing.
- **User Value:** Data portability, backup/restore, clinician-ready summaries with charts and key stats.
- **Success Criteria:**
  - CSV/JSON round-trip succeeds (export → delete data → import → data restored equivalently).
  - PDF generated offline with required sections and sharable file output.
  - Analyzer clean; all tests passing; new coverage: services ≥85%, widgets ≥80%.
- **Rollback Strategy:** Ship export-only (CSV/JSON) behind feature flag; defer PDF if blocked.

## 2) Technical Design
### 2.1 Export/Import Architecture
- **Service Layer:**
  - New `ExportService` for CSV/JSON generation (streams to file; chunked where possible).
  - New `ImportService` for CSV/JSON parsing, validation, and conflict resolution.
- **Data Scope:** BloodPressureReading (raw), WeightEntry, SleepEntry, Medication, MedicationIntake.
- **File Formats:**
  - **CSV:** flat tables per entity; UTF-8; ISO-8601 timestamps; headers required. Optional fields empty when null. Tags as pipe-delimited list. Include header-level metadata row noting export timestamp and "Sensitive Health Data" warning.
  - **JSON:** structured object with metadata `{ version, exportedAt, appVersion, profileId, timezoneOffset }` and arrays per entity. IDs optional; rely on timestamps+type for matching.
- **Conflict Resolution:**
  - Modes: Overwrite (wipe existing of that type before import) or Append (upsert; skip duplicates by composite keys).
  - Duplicate keys:
    - Readings: timestamp + systolic + diastolic + profileId.
    - Weight: timestamp + weight + profileId.
    - Sleep: date + source + profileId.
    - Medications: name + dosage + profileId; Intakes: medicationId/name + timestamp.
- **Validation & Error Handling:**
  - Strict parsing with per-row error accumulation; fail-fast threshold (e.g., >20 errors aborts).
  - Bounds checks reuse Validators (BP bounds 70–250/40–150, pulse 30–200; weight >0; sleep 0–24h).
  - Produce import summary (rows processed, inserted, skipped, errors) for user display.
- **I/O & Permissions:**
  - Use `path_provider` for app documents; `file_picker` (if added) for user-selected imports; warn about sensitive data per SECURITY.md.

### 2.2 PDF Generation Pipeline
- **Data Aggregation:** Reuse `AnalyticsService`/`AnalyticsViewModel` to fetch 30d/90d ranges, stats, and chart datasets.
- **Rendering:**
  - Use `pdf` package; consider `printing` for layout helpers.
  - Charts: rasterize existing fl_chart widgets via `RepaintBoundary` with high-resolution capture (pixelRatio ≥ 3.0) to avoid print pixelation; fallback to simplified PDF-native line plots if raster fails.
  - Sections: Header, Summary Stats, Charts (BP & Pulse), Table (condensed readings), Medications/Intakes summary, Irregular Flags, Footer disclaimer.
- **Output & Sharing:** Save PDF to app documents; expose share intent via `share_plus`; show location and success toast.
 - **Output & Sharing:** Save PDF to app documents and expose platform share sheets via `share_plus` (email, messaging, cloud/Discord/other standard targets); show saved path and success toast.
- **Performance:** Paginate tables (50 rows per page); cap charts to selected range to avoid memory spikes.

### 2.3 UI/UX Flows
- **Export Screen:**
  - Controls: Format toggle (CSV/JSON), Data scope checkboxes (BP/Weight/Sleep/Medications), Conflict mode (overwrite/append for JSON import reference), Generate button.
  - Feedback: Progress indicator, success state with file path + share action, error summary.
- **Import Screen:**
  - File picker, format auto-detect (by extension/header), conflict mode selector, dry-run summary preview (rows to insert/skip/errors), execute import button, result report dialog.
- **PDF Screen:**
  - Range selector (30/90 days), Generate button, progress indicator, preview thumbnail (optional), Share button.
- **Accessibility:** Semantics labels on all controls; announce progress/results; buttons disabled during in-flight ops.

## 3) Implementation Tasks
### 3.1 Services
- Add `ExportService` (CSV/JSON writers, streaming where possible).
- Add `ImportService` (parsers, validators, conflict resolution, summaries).
- Add `PdfReportService` (data gather + PDF build + file write + share hook).

### 3.2 ViewModels
- `ExportViewModel`: orchestrate export, hold state/progress, expose file path.
- `ImportViewModel`: manage file selection, dry-run parsing, execution, summary/errors.
- `ReportViewModel` (or reuse AnalyticsViewModel with façade): generate PDF, expose status and share.

### 3.3 UI
- New screens/widgets: Export screen, Import screen, Report/PDF screen or section in settings/tools.
- Reusable components: Progress banner, ResultSummary card, ErrorList, ConflictMode selector.

### 3.4 Data/Models
- Add lightweight DTOs: `ExportMetadata`, `ImportResult`, `ImportError`, `ReportMetadata`.
- No DB schema changes expected.

### 3.5 Dependency Updates
- Add `csv: ^6.0.0`, `pdf: ^3.11.0`, `printing: ^5.12.0` (optional), `share_plus` (already present), add `file_picker` if needed.

### 3.6 Testing
- Unit: ExportService round-trip, ImportService validation/conflict handling, PdfReportService section assembly.
- Widget: Export/Import/PDF screens interactions, progress + error display.
- Integration: Export → wipe data → import → verify counts/values; PDF generation smoke (file exists, sections present markers).

### 3.7 Docs & Tooling
- Update QUICKSTART/README with export/import/report usage and privacy warning.
- Add sample CSV/JSON fixtures for tests under test/unit_test_assets.
 - Add DartDoc for all public methods in `ExportService`, `ImportService`, and `PdfReportService`.

## 4) Dependencies & Sequencing
1) Services first (Export/Import/PDF) with unit tests.
2) ViewModels layering + tests.
3) UI screens + widget tests.
4) Integration tests (round-trip, PDF smoke).
5) Docs updates.

## 5) Acceptance Criteria (aligns with Implementation_Schedule)
- CSV/JSON export/import supports BP, Weight, Sleep, Meds/Intakes; overwrite/append modes implemented.
- Round-trip test passes for CSV and JSON.
- PDF report generates offline for 30d and 90d ranges with required sections and embedded charts or fallback plots.
- Import shows user-visible summary with errors/skips; does not corrupt existing data.
- Analyzer clean; all tests pass; coverage thresholds met (services ≥85%, widgets ≥80%).
 - PDF can be saved locally and shared through standard platform share sheets (email, messaging, Discord, cloud targets) via `share_plus`.

## 6) Risks & Mitigations
- **Large files / memory spikes:** Stream CSV writes; chunk reads; paginate PDF tables; limit chart samples per range.
- **Corrupt imports:** Strict validation; dry-run preview; cap errors; clear user messaging.
- **Duplicate handling ambiguity:** Explicit overwrite/append choice; document matching keys.
- **Chart raster failures:** Provide PDF-native fallback line plots if image render fails.
- **Sensitive data exposure:** Prominent warning per SECURITY.md; store in app docs; allow user-chosen path.

## 7) Open Questions
1. Confirm entity set for export/import: include medications & intakes by default? (Recommend yes.)
2. Preferred default conflict mode for import? (Recommend append with duplicate skip.)
3. Require dry-run preview before import executes? (Recommend yes.)
4. Accept rasterized charts in PDF or require vector fallback by default? (Recommend raster with vector fallback.)
5. File naming convention: `bp_export_<profile>_<yyyyMMdd_HHmm>.(csv|json|pdf)`? (Recommend yes.)

## 8) Branch & Workflow
- Implementation branch: `feature/export-reports` from `main`.
- Follow Coding_Standards: analyzer/test/format gates; Conventional Commits; PR required with CI green.

## 9) Handoff Plan
- Deliver this plan to Clive for review (Coding Standards compliance, completeness, risks).
- After approval, hand to Georgina/Claudette for implementation following sequencing above.

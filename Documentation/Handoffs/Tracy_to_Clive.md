# Handoff: Tracy → Clive

**Date:** December 31, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Scope:** Phase 13 – Export/PDF management & export sharing + automated cleanup

---

## Objectives & Success Metrics
- Provide users a way to **view, share, and delete** locally stored exports (JSON/CSV) and doctor report PDFs.
- Add **sharing for exports** identical to existing doctor report sharing (platform share sheet via `share_plus`).
- Implement **automated cleanup** based on time and/or count thresholds, with clear controls and confirmations.
- Maintain existing export/PDF generation behavior and file naming.
- Success: Users can see stored files with size/date, share any export/PDF, delete individually/bulk, and configure/trigger cleanup; analyzer/tests green and coverage ≥ project standards.

## Best Practices Alignment (must-have)
- **Security/Privacy**: Treat exports as sensitive; keep in app documents dir; avoid PII in filenames; no world-readable paths; do not auto-upload. Consider optional password-zip later (out of scope now).
- **Sharing UX**: Use platform share sheet with clear text (e.g., "Sensitive health data – Blood Pressure Export"); handle missing files gracefully; never share by default.
- **Data Integrity**: Keep JSON/CSV schema versioned; include metadata (app version, timezone offset, profile id) and preserve existing CSV sanitization against formula injection.
- **Lifecycle & Cleanup**: Provide visibility (list with size/date), confirmation for delete/bulk, configurable cleanup (age/count, optional size), default conservative values; show summary of freed space.
- **Resilience**: Handle low disk space and I/O errors with user-friendly messaging; tolerate orphaned or unparsable filenames; fall back to fs metadata.
- **Performance/UX**: Async operations with progress/spinners; non-blocking cleanup; success/error toasts; predictable filenames already in place.
- **Compliance & Docs**: Document that shares leave secure storage and users must handle responsibly; align with Coding_Standards security/testability sections.

## Constraints & Standards
- Architecture: MVVM (Service → ViewModel → View). Provider/ChangeNotifier.
- Storage: Uses `path_provider` documents directory; respect sandboxing (Android/iOS).
- Coding: Follow Coding Standards (import ordering, 80-char guidance, security/testability emphasis) per Documentation/Standards/Coding_Standards.md §1 (security/reliability/testability) and §3 (imports/style).
- Tests: New logic must be unit-testable; target same coverage bar as existing (~90%+ on new code). No analyzer warnings.
- Branching: use protected main; branch e.g., `feature/export-file-management`.

## Current State (for reference)
- `ExportService` saves JSON/CSV to documents dir; no sharing/cleanup.
- `PdfReportService` saves PDFs; has `shareReport(File)` using `Share.shareXFiles`.
- `ExportViewModel` handles export; tracks last path and errors only.
- `ExportView` shows buttons for JSON/CSV, success path, no share/management UI.
- No file registry; files accumulate indefinitely.

## Key Decisions to Lock
1. **File discovery**: Prefer filesystem scan in documents dir using naming patterns (`bp_export_*`, `bp_report_*`). Optional registry not required now; handle orphaned files gracefully.
2. **UI pattern**: Use **hybrid** approach:
   - Add "Recent exports" and share button in `ExportView` post-export.
   - Add dedicated **File Manager** screen for full list and cleanup controls, linked from Export screen and Settings.
3. **Auto-cleanup policy**: Configurable thresholds with safe defaults (proposal: age ≥ 90 days OR keep latest 50 per type). Manual cleanup always available.
4. **Deletion UX**: Confirm dialogs for single/bulk; show total size freed; handle missing files without crashing.
5. **Sharing**: Use `share_plus` for all file types; reuse pattern from doctor reports.

## Architecture & Components
- **FileManagerService (new)**
  - Responsibilities: scan documents dir, classify files (type, createdAt from filename or fs metadata), compute size, delete files, bulk delete by filters (age/count/type), run auto-cleanup routine.
  - Inputs: documents path (`getApplicationDocumentsDirectory()`), optional filters.
  - Outputs: `List<ManagedFile>` model with metadata (path, name, size, createdAt, type: export_json/export_csv/report_pdf).

- **ManagedFile model (new)**
  - Fields: `String path`, `String name`, `int sizeBytes`, `DateTime createdAt`, `FileKind kind`, `String? profileName` (parsed if present).
  - Parsing: derive from filename prefix; fallback to fs stats if parse fails.

- **ExportService (update)**
  - Add `Future<void> shareExport(File file)` using `Share.shareXFiles([XFile(file.path)], text: 'Blood Pressure Export');`.
  - Optionally centralize filename pattern helpers for reuse by FileManagerService.

- **PdfReportService (existing)**
  - No change to generation; ensure share helper reused if possible (optional utility wrapper).

- **ExportViewModel (update)**
  - Expose `shareLastExport()` (uses stored path) and error handling.
  - Optionally expose a callback to open File Manager.

- **FileManagerViewModel (new)**
  - Holds list state, loading/error flags, total size, filters.
  - Actions: load files, delete single, delete bulk (by selection or rule), run auto-cleanup, refresh.
  - Handles missing-file gracefully (removes from state, surfaces soft warning).

- **AutoCleanupPolicy (new model)**
  - Fields: `Duration? maxAge`, `int? maxFilesPerType`, `bool enabled` (defaults enabled with safe values?), `int? maxTotalSizeMB` (optional stretch).
  - Stored in `SharedPreferences` or existing settings mechanism.

- **FileManagerView (new UI)**
  - Lists files grouped by type; shows name, size, date.
  - Actions per item: Share, Delete.
  - Bulk actions: Delete selected; Run auto-cleanup now.
  - Summary header: total files, total size, cleanup policy display.

- **ExportView (update UI)**
  - After successful export, show buttons: `Share`, `Open in File Manager`.
  - Optional mini-list of last N exports (with share/delete quick actions) to reduce navigation friction.

## Data Flow
1. Export/Report generation writes to documents dir with current naming.
2. FileManagerService scans dir on demand; returns `ManagedFile` list.
3. FileManagerViewModel loads list, applies grouping/sorting, exposes to UI.
4. Share action: FileManagerViewModel → Share via ExportService/PdfReportService helper (based on type) or unified share utility.
5. Delete action: FileManagerViewModel → FileManagerService.delete(path) → refresh list.
6. Auto-cleanup: run on demand and optionally on startup of FileManagerViewModel or app init; uses policy to delete old/excess files.

## Automated Cleanup Design
- Trigger points: manual "Run cleanup now" button; optional automatic on app launch of Export/FileManager screens; post-export hook (non-blocking).
- Rules (configurable):
  - **Age rule**: delete files older than N days (default 90).
  - **Count rule**: retain most recent M per type (default 50) and delete older.
  - (Optional) **Size rule**: keep total under S MB by deleting oldest first.
- Safety: dry-run preview counts/size to be deleted; confirm before executing.
- Error handling: skip missing/locked files; collect errors; present summary.

## Sequencing
1. **Services/Models**: Add ManagedFile, AutoCleanupPolicy, FileManagerService; update ExportService sharing helper.
2. **ViewModels**: Add FileManagerViewModel; extend ExportViewModel with share + navigation hooks.
3. **UI**: Update ExportView (share button + recent list + link); create FileManagerView; add navigation entry (Settings or menu/quick action).
4. **Auto-cleanup**: Implement policy storage, apply rules in service, wire UI controls, optional on-load trigger.
5. **Tests**: Unit tests for services, viewmodels; widget tests for views; integration-style tests for cleanup logic with temp dirs.
6. **Docs**: Update README/QUICKSTART or in-app help; note storage/cleanup behavior.

## Test Strategy
- **Service tests**: FileManagerService scanning (mixed file types), delete single/bulk, age and count pruning, size calculations, missing file handling.
- **ViewModel tests**: state transitions on load/share/delete/cleanup success and failures; error propagation.
- **Widget tests**: ExportView share button visible after export; FileManagerView list rendering, share/delete flows (mocked); confirmation dialogs.
- **Edge cases**: zero files; corrupted filename parse; file removed between scan and delete; share on missing file; policy disabled; large file sizes.
- Follow Coding_Standards guidance on test isolation and coverage (§1.1 Testability, §3 style).

## Risks & Mitigations
- **Platform storage quirks**: Android/iOS sandbox—mitigate by staying in documents dir; no external storage assumptions.
- **Incorrect deletions**: Require confirmations; default conservative policy; dry-run preview.
- **Orphaned files/unparseable names**: Fallback to fs metadata; show as "Unknown" type but manageable.
- **Long scans**: Use async with progress; consider caching if needed (defer unless perf issues).
- **Concurrent access**: Guard against deleting file in use; surface user-friendly error and refresh.

## Open Questions for Clive/User
1. Default auto-cleanup policy values (proposed: age 90 days, keep 50 per type; size cap? 200 MB?).
2. Should auto-cleanup be enabled by default, or opt-in?
3. Where to surface File Manager entry (Settings, Export screen button, plus possibly Home quick action)?
4. Should users be able to open files (JSON/CSV) in external viewer, or only share/delete?
5. Need a "Select all" bulk delete, or only rule-based cleanup?

---

## Ready for Review
This plan is ready for your review, focusing on the proposed architecture, auto-cleanup defaults, and UI placement choices.

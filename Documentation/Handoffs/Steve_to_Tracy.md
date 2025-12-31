# Handoff: Steve → Tracy

**Date:** December 31, 2025  
**From:** Steve (Workflow Conductor)  
**To:** Tracy (Planning Agent)  
**Task:** Plan Phase 13 - Export/PDF Management & Sharing Enhancement

---

## User Request

The user has requested two new features:

1. **Export/PDF File Management**  
   - Currently, exported files (JSON/CSV) and generated PDFs accumulate in the app's documents directory without any cleanup mechanism
   - Will eventually fill up device storage
   - Need a way to manage (view, delete, clean up) these files

2. **Export File Sharing**  
   - Currently, only Doctor Reports (PDFs) can be shared via the platform share sheet
   - Export files (JSON/CSV) should also be sharable the same way
   - Should use the same `share_plus` package pattern

---

## Current Implementation Context

### Existing Export/PDF System

**Export Service** ([lib/services/export_service.dart](lib/services/export_service.dart)):
- Exports JSON and CSV files to `getApplicationDocumentsDirectory()`
- Filename pattern: `bp_export_{profileName}_{timestamp}.{extension}`
- No sharing capability currently implemented
- No file management/cleanup mechanism
- Files accumulate indefinitely

**PDF Report Service** ([lib/services/pdf_report_service.dart](lib/services/pdf_report_service.dart)):
- Generates doctor reports as PDFs to `getApplicationDocumentsDirectory()`
- Filename pattern: `bp_report_{profileName}_{timestamp}.pdf`
- Already has `shareReport(File file)` method using `Share.shareXFiles()`
- Uses `share_plus: ^10.1.0` package
- No file management/cleanup mechanism
- Files accumulate indefinitely

**Export View** ([lib/views/export_view.dart](lib/views/export_view.dart)):
- UI for exporting JSON/CSV
- Shows success message with file path
- No share button currently
- No file management UI

**Storage Location:**
- All files saved to app's documents directory via `path_provider`
- Not accessible to users through file browser on most platforms
- Files persist until app uninstall or manual cleanup (which doesn't exist yet)

---

## Success Criteria

### 1. File Management
- Users can view all exported files and generated PDFs in one place
- Users can delete individual files
- Users can perform bulk cleanup (e.g., "delete all files older than X days")
- Display file size and creation date for informed cleanup decisions
- Show total storage used by exports/reports
- Confirmation dialogs before deletion

### 2. Export File Sharing
- JSON and CSV exports can be shared using platform share sheet (same as PDFs)
- Share button appears immediately after export completion
- Sharing should work the same way as doctor reports (email, messaging, cloud storage, etc.)
- Maintain existing doctor report sharing functionality

### 3. Additional Considerations
- No breaking changes to existing export/PDF generation
- Maintain existing file naming conventions
- Consider auto-cleanup policy (optional: delete files older than 90 days)
- Clear UX for file management (dedicated screen or integration into Export View)
- Handle edge cases (file deleted while being shared, permission errors, etc.)

---

## Constraints

- **Architecture:** MVVM pattern (Service → ViewModel → View)
- **State Management:** Provider with ChangeNotifier
- **Testing:** Maintain 90%+ code coverage for new code
- **Standards:** Follow [Documentation/Reference/CODING_STANDARDS.md](../Reference/CODING_STANDARDS.md)
- **Backwards Compatibility:** Existing exports/PDFs must remain accessible
- **Platform Support:** Android and iOS (Windows/macOS optional)
- **Security:** Ensure file operations are secure (no path traversal, proper permissions)

---

## Technical Notes

### File Detection Strategy
Since files are created by `ExportService` and `PdfReportService`, you need to:
- Scan the documents directory for files matching naming patterns
- Parse filenames to extract metadata (profile name, timestamp, type)
- OR maintain a database/shared preferences registry of created files
- Consider: What if users manually delete files outside the app?

### Sharing Implementation
The pattern is already established in `PdfReportService.shareReport()`:
```dart
Future<void> shareReport(File file) async {
  await Share.shareXFiles([XFile(file.path)], text: 'Blood Pressure Report');
}
```

Apply the same pattern to `ExportService` for JSON/CSV files.

### File Management UI Options

**Option A: Dedicated File Manager Screen**
- New view: `FileManagerView`
- Accessible from settings or main menu
- Shows all exports/PDFs in a list
- Actions: view details, share, delete

**Option B: Integrate into Export View**
- Add a section to existing `ExportView`
- "Recent Exports" section below export buttons
- Quick access to recent files

**Option C: Hybrid**
- Recent files shown in `ExportView`
- "Manage All Files" button leads to dedicated screen

### Storage Calculation
Use `File.length()` to get size in bytes, aggregate for total storage display.

### Auto-Cleanup Policy
Consider adding a setting for automatic cleanup:
- Default: off (manual cleanup only)
- Optional: auto-delete files older than 30/60/90 days
- Check and clean on app startup or background task

---

## Recommended Approach

1. **Phase 13A: File Management**
   - Create `FileManagerService` to scan/list/delete files
   - Create `FileManagerViewModel` for state management
   - Create `FileManagerView` for UI (or enhance `ExportView`)
   - Add tests for file operations

2. **Phase 13B: Export Sharing**
   - Add `shareExport(File file)` method to `ExportService`
   - Update `ExportViewModel` to expose sharing action
   - Add share button to `ExportView` after successful export
   - Add tests for sharing functionality

3. **Phase 13C: Integration & Polish**
   - Wire up file manager to main navigation
   - Add settings for auto-cleanup policy (optional)
   - Update documentation
   - End-to-end testing

---

## Required Deliverables

1. **Detailed Technical Plan** following standard Phase Plan format
2. **Architecture decisions** (file detection strategy, UI approach)
3. **Implementation steps** with file-by-file breakdown
4. **Test strategy** covering edge cases
5. **Risk assessment** (data loss, permissions, platform differences)
6. **Reference to CODING_STANDARDS.md** for all new code

---

## Questions for Tracy to Address in Plan

1. Should we use filesystem scanning or maintain a registry of created files?
2. Where should File Manager be accessible from (dedicated screen vs integrated)?
3. Should auto-cleanup be part of Phase 13 or future enhancement?
4. How to handle orphaned files (created outside app control)?
5. What confirmation/warning UX for deletion operations?
6. Should we support file renaming or just view/share/delete?
7. Platform-specific considerations (Android storage scoping, iOS sandboxing)?

---

## Next Steps

1. Tracy creates comprehensive Phase 13 plan
2. Clive reviews plan against CODING_STANDARDS.md
3. Steve selects implementer (Claudette vs Georgina)
4. Implementation → Review → Deploy cycle

---

**Status:** READY FOR TRACY REVIEW  
**Priority:** HIGH (storage accumulation is a production issue)  
**Complexity:** MEDIUM (file operations + UI additions)


# Handoff: Steve to Tracy

**Date**: 2026-01-19  
**From**: Steve (Workflow Conductor)  
**To**: Tracy (Planner)  
**Branch**: `feature/phase-26-encrypted-backup`

---

## Mission

Create a comprehensive plan to fix the **Import Data** functionality which is currently failing with a FilePicker error on Android.

---

## Problem Statement

### User Report
The Import Data feature is non-functional. When attempting to select a JSON file for import, the following error appears:

> "Failed to pick file: PlatformException(FilePicker, Unsupported filter. Make sure that you are only using the extension without the dot, (ie., jpg instead of .jpg). This could also have happened because you are using an unsupported file extension. If the problem persists, you may want to consider using FileType.any instead., null, null)"

### Current Implementation

**File**: [lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart#L43-L48)

```dart
/// Picks a JSON file from the device.
Future<void> pickFile() async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
```

**Key Observations**:
1. The extension is already specified without a dot (`'json'` not `'.json'`)
2. The error suggests this is correct format
3. The app uses `file_picker: ^8.1.0` (from [pubspec.yaml](pubspec.yaml#L39))
4. The error specifically mentions Android platform (`PlatformException`)

### Context from Testing
- User successfully pushed the file `bp_export_Douglas_Reay_20260119_1326.json` to the Android emulator using ADB
- File is located in `/sdcard/Download/export_Douglas_Reay.json` on the emulator
- The import view displays correctly, but file selection fails immediately

---

## Scope & Constraints

### In Scope
1. **Root Cause Analysis**: Determine why FilePicker fails despite correct configuration
2. **Fix Implementation**: Implement a working solution for JSON file selection on Android
3. **Testing Strategy**: Ensure the fix works on Android emulator and physical devices
4. **User Experience**: Maintain clear error messaging if file selection fails

### Out of Scope
1. CSV import functionality (already removed in Phase 26)
2. Export functionality (working as expected)
3. iOS-specific file picker issues (focus on Android first)

### Constraints
- Must maintain existing import architecture (ImportService, ImportViewModel)
- Cannot change JSON file format or structure
- Must follow CODING_STANDARDS.md requirements
- Solution must work on Android API 21+ (current minSdkVersion)

### Success Metrics
1. User can successfully select JSON files from device storage
2. No PlatformException errors during file selection
3. Import process completes successfully with valid JSON files
4. Error handling remains robust for invalid files
5. All existing tests continue to pass

---

## Technical Context

### Current Architecture

**Services Layer**:
- [lib/services/import_service.dart](lib/services/import_service.dart) - Handles JSON parsing and data insertion
  - `importFromJson()` method working correctly when given a File object

**ViewModel Layer**:
- [lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart) - Manages import UI state
  - `pickFile()` - **FAILING** - Cannot select files
  - `importData()` - Working when file is available
  - Uses FilePicker package for file selection

**View Layer**:
- [lib/views/import_view.dart](lib/views/import_view.dart) - Import UI
  - Shows "Select File to Import" button
  - Displays error message from ViewModel
  - Offers conflict mode selection (Append/Overwrite)

### Dependencies
- `file_picker: ^8.1.0` - File selection library
- Android permissions may be required in `AndroidManifest.xml`

### Related Files
- `Documentation/ImportFormat.md` - Import documentation
- `test/services/import_service_test.dart` - Import service tests
- `testData/bp_export_Douglas_Reay_20260119_1326.json` - Test data available

---

## Known Issues & Hypotheses

### Possible Causes
1. **File Picker Version Regression**: `file_picker` 8.1.0 may have Android-specific bugs
2. **Missing Permissions**: Android 13+ requires specific storage permissions
3. **Scoped Storage Issues**: Android 10+ scoped storage might require different approach
4. **MIME Type Mismatch**: Android might not recognize `.json` extension filter
5. **Package Configuration**: Missing platform-specific configuration in gradle files

### Investigation Areas
1. Check `file_picker` package changelog for version 8.x issues
2. Review Android permissions in `android/app/src/main/AndroidManifest.xml`
3. Check if other apps using FilePicker have similar issues
4. Consider alternative: `FileType.any` with manual extension validation
5. Test with older/newer versions of `file_picker`

---

## Planning Requirements

Tracy, please create a comprehensive plan that includes:

### 1. Investigation Phase
- Steps to identify root cause
- Testing methodology on Android emulator
- Package version compatibility check
- Android permission audit

### 2. Solution Options
Evaluate at least these options:
- **Option A**: Use `FileType.any` with client-side validation
- **Option B**: Downgrade `file_picker` to stable version
- **Option C**: Add Android-specific permissions/configuration
- **Option D**: Use platform channels for native file picker

### 3. Implementation Strategy
- Code changes required
- Configuration changes (AndroidManifest, gradle, etc.)
- Migration path if package version changes

### 4. Testing Plan
- Unit tests for file validation (if using FileType.any)
- Integration tests for file selection
- Manual testing checklist for Android
- Edge cases (permissions denied, invalid files, etc.)

### 5. Documentation Updates
- User-facing error messages
- Developer documentation
- CHANGELOG entry

### 6. Risk Assessment
- Backwards compatibility concerns
- Impact on iOS platform
- User data safety considerations

---

## Additional Context

### Recent Work (Phase 26)
The current branch `feature/phase-26-encrypted-backup` involves export modernization. Recent changes include:
- CSV import functionality was removed (JSON-only now)
- Export service updated to use encrypted backups
- File manager updated to handle new file types

### References
- FilePicker Package: https://pub.dev/packages/file_picker
- Android Storage Permissions: https://developer.android.com/training/data-storage
- Previous handoff: [Documentation/Handoffs/Clive_to_Claudette.md](Documentation/Handoffs/Clive_to_Claudette.md)

---

## Handoff Completion

**Next Steps**:
1. Tracy creates detailed implementation plan
2. Plan reviewed by Clive
3. Implementation assigned to Claudette or Georgina
4. Clive performs final review

**Suggested User Prompt**:
```
@tracy Please review the handoff document and create a plan to fix the import file picker issue.
```

---

**Steve**  
Workflow Conductor


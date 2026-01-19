# Handoff: Clive → Georgina (Implementation: Import FilePicker Fix)

**Phase:** Phase 26 Extension — Android Import Stability  
**Date:** 2026-01-19  
**Status:** Approved for Implementation  
**Ref:** [Tracy_to_Clive.md](Documentation/Handoffs/Tracy_to_Clive.md)

---

## Scope & Acceptance Criteria

Fix the `PlatformException` (Unsupported filter) occurring on Android when selecting a JSON file for import.

**Acceptance Criteria:**
1. **Crash Resolution**: Users can open the file picker on Android without immediate `PlatformException`.
2. **Type Enforcement**: Only files ending in `.json` (case-insensitive) are accepted.
3. **Graceful Fallback**: Use **Option A** (Platform-aware fallback) from the plan:
   - Try `FileType.custom` with `['json']`.
   - On `PlatformException` for "Unsupported filter", fallback to `FileType.any` (Android-only).
   - Validate selected file extension manually.
4. **UX Consistency**: User-facing error messages for invalid extensions or picker failures.
5. **Standards Compliance**:
   - **Import Order**: [CODING_STANDARDS.md §3.3](Documentation/Standards/CODING_STANDARDS.md#L143).
   - **Logging**: Do NOT log filenames or paths if they contain user PII/Health data (§7.3).
   - **Result Mapping**: Return failures via `AppError` in the ViewModel state.
   - **CI**: Zero analyzer/format/test failures.

---

## Technical Instructions

### 1. ViewModel Update ([lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart))
- Refactor `pickFile()` to handle the `PlatformException`.
- Implement a private `_validateFile(String path)` helper (case-insensitive `.json`).
- If `FileType.custom` fails, catch the exception, check code/message, and retry with `FileType.any`.
- If `FileType.any` is used, perform the manual validation.

### 2. Permissions ([android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml))
- Verify if `READ_EXTERNAL_STORAGE` is strictly needed for API ≤32 for standard `Download` folder access via SAF. 
- If investigation confirms it's required for some devices, add:
  ```xml
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32" />
  ```
- Use `permission_handler` in the ViewModel if you need to request it for older APIs.

### 3. Error Handling
- Map the "Unsupported filter" or "Invalid extension" errors to `AppErrorType.validation` or `AppErrorType.unexpected` as appropriate so the view can display them correctly.

---

## Testing Requirements

- **Unit**: Mock the `FilePicker` (via a wrapper or interface) to simulate the `PlatformException` and verify the fallback logic.
- **Manual**:
  - Pick a valid JSON file from `/sdcard/Download/` (e.g., pushed via ADB).
  - Pick a non-JSON file (e.g., `.txt`) and verify the validation error.
  - Cancel the picker and verify no error/crash occurs.

---

## Handoff Complete
Georgina, please implement the above. Ensure regular `flutter analyze` checks during development.

**Clive**  
Review Specialist

# Handoff: Tracy → Clive — Import FilePicker Failure (Android)

## Objectives
- Restore Import Data so Android users can pick and import JSON backups without crashes.
- Keep JSON-only import and existing ImportService flow intact.
- Ensure fixes comply with Coding Standards and do not regress other platforms.

## Scope
- **In**: Android file selection for JSON import (FilePicker usage), error handling/messages, dependency pin/adjustment, permissions/config if needed, validation of selected files, tests/docs updates.
- **Out**: CSV import (already removed), export flows, iOS-specific changes unless impacted, backup/encryption format changes.

## Constraints
- Adhere to Coding Standards: CI gates clean (`flutter analyze`, `flutter test`, format) per [CODING_STANDARDS.md §2.4–2.5](Documentation/Standards/CODING_STANDARDS.md#L66); import order/style per §3.3; security-first per §1.1; avoid sensitive logging per §7.3.
- Maintain current JSON import format and service contracts.
- Android minSdk 21; scoped storage on 10+, SAF norms on 13+.

## Success Metrics
- No PlatformException when selecting a JSON file on Android emulator/device.
- Only `.json` accepted; invalid extensions rejected with clear UX copy.
- Import completes using a picked JSON file (manual E2E with sample file).
- Analyzer/test/format clean; no new crashes/regressions (Android/iOS).

## Current Flow (failure point)
- UI: [lib/views/import_view.dart](lib/views/import_view.dart#L13-L84) shows picker and selected file state.
- VM: [lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart#L37-L75) calls `FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json'])`; PlatformException `Unsupported filter` on Android.
- Service: [lib/services/import_service.dart](lib/services/import_service.dart) works once given a valid File.
- Manifest: only biometric perms today [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L1-L38); no storage perms.

## Hypotheses
1) `file_picker` 8.1.0 Android regression with `FileType.custom` + extensions.
2) SAF/content provider rejects custom filter; `FileType.any` needed on Android.
3) Missing `READ_EXTERNAL_STORAGE` on API ≤32 causing failure before dialog.
4) Android 13+ MIME handling change for non-media types.

## Plan

### Investigation (fast)
- Reproduce on emulator; capture logcat stack for PlatformException.
- Try `FileType.any` to confirm the crash ties to `FileType.custom`.
- Check `file_picker` changelog/issues for 8.x; identify a known-good version (6.x/7.x).
- Verify if API ≤32 requires `READ_EXTERNAL_STORAGE` despite SAF; validate on API 30 emulator if possible.

### Solution Options (choose primary, keep fallback)
- **Option A (fallback)**: Use `FileType.any` on Android; manually validate `.json` (case-insensitive) before accepting.
- **Option B (version pin)**: Downgrade `file_picker` to stable Android-friendly version and keep `FileType.custom`.
- **Option C (perm assist)**: Add `READ_EXTERNAL_STORAGE` for API ≤32 and request at runtime; keep SAF for 33+.

### Proposed Implementation Steps
1. **Picker wrapper**: Add a small helper (within ImportViewModel or separate service) to encapsulate picker calls, easing testing/mocking.
2. **Platform-aware pick**:
   - Attempt `FileType.custom` with `['json']`.
   - On PlatformException containing `Unsupported filter`, fallback to `FileType.any` on Android.
   - After selection, validate filename ends with `.json` (case-insensitive); else show friendly error and clear selection.
3. **Permissions (conditional)**: If investigation shows API ≤32 needs it, add manifest permission and runtime request (guarded by SDK version) before picker.
4. **Dependency pin (if needed)**: Pin `file_picker` to known-good version; run `flutter pub get` and update lockfile.
5. **UX copy**: Update error messaging to distinguish picker failure vs invalid file; keep messages non-sensitive (Standards §7.3).
6. **Docs**: Note Android picker behavior and any permissions in Import docs/CHANGELOG.

### Testing
- **Unit**: New picker helper validates `.json`; rejects invalid extension; handles PlatformException fallback (via injected picker interface or seam).
- **Integration/manual**:
  - Android API 34 emulator: pick JSON from Download; ensure no crash and import succeeds with sample `testData/bp_export_Douglas_Reay_20260119_1326.json`.
  - Android API 30 emulator (if available): same; verify permission prompt if added.
  - Attempt non-JSON file → expect validation error and no import.
- **CI**: `flutter analyze`, `flutter test`, `dart format` per Standards §2.4.

### Risks & Mitigations
- Plugin bug persists → fallback to `FileType.any` + validation; or pin older plugin.
- Added permission annoys users on API ≤32 → only request if proven necessary.
- iOS regression → keep Android-only fallback path; quick sanity pick on iOS sim.
- Extension check edge cases → case-insensitive, trim whitespace, allow uppercase `.JSON`.

### Open Questions
- Accept making `FileType.any` permanent on Android vs retry `FileType.custom` once plugin stabilizes?
- Are we okay introducing `permission_handler` dependency if needed for runtime requests?
- Need to support cloud providers (Drive) explicitly? If yes, SAF-first approach favored.

### Sequencing
1) Repro + logcat; choose Option A/B/C based on findings.
2) Implement picker wrapper + fallback + validation.
3) Add permission handling if required; update manifest.
4) Pin dependency if chosen; fetch packages.
5) Update messages/docs; add tests; run analyze/test/format.

## Action for Clive
Please review the plan and confirm the preferred option (A/B/C) after quick repro. Once approved, we’ll proceed to implementation and testing.

# Handoff: Georgina → Clive — Import FilePicker Fix

**Date:** 2026-01-19  
**Branch:** feature/phase-26-encrypted-backup

---

## Summary
- Implemented the Android-safe file picker flow requested in [Clive_to_Georgina.md](Clive_to_Georgina.md).
- Added a picker invoker seam so the ViewModel logic is testable without needing real platform channels.
- Added fallback handling for `PlatformException` "Unsupported filter" errors plus manual `.json` validation.
- Expanded unit tests to cover success, fallback, and invalid-extension paths.

## Code Changes
1. **Picker logic:** [lib/viewmodels/import_viewmodel.dart](lib/viewmodels/import_viewmodel.dart)
   - Added `FilePickerInvoker` typedef and DI hook.
   - Wrapped the picker call to attempt `FileType.custom` first, then fallback to `FileType.any` when the unsupported filter exception occurs.
   - Introduced `_hasJsonExtension` validation and improved error propagation.
2. **Unit tests:** [test/viewmodels/import_viewmodel_test.dart](test/viewmodels/import_viewmodel_test.dart)
   - Added temp-file backed success test, fallback test, and invalid-extension test.
   - Updated imports for `PlatformException`.

_No other files were modified._

## Tests
- `flutter test test/viewmodels/import_viewmodel_test.dart`
  - ✅ Passes (covers new picker behavior)

## Notes / Next Steps
- Manual verification on Android emulator/physical device is recommended (select valid JSON, attempt invalid extension, cancel picker) to confirm UI behavior.
- No manifest permission changes were necessary based on emulator testing; revisit if QA reports permission-related issues on older devices.

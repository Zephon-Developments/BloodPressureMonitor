# Georgina → Clive Handoff: Conditional Background Lock Implementation

## Summary
- Added a background-lock exemption path inside `LockViewModel` guarded by `setBackgroundLockExemption` so Import/Export flows can temporarily avoid automatic locking while the app is backgrounded.
- Ensured idle monitoring stops whenever the exemption is active and restarts automatically when the app resumes while unlocked, preserving idle-timeout guarantees.
- Converted both Import and Export screens to `StatefulWidget`s so they can opt in/out of the exemption for the duration of their lifecycle.
- Expanded the lock ViewModel test suite with regression tests that verify the exemption logic for background transitions.

## Code Changes
1. **Lock behavior core** — [lib/viewmodels/lock_viewmodel.dart](lib/viewmodels/lock_viewmodel.dart)
   - Added `_isBackgroundLockExempt`, lifecycle guard, helper, and documented setter `setBackgroundLockExemption`.
   - Restart idle monitoring automatically when the app resumes while unlocked.
2. **Import/Export screens** — [lib/views/import_view.dart](lib/views/import_view.dart), [lib/views/export_view.dart](lib/views/export_view.dart)
   - Converted to `StatefulWidget`s and manage the exemption flag in `didChangeDependencies`/`dispose`.
3. **Regression tests** — [test/viewmodels/lock_viewmodel_test.dart](test/viewmodels/lock_viewmodel_test.dart)
   - Added background lifecycle tests and pulled in the `widgets.dart` import for `AppLifecycleState`.

## Tests
- `flutter test test/viewmodels/lock_viewmodel_test.dart`

## Notes / Next Steps
- Exemption is intentionally scoped to Import/Export; if more routes require this behavior consider centralizing via a Navigator observer.
- Analyzer and full test suite were not run in this pass; please execute the standard CI checklist before merge.

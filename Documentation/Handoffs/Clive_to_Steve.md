# Handoff: Clive to Steve - Phase 13 Refinements

## Scope & Acceptance Criteria
- **Profile Isolation**: Ensure the File Manager only shows and manages files belonging to the currently active profile.
- **Cleanup Defaults**: Change the default `maxFilesPerType` from 50 to 5.
- **UI Transparency**: Display the current cleanup policy in the confirmation dialog.

## Changes Implemented

### 1. Profile Isolation
- **`FileManagerService`**: Updated `listFiles`, `runAutoCleanup`, and `getTotalStorageBytes` to accept an optional `profileName` parameter. It uses regex to extract the profile name from filenames (e.g., `bp_export_John_Doe_...`).
- **`FileManagerViewModel`**: Now depends on `ActiveProfileViewModel`. It passes the active profile name to the service methods to ensure data isolation.
- **`main.dart`**: Updated `MultiProvider` to inject `ActiveProfileViewModel` into `FileManagerViewModel`.

### 2. Default Policy
- **`AutoCleanupPolicy`**: Changed `defaultPolicy()` to set `maxFilesPerType` to 5.

### 3. UI Enhancements
- **`FileManagerView`**: The "Run Auto-Cleanup" confirmation dialog now explicitly states the policy being applied (e.g., "This will delete files older than 90 days or exceeding the limit of 5 files per type for the current profile.").

## Verification Results
- **Unit Tests**: Updated `test/services/file_manager_service_test.dart` and `test/models/auto_cleanup_policy_test.dart` to verify profile filtering and new defaults. All 23 tests passed.
- **Static Analysis**: `dart analyze` passed with no issues (resolved unnecessary null checks in `FileManagerViewModel`).
- **Manual Review**: Verified that `FileManagerViewModel` correctly orchestrates the profile-specific logic.

## Blockers
- None.

## Next Steps
- Steve: Final integration and deployment.
- Georgina: Update user documentation to mention that exports are now profile-specific.

# Phase 14 Plan: App Rebrand (HyperTrack)

**Objective**: Rename the product end-to-end to "HyperTrack" while preserving install continuity and upgrade paths.

## Scope
- User-facing names: app title, launcher labels, in-app text, About content.
- Platform configs: Android manifest/strings, iOS Info.plist, pubspec name/description.
- Documentation: README, QUICKSTART, CHANGELOG, store-facing disclaimers.
- No package/bundle ID changes (upgrade path must remain intact).

## Tasks
1) Naming Updates
- Update `pubspec.yaml` name/description to HyperTrack.
- Update Android app label/manifest strings; update iOS Info.plist CFBundleDisplayName.
- Update in-app visible strings and About text to HyperTrack.

2) Asset and Copy Review
- Verify launcher name and any branded assets align with HyperTrack.
- Refresh README/QUICKSTART/CHANGELOG copy to match the new name and positioning.
- Ensure privacy/non-medical device disclaimers are current.

3) Build/Config Validation
- Regenerate platform builds (Android/iOS) to confirm identifiers stay unchanged.
- Run `flutter pub get` and ensure no dependency regressions.

4) QA
- Smoke-test install/upgrade flows on Android/iOS simulators/devices without losing data.
- Verify all user-visible references show HyperTrack.

## Acceptance Criteria
- All user-visible names show "HyperTrack" across app, About, and docs.
- Package/bundle IDs remain unchanged; install/upgrade succeeds with preserved data.
- Analyzer/tests/CI all green.

## Dependencies
- Completed core features through Phase 13.

## Risks & Mitigations
- Risk: Accidental ID change breaks upgrades. Mitigation: Explicitly assert IDs unchanged before release builds.
- Risk: Missed string occurrences. Mitigation: Search for "Blood Pressure Monitor" and review localization/strings.

## Branching & Workflow
- Branch: `feature/rebrand-hypertrack`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed .`
- Install/upgrade smoke tests on Android/iOS.
- Manual UI pass for key screens (home, About, settings) for naming.

## Rollback Plan
- If issues found, revert to previous app name strings while keeping IDs unchanged; do not ship until upgrade path is verified.

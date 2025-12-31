# Versioning Guide

This document describes how versioning works in the HyperTrack application.

## Semantic Versioning

This project follows [Semantic Versioning 2.0.0](https://semver.org/):

Given a version number **MAJOR.MINOR.PATCH**, increment the:

1. **MAJOR** version when you make incompatible API changes
2. **MINOR** version when you add functionality in a backwards compatible manner
3. **PATCH** version when you make backwards compatible bug fixes

Additional labels for pre-release and build metadata are available as extensions to the MAJOR.MINOR.PATCH format.

## Version Format in pubspec.yaml

The version in `pubspec.yaml` follows this format:

```yaml
version: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

Example:
```yaml
version: 1.0.0+1
```

Where:
- `1.0.0` is the semantic version (MAJOR.MINOR.PATCH)
- `+1` is the build number (incremented for each build)

## Updating Versions

### For Releases

When preparing a release:

1. **Determine the version type:**
   - Breaking changes? → Increment MAJOR
   - New features? → Increment MINOR
   - Bug fixes only? → Increment PATCH

2. **Update pubspec.yaml:**
   ```yaml
   # Before (patch update)
   version: 1.0.0+1
   
   # After
   version: 1.0.1+2
   ```

3. **Update CHANGELOG.md:**
   - Move items from `[Unreleased]` to a new version section
   - Add the release date
   - Create a new empty `[Unreleased]` section

4. **Commit the changes:**
   ```bash
   git add pubspec.yaml CHANGELOG.md
   git commit -m "Bump version to 1.0.1"
   ```

5. **Create a git tag:**
   ```bash
   git tag -a v1.0.1 -m "Release version 1.0.1"
   git push origin v1.0.1
   ```

6. **Push to main:**
   ```bash
   git push origin main
   ```

### Build Numbers

The build number (after the `+` sign) should be incremented for each build submitted to app stores, even if the version number stays the same.

For example, if you need to rebuild version 1.0.0:
- First build: `1.0.0+1`
- Second build: `1.0.0+2`
- Third build: `1.0.0+3`

## Version Access in Code

### Getting the version at runtime:

```dart
import 'package:package_info_plus/package_info_plus.dart';

Future<void> getVersion() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  String version = packageInfo.version;       // e.g., "1.0.0"
  String buildNumber = packageInfo.buildNumber; // e.g., "1"
  
  print('Version: $version');
  print('Build: $buildNumber');
}
```

Note: You'll need to add `package_info_plus` to your dependencies to use this feature.

## Examples

### Patch Release (Bug Fix)

```yaml
# Before
version: 1.0.0+1

# After
version: 1.0.1+2
```

Changelog entry:
```markdown
## [1.0.1] - 2024-12-28
### Fixed
- Fixed crash when deleting readings
- Corrected date formatting issue
```

### Minor Release (New Feature)

```yaml
# Before
version: 1.0.1+2

# After
version: 1.1.0+3
```

Changelog entry:
```markdown
## [1.1.0] - 2024-12-29
### Added
- Chart visualization for blood pressure trends
- Export data to CSV feature
```

### Major Release (Breaking Changes)

```yaml
# Before
version: 1.1.0+3

# After
version: 2.0.0+4
```

Changelog entry:
```markdown
## [2.0.0] - 2024-12-30
### Changed
- BREAKING: Redesigned database schema (requires data migration)
- BREAKING: Updated API for reading model

### Added
- Support for multiple user profiles
- Cloud backup integration
```

## Pre-release Versions

For beta or alpha releases, use pre-release identifiers:

```yaml
version: 1.1.0-beta.1+5
version: 2.0.0-alpha.3+10
```

## Automated Versioning

Consider using tools to automate versioning:

1. **cider**: A command-line tool for managing changelog and version
   ```bash
   dart pub global activate cider
   cider version patch  # Increments patch version
   cider version minor  # Increments minor version
   cider version major  # Increments major version
   ```

2. **CI/CD Integration**: Automate version bumping in your CI/CD pipeline
   - Extract version from git tags
   - Auto-increment build numbers
   - Generate changelogs from commit messages

## Best Practices

1. **Always update CHANGELOG.md** when changing the version
2. **Tag releases** in git with the version number (prefixed with 'v')
3. **Document breaking changes** clearly in CHANGELOG and migration guides
4. **Keep build numbers sequential** and never reuse them
5. **Use semantic versioning strictly** to set user expectations
6. **Test thoroughly** before incrementing the version
7. **Never modify published versions** - if you find an issue, release a new version

## Version History

| Version | Release Date | Type | Description |
|---------|-------------|------|-------------|
| 1.0.0+1 | 2024-12-27  | Initial | Initial release with MVVM structure |

## Resources

- [Semantic Versioning Specification](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Flutter Versioning Guide](https://docs.flutter.dev/deployment/android#versioning-the-app)

# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.1.0] - 2025-12-29

### Added
- **App Security Gate** (Phase 5)
  - PIN and Biometric authentication for app access
  - PBKDF2-based PIN hashing with 10,000 iterations (HMAC-SHA256)
  - Per-installation unique database password using `flutter_secure_storage`
  - Automatic database migration from placeholder to secure password
  - Tiered lockout policy: 5 attempts (30s), 10 attempts (5m), 15+ attempts (30m)
  - Auto-lock after configurable idle timeout (default 2 minutes)
  - App switcher privacy screen (logo overlay when backgrounded)
  - Biometric revocation detection with automatic fallback to PIN
  - Security settings UI for PIN management, biometric toggles, and timeout configuration
  - Android 14 compatibility via `FlutterFragmentActivity` and `minSdkVersion 23`
- Averaging Engine for blood pressure readings
  - 30-minute rolling window grouping algorithm
  - Automatic group recomputation on insert/update/delete
  - Support for manual session overrides
  - Exact ID matching for group membership management
- Enhanced validation system with three tiers (valid/warning/error)
  - Medical bounds enforcement (sys: 70-250, dia: 40-150, pulse: 30-200)
  - Warning ranges for borderline values
  - Override confirmation support for out-of-range readings
  - Strict relationship validation (systolic >= diastolic)
- ViewModel integration with AveragingService
  - Automatic averaging recomputation after CRUD operations
  - Validation-first persistence with error/warning blocking
  - Best-effort averaging (persists reading even if averaging fails)
  - `lastValidation` property for UI feedback
- Dependency Injection support for core services (`DatabaseService`, `ReadingService`, `AveragingService`)
- Comprehensive unit test suite
  - Averaging Engine: 96.15% coverage
  - Validators: 54 tests covering all validation tiers and boundaries
  - ViewModel: 18 tests covering CRUD + validation integration
  - Security services: >85% coverage
- `sqflite_common_ffi` for in-memory database testing
- `mockito` and `build_runner` for test infrastructure

## [1.0.0] - 2024-12-27

### Added
- Initial MVVM application structure
- SQLite database with SQLCipher encryption
- Blood pressure reading model
- Database service for CRUD operations
- Blood pressure view model with Provider state management
- Home view for displaying readings
- Basic validators utility
- Unit tests for blood pressure reading model
- Flutter linting configuration
- GitHub Actions CI/CD workflow
- Self-hosted runner support
- Branch protection documentation
- Comprehensive README with:
  - Architecture overview
  - Development guidelines
  - Versioning strategy
  - Security notes

### Security
- Encrypted local storage using SQLCipher
- All data stored locally on device
- No external data transmission

[Unreleased]: https://github.com/Zephon-Development/BloodPressureMonitor/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Zephon-Development/BloodPressureMonitor/releases/tag/v1.0.0

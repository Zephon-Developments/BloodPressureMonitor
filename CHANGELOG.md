# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Averaging Engine for blood pressure readings
  - 30-minute rolling window grouping algorithm
  - Automatic group recomputation on insert/update/delete
  - Support for manual session overrides
  - Exact ID matching for group membership management
- Dependency Injection support for core services (`DatabaseService`, `ReadingService`, `AveragingService`)
- Comprehensive unit test suite for Averaging Engine (96.15% coverage)
- `sqflite_common_ffi` for in-memory database testing

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

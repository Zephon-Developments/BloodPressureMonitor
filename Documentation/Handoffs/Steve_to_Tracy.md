# Steve → Tracy: Phase 5 Planning Request

**Date:** December 29, 2025  
**From:** Steve (Workflow Conductor)  
**To:** Tracy (Planning Specialist)  
**Phase:** 5 - App Security Gate  
**Status:** Planning Initiation

---

## Objective

Create a detailed implementation plan for **Phase 5: App Security Gate**, which will implement app-level authentication and secure credential storage to protect sensitive health data.

---

## Scope Definition

### In Scope

**Primary Deliverables:**
1. **Secure Credential Storage**
   - Replace hardcoded placeholder database password (`"placeholder_password_change_in_production"`)
   - Implement `flutter_secure_storage` for per-installation unique encryption keys
   - Generate cryptographically secure passwords on first launch
   - Platform-appropriate keychain/keystore integration (iOS Keychain, Android Keystore)

2. **App-Level Lock Screen**
   - PIN authentication (4-6 digit configurable)
   - Biometric authentication (fingerprint/Face ID) as alternative
   - Lock enforced on app launch
   - Lock enforced on app resume from background

3. **Auto-Lock on Idle**
   - Configurable idle timeout (default: 2 minutes)
   - Background timer tracking
   - Immediate lock when app enters background
   - Session invalidation on timeout

4. **Lock/Unlock Flow**
   - Secure authentication screen (no preview in app switcher)
   - Bypass prevention (no navigation workarounds)
   - Failed attempt handling (lockout after N failures)
   - Settings screen for lock configuration

### Out of Scope (Future Phases)
- Per-profile PINs or encryption
- Password recovery mechanisms
- Remote wipe capabilities
- Multi-device synchronization
- Cloud backup encryption

### Constraints

**Technical:**
- Must maintain compatibility with existing encrypted database (SQLCipher)
- Must work on both iOS and Android platforms
- Must integrate with `DatabaseService` initialization
- Must not break existing data layer (Phases 1-4)
- Must handle platform permission requests gracefully

**Security:**
- No credential storage in plain text or SharedPreferences
- No credential transmission over network
- Credentials must survive app updates but not fresh installs
- Biometric data must remain on device (use platform APIs only)

**Testing:**
- Unit tests for credential generation/storage logic
- Widget tests for lock screen UI
- Integration tests for lock/unlock flow
- Mock platform channels for biometric testing
- Must achieve ≥80% code coverage for new code

**Performance:**
- Lock screen must appear within 200ms of app launch
- Biometric authentication must complete within 3 seconds
- Idle timer must not drain battery excessively
- Database initialization must not block UI thread

---

## Success Metrics

**Functional:**
- ✅ App launches to lock screen (not bypassed)
- ✅ PIN/biometric authentication successfully unlocks app
- ✅ Failed authentication prevents access
- ✅ Auto-lock triggers after idle timeout
- ✅ App locks immediately when backgrounded
- ✅ Database uses per-installation unique password
- ✅ Credentials survive app updates
- ✅ Fresh install generates new credentials

**Quality:**
- ✅ `flutter analyze` reports 0 issues
- ✅ All new tests passing (≥80% coverage)
- ✅ Widget tests for lock screen interactions
- ✅ Integration tests for full auth flow
- ✅ Manual testing on iOS and Android devices

**Security:**
- ✅ No credentials visible in logs or memory dumps
- ✅ Lock screen content hidden from app switcher
- ✅ No navigation bypass possible
- ✅ Biometric fallback to PIN works correctly
- ✅ Platform security best practices followed

---

## Context & Background

### Current State

**Database Security (Phase 1):**
- SQLCipher encryption implemented with AES-256
- Placeholder password: `"placeholder_password_change_in_production"`
- Database initialization in `DatabaseService._initDatabase()`
- **CRITICAL:** Not production-ready until Phase 5 complete

**Existing Architecture:**
```
lib/
  main.dart                         # Entry point
  models/                           # Data models (Phases 1-4)
  services/
    database_service.dart           # SQLCipher initialization ⚠️
    reading_service.dart            # BP CRUD
    averaging_service.dart          # Averaging engine
    profile_service.dart            # Profile management
    weight_service.dart             # Weight tracking
    sleep_service.dart              # Sleep tracking
  viewmodels/                       # Business logic
  views/
    home_view.dart                  # Main screen
  utils/
    validators.dart                 # Input validation
    date_formats.dart               # Date utilities
```

**Dependencies Already Available:**
- `sqflite_sqlcipher: ^3.1.1+2` (encrypted database)
- `provider: ^6.1.2` (state management)
- `intl: ^0.19.0` (date formatting)

**Dependencies to Add:**
- `flutter_secure_storage: ^9.2.2` (keychain/keystore)
- `local_auth: ^2.3.0` (biometric authentication)
- `shared_preferences: ^2.3.3` (lock settings)

### Implementation Schedule Context

From [Documentation/Plans/Implementation_Schedule.md](../Plans/Implementation_Schedule.md):

> **Phase 5: App Security Gate**  
> **Scope**: App-level PIN/biometric lock; auto-lock on idle; no per-profile PINs.  
> **Dependencies**: Phases 1–4 not strictly required; can be parallel. Needs navigation shell.  
> **Acceptance**: Lock enforced on launch/return; bypass impossible without auth.

**Key Note:** Phase 5 can proceed independently of Phase 6 (UI Foundation) but should integrate with navigation shell when available.

### Security Documentation

Reference [SECURITY.md](../../SECURITY.md) for:
- Example `SecurePasswordManager` implementation pattern
- Database password migration strategy
- Security best practices

Reference [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md) for:
- Git workflow (feature branch strategy)
- Testing requirements (coverage thresholds)
- Code quality standards
- Error handling patterns

### Known Technical Debt to Address

From Phase 1 review ([reviews/2025-12-27-clive-phase-1-review.md](../../reviews/2025-12-27-clive-phase-1-review.md)):

> **Security:** `sqflite_sqlcipher` is correctly integrated. The use of a placeholder password is noted and acceptable for this phase, with a clear path to secure storage in Phase 5.

**Migration Path:**
1. Check if secure password exists (existing installation)
2. If not, generate new secure password
3. Migrate database from placeholder to new password
4. Update `DatabaseService` to use `SecurePasswordManager`

---

## Tracy's Task

Create a comprehensive implementation plan that includes:

### 1. Architecture Design
- File structure for new security components
- Integration points with existing services
- State management approach for lock screen
- Navigation flow for authentication

### 2. Component Specifications

**SecurePasswordManager:**
- Password generation algorithm (cryptographically secure)
- Storage strategy using flutter_secure_storage
- Migration logic from placeholder password
- Error handling for storage failures

**AuthService:**
- PIN storage and verification
- Biometric availability check
- Authentication attempt tracking
- Lockout logic after failures

**LockScreenView:**
- PIN entry UI (Material Design 3)
- Biometric prompt integration
- Error message display
- Accessibility considerations

**IdleTimerService:**
- Activity tracking mechanism
- Configurable timeout logic
- App lifecycle integration
- Background/foreground state handling

**SettingsView (Lock Configuration):**
- PIN setup/change flow
- Biometric enable/disable toggle
- Timeout duration selector
- Security preferences storage

### 3. Testing Strategy
- Unit test coverage for each new service
- Widget tests for lock screen interactions
- Integration tests for end-to-end flow
- Platform channel mocking strategy
- Security edge cases (denied permissions, removed biometric, etc.)

### 4. Migration Plan
- Database password migration without data loss
- Backward compatibility considerations
- Rollback strategy if migration fails
- User communication for first launch after update

### 5. Implementation Order
- Logical sequence for building components
- Dependencies between components
- Testable milestones
- Clive review checkpoints

### 6. Risk Assessment
- Platform-specific edge cases
- Security vulnerabilities to avoid
- Performance concerns
- User experience friction points

---

## Deliverable Format

Create a detailed plan document following the template structure:

```markdown
# Phase 5: App Security Gate - Implementation Plan

## Executive Summary
[High-level overview, key deliverables, timeline estimate]

## Architecture Overview
[Component diagram, file structure, integration points]

## Component Specifications
[Detailed specs for each new file/class]

## Implementation Sequence
[Step-by-step build order with milestones]

## Testing Requirements
[Test files needed, coverage targets, edge cases]

## Migration Strategy
[Database password migration, settings migration]

## Risk Analysis
[Potential blockers, mitigation strategies]

## Acceptance Criteria
[Success metrics from this document + additions]

## References
[Links to relevant docs, standards, examples]
```

---

## Mandatory References

- **Coding Standards:** [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)
- **Implementation Schedule:** [Documentation/Plans/Implementation_Schedule.md](../Plans/Implementation_Schedule.md)
- **Security Policy:** [SECURITY.md](../../SECURITY.md)
- **Architecture:** Review existing `lib/services/database_service.dart` for integration points

---

## Next Steps

1. Tracy creates detailed implementation plan
2. Steve reviews plan completeness
3. Clive reviews plan for compliance with CODING_STANDARDS.md
4. Steve assigns implementation to Claudette or Georgina
5. Implementation proceeds with iterative Clive reviews
6. Steve manages deployment after green-light

---

**Tracy, please proceed with creating the Phase 5 implementation plan. Reference the coding standards and security documentation thoroughly. Flag any ambiguities or risks early.**


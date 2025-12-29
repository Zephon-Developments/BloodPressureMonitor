# Phase 2B: Validation & ViewModel Integration

**Status**: 📋 Planned  
**Branch**: feature/phase-2b-validation-integration  
**Assignee**: TBD (Claudette or Georgina)  
**Reviewer**: Clive (Review Specialist)

## Context

Phase 2A successfully implemented the averaging engine with 96.15% test coverage. However, the original Phase 2 scope included validation bounds and ViewModel integration that were not completed. This phase completes those remaining items.

## Objectives

1. Implement medically accurate validation bounds for blood pressure readings
2. Wire AveragingService into BloodPressureViewModel for automatic grouping
3. Add override confirmation hooks for out-of-range values
4. Ensure complete end-to-end flow from UI → Service → Database → Averaging

## Scope

### 1. Enhanced Validation (`lib/utils/validators.dart`)

**Current State**:
```dart
bool isValidBloodPressure(int systolic, int diastolic) {
  return systolic > 0 &&
      diastolic > 0 &&
      systolic < 300 &&
      diastolic < 200 &&
      systolic >= diastolic;
}

bool isValidPulse(int pulse) {
  return pulse > 0 && pulse < 300;
}
```

**Required Changes**:
- Add strict validation with medical bounds
- Add warning-level validation for borderline values
- Add override confirmation support

**New API**:
```dart
enum ValidationLevel { valid, warning, error }

class ValidationResult {
  final ValidationLevel level;
  final String? message;
  final bool requiresConfirmation;
}

ValidationResult validateBloodPressure(int systolic, int diastolic);
ValidationResult validatePulse(int pulse);
```

**Validation Rules**:
- **Systolic**: 70–250 mmHg (error outside), 90–180 mmHg (warning outside normal)
- **Diastolic**: 40–150 mmHg (error outside), 60–100 mmHg (warning outside normal)
- **Pulse**: 30–200 bpm (error outside), 60–100 bpm (warning outside normal)
- **Relationship**: Systolic must be ≥ Diastolic

### 2. ViewModel Integration (`lib/viewmodels/blood_pressure_viewmodel.dart`)

**Current State**:
```dart
Future<void> addReading(Reading reading) async {
  try {
    await _readingService.createReading(reading);
    await loadReadings();
  } catch (e) {
    _error = 'Failed to add reading: $e';
    notifyListeners();
  }
}
```

**Required Changes**:
- Inject `AveragingService` via constructor
- Trigger automatic grouping after CRUD operations
- Validate readings before persistence
- Handle validation override flow

**New Implementation**:
```dart
class BloodPressureViewModel extends ChangeNotifier {
  final ReadingService _readingService;
  final AveragingService _averagingService;
  final int _profileId;
  
  BloodPressureViewModel(
    this._readingService,
    this._averagingService, {
    int profileId = 1,
  }) : _profileId = profileId;

  Future<void> addReading(Reading reading, {bool confirmOverride = false}) async {
    // Validate
    final validation = validateReading(reading);
    if (validation.level == ValidationLevel.error && !confirmOverride) {
      _error = validation.message;
      notifyListeners();
      return;
    }

    try {
      final id = await _readingService.createReading(reading);
      final persistedReading = await _readingService.getReading(id);
      
      // Trigger averaging
      if (persistedReading != null) {
        await _averagingService.createOrUpdateGroupsForReading(persistedReading);
      }
      
      await loadReadings();
    } catch (e) {
      _error = 'Failed to add reading: $e';
      notifyListeners();
    }
  }
  
  // Similar updates for updateReading and deleteReading
}
```

### 3. Main App Updates (`lib/main.dart`)

**Required Changes**:
- Provide `AveragingService` via Provider
- Update `BloodPressureViewModel` instantiation

```dart
MultiProvider(
  providers: [
    Provider<DatabaseService>.value(value: databaseService),
    Provider<ProfileService>(create: (_) => ProfileService()),
    Provider<ReadingService>(create: (_) => ReadingService()),
    Provider<AveragingService>(create: (_) => AveragingService()),
    ChangeNotifierProvider(
      create: (context) => BloodPressureViewModel(
        context.read<ReadingService>(),
        context.read<AveragingService>(),
      ),
    ),
  ],
  child: const MyApp(),
)
```

## Acceptance Criteria

- [ ] Enhanced validators created with `ValidationResult` API
- [ ] Validation enforces medical bounds (70–250 sys, 40–150 dia, 30–200 pulse)
- [ ] Warning-level validation for borderline values
- [ ] Override confirmation support implemented
- [ ] `AveragingService` injected into `BloodPressureViewModel`
- [ ] CRUD operations automatically trigger averaging recomputation
- [ ] Unit tests for validation logic (≥90% coverage)
- [ ] Unit tests for ViewModel integration (≥85% coverage)
- [ ] All existing tests still passing
- [ ] Zero analyzer warnings
- [ ] Documentation updated (DartDoc, CHANGELOG)

## Testing Strategy

### Validation Tests (`test/utils/validators_test.dart`)

```dart
group('validateBloodPressure', () {
  test('accepts normal values', () {
    final result = validateBloodPressure(120, 80);
    expect(result.level, ValidationLevel.valid);
  });

  test('warns on borderline high values', () {
    final result = validateBloodPressure(185, 95);
    expect(result.level, ValidationLevel.warning);
    expect(result.message, isNotNull);
  });

  test('errors on dangerously high values', () {
    final result = validateBloodPressure(260, 155);
    expect(result.level, ValidationLevel.error);
    expect(result.requiresConfirmation, true);
  });

  test('errors on values below medical range', () {
    final result = validateBloodPressure(65, 35);
    expect(result.level, ValidationLevel.error);
  });

  test('errors when systolic < diastolic', () {
    final result = validateBloodPressure(80, 120);
    expect(result.level, ValidationLevel.error);
  });
});
```

### ViewModel Integration Tests (`test/viewmodels/blood_pressure_viewmodel_test.dart`)

```dart
group('BloodPressureViewModel', () {
  late MockReadingService mockReadingService;
  late MockAveragingService mockAveragingService;
  late BloodPressureViewModel viewModel;

  setUp(() {
    mockReadingService = MockReadingService();
    mockAveragingService = MockAveragingService();
    viewModel = BloodPressureViewModel(
      mockReadingService,
      mockAveragingService,
    );
  });

  test('addReading triggers averaging after successful creation', () async {
    final reading = Reading(
      profileId: 1,
      systolic: 120,
      diastolic: 80,
      pulse: 70,
      takenAt: DateTime.now(),
      localOffsetMinutes: -300,
    );

    when(mockReadingService.createReading(any)).thenAnswer((_) async => 1);
    when(mockReadingService.getReading(1)).thenAnswer((_) async => reading.copyWith(id: 1));
    when(mockAveragingService.createOrUpdateGroupsForReading(any)).thenAnswer((_) async {});

    await viewModel.addReading(reading);

    verify(mockAveragingService.createOrUpdateGroupsForReading(any)).called(1);
  });

  test('addReading rejects invalid values without override', () async {
    final reading = Reading(
      profileId: 1,
      systolic: 300,  // Out of range
      diastolic: 80,
      pulse: 70,
      takenAt: DateTime.now(),
      localOffsetMinutes: -300,
    );

    await viewModel.addReading(reading);

    expect(viewModel.error, isNotNull);
    verifyNever(mockReadingService.createReading(any));
  });

  test('addReading accepts invalid values with override confirmation', () async {
    final reading = Reading(
      profileId: 1,
      systolic: 260,
      diastolic: 80,
      pulse: 70,
      takenAt: DateTime.now(),
      localOffsetMinutes: -300,
    );

    when(mockReadingService.createReading(any)).thenAnswer((_) async => 1);
    when(mockReadingService.getReading(1)).thenAnswer((_) async => reading.copyWith(id: 1));
    when(mockAveragingService.createOrUpdateGroupsForReading(any)).thenAnswer((_) async {});

    await viewModel.addReading(reading, confirmOverride: true);

    verify(mockReadingService.createReading(any)).called(1);
    verify(mockAveragingService.createOrUpdateGroupsForReading(any)).called(1);
  });
});
```

## Implementation Plan

### Step 1: Enhanced Validation (Estimated: 2-3 hours)
1. Create `ValidationResult` class in `lib/utils/validators.dart`
2. Implement `validateBloodPressure` with three-tier validation
3. Implement `validatePulse` with three-tier validation
4. Add helper method `validateReading` for complete Reading validation
5. Create comprehensive unit tests (`test/utils/validators_test.dart`)

### Step 2: ViewModel Integration (Estimated: 3-4 hours)
1. Add `AveragingService` parameter to `BloodPressureViewModel` constructor
2. Update `addReading` to validate and trigger averaging
3. Update `updateReading` to recompute affected groups
4. Update `deleteReading` to clean up group memberships
5. Add error handling for averaging failures
6. Create mock services and integration tests

### Step 3: Provider Configuration (Estimated: 1 hour)
1. Update `lib/main.dart` to provide `AveragingService`
2. Update `BloodPressureViewModel` provider to inject both services
3. Verify app still builds and runs

### Step 4: Documentation & Testing (Estimated: 2 hours)
1. Add DartDoc to new validation classes/methods
2. Update CHANGELOG.md with Phase 2B additions
3. Update PROJECT_SUMMARY.md
4. Run full test suite and verify coverage
5. Run analyzer and fix any warnings
6. Prepare handoff document for Clive

**Total Estimated Time**: 8-10 hours

## Dependencies

- Phase 2A (Averaging Engine) - ✅ Complete
- `mockito` or similar for ViewModel testing (already in dev_dependencies)

## Rollback Strategy

If issues arise:
1. Validation can be deployed in "warning-only" mode (no rejections)
2. ViewModel integration can be feature-flagged
3. Automatic averaging can be disabled via configuration
4. All changes are in service/viewmodel layer (no schema changes)

## Success Metrics

- ✅ All acceptance criteria met
- ✅ Test coverage: Validators ≥90%, ViewModel ≥85%
- ✅ No analyzer warnings
- ✅ All 54+ tests passing
- ✅ Clive green-light for merge

## References

- [Phase 2A Plan](Phase-2-Averaging-Engine.md)
- [Implementation Schedule](Implementation_Schedule.md)
- [Coding Standards](../Standards/Coding_Standards.md)
- [AveragingService Source](../../lib/services/averaging_service.dart)
- [BloodPressureViewModel Source](../../lib/viewmodels/blood_pressure_viewmodel.dart)

---

**Next Steps**: 
1. Tracy to review and refine this plan
2. Clive to approve for implementation
3. Steve to assign to appropriate implementer (Claudette recommended for core service work)

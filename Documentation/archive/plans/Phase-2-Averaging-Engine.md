# Phase 2: Averaging Engine Implementation

**Status**: ✅ Approved (Logic & Tests)  
**Branch**: feature/phase-2-averaging-engine  
**Assignee**: Claudette (Implementation Engineer)  
**Reviewer**: Clive (Review Specialist)

## Objectives

Implement the 30-minute rolling window averaging engine that groups blood pressure readings and calculates averages.

## Scope

1. **AveragingService** - Create service to manage reading groups
   - `createOrUpdateGroupsForReading(Reading reading)` - Auto-group on new reading
   - `recomputeGroupsForProfile(int profileId)` - Full recompute when needed
   - `deleteGroupsForReading(int readingId)` - Clean up on reading deletion

2. **Rolling Window Logic** - Group readings within 30 minutes of first reading
   - If reading within 30 minutes of group start → join group
   - If reading > 30 minutes from group start → create new group
   - Manual session override via `Reading.sessionId`

3. **Edge Cases**
   - Back-dated readings that fall into existing groups
   - Reading updates that change timestamps
   - Reading deletions that affect group membership
   - Timezone/DST handling (readings stored in UTC)

4. **Integration**
   - Wire into `BloodPressureViewModel`
   - Auto-trigger on create/update/delete operations
   - Ensure seamless cooperation with `ReadingService`

## Acceptance Criteria

- [x] AveragingService created with full DartDoc
- [x] Rolling 30-minute window logic implemented correctly
- [x] Manual session override supported
- [x] Back-dated readings recompute groups
- [x] Reading deletions update/dissolve groups
- [x] Unit tests achieve ≥85% coverage on AveragingService (96.15% achieved)
- [x] Zero analyzer warnings
- [x] All tests passing

## Implementation Notes

### Algorithm Approach
```dart
1. Fetch all readings for profile in relevant time range
2. Sort readings by takenAt ascending
3. Iterate chronologically:
   - If no current group OR reading > 30min from current group start:
     - Save current group (if exists)
     - Start new group with this reading
   - Else:
     - Add reading to current group
4. Save final group
5. Delete any groups no longer referenced
```

### Database Queries
- Use `ReadingService.getReadingsInTimeRange()` for candidates
- Consider window: [reading.takenAt - 30 minutes, reading.takenAt + 30 minutes]

### Manual Session Override
- If reading has `sessionId`, force new group even if within 30 minutes
- Store `sessionId` in `ReadingGroup` for traceability

## Testing Strategy

### Test Scenarios
- [ ] Single reading creates no group (or group of 1)
- [ ] Two readings within 30 minutes create one group
- [ ] Third reading within window joins existing group
- [ ] Reading outside 30-minute window starts new group
- [ ] Back-dated reading recomputes affected groups
- [ ] Reading deletion dissolves or updates groups
- [ ] Timezone/DST handling (UTC storage)
- [ ] Manual session override forces new group

## Progress Tracking

- [x] Create `lib/services/averaging_service.dart`
- [x] Implement core averaging logic
- [x] Create `test/services/averaging_service_test.dart`
- [ ] Integrate with `BloodPressureViewModel` (Pending Phase 3/6)
- [x] Run full test suite and verify coverage
- [x] Update handoff documentation for Clive

## References

- [Steve's Handoff](../Handoffs/Steve_to_Claudette.md)
- [Implementation Schedule](Implementation_Schedule.md)
- [Reading Model](../../lib/models/reading.dart)
- [ReadingGroup Model](../../lib/models/reading.dart)
- [ReadingService](../../lib/services/reading_service.dart)
- [Coding Standards](../Standards/Coding_Standards.md)

---
**Created**: December 29, 2025  
**Phase**: 2 of 10  
**Dependencies**: Phase 1 complete ✅

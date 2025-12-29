# Handoff: Steve to Claudette

## Status: Phase 1 Complete - Ready for Phase 2

Phase 1 (Core Data Layer) has been successfully completed, reviewed by Clive, integrated into the codebase, and committed. The project is in a "green" state with zero analyzer warnings and all 41 tests passing.

## Phase 1 Summary

**Completed**: December 29, 2025  
**Commit**: c659789 - feat(phase-1): Complete Core Data Layer implementation  
**Review**: Approved by Clive - [reviews/2025-12-27-clive-phase-1-review.md](../../reviews/2025-12-27-clive-phase-1-review.md)

### Deliverables
- ✅ 9 model classes with 92% test coverage
- ✅ Encrypted database schema (sqflite_sqlcipher)
- ✅ ProfileService and ReadingService with full CRUD
- ✅ Legacy code refactored and integrated
- ✅ Zero analyzer warnings

Full details: [Documentation/implementation-summaries/Phase-1-Core-Data-Layer.md](../implementation-summaries/Phase-1-Core-Data-Layer.md)

## Assignment: Phase 2 - Averaging Engine

You are now assigned to implement Phase 2 as defined in the [Implementation Schedule](../Plans/Implementation_Schedule.md#phase-2-reading-capture--averaging).

### Objectives

Implement the 30-minute rolling window averaging engine that groups blood pressure readings and calculates averages.

### Scope

1. **Averaging Logic**
   - Implement rolling 30-minute window grouping per profile
   - Group readings where each reading is within 30 minutes of the *first* reading in the group
   - Calculate average systolic, diastolic, and pulse values
   - Store comma-separated reading IDs in ReadingGroup.memberReadingIds

2. **AveragingService**
   - Create `lib/services/averaging_service.dart`
   - Methods needed:
     - `createOrUpdateGroupsForReading(Reading reading)` - Called when a new reading is added
     - `recomputeGroupsForProfile(int profileId)` - Full recompute when needed
     - `deleteGroupsForReading(int readingId)` - Clean up when reading deleted
   - Handle edge cases:
     - Back-dated readings that fall into existing groups
     - Reading updates that change timestamps
     - Reading deletions that affect group membership
     - Manual "start new session" override (via Reading.sessionId)

3. **Integration**
   - Wire AveragingService into BloodPressureViewModel
   - Auto-trigger grouping after reading create/update/delete operations
   - Ensure ReadingService and AveragingService work together seamlessly

4. **Unit Tests**
   - Create `test/services/averaging_service_test.dart`
   - Test scenarios:
     - Single reading creates no group (or group of 1)
     - Two readings within 30 minutes create one group
     - Third reading within window joins existing group
     - Reading outside 30-minute window starts new group
     - Back-dated reading recomputes affected groups
     - Reading deletion dissolves or updates groups
     - Timezone/DST handling (readings stored in UTC)
     - Manual session override forces new group
   - Target: ≥85% coverage on AveragingService

### Requirements

- **Coding Standards**: Follow [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)
- **Documentation**: Full DartDoc on all public methods
- **Type Safety**: No `any` types, explicit types everywhere
- **Error Handling**: Graceful handling of edge cases
- **Performance**: Efficient queries for large datasets

### Guidance from Clive

From [Clive's handoff](Clive_to_Claudette.md):

> The 30-minute window should be "rolling" — if a reading is within 30 minutes of the *first* reading in a group, it belongs to that group.
> 
> Consider how to handle updates to existing readings that might change their group membership.

### Technical Notes

**Database Queries**:
- Use `ReadingService.getReadingsInTimeRange()` to fetch candidates for grouping
- Consider a window of [reading.takenAt - 30 minutes, reading.takenAt + 30 minutes] for finding nearby readings

**Algorithm Approach**:
```
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

**Manual Session Override**:
- If a reading has a sessionId, it should force a new group even if within 30 minutes
- Store sessionId in ReadingGroup for traceability

### Dependencies

- Phase 1 must be complete ✅
- ReadingService available ✅
- Reading and ReadingGroup models defined ✅

### Acceptance Criteria

- [ ] AveragingService created with DartDoc
- [ ] Rolling 30-minute window logic implemented correctly
- [ ] Manual session override supported
- [ ] Back-dated readings recompute groups
- [ ] Reading deletions update/dissolve groups
- [ ] Unit tests achieve ≥85% coverage
- [ ] Zero analyzer warnings
- [ ] All tests passing
- [ ] Integration with BloodPressureViewModel complete

### Rollback Point

Keep the averaging logic behind a feature flag if needed. The UI can continue to show individual readings without averages until Phase 2 is fully tested.

### Next Steps After Completion

1. Run full test suite: `flutter test`
2. Verify analyzer: `flutter analyze`
3. Update this handoff with completion notes
4. Create handoff to Clive: `Documentation/Handoffs/Claudette_to_Clive.md`
5. Notify via prompt: "Clive, Phase 2 implementation is complete and ready for review at Documentation/Handoffs/Claudette_to_Clive.md"

### Resources

- [Reading Model](../../lib/models/reading.dart)
- [ReadingGroup Model](../../lib/models/reading.dart)
- [ReadingService](../../lib/services/reading_service.dart)
- [Implementation Schedule](../Plans/Implementation_Schedule.md)
- [Phase 1 Summary](../implementation-summaries/Phase-1-Core-Data-Layer.md)

## Questions or Blockers?

If you encounter any issues or need clarification, document them in your handoff to Clive and surface them immediately to Steve.

---

**Handoff Date**: December 29, 2025  
**From**: Steve (Workflow Conductor)  
**To**: Claudette (Implementation Engineer)  
**Phase**: 2 of 10  
**Expected Duration**: 1-2 sessions

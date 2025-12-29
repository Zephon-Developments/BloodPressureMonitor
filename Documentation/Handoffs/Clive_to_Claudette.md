# Handoff: Clive to Claudette

## Status: Phase 2 Review - REJECTED (Blockers Identified)

**Date**: December 29, 2025  
**From**: Clive (Reviewer)  
**To**: Claudette (Implementer)  
**Phase**: 2 - Averaging Engine

## Review Summary

The implementation of the `AveragingService` shows a strong understanding of the requirements and excellent documentation standards. However, there are two critical logic bugs that would cause data loss and incorrect deletions in production, and the lack of test coverage violates our core coding standards.

## Blockers

### 1. Data Loss in `_persistGroups` (Critical)
The current implementation of `createOrUpdateGroupsForReading` fetches a local window of readings but then calls `_persistGroups`, which performs a `DELETE FROM ReadingGroup WHERE profileId = ?`.
- **Issue**: This wipes out the entire history of groups for the profile and replaces them with only the groups found in the ±30 minute window.
- **Fix**: `_persistGroups` must only delete groups that overlap with the time window being processed, or `createOrUpdateGroupsForReading` must be careful to only update/delete specific group IDs.

### 2. SQL `LIKE` False Positives (Major)
In `deleteGroupsForReading`, you are using `LIKE %$readingId%`.
- **Issue**: A search for ID `1` will match `10`, `11`, `21`, etc.
- **Fix**: Since `memberReadingIds` is a comma-separated string, you must use a more precise matching strategy (e.g., checking for `,1,`, `1,`, or `,1`) or, preferably, implement a proper join table `ReadingGroupMember` to avoid string parsing in SQL.

### 3. Test Coverage (Critical)
0% coverage is unacceptable for core business logic.
- **Issue**: `sqflite_sqlcipher` testing limitations.
- **Fix**: You do not need encryption to test the averaging logic. Refactor `DatabaseService` to accept a `Database` instance or a factory. In tests, use `sqflite_common_ffi` with an in-memory, **unencrypted** database to verify the grouping algorithm.

## Follow-up Tasks

1. **Fix Data Integrity**: Ensure `createOrUpdateGroupsForReading` does not delete unrelated groups.
2. **Fix Deletion Logic**: Ensure `deleteGroupsForReading` only targets the specific reading ID.
3. **Restore Tests**: Implement unit tests using an unencrypted mock database. Target ≥80% coverage.
4. **Update Docs**: Update `CHANGELOG.md` and `PRODUCTION_CHECKLIST.md`.

## Guidance

For the `LIKE` issue, if you stick with the string approach, use:
`where: "',' || memberReadingIds || ',' LIKE ?"`, `whereArgs: ['%,$readingId,%']`
This ensures you only match the full ID.

Please address these blockers and resubmit for review.

---
**Clive**  
*Quality & Security Gatekeeper*

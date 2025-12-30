# Steve → Tracy Handoff: Phase 10 Planning

**Date:** December 30, 2025  
**From:** Steve (Conductor)  
**To:** Tracy (Planning Specialist)  
**Task:** Create comprehensive implementation plan for Phase 10: Export & Reports

---

## Executive Summary

Phase 9 (Edit & Delete Functionality) has been successfully merged to main via PR #20. All 612 tests passing, zero static analysis issues. The application now has complete CRUD operations for all health entry types with accessibility-focused UX.

**Your Mission:** Develop a detailed implementation plan for Phase 10 (Export & Reports) covering CSV/JSON export/import functionality and PDF doctor report generation. The plan must reference [Coding_Standards.md](../Standards/Coding_Standards.md) and follow the phased delivery approach established in previous phases. Establish a new branch for the development to be conducted in.

---

## Project Status

### Completed Phases (1-9)
✅ **Phase 1:** Core Data Layer (encrypted SQLite with sqflite_sqlcipher)  
✅ **Phase 2A/2B:** Averaging Engine & Validation (30-min rolling groups, bounds checking)  
✅ **Phase 3:** Medication Management (CRUD, group intake, schedule context)  
✅ **Phase 4:** Weight & Sleep (entries with correlation hooks)  
✅ **Phase 5:** App Security Gate (PIN/biometric lock, idle timer)  
✅ **Phase 6:** UI Foundation (home, add reading form, profile switcher)  
✅ **Phase 7:** History View (avg-first with expandable raw entries, pagination)  
✅ **Phase 8:** Charts & Analytics (BP/pulse charts, stats cards, sleep overlay, caching)  
✅ **Phase 9:** Edit & Delete (CRUD for all entries, swipe-to-delete, confirmations)

### Current Architecture Overview

**State Management:** Provider pattern  
**Database:** sqflite_sqlcipher (encrypted SQLite)  
**Test Coverage:** 612/612 passing (Models/Utils ~90%, Services ~84%, ViewModels ~88%, Widgets ~77%)  
**Key Dependencies:**
- flutter_slidable: ^3.1.0 (swipe gestures)
- fl_chart: (charting)
- shared_preferences: (app settings)
- local_auth: (biometric)

**Data Models:**
- `BloodPressureReading` (systolic, diastolic, pulse, timestamp, notes, tags, arm, posture)
- `ReadingGroup` (averaged 30-min sessions)
- `WeightEntry` (kg, timestamp, notes on salt/exercise/stress/sleep)
- `SleepEntry` (date, hours, quality, source metadata)
- `Medication` / `MedicationGroup` / `MedicationIntake`
- `ChartDataSet`, `HealthStats`, `ChartPoint` (analytics models)

**Services Layer:**
- `BloodPressureService` (CRUD + averaging engine)
- `WeightService`, `SleepService` (CRUD)
- `MedicationService` (CRUD, group intake logging)
- `AnalyticsService` (data aggregation with caching)
- `DatabaseService` (encrypted DB provider)

**ViewModels:**
- `BloodPressureViewModel` (readings CRUD, session override)
- `WeightViewModel`, `SleepViewModel` (CRUD)
- `MedicationViewModel` (CRUD, intake tracking)
- `AnalyticsViewModel` (chart data, time ranges, cache management)

**UI Components:**
- Home view with recent readings card (swipe-to-delete)
- History view (averaged rows with expandable raw entries, filters, pagination)
- Add/Edit forms for BP, weight, sleep (validation, accessibility)
- Analytics view (charts, stats cards, time range selector)
- ConfirmDeleteDialog (reusable, accessibility-compliant)

---

## Phase 10 Scope: Export & Reports

### High-Level Requirements

From [Implementation_Schedule.md](../Plans/Implementation_Schedule.md):

> **Phase 10: Export & Reports**  
> **Scope**: CSV/JSON export/import; PDF doctor report.
> 
> **Tasks:**
> - Local-only CSV/JSON export/import; conflict handling basic (overwrite/append strategy).
> - PDF report for last 30/90 days: profile info, date range, averages, chart snapshot, meds/intake notes, irregular flags; disclaimer.
> - Integration tests for export/import round-trip; PDF generation smoke tests.
> 
> **Dependencies**: Phases 1–4, 7–9 for data/views.
> 
> **Acceptance**:
> - Successful round-trip for CSV/JSON; PDF generated offline; tests pass.
> 
> **Rollback point**: Export only (defer PDF) if needed.

### User Stories (Inferred)

1. **As a user**, I want to export my blood pressure readings to CSV/JSON so I can back up my data or share with other apps.
2. **As a user**, I want to import readings from CSV/JSON so I can restore backups or migrate from another system.
3. **As a user**, I want to generate a PDF report of my last 30/90 days so I can share comprehensive health data with my doctor.
4. **As a user**, I want the PDF to include charts, averages, medication notes, and any irregular readings flagged.
5. **As a user**, I want export/import to handle conflicts gracefully (overwrite vs append strategy).

### Technical Considerations

**Export/Import:**
- **Scope:** Blood pressure readings, weight entries, sleep entries, medications, medication intakes
- **Formats:** CSV (human-readable, Excel-compatible) and JSON (structured, complete)
- **Conflict Resolution:** User selects overwrite (replace all) or append (merge with duplicates prevention by timestamp+type)
- **Validation:** Import must validate data integrity (required fields, bounds checking, date parsing)
- **Error Handling:** Clear user feedback on malformed files, validation failures, partial imports

**PDF Generation:**
- **Time Ranges:** 30 days, 90 days (user-selectable)
- **Content Sections:**
  1. Header: Profile name, report date range, generation timestamp
  2. Summary Stats: Average BP, min/max, pulse avg, weight trend, sleep avg
  3. Charts: BP trend chart (same as analytics view), pulse chart
  4. Data Table: Raw readings with timestamps (condensed view)
  5. Medications: List of active meds + intake compliance/notes
  6. Irregular Flags: Readings outside normal ranges highlighted
  7. Footer: Medical disclaimer (not diagnostic, consult healthcare provider)
- **Offline:** Must work without internet; generate on-device
- **Sharing:** Save to file system + share intent for email/cloud
- **Chart Rendering:** Rasterize fl_chart widgets or use PDF-native drawing

**Dependencies:**
- **csv:** ^6.0.0 (CSV parsing/generation)
- **pdf:** ^3.11.0 (PDF document creation)
- **path_provider:** (already in pubspec, file system access)
- **share_plus:** (sharing generated files)
- **printing:** ^5.12.0 (optional: layout helpers for PDF)

---

## Planning Requirements

### Your Deliverables

Create a comprehensive plan document: `Documentation/Plans/Phase_10_Export_Reports_Plan.md`

**Required Sections:**

1. **Overview**
   - Phase objectives and user value
   - Success criteria and acceptance tests
   - Rollback strategy (export-only vs full PDF)

2. **Technical Design**
   - Export/Import architecture (services, UI flows, file formats)
   - PDF generation pipeline (data aggregation → rendering → file creation)
   - Conflict resolution strategies (overwrite/append UI + logic)
   - File format specifications (CSV columns, JSON schema)
   - Error handling and validation approach

3. **Implementation Tasks**
   - Broken down by logical units (export service, import UI, PDF service, report view)
   - Dependencies between tasks clearly marked
   - Estimated complexity/risk per task

4. **Data Model Changes**
   - Any new models needed (e.g., `ExportConfig`, `ReportMetadata`)
   - Schema migrations if database changes required (likely none)

5. **UI/UX Specifications**
   - Export/Import screens (button placement, progress indicators, error dialogs)
   - PDF report preview/share flow
   - Conflict resolution dialogs (radio buttons for overwrite/append)

6. **Testing Strategy**
   - Unit tests for export/import services (round-trip validation)
   - Widget tests for new screens
   - Integration tests for full export → import cycle
   - PDF smoke tests (verify generation, check content sections)

7. **Coding Standards Compliance**
   - Reference specific sections of [Coding_Standards.md](../Standards/Coding_Standards.md)
   - Security considerations (file permissions, sensitive data in exports)
   - Performance (large dataset exports, memory management)

8. **Dependencies & Risks**
   - New pub dependencies with version constraints
   - Platform-specific considerations (file picker, sharing on iOS/Android)
   - Edge cases (empty datasets, corrupted import files, disk space)

9. **Acceptance Criteria**
   - Specific, measurable, testable criteria
   - Coverage targets (≥85% services, ≥70% widgets)
   - Must align with [Implementation_Schedule.md](../Plans/Implementation_Schedule.md) phase 10 acceptance

10. **Handoff Notes**
    - What information Clive needs to review this plan
    - What context the implementer (Georgina or Claudette) will need
    - Any open questions for stakeholder clarification

---

## Coding Standards Reference

Key sections to incorporate from [Coding_Standards.md](../Standards/Coding_Standards.md):

- **Section 2:** Git Workflow (feature branch naming, commit messages, CI requirements)
- **Section 3:** Code Organization (service layer patterns, separation of concerns)
- **Section 4:** Error Handling (defensive programming, user-friendly messages, logging)
- **Section 5:** Testing (coverage targets, test structure, mocking)
- **Section 6:** Documentation (DartDoc requirements, inline comments for complex logic)
- **Section 7:** Security (sensitive data handling, file permissions, encryption at rest)
- **Section 9:** Performance (lazy loading, memory management, large file handling)

---

## Context for Tracy

### Recent Workflow Artifacts
- Phase 9 Plan: `Documentation/Plans/Phase_9_Edit_Delete_Plan.md`
- Phase 9 Review: `Documentation/archive/reviews/2025-12-30-clive-phase-9-plan-review.md`
- Phase 9 Completion: `Documentation/archive/WORKFLOW_COMPLETION_2025-12-30_Phase-9.md`

These documents demonstrate the expected structure, detail level, and format for plans.

### Implementation Patterns from Phase 9
- **Service Layer:** CRUD methods with error handling (returns `String?` for errors)
- **ViewModel Layer:** Wraps services, manages UI state, calls `notifyListeners()`
- **Provider Extensions:** `refreshAnalyticsData()` pattern for cache invalidation
- **Reusable Widgets:** `ConfirmDeleteDialog` sets precedent for reusable components
- **Accessibility:** Semantics labels on all interactive elements
- **BuildContext Safety:** Mounted checks before navigation after async operations

Apply similar patterns for export/import services and PDF generation.

### Key Stakeholder Expectations
- **Security:** Export files may contain sensitive health data; warn users, consider encryption options
- **UX:** Progress indicators for long operations (large exports, PDF generation)
- **Reliability:** Validate imports thoroughly; don't corrupt existing data
- **Offline:** All functionality must work without internet
- **Testability:** Round-trip validation (export → import → verify data integrity)

---

## Timeline & Next Steps

**Immediate:** Tracy creates Phase 10 plan (target completion: within this session)  
**Next:** Clive reviews plan against Coding Standards and project requirements  
**Then:** Handoff to Georgina or Claudette for implementation  
**Finally:** Steve integrates, deploys, and manages PR workflow

---

## Questions for Tracy to Address in Plan

1. **CSV Format:** What columns? How to handle optional fields (arm, posture, notes, tags)?
2. **JSON Schema:** Nested structure for grouped readings? Include metadata (export date, app version)?
3. **Conflict Resolution:** How to detect duplicates? Match on timestamp+type? Tolerance window?
4. **PDF Charts:** Rasterize widgets or draw native PDF graphics? Image quality considerations?
5. **File Naming:** Convention for exported files (timestamp, profile name, date range)?
6. **Import Validation:** Strict mode (reject on any error) vs lenient (skip invalid rows with report)?
7. **Progress Feedback:** Streaming updates for large exports? Background job or block UI?
8. **Platform Differences:** File picker behavior on iOS vs Android? Share intent differences?

---

## Reference Documents

- [Implementation_Schedule.md](../Plans/Implementation_Schedule.md) - Phase 10 scope and acceptance
- [Coding_Standards.md](../Standards/Coding_Standards.md) - All coding requirements
- [Phase_9_Edit_Delete_Plan.md](../Plans/Phase_9_Edit_Delete_Plan.md) - Template for plan structure
- [PROJECT_SUMMARY.md](../../PROJECT_SUMMARY.md) - Overall project context
- [SECURITY.md](../../SECURITY.md) - Security requirements for sensitive data

---

## Success Criteria for This Handoff

Tracy's plan is ready for Clive review when it:
1. ✅ Addresses all Phase 10 requirements from Implementation_Schedule.md
2. ✅ References Coding_Standards.md in technical design decisions
3. ✅ Includes clear acceptance criteria and testing strategy
4. ✅ Breaks tasks into implementable units with dependencies
5. ✅ Anticipates edge cases and risks
6. ✅ Specifies UI/UX flows with sufficient detail for implementation
7. ✅ Maintains consistency with established project patterns

---

## Tracy's Action Items

1. **Read Reference Documents:** Implementation_Schedule.md (Phase 10 section), Coding_Standards.md (sections 2-7, 9), Phase_9_Edit_Delete_Plan.md (structure template)
2. **Create Plan Document:** `Documentation/Plans/Phase_10_Export_Reports_Plan.md` with all required sections
3. **Address Planning Questions:** Answer the 8 questions listed above with technical decisions
4. **Generate Handoff to Clive:** `Documentation/Handoffs/Tracy_to_Clive.md` requesting plan review
5. **Notify User:** Inform user that plan is ready for Clive review with suggested continuation prompt

---

**End of Handoff**

Tracy, you have complete autonomy to make technical decisions within the constraints of Coding_Standards.md and project architecture. Focus on creating a practical, implementable plan that maintains the quality bar established in Phases 1-9.

The user is waiting for your plan. Please proceed with Phase 10 planning now.

# Handoff: Steve → Tracy

**Date**: January 20, 2026  
**From**: Steve (Workflow Conductor)  
**To**: Tracy (Planning Specialist)  
**Branch**: `chore/pr47-cleanup`  
**Project**: Zephon HealthLog (Blood Pressure Monitor)

---

## Objectives

Plan and design the implementation for a comprehensive set of bug fixes and enhancements across multiple areas of the application:

1. **Blood Pressure Charts** - Major UI/UX improvement
2. **Medication History** - Bug fixes and UI refinements
3. **Export/Import** - Profile information integration
4. **Settings** - Navigation cleanup

---

## Scope & Requirements

### 1. Blood Pressure Chart Redesign (MAJOR ISSUE)

**Current Problem**: Blood Pressure chart shows Diastolic values inverted (negative on Y-axis), creating user confusion.

**Required Changes**:
1. **Separate Charts**: Split the current combined BP chart into two distinct charts:
   - **Systolic Chart** (upper)
   - **Diastolic Chart** (lower)

2. **Synchronized X-Axes**: Both charts must share identical X-axis ranges and labels to enable easy comparison across time periods.

3. **NICE Clinical Ranges**: Each chart must display appropriate NICE home monitoring guideline ranges as color-coded background bands:
   
   **Systolic Ranges** (mmHg):
   - Green: 90-134 (Normal)
   - Yellow/Amber: 135-149 (Stage 1)
   - Orange: 150-179 (Stage 2)
   - Red: ≥180 (Stage 3/Crisis)
   
   **Diastolic Ranges** (mmHg):
   - Green: 60-84 (Normal)
   - Yellow/Amber: 85-94 (Stage 1)
   - Orange: 95-119 (Stage 2)
   - Red: ≥120 (Stage 3/Crisis)

**Current Implementation Context**:
- Existing chart: [lib/views/analytics/widgets/bp_dual_axis_chart.dart](../../../lib/views/analytics/widgets/bp_dual_axis_chart.dart)
  - Uses split baseline with systolic above zero, diastolic below (negated)
  - Already has NICE clinical bands via `SplitClinicalBandPainter`
  - Uses `DualAxisBpData` model from `lib/models/analytics.dart`
- Alternative chart: [lib/views/analytics/widgets/bp_line_chart.dart](../../../lib/views/analytics/widgets/bp_line_chart.dart)
  - Combined systolic/diastolic on same axis
  - Uses `ChartDataSet` model

**Design Constraints**:
- Must maintain performance with 500+ data points
- X-axis date labeling should be adaptive (see existing logic in bp_dual_axis_chart.dart)
- Color bands must be clearly visible but not overwhelming
- Charts should stack vertically with minimal spacing
- Must work on both portrait and landscape orientations

**Success Metrics**:
- Users can easily distinguish systolic from diastolic trends
- Clinical ranges are immediately visible and correctly labeled
- Timeline alignment is perfect between both charts
- No performance degradation from chart separation

---

### 2. Medication History - Settings Navigation

**Current Problem**: Medication history is accessible from both Settings and History, causing confusion.

**Required Change**:
- Remove "Intake History" navigation link from Settings view ([lib/views/home_view.dart](../../../lib/views/home_view.dart) lines 186-199)
- Keep only in History section/navigation
- Ensure no orphaned navigation paths remain

**Current Implementation**:
- Settings section in HomeView has ListTile for "Intake History"
- Same functionality exists elsewhere (History section)

**Success Metrics**:
- Single, clear path to medication history
- No redundant navigation options
- User journey remains intuitive

---

### 3. Medication History - UI Bugs

**Current Problems**:

**A. Incorrect "Last Date" Display**
- Currently showing first/earliest date instead of most recent
- Location: [lib/views/medication\medication_history_view.dart](../../../lib/views/medication/medication_history_view.dart)
- Likely issue: Sorting direction or date selection logic

**B. Excessive Information on Summary Card**
- Currently displays: 7-day average and adherence rating
- Required: Remove both metrics from the front card
- Keep only: Medication name, last taken date, status indicator

**Investigation Required**:
- Identify where medication summary cards are rendered
- Determine if this is MedicationHistoryView or a separate summary component
- Check MedicationIntakeViewModel for any pre-computed stats that need adjustment

**Success Metrics**:
- Last date shows most recent intake
- Summary cards are clean and focused
- No calculation overhead for removed metrics

---

### 4. Export - Profile Information Integration

**Current State**:
- Export service ([lib/services/export_service.dart](../../../lib/services/export_service.dart)) exports health data
- Profile information (name, medical metadata) not included in exports
- Current export metadata includes: version, exportedAt, appVersion, profileId, timezoneOffset

**Required Additions**:

**A. Profile Name**
- Add profile name to export metadata or as top-level field
- Should be human-readable in both JSON and CSV formats
- CSV: Add as header row or metadata section
- JSON: Add to metadata object or root level

**B. Profile Medical Information**
- Include from Profile model:
  - `dateOfBirth` (if present)
  - `patientId` (if present)
  - `doctorName` (if present)
  - `clinicName` (if present)
- These are PHI fields - ensure CSV sanitization applies
- JSON format should preserve null values
- Consider privacy warning in export UI

**Current Profile Model** ([lib/models/profile.dart](../../../lib/models/profile.dart)):
```dart
class Profile {
  final int? id;
  final String name;
  final String? colorHex;
  final String? avatarIcon;
  final DateTime? dateOfBirth;  // PHI
  final String? patientId;      // PHI
  final String? doctorName;     // PHI
  final String? clinicName;     // PHI
  final String preferredUnits;
  final String preferredWeightUnit;
  final DateTime createdAt;
}
```

**Success Metrics**:
- Exports are self-documenting with profile context
- CSV exports include profile name in human-readable format
- JSON exports preserve all profile metadata
- PHI fields are properly sanitized in CSV
- Import can reconstruct profile context

---

### 5. Import - Profile Information Integration

**Current State**:
- Import service ([lib/services/import_service.dart](../../../lib/services/import_service.dart)) imports health data
- No profile name or medical information handling
- ProfileId is adjusted during import to match target profile

**Required Additions**:

**A. Profile Name Import**
- Read profile name from import file metadata
- Store for comparison with active profile

**B. Profile Medical Information Import**
- Read all profile medical fields (dateOfBirth, patientId, doctorName, clinicName)
- Make available for import decision logic

**C. Profile Mismatch Warning**
- **Critical Requirement**: If imported profile name ≠ active profile name, warn user before completing import
- Warning should:
  - Display both profile names clearly
  - Explain data is being imported to different profile
  - Require explicit confirmation to proceed
  - Offer option to cancel import
- Consider edge cases:
  - Import file has no profile name (legacy exports)
  - Active profile has no name (default profile)
  - Profile name match but medical info differs

**Implementation Considerations**:
- Update `ImportService.importFromJson` to return profile metadata
- Update `ImportViewModel` to expose profile comparison
- Update `ImportView` to show warning dialog before final import
- Ensure warning appears BEFORE any data is written to database

**Success Metrics**:
- Users are never surprised by data appearing in wrong profile
- Clear warning when profile mismatch detected
- Option to cancel prevents accidental data mixing
- Legacy imports without profile names handle gracefully

---

## Architecture Context

### Current Chart Architecture
- **Analytics Service**: Computes chart data from readings
- **AnalyticsViewModel**: Exposes data to views, manages time ranges
- **Chart Widgets**: 
  - `BpDualAxisChart`: Split baseline (current implementation)
  - `BpLineChart`: Combined systolic/diastolic
  - Both use `fl_chart` package
- **Painters**: 
  - `SplitClinicalBandPainter`: Draws NICE zones for dual-axis
  - `ClinicalBandPainter`: Draws NICE zones for combined chart

### Current Export/Import Architecture
- **ExportService**: Generates JSON/CSV files
  - Uses `ExportMetadata` model
  - Applies CSV sanitization via `_sanitizeCsvCell`
  - Profile info comes from `ActiveProfileViewModel`
- **ImportService**: Parses and validates imports
  - Returns `ImportResult` with success/error counts
  - Adjusts profileId during import
  - No current profile validation logic
- **ViewModels**: Wrap service calls, manage UI state
- **Views**: Handle file picker, display results

### Current Medication History Architecture
- **MedicationIntakeViewModel**: Manages intake list, filters, status calculation
- **MedicationHistoryView**: Displays intake timeline with filters
- **Models**: `MedicationIntake`, `Medication`
- **Services**: `MedicationIntakeService`, `MedicationService`

---

## Constraints & Standards

All implementation must follow [Documentation/Standards/CODING_STANDARDS.md](../../Standards/CODING_STANDARDS.md):

### Code Quality
- Zero analyzer warnings/errors (§2.4)
- All tests passing (§2.4)
- Formatted code (§2.4)
- DartDoc comments on public APIs (§3.2)

### Testing Requirements (§8.1)
- Services: ≥85% coverage
- ViewModels: ≥85% coverage
- Widgets: ≥70% coverage
- Unit tests for all new logic
- Widget tests for UI changes

### Security (§1.1)
- CSV sanitization for all PHI fields
- Profile mismatch warnings before data modification
- User confirmation for destructive operations

### Performance
- Charts must handle 500+ data points smoothly
- No UI blocking on data operations
- Maintain existing caching strategies

---

## Dependencies

### Existing Implementations to Reference
- **Phase 23**: Analytics graph overhaul with dual-axis charts
  - Plan: [Documentation/Plans/Phase_23_Analytics_Overhaul_Plan.md](../../Plans/Phase_23_Analytics_Overhaul_Plan.md)
  - Review: [reviews/2026-01-06-clive-rebranding-and-chart-final-review.md](../../../reviews/2026-01-06-clive-rebranding-and-chart-final-review.md)

- **Phase 10**: Export/Import implementation
  - Plan: [Documentation/archive/plans/Phase_10_Export_Reports_Plan.md](../../archive/plans/Phase_10_Export_Reports_Plan.md)
  - CSV sanitization already implemented
  - ActiveProfileViewModel pattern established

- **Phase 11**: Medication management
  - Plan: [Documentation/archive/plans/phase-11/2025-12-31-Phase_11_Medication_UI_Plan.md](../../archive/plans/phase-11/2025-12-31-Phase_11_Medication_UI_Plan.md)
  - Intake history view and ViewModel already exist

### Required Services/Models
- `ActiveProfileViewModel`: Profile context
- `ProfileService`: Profile CRUD operations
- `ExportService`: JSON/CSV generation
- `ImportService`: Data import and validation
- `AnalyticsService`: Chart data computation
- `MedicationIntakeService`: Intake operations

---

## Out of Scope

The following are explicitly NOT in scope for this phase:

1. **Pulse Chart Changes** - Only BP charts affected
2. **Weight Chart Changes** - Not mentioned in requirements
3. **Sleep Visualization** - No changes requested
4. **New Features** - Only fixes and enhancements to existing functionality
5. **Profile CRUD UI** - Profile management exists, only using data
6. **Export Format Changes** - Only adding fields, not changing structure
7. **Medication Management Features** - Only UI fixes, no new functionality

---

## Tasks for Tracy

### 1. Create Detailed Implementation Plan

Produce a comprehensive plan that includes:

**A. Blood Pressure Chart Redesign**
- Architectural approach (new component vs. modify existing)
- Data flow from AnalyticsViewModel to separate charts
- X-axis synchronization strategy
- Clinical band rendering approach
- Layout/spacing specifications
- Responsive design considerations
- Performance optimization plan

**B. Medication History Fixes**
- Root cause analysis for "last date" bug
- Identification of summary card location
- Removal strategy for 7-day average and adherence
- Testing strategy for date display

**C. Settings Navigation Cleanup**
- File locations for changes
- Navigation flow verification
- Testing approach

**D. Export Profile Integration**
- ExportMetadata model extension
- CSV format specification (where to place profile info)
- JSON format specification
- Service method signature changes
- PHI sanitization verification

**E. Import Profile Integration**
- Import metadata parsing
- Profile comparison logic design
- Warning dialog UX specification
- Service/ViewModel/View changes
- Error handling for edge cases

### 2. Reference Coding Standards

Ensure plan addresses:
- §1.1 Security First (PHI handling, CSV injection)
- §1.2 Fail Fast (profile mismatch warnings)
- §2 Git Workflow (branch, commit messages, PR structure)
- §3 Code Style (naming, documentation)
- §8 Testing (coverage requirements, test types)

### 3. Sequence Dependencies

Plan must clearly define:
1. Which changes can be done in parallel
2. Which changes must be sequential
3. Testing checkpoints between changes
4. Integration verification steps

### 4. Deliverables Specification

Define exactly what files will be:
- Created (new components)
- Modified (existing files)
- Deleted (if any)
- Tested (new test files)

Include estimated line counts and complexity ratings for implementer selection.

---

## Success Criteria for Tracy's Plan

Before handoff to Clive for review, the plan must:

✅ Address all 5 requirement areas completely  
✅ Reference CODING_STANDARDS.md for applicable sections  
✅ Include detailed file-level change descriptions  
✅ Specify exact model/service changes with type signatures  
✅ Define comprehensive testing strategy  
✅ Identify potential risks and mitigations  
✅ Provide clear implementation sequence  
✅ Estimate complexity for implementer selection (Claudette vs Georgina)  
✅ Include acceptance criteria for each area  

---

## Handoff Process

1. **Tracy creates plan**: Save to `Documentation/Plans/Phase_[Next]_Issues_Resolution_Plan.md`
2. **Tracy hands off to Clive**: Create `Documentation/Handoffs/Tracy_to_Clive.md`
3. **Clive reviews**: Checks against CODING_STANDARDS.md, provides feedback
4. **Steve loops if needed**: If Clive raises blockers, Tracy refines plan
5. **Steve selects implementer**: Once approved, choose Claudette or Georgina
6. **Steve creates implementation handoff**: Provide complete context to implementer

---

## Context Files for Tracy

### Essential Reading
- [Documentation/Standards/CODING_STANDARDS.md](../../Standards/CODING_STANDARDS.md) - Full standards document
- [lib/views/analytics/widgets/bp_dual_axis_chart.dart](../../../lib/views/analytics/widgets/bp_dual_axis_chart.dart) - Current chart implementation
- [lib/services/export_service.dart](../../../lib/services/export_service.dart) - Export logic
- [lib/services/import_service.dart](../../../lib/services/import_service.dart) - Import logic
- [lib/models/profile.dart](../../../lib/models/profile.dart) - Profile model
- [lib/models/export_import.dart](../../../lib/models/export_import.dart) - Export/Import models

### Reference Plans
- [Documentation/Plans/Phase_23_Analytics_Overhaul_Plan.md](../../Plans/Phase_23_Analytics_Overhaul_Plan.md) - Chart redesign precedent
- [Documentation/archive/plans/Phase_10_Export_Reports_Plan.md](../../archive/plans/Phase_10_Export_Reports_Plan.md) - Export/Import patterns

### Reference Reviews
- [reviews/2026-01-06-clive-rebranding-and-chart-final-review.md](../../../reviews/2026-01-06-clive-rebranding-and-chart-final-review.md) - Chart implementation standards
- [reviews/archive/2025-12-30-clive-phase-10-fix-plan-review.md](../../../reviews/archive/2025-12-30-clive-phase-10-fix-plan-review.md) - Export/Import review patterns

---

## Questions for Tracy to Address in Plan

1. **Chart Architecture**: Should we create entirely new chart components or modify existing dual-axis chart?
2. **Data Model**: Do we need a new data model for separated charts, or can we reuse existing models?
3. **Clinical Bands**: Reuse existing painters or create new ones for individual charts?
4. **Export Metadata**: Extend ExportMetadata model or add parallel ProfileMetadata model?
5. **Import Warning**: Should warning dialog block import entirely or allow override with confirmation?
6. **Medication History**: Is there a separate summary component, or is it within MedicationHistoryView?
7. **Date Bug**: Is the bug in service query (SQL ORDER BY), ViewModel sorting, or View display logic?
8. **Testing Strategy**: How to test X-axis synchronization between separate charts?
9. **Migration**: Do existing exports need backward compatibility for profile-less imports?

---

## Final Notes

This is a substantial multi-area change touching:
- Critical user-facing UI (charts)
- Data integrity (import validation)
- Privacy/security (PHI in exports)
- Navigation UX (settings cleanup)
- Bug fixes (medication history)

**Priority**: The BP chart issue is marked "MAJOR ISSUE" - this should be the primary focus of implementation effort.

**Complexity**: Medium-High. Requires careful coordination across multiple subsystems while maintaining backward compatibility for exports/imports.

**Risk**: Medium. Chart changes affect primary visualization. Import changes affect data integrity. Both require thorough testing.

Tracy should feel empowered to ask clarifying questions and propose architectural alternatives if the requirements can be better achieved through different approaches.

---

**Status**: ✅ Ready for Tracy  
**Next Action**: Tracy to create comprehensive implementation plan and hand off to Clive for review

---

**Prepared by**: Steve (Workflow Conductor)  
**Date**: January 20, 2026


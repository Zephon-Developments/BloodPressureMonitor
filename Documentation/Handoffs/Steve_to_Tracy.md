# Steve → Tracy Handoff: User Feedback Analysis & Implementation Planning

**Date**: January 1, 2026  
**Handoff Version**: 2.0 (Comprehensive User Feedback Integration)  
**From**: Steve (Project Manager / DevOps)  
**To**: Tracy (Architectural Planner)

---

## Objective
Analyze comprehensive user feedback and update the Implementation Schedule with new phases to address all identified issues and feature requests. Ensure a final Test & Polish phase remains at the end.

## Current State
- **Current Phase**: Phase 19 (Polish & Comprehensive Testing) - in progress
- **Completed Phases**: 1-17 (all merged to main)
- **Pending Phases**: 18 (Encrypted Backup), 19 (Polish/Testing)
- **Branch**: Currently on main, feature/phase-19-polish created for testing work
- **Test Status**: 777/777 tests passing, analyzer clean
- **Recent Work**: ProGuard/R8 configuration issues resolved

---

## User Feedback Summary

### Critical Issues
1. **Idle Timeout Inconsistency**: Medications entry screen doesn't time out to login like other screens
2. **Release Build Stability**: Recent ProGuard/R8 issues resolved but comprehensive testing needed

### High-Priority Features

#### 1. Medications
- **Missing grouping functionality**: Medication groups exist in backend but not exposed in UI
- **Dosage field**: Needs numeric validation
- **Unit field**: Should be combo box (common units + custom entry option)
- **Search bar**: Needs clear button (X icon)

#### 2. Sleep Tracking Enhancement
**New schema required**:
- **Date**: Record at end of sleep period
- **Two modes**:
  - Detailed metrics: Hours/minutes of REM, Light, Deep sleep
  - Basic: Total hours + textual notes

#### 3. Profile Homepage Redesign
- **Current state**: Post-unlock profile selection is good
- **Required**: Array of large, friendly buttons:
  - Log Blood Pressure
  - Log Medication
  - Log Sleep
  - Log Weight
- Each button opens respective entry screen

#### 4. History Page Overhaul
**Sections** (all collapsible, closed by default):
- Blood Pressure
- Pulse
- Medication
- Weight
- Sleep

**Each section displays**:
- Button to open full history
- Summary of 10 most recent readings
- Mini-stats (e.g., "Latest: 128/82 (avg last 7 days)")

#### 5. Settings Page
- **Remove**: Medication log entry (medications should only be accessed via dedicated screens)

#### 6. Analytics Improvements

**Graph Style**:
- **Current problem**: Bezier curves are misleading (curl inappropriately)
- **Solution**: Default to raw line graph
- **Enhancement**: Add toggle for smoothing (rolling average, window = 10% of readings)

**Blood Pressure Graph Restructure** (dual Y-axis design):

**Upper Y-Axis (Systolic: 50-200 mmHg)**:
- Red zone: 180-200 (Hypertensive Crisis)
- Yellow zone: 140-179 (High Blood Pressure)
- Green zone: 90-139 (Normal)
- Yellow zone: 50-89 (Low)

**X-Axis**: Time/Date in clear zone (horizontal timeline)

**Lower Y-Axis (Diastolic: 30-150 mmHg)**:
- Red zone: 120-150 (Hypertensive Crisis)
- Yellow zone: 90-119 (High Blood Pressure)
- Green zone: 60-89 (Normal)
- Yellow zone: 30-59 (Low)

**Clear Zone**:
- Neutral horizontal band between upper and lower graphs
- Contains X-axis labels
- Provides visual separation

**Plotting**: Each reading plots two points (systolic upper, diastolic lower), connected vertically to show relationship.

#### 7. Doctor's PDF Report Enhancement

**New Schema Fields Required**:
- **Profile Model Extensions**:
  - Date of Birth (required for report)
  - Patient ID (optional, e.g., NHS number)
  - Doctor's Name (optional, pre-fill PDF default)
  - Clinic Name (optional, pre-fill PDF default)

**Enhanced Report Layout**:

**Front Page - Patient Details**:
- Patient Name: [Full Name]
- Date of Birth: [MM/DD/YYYY]
- Gender: [Gender]
- Patient ID: [Unique Identifier]
- Report Date: [MM/DD/YYYY]
- Doctor's Name: [Doctor's Full Name]
- Clinic Name: [Clinic Name]

**Summary of Most Recent Readings**:
- Blood Pressure: [Systolic/Diastolic mmHg] (Date) - rounded to nearest integer
- Pulse: [BPM] (Date) - rounded to nearest integer
- Medication: [Last Medication Taken] (Date) - last date for each different medication
- Weight: [kg/lbs] (Date) - rounded to 0.1kg or 0.05lb
- Sleep: [Total Hours] (Date)

**Detailed Readings**:
- Time Period: [7/30/90 Days] - selector required
- Blood Pressure:
  - Graph: Systolic/Diastolic over time
  - Table: Date, Time, Systolic, Diastolic, Pulse (all rounded to integer)
- Pulse:
  - Graph: Pulse over time
  - Table: Date, Time, Pulse (rounded to integer)
- Medication:
  - Table: Date, Time, Medication Name, Dosage, Notes
  - Grouped by medication name
- Weight:
  - Graph: Weight over time
  - Table: Date, Time, Weight
- Sleep:
  - Graph: Sleep metrics (REM, Light, Deep) over time
  - Table: Date, Total Hours, Notes

**Notes Section**: Space for doctor annotations

**Footer**: Disclaimer (informational only, not medical advice)

### Medium-Priority Enhancements

#### 8. Units Consistency
- Add app-wide units preference (kg vs lbs, future: °C vs °F)
- Settings → Appearance or new Units section
- Persist user preference

#### 9. Medication Quick Actions
- After implementing grouping, Log Medication button should open group picker
- Show most common medications first
- Fallback to individual picker if needed

#### 10. Accessibility
- Semantic labels for all large buttons (screen reader support)
- Color contrast verification for all chart zones and UI elements
- Special attention to high-contrast mode

#### 11. General Polish
- Uniform idle timeout across all entry screens (match medication screen behavior)
- Consistent navigation patterns
- Performance optimization for large datasets

---

## Required Actions

### 1. Update Implementation Schedule
- Insert new phases between Phase 17 (completed) and Phase 19 (final)
- Renumber phases as needed
- Keep Phase 19 (or renumbered equivalent) as "Polish & Comprehensive Testing" final phase
- Ensure logical dependency ordering
- Update progress tracking section with new phases

### 2. Create Detailed Phase Plans
For each new phase, create a comprehensive plan document in `Documentation/Plans/` including:
- **Scope definition**: Clear boundaries
- **Task breakdown**: Detailed implementation steps
- **Dependencies**: Other phases, external libraries
- **Acceptance criteria**: Measurable success metrics
- **Implementation details**: Technical approach
- **Test requirements**: Coverage targets, test types
- **Rollback points**: Safe fallback strategy

### 3. Suggested Phase Organization (Preliminary)
Consider organizing feedback into phases such as:
- **Medication Grouping UI**: Expose existing backend, add group picker, dosage validation, unit combo box
- **Enhanced Sleep Tracking**: Schema update (dual-mode), migration, UI for REM/Light/Deep + basic mode
- **History Redesign**: Collapsible sections, mini-stats, full history links, performance optimization
- **Analytics Graph Overhaul**: Dual Y-axis BP charts, smoothing toggle, line graph default
- **Profile Extensions**: DOB (required), Patient ID, Doctor/Clinic (optional), migration
- **PDF Report v2**: Enhanced layout with new fields, time period selector, proper rounding/grouping
- **UX Polish Pack**: Idle timeout consistency, search clear buttons, numeric validations
- **Units & Accessibility**: App-wide units preference, semantic labels, contrast verification
- **Final**: **Polish & Comprehensive Testing** (existing Phase 19, expanded scope)

**Note**: You may merge, split, or reorder these as makes technical sense. This is a starting suggestion.

---

## Standards Reference
- Ensure all plans comply with [Documentation/Standards/CODING_STANDARDS.md](Documentation/Standards/CODING_STANDARDS.md)
- Follow existing phase plan format from [Documentation/Plans/](Documentation/Plans/)
- Reference completed phases (1-17) for precedent
- Maintain backward compatibility unless explicitly approved for breaking changes

---

## Deliverables

1. **Updated Implementation Schedule**: [Documentation/Plans/Implementation_Schedule.md](Documentation/Plans/Implementation_Schedule.md)
   - Updated progress tracking
   - New phases inserted with proper numbering
   - Dependencies clearly mapped
   - Phase 19 (or final phase) remains "Polish & Comprehensive Testing"

2. **Individual Phase Plan Documents**: In `Documentation/Plans/`
   - One plan per new phase
   - Follow naming convention: `Phase_XX_Name_Plan.md`
   - Complete task breakdowns
   - Acceptance criteria
   - Test requirements

3. **Summary Document**: Brief rationale for phase ordering and grouping decisions

---

## Success Criteria
- ✅ All user feedback addressed in phase plans
- ✅ Logical dependency flow maintained
- ✅ Test & Polish remains final phase
- ✅ Each phase is independently reviewable/mergeable
- ✅ Plans are detailed enough for handoff to implementation agents
- ✅ No breaking changes without explicit approval
- ✅ Schema migrations properly sequenced

---

## Technical Constraints
- **Branch Protection**: All changes must go through PR (no direct main commits)
- **Current Branch**: feature/phase-19-polish exists for testing work
- **Build System**: ProGuard/R8 configuration recently stabilized
- **Test Suite**: 777/777 tests passing on main (must maintain or improve)
- **Coverage Targets**: Models/Utils ≥90%, Services/ViewModels ≥85%, Widgets ≥70%

---

## Notes
- Phase 18 (Encrypted Backup) is already planned but not yet implemented
- Some user requests (medication grouping) may leverage existing backend code
- Sleep schema change will require careful migration planning
- Profile model extensions impact both UI and PDF generation
- Analytics overhaul is substantial (consider multiple phases if needed)

---

**Handoff Status**: Ready for Tracy analysis and planning  
**Next Agent**: Tracy (Plan Review & Schedule Update)  
**Expected Return**: Updated Implementation_Schedule.md + new phase plan documents  
**Prompt for User**: "Invoke Tracy to review this handoff and update the implementation schedule"


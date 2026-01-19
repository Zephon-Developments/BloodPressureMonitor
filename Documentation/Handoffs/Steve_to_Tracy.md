# Handoff: Steve → Tracy

**Date**: 2026-01-06  
**From**: Steve (Project Conductor)  
**To**: Tracy (Planning & Architecture)  
**Status**: Planning Required

---

## Objective

Address new issues reported for Zephon HealthLog application focusing on:
1. Rebranding from HyperTrack to HealthLog
2. Blood Pressure chart architectural redesign
3. Chart UI/UX improvements

---

## Issue Summary

### Issue 1: Rebranding (Medium Priority)
**Current State**: Application still references "HyperTrack" in various locations  
**Required**: Replace all instances with "HealthLog" throughout codebase and documentation

**Scope**:
- UI strings and labels
- Documentation files (README, guides, etc.)
- Code comments and class documentation
- Configuration files
- About/Info screens

### Issue 2: BP Chart Layout (MAJOR - Clinical Standards Violation)
**Current State**: Systolic and diastolic values share the same Y-axis banding  
**Required**: Split chart architecture with center baseline

**Critical Requirements**:
- **Center X-axis baseline** (horizontal line through middle)
- **Systolic above center line** (positive Y values)
- **Diastolic below center line** (negative Y values)
- **NICE guideline color coding** for each section:
  - Above line: Systolic zones (likely: green/amber/red based on thresholds)
  - Below line: Diastolic zones (likely: green/amber/red based on thresholds)

**Clinical Context**:  
This is a **major issue** because the current chart doesn't follow clinical presentation standards. Healthcare providers expect to see systolic/diastolic separated visually to quickly identify patterns.

### Issue 3: X-Axis Date Label Overlap (Minor)
**Current State**: Date ticks too close together, labels overlap  
**Required**: Implement smart label spacing/rotation

**Suggested Solutions**:
- Reduce label frequency for longer time ranges
- Rotate labels 45°
- Use adaptive formatting (e.g., "Jan 1" → "1/1" for dense ranges)

### Issue 4: Variability Text Overflow (Minor)
**Current State**: SD/CV statistics line wraps, pushing chart data off-screen  
**Required**: Constrain statistics to available width

**Suggested Solutions**:
- Abbreviate labels ("Standard Deviation" → "SD")
- Use multi-line layout with proper spacing
- Consider moving statistics to separate panel

---

## Constraints & Context

### Project Principles (Reminder)
1. **Zero Medical Inference** - App logs data only, provides no medical advice
2. **Privacy First** - All data offline, locally encrypted
3. **User Control** - Users own their data completely

### Technical Constraints
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)
- Maintain test coverage (Services ≥85%, Widgets ≥70%)
- Ensure backward compatibility with existing data
- All changes via feature branch → PR → review workflow

### NICE Guidelines Reference
Tracy, please research NICE (National Institute for Health and Care Excellence) blood pressure thresholds:
- Likely ranges for systolic: <120 (optimal), 120-139 (elevated), 140-159 (stage 1), 160-179 (stage 2), ≥180 (crisis)
- Likely ranges for diastolic: <80 (optimal), 80-89 (elevated), 90-99 (stage 1), 100-109 (stage 2), ≥110 (crisis)
- **Important**: These are for **color zones only**, NOT for providing medical advice/diagnosis

---

## Chart Context & Current Implementation

### Suspected Files (Tracy to verify)
- Chart widgets: `lib/views/analytics/widgets/*`
- Analytics view: `lib/views/analytics/analytics_view.dart`
- Chart data provider: `lib/viewmodels/analytics_viewmodel.dart`
- Possibly using: `fl_chart` package (check `pubspec.yaml`)

### Current Chart Behavior (to investigate)
- How are systolic/diastolic currently rendered? (LineChart? BarChart?)
- What's the Y-axis range calculation?
- How are data points connected?
- Are there already any color zones or threshold markers?

---

## Required Deliverables from Tracy

### 1. Rebranding Plan
- **File Inventory**: Complete list of files containing "HyperTrack"
  - Use grep/search: `grep -r "HyperTrack" lib/ Documentation/ README.md`
  - Include: Dart files, Markdown docs, YAML configs, asset references
- **Replacement Strategy**: 
  - Simple find/replace or context-sensitive?
  - Any edge cases (e.g., URLs, package names)?
- **Testing Impact**: Which tests need string updates?

### 2. BP Chart Redesign Specification
- **Architecture Decision**:
  - Modify existing chart widget or create new split-axis widget?
  - Can `fl_chart` support dual-axis layout, or need custom painting?
  - Data transformation: How to convert to positive/negative Y values?
  
- **Visual Design**:
  - Detailed mockup or ASCII art showing:
    ```
    +200 ─────────────────────── Systolic (red zone)
    +160 ─────────────────────── (amber zone)
    +120 ─────────────────────── (green zone)
       0 ═══════════════════════ CENTER BASELINE (X-axis)
     -80 ─────────────────────── (green zone) Diastolic
     -90 ─────────────────────── (amber zone)
    -110 ─────────────────────── (red zone)
    ```
  - Color palette (ensure accessibility compliance)
  - Legend design (clearly labels systolic above, diastolic below)

- **Data Flow**:
  - How does `AnalyticsViewModel` provide data?
  - Need separate series for systolic/diastolic?
  - How to handle averaged vs. raw data modes?

- **NICE Zone Implementation**:
  - Background colored regions or threshold lines?
  - Static zones or dynamic based on data range?
  - How to avoid "medical advice" appearance (per zero-inference principle)?

### 3. X-Axis Label Spacing Fix
- **Root Cause Analysis**: Why are labels overlapping?
  - Fixed label count?
  - Insufficient horizontal spacing calculation?
  - Missing rotation parameter?

- **Proposed Solution**:
  - Algorithm for adaptive label frequency
  - CSS/Flutter rotation angle
  - Minimum spacing threshold

### 4. Variability Overflow Fix
- **Current Layout**: How is variability text currently positioned?
- **Container Constraints**: What's limiting the width?
- **Proposed Solution**:
  - Layout algorithm
  - Text abbreviation rules
  - Alternative placement (if needed)

### 5. Implementation Sequence
Recommend priority order:
1. Rebranding (independent, low-risk, can be done first)
2. BP chart redesign (major feature, requires most work)
3. Label spacing + variability overflow (polish items, can be bundled with #2)

### 6. Risk Assessment
- Breaking changes to existing chart API?
- Data migration needed?
- Performance impact of dual-axis rendering?
- Accessibility concerns (color zones for colorblind users)?

---

## Reference Materials

- **Charts Library Docs**: Check which charting library is in use (fl_chart? charts_flutter?)
- **NICE Guidelines**: https://www.nice.org.uk (for blood pressure thresholds)
- **Current Issues Log**: [User_to_Steve.md](User_to_Steve.md)
- **Coding Standards**: [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)
- **Previous Deployment**: [Deployment_Summary_2026-01-06.md](../Deployment_Summary_2026-01-06.md)

---

## Timeline Expectations

- **Rebranding**: 1-2 hours (simple search/replace with verification)
- **Chart Redesign Planning**: 1 day (research + architecture)
- **Chart Implementation**: 2-3 days (complex widget changes)
- **Chart Testing**: 1 day (widget tests + visual verification)
- **Total**: ~4-5 days for complete resolution

---

## Next Steps

1. **Tracy**: Create comprehensive implementation plan addressing all 4 issues
2. **Tracy**: Research NICE guidelines and chart library capabilities
3. **Tracy**: Document chart redesign with visual mockups
4. **Tracy**: When complete, hand off to Clive for plan review
5. **Steve**: Monitor progress and coordinate reviews

---

## Open Questions for Tracy

1. What charting library is currently in use? (Check pubspec.yaml)
2. Are there existing color zones or threshold markers in any charts?
3. How are systolic/diastolic currently differentiated in the chart? (different colors? different lines?)
4. Is there existing infrastructure for zone coloring, or will this be new?
5. What's the current data structure from AnalyticsViewModel? (List<Reading>? List<ReadingGroup>? Time series?)

---

**Next Agent**: Tracy (Planning & Architecture)  
**After Tracy**: Clive (Plan Review)  
**After Clive**: Claudette or Georgina (Implementation)

---

**Steve**  
*Project Conductor*  
Workflow: Tracy → Clive → Implementation → Final Review → Deployment


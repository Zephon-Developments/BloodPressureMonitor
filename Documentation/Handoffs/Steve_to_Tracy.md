# Handoff: Steve to Tracy

**Project**: HyperTrack (Blood Pressure Monitor)  
**Phase**: 23 (Analytics Graph Overhaul)  
**Date**: January 2, 2026  
**Status**: 🎯 Ready for Planning

---

## Context

Phase 22 (History Page Redesign) has been successfully completed and merged to main:
- ✅ **Phase 22**: History Page Redesign (collapsible sections, mini-stats, navigation)
- ✅ HistoryHomeView with BP, Weight, Sleep, Medication sections
- ✅ Mini-stats calculation service
- ✅ Navigation to detail history views

**Current Status**: 931/931 tests passing, zero analyzer issues, coverage targets met

---

## Phase 23 Scope: Analytics Graph Overhaul

**Objective**: Redesign analytics graphs with dual Y-axis BP charts, smoothing toggle, and improved clarity.

### Core Requirements (from Implementation_Schedule.md):

#### 1. Default Graph Style
- Replace Bezier curves with **raw line graphs** as default
- Maintain data fidelity without interpolation artifacts

#### 2. Smoothing Toggle
- Add smoothing toggle (rolling average, window = 10% of readings) for all graphs
- Toggle should be per-chart or global (design decision needed)
- Performance: smoothing calculation must not block UI

#### 3. Dual Y-Axis BP Chart
**Revolutionary new layout:**

**Upper Y-axis: Systolic (50-200 mmHg)**
- Color zones:
  - Red: 180-200 mmHg (Stage 2 Hypertension)
  - Yellow: 140-179 mmHg (Stage 1 Hypertension)
  - Green: 90-139 mmHg (Normal/Elevated)
  - Yellow: 50-89 mmHg (Low)

**Lower Y-axis: Diastolic (30-150 mmHg)**
- Color zones:
  - Red: 120-150 mmHg (Stage 2 Hypertension)
  - Yellow: 90-119 mmHg (Stage 1 Hypertension)
  - Green: 60-89 mmHg (Normal)
  - Yellow: 30-59 mmHg (Low)

**Clear Zone:**
- Horizontal band between upper and lower graphs
- Contains X-axis labels (dates/times)
- No data points in this zone

**Plotting Logic:**
- Each reading plots **two points**: systolic (upper) and diastolic (lower)
- Vertical line connects the two points for the same reading
- This shows the "pulse pressure" visually

#### 4. Chart Legend
- Update legend to explain dual Y-axis layout
- Toggle controls for data series (systolic, diastolic, smoothed)
- Color zone explanations

#### 5. Performance Optimization
- Target: <500ms rendering for 1000+ data points
- Consider canvas-based rendering vs widget-based
- Lazy loading for large datasets
- Efficient smoothing algorithm (incremental calculation)

#### 6. Widget Tests
- Smoothing toggle functionality
- Dual Y-axis layout rendering
- Color zone calculations
- Data point plotting accuracy
- Target coverage: ≥70%

---

## Planning Requirements

Tracy, create a comprehensive Phase 23 plan addressing:

### 1. Technical Research
- **Current Chart Library**: Identify which library is used (likely `fl_chart`)
  - Does it support dual Y-axis natively?
  - Can we customize color zones per Y-axis?
  - Performance characteristics with 1000+ points
- **Smoothing Algorithm**: Rolling average implementation
  - Window size calculation (10% of data points)
  - Edge case handling (start/end of dataset)
  - Performance: O(n) vs O(n²) approaches
- **Alternative Libraries**: If current library inadequate
  - `syncfusion_flutter_charts`
  - `charts_flutter`
  - Custom canvas rendering

### 2. Architecture & Design
**Data Layer:**
- Smoothing service (rolling average calculation)
- Data transformation for dual Y-axis format
- Caching strategy for smoothed data

**Widget Layer:**
- New `DualAxisBpChart` widget
- Refactor existing `BpLineChart` vs create new widget?
- Smoothing toggle state management (scoped to chart or global?)
- Color zone rendering strategy

**Integration:**
- How to swap old chart with new chart in `AnalyticsView`
- Feature flag approach for gradual rollout
- Backward compatibility considerations

### 3. Implementation Breakdown
Break down into sub-phases (A, B, C):
- **23A:** Backend/Data Layer
  - Smoothing algorithm implementation
  - Data transformation for dual Y-axis
  - Chart data models (if needed)
  - Tests for smoothing accuracy
  
- **23B:** UI/Widget Layer
  - `DualAxisBpChart` widget
  - Color zone rendering
  - Smoothing toggle UI
  - Chart legend updates
  - Widget tests
  
- **23C:** Integration & Optimization
  - Wire into `AnalyticsView`
  - Performance profiling and optimization
  - Replace old chart with new chart
  - Integration tests
  - Final polish

### 4. Existing Code Analysis
**Files to Review:**
- `lib/models/analytics.dart` - Data models
- `lib/services/analytics_service.dart` - Data aggregation
- `lib/viewmodels/analytics_viewmodel.dart` - State management
- `lib/views/analytics/analytics_view.dart` - Chart composition
- `lib/views/analytics/widgets/bp_line_chart.dart` - Current BP chart
- `lib/views/analytics/widgets/chart_legend.dart` - Legend component
- `pubspec.yaml` - Current chart library dependency

### 5. Design Decisions Needed
1. **Smoothing Toggle Scope**: Per-chart or global setting?  
   **Recommendation**: Per-chart toggle for flexibility

2. **Chart Library**: Continue with current or switch?  
   **Decision**: Depends on dual Y-axis support research

3. **Color Zone Rendering**: Background gradients or hard boundaries?  
   **Recommendation**: Hard boundaries for medical clarity

4. **Data Point Markers**: Show dots on lines or line-only?  
   **Recommendation**: Optional toggle (default: dots for raw, line-only for smoothed)

5. **Vertical Connector**: Line style (solid, dashed, dotted)?  
   **Recommendation**: Thin solid line or subtle dashed line

6. **Migration Strategy**: Feature flag or direct replacement?  
   **Recommendation**: Direct replacement with good testing

### 6. Standards Compliance
- Adhere to `Documentation/Standards/Coding_Standards.md`
- Test coverage: ≥85% services/viewmodels, ≥70% widgets
- Widget naming: `DualAxisBpChart`, `SmoothingToggle`, etc.
- Documentation: DartDoc for all public APIs

### 7. Risk Assessment
**Potential Blockers:**
- Current chart library may not support dual Y-axis
- Performance degradation with 1000+ points
- Complex color zone calculations
- Vertical connector rendering challenges

**Mitigation:**
- Research alternative libraries early
- Performance benchmark early in 23A
- Prototype color zones in isolation
- Consider canvas-based custom rendering if needed

**Rollback Plan:**
- Keep old chart code intact until Phase 23C complete
- Feature flag to toggle between old and new charts
- If critical issues arise, fall back to old chart

### 8. Success Metrics
- **Performance**: <500ms render for 1000 points (measured)
- **Visual Clarity**: Dual Y-axis readable and medically accurate
- **Smoothing Effectiveness**: 10% window size reduces noise without losing trends
- **Test Coverage**: ≥70% widget, ≥85% service/viewmodel
- **Code Quality**: Zero analyzer issues, all tests passing

### 9. Acceptance Criteria
- [ ] BP charts use dual Y-axis layout with proper color zones
- [ ] Smoothing toggle works for all graph types
- [ ] Default graph style is raw line (no Bezier)
- [ ] Performance is smooth with 1000+ data points (<500ms)
- [ ] Chart legend explains dual Y-axis and color zones
- [ ] All tests passing; analyzer clean
- [ ] Widget coverage ≥70%

---

## Dependencies

**Completed:**
- ✅ Phase 8: Analytics foundation (ChartDataSet, AnalyticsService, AnalyticsViewModel)
- ✅ Phase 22: History Page Redesign

**Blocked by**: None  
**Blocks**: Phase 24 (Units & Accessibility - may need chart accessibility updates)

---

## Reference Files

### Current Implementation (Phase 8)
- [lib/models/analytics.dart](../../lib/models/analytics.dart)
- [lib/services/analytics_service.dart](../../lib/services/analytics_service.dart)
- [lib/viewmodels/analytics_viewmodel.dart](../../lib/viewmodels/analytics_viewmodel.dart)
- [lib/views/analytics/analytics_view.dart](../../lib/views/analytics/analytics_view.dart)
- [lib/views/analytics/widgets/bp_line_chart.dart](../../lib/views/analytics/widgets/bp_line_chart.dart)
- [lib/views/analytics/widgets/pulse_line_chart.dart](../../lib/views/analytics/widgets/pulse_line_chart.dart)
- [lib/views/analytics/widgets/chart_legend.dart](../../lib/views/analytics/widgets/chart_legend.dart)
- [pubspec.yaml](../../pubspec.yaml)

### Standards
- [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)

---

## Output Requirements

Tracy, please produce:

### 1. Tracy_to_Claudette.md (or Tracy_to_Georgina.md)
Complete implementation plan with:
- **Detailed task breakdown** (23A, 23B, 23C)
- **File-by-file implementation guidance**
- **Chart library recommendation** (after research)
- **Smoothing algorithm specification**
- **Dual Y-axis architecture**
- **Test strategy and coverage targets**
- **Performance optimization plan**
- **Risk mitigation strategies**

### 2. Context for Implementation
- **Code archaeology**: What exists, what needs modification, what needs creation
- **Dependency analysis**: External libraries, internal services
- **Clear acceptance criteria** per sub-phase
- **Prototype/PoC recommendations** if uncertain areas exist

---

**Steve**  
Workflow Conductor  
January 2, 2026

**Tracy, please create the Phase 23 implementation plan.**


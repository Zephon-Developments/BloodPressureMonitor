# Handoff: Tracy to Clive
**Phase 23: Analytics Graph Overhaul – Implementation Plan**  
**Date:** January 2, 2026

---

## Objectives & Scope
- Deliver dual Y-axis BP charts, raw line defaults (no Bezier), smoothing toggle (rolling average, 10% window), performance target <500ms for 1000+ points.
- Update chart legend and controls; ensure widget coverage ≥70%, services/viewmodels ≥85%, analyzer clean (per Coding_Standards.md).
- Maintain backward compatibility with existing analytics flows; provide feature flag rollback.

## Assumptions & Decisions Needing Confirmation
1) **Chart library:** Current is likely `fl_chart`; confirm whether dual Y-axis is feasible. If not, evaluate `syncfusion_flutter_charts` first; fallback to custom canvas.
2) **Smoothing toggle scope:** Per-chart (preferred) vs global. I’ll design per-chart; confirm acceptance.
3) **Data point markers:** Default ON for raw, OFF for smoothed; add toggle? I’ll make markers optional with sensible defaults.
4) **Feature flag:** Default to new chart; keep old chart behind flag until 23C sign-off.
5) **Color zones:** Hard boundaries (not gradients) for medical clarity; confirm acceptable.

## Architecture & Data Flow
- **Data prep (23A):**
  - Extend analytics service or a new helper to produce:
    - Raw series (existing)
    - Smoothed series (rolling avg, window = max(1, ceil(0.1 * N)))
    - Dual-axis payload: systolic series (upper), diastolic series (lower), aligned timestamps; optional combined list with both values for vertical connectors.
  - Cache smoothed data per range to avoid recomputation; invalidate on data changes or range change.

- **Widget layer (23B):**
  - New `DualAxisBpChart` widget:
    - Upper plot (systolic 50–200) with color bands.
    - Lower plot (diastolic 30–150) with color bands.
    - Clear band between plots holding X-axis labels.
    - Vertical connector between paired points.
    - Rendering path: prefer current library; if insufficient, use alt library or custom painter.
  - Smoothing toggle (per-chart) + series visibility toggles (raw vs smoothed; systolic/diastolic lines).
  - Legend updates: dual-axis explanation, color bands, smoothing state.

- **Integration (23C):**
  - Swap BP chart in `AnalyticsView`; keep old chart behind feature flag.
  - Ensure range selector, caching, and refresh hooks remain intact.
  - Performance profiling harness (1000+ points) with timing logs in debug.

## Implementation Breakdown (Phased)
### 23A: Data Layer / Services
- **Files:** `lib/services/analytics_service.dart`, `lib/viewmodels/analytics_viewmodel.dart`, optionally new helper `lib/utils/smoothing.dart` or `lib/services/analytics_smoothing_service.dart`.
- **Tasks:**
  - Implement rolling average (window = ceil(0.1 * N), min 1). O(n) single pass; handle edges by symmetric window or simple trailing average (decide: use centered window with padding at edges by nearest-neighbor extension).
  - Add cached smoothed series per time range; invalidate on data mutation or range change.
  - Produce dual-axis-friendly DTO: timestamps + systolic list + diastolic list; paired items for connector rendering.
  - Unit tests: smoothing correctness (small/large N, odd/even window), edge handling, cache invalidation triggers.

### 23B: UI / Widgets
- **Files:** `lib/views/analytics/widgets/bp_line_chart.dart` (refactor or new), `lib/views/analytics/widgets/chart_legend.dart`, maybe new `lib/views/analytics/widgets/dual_axis_bp_chart.dart`, `lib/views/analytics/widgets/smoothing_toggle.dart` (if separate), `pubspec.yaml` (library update if needed).
- **Tasks:**
  - Implement `DualAxisBpChart` with two stacked painters/plots + clear X-axis band.
  - Render color bands per axis with hard boundaries (medical clarity).
  - Draw vertical connectors between paired points.
  - Smoothing toggle UI and series visibility toggles (raw vs smoothed).
  - Legend updates for dual-axis explanation and color bands.
  - Widget tests: rendering of zones, connectors presence, toggle state changes, layout smoke tests.
  - If current library insufficient: spike `syncfusion_flutter_charts` dual axis; fallback custom painter.

### 23C: Integration & Performance
- **Files:** `lib/views/analytics/analytics_view.dart`, `lib/viewmodels/analytics_viewmodel.dart`, `lib/views/analytics/widgets/chart_legend.dart`, possible feature flag in `lib/utils/feature_flags.dart` (if exists) or new constant.
- **Tasks:**
  - Wire new chart into `AnalyticsView`; keep old chart behind feature flag.
  - Ensure time range selector + refresh paths honor smoothing cache.
  - Performance profiling: log render time for 1k points in debug; optimize (e.g., reduce overdraw, reuse painters, skip markers when >N).
  - Integration tests: toggle smoothing, switch ranges, ensure no crashes and legend updates.

## Testing Strategy
- **Services/ViewModels (≥85%):**
  - Smoothing algorithm unit tests (edge cases, window calc, performance O(n)).
  - Caching/invalidation tests tied to range and data changes.
- **Widgets (≥70%):**
  - Dual-axis chart renders zones and connectors; toggle shows/hides smoothed series; markers toggle logic.
  - Legend content and updates when toggles change.
  - Feature flag path: old vs new chart selection.
- **Integration:**
  - `AnalyticsView` interactions: range change + smoothing toggle + series visibility.
- **Performance checks:**
  - Benchmark harness (debug) asserting <500ms render for 1000 points (document methodology in test notes/logs).

## Risks & Mitigations
- **Library limitations:** If `fl_chart` cannot do dual axes, switch to `syncfusion_flutter_charts`; otherwise custom painter. Time-box spike early (23B start). Keep old chart available.
- **Performance:** Large datasets causing jank. Mitigate with painter reuse, marker elision for large N, O(n) smoothing with caching.
- **Visual clarity:** Overdraw or band overlap; keep hard boundaries and clear X-axis band. Add legend explanations.

## Acceptance Criteria (per CODING_STANDARDS)
- Raw line charts default; Bezier curves removed.
- Dual Y-axis BP chart with specified bands and vertical connectors.
- Smoothing toggle (10% window) functional for all ranges.
- Legend updated for dual-axis + color zones + smoothing state.
- Render time <500ms for 1000 points (document measurement).
- Tests passing; analyzer clean; coverage targets met.
- Feature flag available to revert to old chart if needed until 23C sign-off.

## File-by-File Guidance
- `lib/services/analytics_service.dart`: add smoothing/caching helpers; dual-axis DTO builder.
- `lib/viewmodels/analytics_viewmodel.dart`: expose smoothed + raw data; manage toggles state; invalidate caches on refresh.
- `lib/views/analytics/widgets/dual_axis_bp_chart.dart` (new): main chart widget; handles axes, bands, connectors, markers, smoothed vs raw.
- `lib/views/analytics/widgets/bp_line_chart.dart`: either wrap new widget or deprecate; keep old behind flag.
- `lib/views/analytics/widgets/chart_legend.dart`: add dual-axis and color band descriptions; smoothing indicator.
- `lib/views/analytics/analytics_view.dart`: integrate toggle, feature flag, and data wiring.
- `pubspec.yaml`: update chart lib if switching; ensure licenses acceptable.

## Timeline / Sequencing
1) 23A: Implement smoothing + dual-axis DTO + tests.
2) Spike dual-axis feasibility (library vs custom) with minimal PoC; decide path.
3) 23B: Build `DualAxisBpChart`, legend, toggles; widget tests.
4) 23C: Integrate into `AnalyticsView`, add feature flag, profile performance, integration tests.
5) Final cleanup: docs (DartDoc), analyzer, coverage check.

## Open Questions for Clive/Steve
- Approve per-chart smoothing toggle (vs global)?
- Accept hard-boundary color bands? (recommended)
- Marker defaults: ON for raw, OFF for smoothed—OK?
- Library switch allowed if `fl_chart` insufficient (adding `syncfusion_flutter_charts`)?

---

**Ready for Clive’s review.** Please confirm decisions and provide any additional constraints from Coding_Standards.md beyond coverage/analyzer/typing (e.g., line length, import ordering already assumed).

# Handoff: Tracy → Clive

**Date:** 2026-01-06  
**From:** Tracy (Planning & Architecture)  
**To:** Clive (Plan Review)  
**Status:** Plan Ready for Review

---

## Objectives & Scope
- **Rebranding (HyperTrack → HealthLog):** Update all user-facing strings, docs, and configs. Ensure no medical inference introduced during wording changes.
- **BP Chart Redesign (Major):** Split layout with center baseline; systolic above, diastolic below; apply NICE guideline color zones per band; maintain sleep overlay and tooltips.
- **Chart UX Polish (Minor):** X-axis date tick spacing/rotation; fix variability (SD/CV) overflow line.

## Constraints & Success Metrics
- **Standards:** Follow Coding Standards (80-char lines, const where possible, import ordering) from Documentation/Standards/CODING_STANDARDS.md. Maintain test coverage targets (Services ≥85%, Widgets ≥70%) and zero analyzer warnings.
- **Clinical guardrails:** No medical inference—colors/labels are visual cues only; avoid textual risk labels.
- **Compatibility:** Preserve existing data flows; dual-axis chart must use existing DualAxisBpData already exposed by AnalyticsViewModel.
- **Success:** All “HyperTrack” references replaced; BP chart renders split baseline with correct zones; date labels readable for long ranges; variability text fits without pushing chart content; tests and analyzer pass.

## Current Implementation Notes
- BP chart currently uses single-axis BpLineChart in [lib/views/analytics/widgets/bp_line_chart.dart](lib/views/analytics/widgets/bp_line_chart.dart) with ClinicalBandPainter background and combined systolic/diastolic series in one band (minY=40, maxY=200, straight mapping). X-axis labels are dense month/day strings.
- Data model already includes dual-series support: DualAxisBpData in [lib/models/analytics.dart](lib/models/analytics.dart); AnalyticsViewModel fetches both smoothed and raw dual-axis data via AnalyticsService.getDualAxisBpData but the UI doesn’t render it yet.
- Charting library: fl_chart (pubspec). Time range and smoothing toggles already exist in AnalyticsViewModel.

## Plan
1. **Rebranding inventory & patch plan**
  - Grep for “HyperTrack” across code/docs/assets. Likely targets: pubspec.yaml description, README/QUICKSTART/PROJECT_SUMMARY, in-app strings (About, titles), comments.
  - Define replacements: app name "HealthLog"; ensure no package/bundle ID change unless found (out of scope unless required). Update logos only if referenced textually.
  - Testing: update any string-based widget tests; quick smoke for About/Settings screens.

2. **BP chart architecture (split baseline)**
  - Introduce new widget (e.g., bp_dual_axis_chart.dart) or refactor BpLineChart to use DualAxisBpData. Prefer new widget to minimize regression; deprecate old painter usage for BP only.
  - Transform data: keep timestamps as-is; map systolic to positive axis, diastolic to negative axis (e.g., y = -diastolic). Center baseline at 0.
  - Axis ranges: compute symmetric padding (e.g., max(|systolic|, |diastolic|) + margin). Ensure tooltips display actual values (convert back from negated diastolic).
  - Maintain sleep overlay vertical lines and tooltip pairing (reuse existing correlation logic).

3. **NICE color zones implementation**
  - Define constants for systolic bands (e.g., <120 green, 120–139 amber, 140–159 red, 160–179 deep red, ≥180 critical) and diastolic bands (<80 green, 80–89 amber, 90–99 red, 100–109 deep red, ≥110 critical). Clarify exact thresholds with Clive before coding if needed.
  - Render as background bands: top-half zones for systolic (0→positive), bottom-half zones for diastolic (0→negative). Implement new CustomPainter (e.g., SplitClinicalBandPainter) replacing ClinicalBandPainter for BP only.
  - Accessibility: use distinct hues with sufficient contrast; avoid textual inference labels.

4. **Chart UX polish**
  - **X-axis labels:** Adaptive tick strategy based on visible range and width. Options: reduce label count (e.g., target ≤6 labels), rotate 30–45°, short date formats, or sampling by day/week/month boundaries.
  - **Variability overflow:** Identify widget that renders SD/CV line (likely in stats/legend area). Apply wrapping/column layout, abbreviate labels ("SD", "CV"), or expand container width; ensure BP chart area not pushed down.

5. **Sequencing**
  - Phase 1: Rebranding replacements + doc updates (low risk).
  - Phase 2: Implement dual-axis BP chart + painter + tooltips + legend update; preserve smoothing toggle behavior.
  - Phase 3: X-axis spacing improvements and variability text fix.
  - Phase 4: Tests & polish (widget tests for new chart rendering and label spacing logic; service tests unaffected unless data transforms added).

## Testing Strategy
- Unit/widget tests: new chart widget (renders split baseline, zones, tooltips show correct values), x-axis label density logic, variability layout (no overflow on common devices).
- Regression: existing analytics tests; ensure flutter analyze clean per standards.

## Risks & Mitigations
- **Color zones perceived as clinical advice:** Keep neutral legends; no text implying diagnosis.
- **Axis transform errors (diastolic negation):** Add helper conversion methods and tests to prevent flipped values/tooltips.
- **Label density edge cases:** Validate across time ranges (7, 30, 90 days) with snapshots or golden tests if feasible.

## Open Questions for Clive
1. Confirm NICE thresholds and color palette to use (are the proposed bands acceptable?).
2. Prefer refactor of existing BpLineChart vs. new widget file? I lean new widget for safer rollout.
3. Are smoothing toggles required for the dual-axis BP chart on day one, or can we defer smoothing to follow-up?

---

## Ready for Review
Plan is complete and ready for your review, Clive.
- **ViewModels (≥85%)**: Tests for BP ViewModel ensuring no status text emitted; history ViewModel averaged/raw data pipelines; analytics ViewModel series generation.
- **Widgets (≥70%)**: BP card widget test asserting absence of status labels; history view golden/screenshot for layout (filters visible, nav present, correct background); chart widget renders with sample data.
- **Integration/manual**: Import a fixed CSV sample; navigate history averaged/raw; view charts; verify theme and navigation; confirm no medical inference text.

## Risks & Mitigations
- Removing status text may leave spacing; adjust layout to avoid visual gaps.
- History/analytics changes could impact performance; profile data queries and caching.
- Import normalization must avoid loosening validation too much; restrict to comma-in-milliseconds case only.
- Backward compatibility: legacy CSVs should import after normalization; clearly document expected format.

## Open Questions
- Exact location of BP status string generation? (confirm in code before removal)
- Minimum data threshold for charts—hard-coded or configurable? (adjust if preventing render with valid data)
- Is there a shared export utility already used by other formats (e.g., JSON)? (reuse/extend vs. duplicate logic)

---

## Artifacts to Update
- [Documentation/ImportFormat.md](Documentation/ImportFormat.md) — clarify timestamp format and CSV behavior.
- Sample files: [Documentation/sample_import.csv](Documentation/sample_import.csv), [Documentation/sample_import.json](Documentation/sample_import.json) — update timestamps and examples.

---

## Ready for Clive
Please review the plan above for architectural soundness, sequencing, and test coverage alignment with [Coding Standards §8](Documentation/Standards/Coding_Standards.md#L542) and accessibility expectations in [§11](Documentation/Standards/Coding_Standards.md#L817). Upon approval, we will proceed to implementation following the recommended sequence.

# Review: Rebranding and BP Chart Redesign Plan

**Date:** 2026-01-06  
**Reviewer:** Clive (Quality Assurance)  
**Status:** **APPROVED WITH MINOR REFINEMENTS**

---

## Scope Review
- **Rebranding:** Comprehensive. Grepping for "HyperTrack" is correct. Must include `pubspec.yaml`, `README.md`, `QUICKSTART.md`, and UI strings.
- **BP Chart Redesign:** Architecture for split baseline (systolic positive, diastolic negative) is sound. Data mapping $y = systolic$ and $y = -diastolic$ is correct for visual separation.
- **Chart UX:** Adaptive labels and variability wrap logic addresses the user's report of "overlapping ticks" and "overflowing text".

## Compliance Check (CODING_STANDARDS.md)
- **Zero Medical Inference:** The plan correctly emphasizes "visual cues only" and "no textual risk labels". Colors should be descriptive of zones, not diagnostic.
- **Test Coverage:** Plan correctly targets Services ≥85% and Widgets ≥70%.
- **Typing:** Ensure no `dynamic` or `any` is introduced during the rebranding of model objects or if renaming files.

## Refinements & Recommendations

### 1. NICE Thresholds (Home Monitoring)
Use the following bands for the `SplitClinicalBandPainter`:
- **Systolic (Above Baseline):**
  - Green: $0$ to $134$
  - Yellow: $135$ to $149$
  - Orange: $150$ to $179$
  - Red: $\ge 180$
- **Diastolic (Below Baseline):**
  - Green: $0$ to $-84$
  - Yellow: $-85$ to $-92$
  - Orange: $-93$ to $-119$
  - Red: $\le -120$

### 2. Widget Strategy
- Proceed with a new widget `lib/views/analytics/widgets/bp_dual_axis_chart.dart` rather than refactoring the existing `BpLineChart`. This allows for a cleaner implementation of the negative axis logic and better isolation for testing.
- Deprecate (but keep until transition is complete) `BpLineChart` and `ClinicalBandPainter`.

### 3. X-Axis Density
- For 7-day views, show all days.
- For 30-day+ views, show weekly intervals or sample every Nth point to ensure no label overlap.
- Rotate labels by $30^{\circ}$ if width is constrained.

### 4. Visibility (SD/CV)
- Abbreviate labels in `_variabilityRow` to "Systolic", "Diastolic", "Pulse" (already short) but abbreviate header or values if needed.
- Consider switching `Row` to a `Column` with `crossAxisAlignment: CrossAxisAlignment.end` for the values if the Row still overflows.

---

## Final Approval
The plan is solid. Handing off to **Claudette** for implementation.

# Handoff: Clive → Claudette

**Date:** 2026-01-06  
**From:** Clive (Quality Assurance)  
**To:** Claudette (Implementation - UI/UX & Charts)  
**Status:** Implementation Ready

---

## 1. Summary of Work

Implement rebranding and BP chart redesign as specified in Tracy's plan with Clive's refinements.

## 2. Tasks & Requirements

### Task 1: Rebranding (HyperTrack → HealthLog)
- **Scope:** Replace all instances of "HyperTrack" with "HealthLog".
- **Files to check:**
  - `pubspec.yaml` (name and description)
  - All `.md` files in root and `Documentation/`
  - In-app strings (About screen, App titles, etc.)
  - Code comments and JSDoc strings.
- **Constraint:** Do NOT change package names or bundle IDs unless they explicitly use the word "HyperTrack" in a way that breaks brand requirements.

### Task 2: Split BP Chart Redesign (MAJOR)
- **New Widget:** Create `lib/views/analytics/widgets/bp_dual_axis_chart.dart`.
- **Logic:**
  - $Y$-axis center baseline at $0$.
  - Systolic plotted as positive values ($y = originalValue$).
  - Diastolic plotted as negative values ($y = -originalValue$).
- **Custom Painter:** Create `SplitClinicalBandPainter` to draw background zones.
- **Thresholds (NICE Home Monitoring):**
  - **Systolic:** Normal (<135, Green), Stage 1 (135-149, Yellow), Stage 2 (150-179, Orange), Stage 3 (≥180, Red).
  - **Diastolic:** Normal (>-85, Green), Stage 1 (-85 to -92, Yellow), Stage 2 (-93 to -119, Orange), Stage 3 (≤-120, Red).
- **Tooltips:** MUST show real values (convert Diastolic back to positive for display).
- **Legend:** Update `ChartLegend` to reflect the split zones.

### Task 3: Chart UX Polish
- **X-Axis Ticks:** Implement adaptive labeling to prevent overlap. Rotate labels $30^{\circ}-45^{\circ}$ if necessary.
- **Variability Overflow:** Update `_VariabilityCard` in `lib/views/analytics/widgets/stats_card_grid.dart` to prevent text overflow.
- **Solution:** Use abbreviations or more flexible layout (Column for mobile).

## 3. Standards & Quality
- **Zero Medical Inference:** Use color zones for visual aid only. No diagnostic text labels.
- **Documentation:** JSDoc for all new public methods and classes.
- **Tests:** 
  - Update any existing widget tests that check for "HyperTrack".
  - Add comprehensive widget tests for the new `BpDualAxisChart`.
  - Ensure 31/31 existing tests pass.
- **Architecture:** Maintain MVVM. Use existing `DualAxisBpData` provider in `AnalyticsViewModel`.

## 4. Reference Material
- Implementation Plan: [Documentation/Handoffs/Tracy_to_Clive.md](Documentation/Handoffs/Tracy_to_Clive.md)
- Review Notes: [reviews/2026-01-06-clive-rebranding-and-chart-plan-review.md](reviews/2026-01-06-clive-rebranding-and-chart-plan-review.md)
- Standards: [Documentation/Standards/CODING_STANDARDS.md](Documentation/Standards/CODING_STANDARDS.md)

---

**Next Steps:** Claudette, please begin with Task 1 (Rebranding) as it is lower risk, then proceed to the BP Chart implementation.

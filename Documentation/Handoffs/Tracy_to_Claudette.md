# Handoff: Tracy → Claudette
## Phase 24D – Accessibility Pass (Semantics, Contrast, High-Contrast, Large Text)

**Date:** 2026-01-03  
**From:** Tracy (Planning & Architecture)  
**To:** Claudette (Implementation)  
**Branch Base:** main (merge readiness assumed after 24C)

---

## Objectives
- Add comprehensive accessibility support across the app: semantic labels, WCAG AA contrast, high-contrast mode verification, and large text scaling up to 2.0x.
- Keep behavior/regressions minimal; no functional changes beyond accessibility.

## Scope (What to Cover)
1) **Semantic Labels** (screen reader): all icons-only buttons, FABs, quick actions, chart toggles, navigation icons, and form action buttons. 
2) **Color Contrast (WCAG AA)**: charts (band zones, lines), buttons (normal/disabled/pressed), text-on-surface in light/dark/high-contrast themes.
3) **High-Contrast Mode**: verify system HC (Android/iOS) plus in-app HC toggle; ensure focus/border/foreground visibility.
4) **Large Text Scaling**: validate at 1.5x and 2.0x; fix overflows with Flexible/Expanded/Wrap/scroll; ensure critical CTAs remain visible.

## Key Files / Areas (priority order)
- Home/Quick actions: lib/views/home_view.dart, lib/views/home/widgets/quick_actions.dart
- Navigation/Shell: bottom nav container, app bars with icons (ensure semantics)
- Appearance/Settings: lib/views/appearance_view.dart (already units work; add semantics/contrast checks)
- Analytics: lib/views/analytics/analytics_view.dart, analytics/widgets/* (selectors, toggles, chart legends)
- History: lib/views/history/history_home_view.dart, bp_full_history_view.dart, weight_full_history_view.dart, sleep_history_view.dart
- Forms: lib/views/blood_pressure/add_edit_bp_view.dart, lib/views/weight/add_weight_view.dart, lib/views/sleep/add_sleep_view.dart, medication add/edit/log views
- Reusable widgets: buttons, icon buttons, FABs, toggles, chips, dropdowns, segmented buttons, chart legends

## Implementation Tasks
1) **Semantic Labels Audit & Fixes**
   - Add Semantics/Tooltip/aria-style labels to icons-only controls (use concise, action-oriented labels).
   - Verify quick actions, FABs, chart toggles, navigation icons, and form submit/cancel buttons.
2) **Contrast Verification & Adjustments**
   - Audit with light/dark/high-contrast themes; adjust colors to meet WCAG AA (4.5:1 normal, 3:1 large).
   - Pay special attention to chart band fills/lines, disabled states, chip text, icon contrasts.
3) **High-Contrast Mode Pass**
   - With system HC enabled + in-app HC toggle, ensure borders/focus/foreground remain legible; add conditional borders/backgrounds if needed.
4) **Large Text Scaling Pass**
   - Test at 1.5x and 2.0x; fix overflows with Flexible/Expanded/Wrap or SingleChildScrollView where appropriate.
   - Ensure primary CTAs remain visible without clipping; avoid fixed heights where possible.
5) **Tests**
   - Add widget tests for: (a) semantics labels on critical controls, (b) selectors remain visible with large text (MediaQuery textScaleFactor), (c) high-contrast theme renders key elements (snapshot/semantics assertions where feasible).

## Acceptance Criteria
- Semantic labels on all interactive controls (icons-only + key buttons).
- WCAG AA contrast met for text/buttons/charts in light/dark/HC.
- High-contrast mode usable: borders/focus visible; no invisible icons/text.
- App remains usable at 1.5x and 2.0x text scaling with no blocking overflows on critical flows (home, add/edit forms, analytics selectors, history sections).
- Tests updated/passing; analyzer clean per CODING_STANDARDS (§2 formatting, §3 Dart/Flutter, §8 testing).

## Risks & Mitigations
- **Layout breaks at 2.0x**: prioritize critical screens; add scroll/flex wrappers judiciously.
- **Contrast tweaks affecting brand palette**: confine changes to on-surface/foreground where possible; prefer minimal adjustments.
- **HC mode variability (platform differences)**: gate HC-specific tweaks with platform checks if needed; prefer theme-based toggles.

## Deliverables
- Code updates for semantics, contrast tweaks, HC safeguards, and large-text resilience.
- Widget tests for semantics/large-text/HC where practical.
- Brief update to Implementation_Schedule (Phase 24D status) after completion.

## References
- Plan: [Documentation/Plans/Phase_24_Implementation_Spec.md](../Plans/Phase_24_Implementation_Spec.md)
- Plan: [Documentation/Plans/Phase_24_Units_Accessibility_Plan.md](../Plans/Phase_24_Units_Accessibility_Plan.md)
- Standards: [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)

---

## Next Step
Proceed with implementation on the `feature/phase-24c-units-ui-integration` (or new 24D branch from latest main) incorporating the tasks above, then hand back to Clive for review.

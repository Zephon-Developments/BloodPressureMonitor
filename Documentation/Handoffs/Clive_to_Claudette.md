# Handoff: Clive → Claudette

**Date:** December 31, 2025  
**From:** Clive (Review Specialist)  
**To:** Claudette (Implementation)  
**Scope:** Phase 16 – Profile-Centric UI Redesign

---

## Approved Plan
The implementation plan for Phase 16 has been approved: [Documentation/Plans/Phase_16_Profile_Centric_UI_Plan.md](../Plans/Phase_16_Profile_Centric_UI_Plan.md)

## Key Implementation Requirements
1.  **Security Gate Integration**: Ensure the Profile Picker is only accessible *after* the user has successfully authenticated via the security gate (biometric/PIN).
2.  **Profile Isolation**: This is critical. When switching profiles, you must:
    - Invalidate all caches.
    - **Cancel all profile-scoped subscriptions/listeners** before re-subscribing for the new profile.
    - Ensure all queries are explicitly scoped by the new active profile ID.
3.  **Home Redesign**: Focus on the "hero" quick actions for rapid logging (BP, meds, weight, sleep). Ensure the layout is responsive and handles large text gracefully.
4.  **Documentation**: All new public classes, methods, and widgets must have DartDoc comments per §10.1 of the [Coding Standards](../Standards/Coding_Standards.md).
5.  **Testing**: 
    - Unit tests for `ActiveProfileViewModel` switch logic and subscription management.
    - Widget tests for the new Profile Picker and Home quick actions.
    - Coverage targets: ViewModels/Services ≥85%, Widgets ≥70%.

## Branching
- **Branch**: `feature/phase-16-profile-ui`

## Next Steps
- Initialize the feature branch.
- Follow the task list in the approved plan.
- Submit a PR for review once all quality gates (analyzer, format, tests) are passing.

---
*Clive has approved this plan for implementation.*

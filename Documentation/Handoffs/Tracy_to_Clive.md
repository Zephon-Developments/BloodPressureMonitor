# Handoff: Tracy → Clive

**Date:** December 31, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Scope:** Phase 16 – Profile-Centric UI Redesign (architecture/implementation plan)

---

## Documents for Review
- Plan: [Documentation/Plans/Phase_16_Profile_Centric_UI_Plan.md](../Plans/Phase_16_Profile_Centric_UI_Plan.md)
- Standards: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md) (see §2.1/§2.4 workflow, §8.1 coverage targets)

## Plan Summary (updated per review)
- **Objective:** Carer-friendly, profile-first UX with rapid logging and strict profile isolation.
- **Scope:** Launch Profile Picker (post security gate), persistent profile switcher, home redesign with quick actions/tiles, isolation audit with cache invalidation on switch.
- **Architecture:**
	- Central `ActiveProfileViewModel` emits switch events; consumers refresh on change.
	- Profile Picker UI for CRUD (avatar, notes) with confirmation on delete; only presented after the security gate.
	- Home shell includes persistent switcher (avatar/name) + quick-action hero + secondary tiles.
	- Accessibility focus: large-text resilience and semantic labels.
- **Changes from review:**
	- Added subscription management in the isolation audit: cancel profile-scoped listeners/streams before reattaching on switch.
	- Added documentation task: DartDoc for new public APIs (Profile Picker, switcher widgets, ActiveProfileViewModel extensions).
- **Risks/Mitigations:**
	- Stale data after switch → global refresh hooks + cache invalidation + listener teardown on switch.
	- Cross-profile leakage → enforce active profile ID on mutations; assertions in ViewModels.
	- Layout regressions → responsive constraints + accessibility checks.
- **Testing:** Widget tests (picker, switcher, quick actions/tiles), unit tests (ActiveProfileViewModel, cache invalidation, service guards), regression on scoped queries.

## Open Questions for Review
1) Any mandated UX for profile delete confirmation copy (data-impact language)?
2) Preference on switcher control style (avatar dropdown vs. sheet) for accessibility?

## Expected Output from Review
- Approval or adjustments to the Phase 16 plan; any added standards to enforce during implementation.

## Next Steps After Your Review
- If approved, hand off to Claudette/Georgina for implementation on `feature/phase-16-profile-ui`.
- If changes are required, I will update the plan and resubmit.

# Handoff: Tracy → Clive

**Date:** December 31, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Scope:** Plan review for Rebrand + Phases 15–17 + Reminder Removal

---

## Documents for Review
- Plan: `Documentation/Plans/Phase_15-17_Rebrand_Reminder_Removal_Plan.md`
- Standards: `Documentation/Standards/Coding_Standards.md`

## Summary of Proposed Work
- **Plan A:** App rebrand to HyperTrack (strings, assets, docs; keep package IDs if possible).
- **Plan B:** Phase 15 Profile-Centric UI (profile picker at launch, quick actions home, persistent profile switcher, profile-scoped data integrity).
- **Plan C:** Phase 16 Encrypted Backup (passphrase-protected full DB export/restore, rollback on failure).
- **Plan D:** Phase 17 Branding + Appearance (About screen with Zephon branding; theme/accent/font scaling settings).
- **Plan E:** Reminder Removal (drop schema, remove models/services/UI/tests; keep manual intake only).

## Key Standards Alignment
- **Security/Reliability:** Coding_Standards §1.1; backup/restore uses layered encryption and rollback; profile isolation reinforced in UI redesign.
- **Branch Protection & CI:** Coding_Standards §2.1/§2.4 — all changes via PR with analyze/test/format/build gates.
- **Style/UI:** Coding_Standards §3 — Material 3 compliance; theming centralized; mounted checks for async UI.

## Risks / Questions to Validate
1) **Package IDs:** Confirm no change to Android/iOS IDs to preserve upgrade path.
2) **Backup Merge Mode:** Is replace-only acceptable for v1, or is merge required?
3) **Accent Palette:** Any mandated Zephon brand colors for appearance settings?
4) **Reminder Drop:** Accept data loss of reminder table on migration (per user direction)?

## Expected Output from Review
- Approval or requested adjustments on the plan doc.
- Any additional constraints from Coding_Standards to enforce (e.g., line length strictness, test coverage targets).

## Next Steps After Your Review
- If approved, hand off to Claudette for implementation with branch naming per §2.1 (e.g., `feature/phase-15-profile-ui`, `chore/rebrand-hypertrack`, etc.).
- If changes needed, I will update the plan accordingly and re-issue.

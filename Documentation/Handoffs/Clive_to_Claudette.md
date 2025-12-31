# Handoff: Clive → Claudette

**Date**: December 31, 2025  
**From**: Clive (Review Specialist)  
**To**: Claudette (Implementation Engineer)  
**Task**: Implement HyperTrack Evolution (Phases 14–18)

---

## 1. Context

The implementation plans for the next major evolution of the app (now named **HyperTrack**) have been approved. This work involves a significant UI redesign to support carer workflows, a secure backup system, and branding updates for Zephon Development.

## 2. Objectives

Implement Phases 14 through 18 as defined in the approved plans.

## 3. Reference Materials

- **Phase 14 (Rebrand)**: `Documentation/Plans/Phase_14_Rebrand_HyperTrack_Plan.md`
- **Phase 15 (Reminder Removal)**: `Documentation/Plans/Phase_15_Reminder_Removal_Plan.md`
- **Phase 16 (Profile UI)**: `Documentation/Plans/Phase_16_Profile_Centric_UI_Plan.md`
- **Phase 17 (Branding)**: `Documentation/Plans/Phase_17_Zephon_Branding_Appearance_Plan.md`
- **Phase 18 (Backup)**: `Documentation/Plans/Phase_18_Encrypted_Backup_Plan.md`
- **Review Notes**: `reviews/2025-12-31-clive-phases-14-18-plan-review.md`
- **Coding Standards**: `Documentation/Standards/Coding_Standards.md`

## 4. Implementation Sequence & Branching

Please implement in the following order to minimize dependency friction:

1.  **Phase 14: App Rebrand**
    - **Branch**: `feature/rebrand-hypertrack`
    - **Note**: Do NOT change package IDs.
2.  **Phase 15: Reminder Removal**
    - **Branch**: `feature/remove-reminders`
    - **Note**: Ensure migration is tested against legacy data.
3.  **Phase 16: Profile-Centric UI**
    - **Branch**: `feature/phase-16-profile-ui`
    - **Note**: Focus on strict profile isolation and global state refresh.
4.  **Phase 17: Zephon Branding & Appearance**
    - **Branch**: `feature/phase-17-branding-appearance`
5.  **Phase 18: Encrypted Full-App Backup**
    - **Branch**: `feature/phase-18-encrypted-backup`
    - **Note**: Use AES-GCM for the additional encryption layer.

## 5. Quality Gates (Mandatory)

- **Test Coverage**: 
    - Services/ViewModels: **≥85%**
    - Models/Utils: **≥90%**
    - Widgets: **≥70%**
- **Documentation**: All new public APIs must have DartDoc comments.
- **Analyzer**: Zero warnings or errors.
- **Formatting**: Strict adherence to `dart format`.

## 6. Success Criteria

- All phases implemented and merged to `main`.
- App name is "HyperTrack" everywhere.
- Carer workflow (profile-first) is smooth and intuitive.
- Encrypted backups work reliably with passphrase protection.

---

**Handoff Complete.** Please notify me as each PR is ready for review.

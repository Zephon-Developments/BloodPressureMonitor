# HyperTrack Update Summary

**Date:** December 31, 2025  
**Project:** HyperTrack (formerly Blood Pressure Monitor)  
**Developed under Zephon Development**  
**Zephon Project Hub:** [https://www.zephon.org](https://www.zephon.org) – Beta testing and analytics tools for optimization projects  

## Key Changes and Evolution

After completing the initial 13 phases (core data, averaging, medication, UI, analytics, exports, etc.) and beginning Phase 14 (Polish & Testing), the project direction has evolved to better support multi-profile use cases — particularly for carers managing data for multiple individuals (e.g., family members or patients) — while maintaining strong focus on secure, offline-first data collation and GP-friendly PDF/report sharing.

### 1. App Name Change
- **New Name:** **HyperTrack**
  - Rationale: Retains a subtle tie to "hypertension" management while being broad enough for multi-metric tracking (BP, pulse, medications, weight, sleep correlations).
  - Distinct from generic "BP Monitor/Tracker" names; unique in health app space.
  - Supports future expansion without limiting scope.

### 2. UI Redesign: Profiles Front and Center (Planned Phase 15)
- Profile selection moved to the **launch screen** (post security gate).
- Full profile management: Add/edit/delete profiles with avatars/names/notes.
- New **main home screen** after profile selection:
  - Large quick-logging buttons for core actions (Log Blood Pressure, Log Medication Intake, Log Weight, Log Sleep).
  - Secondary access to History, Analytics, Medications List, Exports.
  - Persistent profile switcher for fast context changes.
- All data queries and services scoped strictly by active profile ID.
- Goal: Reduce taps for daily logging; emphasize carer/multi-patient workflow.

### 3. Encrypted Full-App Backup (Planned Phase 16)
- New feature for secure off-device backups.
- Export entire app data (all profiles + encrypted SQLite DB) as a single passphrase-protected file.
- Options: Direct export of encrypted DB or additional AES encryption layer.
- UI in Settings: Export Backup / Import Restore with progress, warnings, and optional merge/conflict handling.
- Ensures data safety in case of device loss; aligns with privacy-first design.

### 4. Zephon Branding Integration (Planned Phase 17)
- **About Screen**
  - New dedicated About section in Settings.
  - Content:
    - App name and version.
    - Brief description: "HyperTrack is a private, offline health data logger designed to help you collate and share accurate records with your healthcare professional."
    - Prominent Zephon Development branding:
      - Logo (if available) or text: "Developed under Zephon Development"
      - Link to [https://www.zephon.org](https://www.zephon.org)
      - Short tagline: "Empowering optimization and analytics through focused, user-centric projects."
    - Privacy note and disclaimer: "Not a medical device. No data is transmitted or shared without your explicit action."
- **Appearance Settings**
  - New Appearance section in Settings.
  - Options:
    - Theme: Light / Dark / System default.
    - Accent color selection (subtle palette suitable for health apps).
    - Optional: High contrast mode toggle.
    - Font size scaling (normal / large / extra large) for accessibility.
  - Aligns visual style with clean, professional Zephon aesthetic.

### 5. Removal of Reminders
- All reminder-related features removed entirely:
  - Reminder model, schema, CRUD services, and any scheduled notifications.
  - No medication schedule metadata or late/missed indicators tied to reminders.
  - Medication intake remains purely manual timestamp logging.
- Rationale: Keeps the app focused on neutral data collection and reporting; avoids any perception of treatment guidance or alerting.

## Regulatory & Distribution Notes
- Positioning remains as a **non-medical device** personal health logger (manual entry, neutral reports, no diagnoses/recommendations/alerts).
- Strong disclaimers planned for store listings, About screen, and in-app.
- Google Play compliance expected via accurate Health Apps declaration and privacy policy.

## Next Steps
- Implement Phase 15 (Profile-centric UI).
- Implement Phase 16 (Encrypted Backup).
- Implement Phase 17 (Zephon Branding + Appearance Settings).
- Complete comprehensive testing and polish.
- Prepare for internal/personal use first, with potential wider release.

This evolution makes HyperTrack a polished, carer-friendly tool for long-term health data management and doctor collaboration — fully aligned with Zephon Development principles.

**Zephon Development** – Empowering optimization and analytics through focused, user-centric projects.
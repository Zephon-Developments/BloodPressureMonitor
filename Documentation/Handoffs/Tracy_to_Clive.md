# Handoff: Tracy → Clive

**Date:** December 31, 2025  
**From:** Tracy (Planning)  
**To:** Clive (Review)  
**Scope:** Phase 17 – Zephon Branding & Appearance Settings (architecture/implementation plan)

---

## Documents for Review
- Phase scope: [Documentation/Plans/Implementation_Schedule.md](../Plans/Implementation_Schedule.md) (Phase 17 section)
- Draft notes: [Documentation/Plans/Phase_17_Zephon_Branding_Appearance_Plan.md](../Plans/Phase_17_Zephon_Branding_Appearance_Plan.md)
- Standards: [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) — branch/CI rules (§2.1/§2.4), coverage targets (§8)

## Objectives & Success Criteria
- Deliver Zephon-branded About screen and Appearance settings with live, persistent theme changes.
- Success metrics: theme/accent/font changes apply instantly and persist across restart; About shows Zephon brand assets and safe external link handling; tests meet coverage targets (ViewModels/Services ≥85%, Widgets ≥70% per §8); CI green per §2.4.

## Scope
1) **About HyperTrack** (Settings → About)
	- Show app name/version (from package_info_plus), Zephon tagline/link, privacy disclaimer.
	- Include Zephon logo + icon variant from Assets (provided in repo); ensure accessible labels.
	- External link handling via safe launcher with confirmation on non-HTTPS.
2) **Appearance Settings** (Settings → Appearance)
	- Theme mode: light/dark/system.
	- Accent palette: curated 5–8 colors (health-friendly, contrast-checked).
	- Font scaling: normal/large/XL.
	- High-contrast toggle (applies to color roles + text emphasis).
3) **Theming Architecture**
	- Central `ThemeViewModel` managing mode/accent/fontScale/highContrast.
	- Persistence via SharedPreferences; load/apply at startup.
	- Material 3 color scheme generation per accent; ensure semantic color roles.

## Constraints & Dependencies
- Main is protected; all work must go through PRs and CI per §2.1/§2.4.
- Phase 14 rebrand completed; Settings shell available from Phase 16 (assumed merged per PR #29); if schedule discrepancy remains (Implementation_Schedule still shows Phase 16 open), confirm status to avoid branch conflicts.
- Assets: Zephon logo and icon variant available in Assets folder; ensure correct resolution and theme-aware usage.

## Architecture & Data Flow
- **Theme state flow**: UI toggles → ThemeViewModel → persisted in SharedPreferences → applied to MaterialApp ThemeData (M3) → widgets react via Providers.
- **About links**: tap → safe launcher wrapper → external browser; guard against non-https with confirmation.
- **High-contrast**: adjusts color roles (onPrimary/onSurface), elevation overlays, and text styles in ThemeData; ensure chart/illustrations remain legible.

## Proposed Implementation Plan
1) **Models & Persistence**
	- Add settings model (themeMode, accentKey, fontScale enum, highContrast bool).
	- Settings persistence service wrapping SharedPreferences keys (namespaced).
2) **ViewModel**
	- `ThemeViewModel`: load/save, expose current ThemeData, notify on changes; default to system theme, neutral accent.
	- Provide factory to build ThemeData from model (M3, seeded colors, typography scaling, high-contrast overrides).
3) **Views & Widgets**
	- About screen: app info, Zephon logo/icon, tagline, privacy blurb, link button (with icon), version text.
	- Appearance screen: segmented control for theme mode; palette picker (grid of swatches with checkmark); font scale radio/slider; high-contrast switch with preview.
	- Optional preview card showing sample text/buttons with current theme.
4) **Integration**
	- Wire ThemeViewModel provider at app root; apply theme to MaterialApp.
	- Add routes/entries in Settings menu for About and Appearance.
5) **Tests**
	- Unit: ThemeViewModel persistence/load/apply; color scheme generation; high-contrast toggles.
	- Widget: Appearance screen toggles update UI and persist; About screen renders logo, version, link tap invokes launcher stub.
	- Accessibility: golden/semantics check for large fonts and high-contrast preview.

## Files & Ownership (proposed)
- `lib/viewmodels/theme_viewmodel.dart` — new
- `lib/services/theme_persistence_service.dart` (or extend settings service) — new
- `lib/views/settings/appearance_view.dart` — new
- `lib/views/settings/about_view.dart` — new
- `lib/widgets/settings/theme_palette_picker.dart`, `font_scale_selector.dart`, `contrast_toggle_tile.dart` — new helper widgets
- Assets: reference Zephon logo/icon from Assets; ensure 1x/2x/3x usage.
- Tests under `test/viewmodels/theme_viewmodel_test.dart`, `test/views/settings/appearance_view_test.dart`, `test/views/settings/about_view_test.dart`, plus widget helpers for launcher stubs.

## Acceptance Criteria (expanded)
- Theme/accent/font/high-contrast changes apply immediately and persist across restart.
- About screen displays Zephon logo/icon, version, tagline, privacy statement; external link opens safely.
- Palette meets contrast expectations; no clipping at large text/XL.
- Tests meet coverage targets (per §8) and CI passes (per §2.4); analyzer clean.

## Risks & Mitigations
- **Contrast regressions**: curate palette with WCAG-aware roles; add snapshot tests for high-contrast.
- **Layout breaks with large fonts**: use Flexible/Wrap, avoid hard widths; test with textScaleFactor 1.2/1.4.
- **Theme jitter on startup**: hydrate ThemeViewModel before runApp; show fallback splash theme.
- **Launcher safety**: guard non-https with confirm dialog; mock launcher in tests.

## Open Questions for Clive
1) Palette direction: prefer muted health tones (teal/blue/green) or allow brighter accents (purple/orange)?
2) High-contrast spec: apply only to text/background, or also to icons/dividers?
3) About link behavior: open directly in browser or require in-app confirmation?
4) Should logo/icon respect theme (e.g., dark-mode variant), or always use brand primary?

## Plan Sign-off Path
- Target branch: `feature/phase-17-branding-appearance` (per §2.1).
- CI gates: flutter analyze, flutter test, dart format, flutter build apk (per §2.4).
- After your review, I’ll update the plan as needed and pass to the implementer (Claudette/Georgina) with your notes.

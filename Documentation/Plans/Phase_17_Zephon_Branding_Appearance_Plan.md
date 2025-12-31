# Phase 17 Plan: Zephon Branding & Appearance Settings

**Objective**: Introduce Zephon branding (About screen) and user appearance controls (theme, accent, font size, accessibility) with live updates.

## Scope
- Settings → About HyperTrack with app name/version, Zephon link/tagline, privacy disclaimer.
- Settings → Appearance: theme mode (light/dark/system), accent palette, font scaling (normal/large/XL), optional high-contrast toggle.
- Centralized theming via ThemeViewModel with persistence (SharedPreferences).

## Tasks
1) About Screen
- Build About view with version from package_info_plus, Zephon link/tagline, and privacy statement.
- Ensure external link handling is safe and user-confirmed where needed.

2) Appearance Settings
- Theme mode selector (light/dark/system) with immediate apply.
- Accent color palette (5–8 options) feeding Material 3 color scheme.
- Font scaling options and optional high-contrast toggle.

3) Theming Architecture
- Create/extend ThemeViewModel to hold theme mode, accent, font scale, contrast.
- Persist settings in SharedPreferences; apply on app start.

## Acceptance Criteria
- Theme, accent, and font changes apply live and persist across restarts.
- About screen shows Zephon branding and opens link safely.
- Widget/unit tests cover toggles, persistence, and About content.
- Analyzer/tests pass; coverage targets met (Services/ViewModels ≥85%, Widgets ≥70%).

## Dependencies
- Phase 14 rebrand; Phase 16 shell for settings entry.

## Risks & Mitigations
- Risk: Layout breaks with large fonts. Mitigation: Responsive typography and overflow handling.
- Risk: Palette clashes. Mitigation: Curate health-appropriate palette and verify contrast.

## Branching & Workflow
- Branch: `feature/phase-17-branding-appearance`
- Follow Coding_Standards §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- Widget tests for Appearance toggles and About screen link handling.
- Unit tests for ThemeViewModel persistence and state changes.
- Manual accessibility pass (large text, contrast).

## Rollback Plan
- Feature-flag Appearance settings; default to system theme if issues arise.

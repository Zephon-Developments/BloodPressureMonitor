# Phase 17 Plan: Zephon Branding & Appearance Settings

**Objective**: Introduce Zephon branding (About screen) and user appearance controls (theme, accent, font size, accessibility) with live updates.

## Scope
- **Settings → About HyperTrack**: App name/version (via `package_info_plus`), Zephon link/tagline, privacy disclaimer.
- **Settings → Appearance**: Theme mode (light/dark/system), accent palette, font scaling (normal/large/XL), high-contrast toggle.
- **Theming Architecture**: Centralized theming via `ThemeViewModel` with persistence (`SharedPreferences`).

## Architecture & Data Flow
- **Theme State Flow**: UI toggles → `ThemeViewModel` → persisted in `SharedPreferences` → applied to `MaterialApp` `ThemeData` (M3) → widgets react via Providers.
- **About Links**: Tap → safe launcher wrapper → external browser; guard against non-HTTPS with confirmation dialog.
- **High-Contrast**: Adjusts color roles (`onPrimary`/`onSurface`), elevation overlays, and text styles in `ThemeData`; ensure chart/illustrations remain legible.
- **Startup**: Hydrate `ThemeViewModel` before `runApp()` to prevent theme jitter/flash.

## Tasks

### 1. Models & Persistence
- Define `ThemeSettings` model (themeMode, accentKey, fontScale enum, highContrast bool).
- Implement `ThemePersistenceService` wrapping `SharedPreferences` keys (namespaced).

### 2. ViewModel
- Create `ThemeViewModel`:
  - Load/save settings via persistence service.
  - Expose current `ThemeData` and `ThemeMode`.
  - Provide factory to build `ThemeData` from model (Material 3, seeded colors, typography scaling, high-contrast overrides).
  - Notify listeners on any change for live updates.

### 3. Views & Widgets
- **About Screen**:
  - Display app info, Zephon logo (`Assets/ZephonDevelopmentsLogo.jpg`), and icon (`Assets/ZephonDevelopmentsIcon.png`).
  - Tagline, privacy statement, and version text.
  - External link button with confirmation dialog.
- **Appearance Screen**:
  - Segmented control for theme mode.
  - Palette picker (grid of swatches with checkmark) using curated health-friendly colors (Teals, Blues, Greens).
  - Font scale selector (Normal/Large/XL).
  - High-contrast switch with preview.
- **Helper Widgets**: `ThemePalettePicker`, `FontScaleSelector`, `ContrastToggleTile`.

### 4. Integration
- Add `url_launcher: ^6.2.0` to `pubspec.yaml`.
- Declare Zephon assets in `pubspec.yaml` (Note: `Assets/` is capitalized).
- Wire `ThemeViewModel` provider at app root.
- Add routes/entries in Settings menu for About and Appearance.

## Acceptance Criteria
- Theme, accent, font, and high-contrast changes apply live and persist across restarts.
- About screen shows Zephon branding and opens links safely after confirmation.
- Layout remains responsive and overflow-free at XL font scaling (use `Flexible`, `Wrap`, `SingleChildScrollView`).
- High-contrast mode meets WCAG AAA standards for core roles where possible.
- **Test Coverage**: ≥80% for all new code (ViewModels, Services, and Widgets).
- Analyzer/tests pass; CI green.

## Dependencies
- Phase 14 rebrand; Phase 16 shell for settings entry.
- `package_info_plus`, `url_launcher`, `shared_preferences`.

## Risks & Mitigations
- **Risk**: Layout breaks with large fonts. **Mitigation**: Responsive typography and overflow handling (Flexible/Wrap).
- **Risk**: Palette clashes/low contrast. **Mitigation**: Curate health-appropriate palette and verify contrast roles.
- **Risk**: Theme jitter on startup. **Mitigation**: Initialize `ThemeViewModel` before `runApp()`.

## Branching & Workflow
- Branch: `feature/phase-17-branding-appearance`
- Follow `CODING_STANDARDS.md` §2.1/§2.4 (PR + CI gates).

## Testing Strategy
- **Unit Tests**: `ThemeViewModel` persistence/load/apply; color scheme generation; high-contrast toggles.
- **Widget Tests**: Appearance screen toggles update UI and persist; About screen renders logo, version, and link tap invokes launcher stub.
- **Accessibility**: Golden/semantics check for large fonts and high-contrast preview.
- **Coverage**: Target ≥80% across all new files.

## Rollback Plan
- Feature-flag Appearance settings; default to system theme if issues arise.

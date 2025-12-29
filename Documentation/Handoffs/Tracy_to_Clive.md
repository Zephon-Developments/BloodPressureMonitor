# Tracy to Clive Handoff - Phase 6: UI Foundation (Home & Add Reading)

## Objectives & Scope
- Build the Phase 6 UI foundation: Home/Dashboard, Add Reading form, Navigation shell.
- Integrate existing services/viewmodels (BloodPressureViewModel, validators, averaging) without altering domain logic.
- Maintain security posture: lock screen must gate navigation when locked.

## Dependencies & Standards
- Upstream complete: Phases 1, 2A, 2B, 5; Navigation shell already minimal in HomeView.
- Coding Standards: follow import order, 80-char lines, mandatory trailing commas, `flutter analyze`/`flutter test`/`dart format` required (see Documentation/Standards/Coding_Standards.md sections 2.4, 3.3, 3.4).

## Proposed Architecture
- **Navigation Shell**: Single `Scaffold` host with bottom navigation (Home, History stub, Charts stub, Settings). Uses named routes for future deep links. LockViewModel guards entry (redirect to lock screen when locked).
- **Home (Dashboard)**: Composition of widgets: profile selector (if >1 profile), recent readings card, quick actions (Add Reading, Go to History), and shortcuts to Settings/Security.
- **Add Reading Form**: Two-pane layout (basic + advanced collapsible). Uses form state + validators; on submit, calls BloodPressureViewModel to create reading and triggers averaging. Provides session override toggle.
- **Common Widgets**: Reusable validated text field, expandable section, loading button, validation message banner.

## Wireframes (textual)
- **Navigation (Bottom bar)**: [Home | History (stub) | Charts (stub) | Settings]
- **Home**:
  - AppBar: title, profile selector (dropdown if multi-profile), settings icon.
  - Body: Quick actions row (Add Reading primary), Recent readings card (list 3-5 averaged entries, tappable to History stub), Optional meds shortcut.
- **Add Reading**:
  - AppBar: "Add Reading", save action disabled until valid.
  - Form (scrollable):
    - Basic: systolic, diastolic, pulse, timestamp picker.
    - Advanced (expandable): arm (chips), posture (chips), notes (multiline), tags (chips or text), medication checkbox/link.
    - Session control: switch + helper text.
    - Validation banner inline; submit button with loading state.

## Component/Widget Hierarchy
- `lib/views/home/home_view.dart` (enhance):
  - `HomeView` -> `Scaffold` with bottom nav
    - `AppBar`: profile selector, settings button
    - `Body`: `RecentReadingsCard`, `QuickActions`, `MedsShortcut` (optional)
- `lib/views/home/widgets/`:
  - `profile_selector.dart`: dropdown/list tile with profile names
  - `recent_readings_card.dart`: list of recent averaged readings with timestamps
  - `quick_actions.dart`: primary CTA "Add Reading", secondary "History" (stub)
- `lib/views/readings/add_reading_view.dart`:
  - `AddReadingView` -> `Form` + `SingleChildScrollView`
  - Uses subwidgets in `lib/views/readings/widgets/`:
    - `reading_form_basic.dart`: systolic, diastolic, pulse, timestamp
    - `reading_form_advanced.dart`: arm, posture, notes, tags
    - `session_control_widget.dart`: toggle + tooltip
    - `validation_message_widget.dart`: warning/error banner
- `lib/widgets/common/`:
  - `custom_text_field.dart`: labeled, helper/error, numeric keyboard, validation hook
  - `expandable_section.dart`: animated expand/collapse
  - `loading_button.dart`: handles busy state

## Data Flow & Integration
- **Add Reading Submit**: Validate -> confirm overrides -> call BloodPressureViewModel.addReading(...) -> service writes -> averaging auto-triggers -> refresh Home recent readings.
- **Session Override**: Toggle sets flag passed into ViewModel to start new averaging session.
- **Lock Integration**: On app resume or navigation change, if LockViewModel.state.isLocked, route to lock screen.

## File Impact (planned)
- Update: `lib/views/home_view.dart` (replace current minimal UI with shell + sections).
- Add dirs/files: `lib/views/home/widgets/*`, `lib/views/readings/add_reading_view.dart`, `lib/views/readings/widgets/*`, `lib/widgets/common/*`.
- Tests: `test/views/home/`, `test/views/readings/`, `test/widgets/common/` for widget coverage.

## Validation & UX Rules
- Real-time validation using existing validators (bounds: sys 70–250, dia 40–150, pulse 30–200).
- Warning/override path uses existing override confirmation pattern; block errors.
- Accessibility: labels for inputs, switches, and chips; touch targets >=48dp; high-contrast colors; semantic hints for validation banners.
- Performance: keep widget trees lean; use const where possible; ListView.builder for recent readings.

## Test Strategy
- **Widget tests (target ≥70% for new widgets):**
  - AddReading basic fields validate bounds; warnings surface; submit disabled until valid.
  - Advanced section expand/collapse state persists; arm/posture selection emits value.
  - Session toggle sets new-session flag.
  - Home quick action triggers navigation to AddReading; recent readings render list.
  - Lock state redirect when locked (mock LockViewModel).
- **Unit tests:** helper widgets (expandable_section, loading_button) behaviors.
- **Integration (optional):** create reading -> appears in recent list (using fake services).

## Sequencing
1) Shell & navigation scaffold (bottom nav, routes, lock gating hook)
2) Home widgets (profile selector, quick actions, recent readings stub with mock data)
3) Add Reading basic form + validation + submission to ViewModel
4) Advanced section + session control + medication stub link
5) Wire to real services; refresh recent readings
6) Tests (widgets, unit); analyzer/format

## Risks & Mitigations
- **Lock integration**: ensure navigation respects locked state; add guard in shell. Mitigation: route middleware or early return to lock screen.
- **Validation UX complexity**: warning vs error states. Mitigation: shared validation banner component.
- **Large forms usability**: ensure scroll + keyboard padding. Mitigation: SingleChildScrollView + padding + safe area.

## Open Questions
- Should recent readings show averaged groups or raw latest? (Assuming averaged top 3-5.)
- Preferred nav pattern: bottom nav (default) vs navigation rail for tablets?
- Medication quick-log: open existing intake flow or stub dialog? (Assuming stub link for now.)

## Timeline (per handoff, reaffirmed)
- Planning/wireframes: 0.5 day
- Implementation: 2-3 days (form, home, nav shell)
- Testing/QA: 1 day
- Polish/Review: 0.5 day

## Handoff Action
- Clive: review this plan. On approval, proceed to implement on a feature branch following Coding Standards and CI gates.


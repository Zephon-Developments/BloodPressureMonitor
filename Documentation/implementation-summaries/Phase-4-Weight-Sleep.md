# Phase 4 — Weight & Sleep Tracking Progress

## Requirements & Assumptions
- Deliver Phase 4 UI layers per Tracy's plan focusing on manual weight and sleep capture.
- Keep APIs narrow by delegating persistence to existing services (`WeightService`, `SleepService`).
- Maintain type safety (no `dynamic`/`any` usage) and wire forms through the MVVM layer using the new `WeightViewModel` and `SleepViewModel`.

## Implementation Summary
- Added weight entry form and history surfaces to unblock manual capture workflows.
  - [lib/views/weight/add_weight_view.dart](lib/views/weight/add_weight_view.dart): Stateful form with validation, lifestyle context chips, and `LoadingButton` integration.
  - [lib/views/weight/weight_history_view.dart](lib/views/weight/weight_history_view.dart): List UI for saved entries with lifestyle chips and quick navigation to the add form (now uses `withOpacity` to avoid color API issues).
- Introduced sleep tracking surfaces mirroring the weight UX for consistency.
  - [lib/views/sleep/add_sleep_view.dart](lib/views/sleep/add_sleep_view.dart): Handles date selection, overnight spans, quality dropdown, optional notes, and delegates persistence to `SleepViewModel`.
  - [lib/views/sleep/sleep_history_view.dart](lib/views/sleep/sleep_history_view.dart): Displays sessions with duration formatting, source badges, and navigation to the add screen.

## Tests & Analysis
- Not yet run. Recommend executing `flutter analyze` followed by `flutter test` once remaining Phase 4 wiring (providers, routes, migrations) is in place.

## Risks / Follow-ups
- New views are not wired into navigation or providers yet; `main.dart` still needs to register `SleepViewModel`/`WeightViewModel` and expose routes.
- Database migrations for normalized weight and sleep tables remain outstanding.
- No widget/unit tests exist for the new flows; add coverage (>=80%) once services and navigation glue are finalized.

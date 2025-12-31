# Phase 7 Plan — History (Avg-first with expansion)

## Objectives
- Deliver a History experience where averaged reading groups are the primary view and raw readings are one tap away.
- Support filters (date range, profile, tags) and an averaged/raw toggle.
- Maintain smooth performance for 100+ groups with lazy loading/pagination.
- Achieve ≥70% widget coverage and keep analyzer/test suite at 0 issues.

## Scope & Assumptions
- In-scope: history screen UI, filtering, expand/collapse behavior, viewmodels/services for grouped history retrieval, performance safeguards.
- Out-of-scope: new charting/analytics (Phase 8), exports (Phase 9), weight/sleep UI revisions (later change), doctor advice.
- Assumptions: existing `AveragingService` grouping logic is correct; reading data stored locally with encrypted DB; navigation shell from Phase 6 is available.

## Dependencies
- `AveragingService` and reading storage from Phases 1/2.
- UI shell/navigation from Phase 6.
- Coding standards: 80-char lines, import ordering, trailing commas, zero analyzer warnings; tests required (see Documentation/Standards/Coding_Standards.md).

## Architecture & Data Flow
- **ViewModel**: Introduce `HistoryViewModel` (extends ChangeNotifier).
  - Responsibilities: load grouped history, manage filters, manage expand state, provide averaged/raw toggle, expose loading/error states, handle pagination/lazy loading.
  - Inputs: `ReadingService` (raw reads), `AveragingService` (group recomputation if needed), `profileId`.
  - Outputs: `List<HistoryGroupItem>` (averaged summary + children metadata), filter state, `isLoading`, `error`.
- **Data Structures**:
  - `HistoryGroupItem`: groupId, averaged systolic/diastolic/pulse, takenAt range, memberIds, tags, sessionId, readings (lazy-loaded), isExpanded flag, count.
  - `HistoryFilters`: dateRange (preset chips + custom), profileId, tags, viewMode (averaged/raw).
- **Data Flow**:
  1) View requests `HistoryViewModel.loadGroups(filters)`.
  2) ViewModel fetches groups via new `HistoryService` helper or `ReadingService` + grouping table; applies filters at query level.
  3) For expand: on toggle, fetch raw readings for the group (if not cached) via `ReadingService.getReadingsByIds(memberIds)` or equivalent query; update state.
  4) Pagination: fetch groups in pages (e.g., 20) ordered by takenAt desc; append as user scrolls.
  5) Toggle averaged/raw: view swaps between grouped list (averaged) vs flat raw list (still paginated) without losing filters.

## UI / Component Plan
- **HistoryView** (new screen): scaffold with AppBar, filter bar, list body, optional empty state.
- **FilterBar**: chips for presets (7d/30d/90d/All) + custom date picker; profile selector; tag filter (simple multiselect); view mode toggle (Averaged | Raw).
- **HistoryList**: `ListView.builder` with `HistoryGroupTile` rows; supports pagination via scroll listener or `ScrollController` + load-more sentinel.
- **HistoryGroupTile**:
  - Collapsed: averaged values, timestamp range, member count, tags indicator, session marker.
  - Expanded: renders child `RawReadingTile` list for that group; reuse existing reading card style for consistency.
  - Loading state for expansion fetch; error state per group.
- **RawModeList**: when in raw mode, show `ReadingTile` items directly (no grouping) respecting filters; still paginated.
- **EmptyState**: friendly message + CTA to add reading.

## Performance Strategy
- Use paged queries (LIMIT/OFFSET) for groups and raw mode; avoid fetching entire history.
- Cache expanded group children in-memory for session; invalidate on pull-to-refresh or data change.
- Use `ListView.builder` with const widgets and keys; avoid `ShrinkWrap` on large lists.
- Debounce filter changes before querying; show loading indicator.
- Consider prefetching next page when nearing end of list (threshold-based).

## Accessibility & UX
- Maintain M3 patterns; ensure tappable rows (min 48dp) and semantics on expand toggles.
- Provide clear labels for averaged/raw toggle and filters.
- Preserve scroll position when toggling expansion or switching modes where feasible.

## Testing Strategy (targets per Coding_Standards)
- **Unit**: `HistoryViewModel` filter logic, pagination, expand/collapse state, error handling, caching, toggle behavior (averaged vs raw).
- **Widget**: HistoryView interactions: filter chips apply; expand/collapse shows children; pagination loads more; raw mode renders flat list; empty state renders.
- **Integration**: fetch groups -> expand -> pull-to-refresh; ensure no duplicate loads; verify smooth scrolling with large fixture (e.g., 150 groups).
- Coverage goals: ≥85% for new viewmodel/service logic; ≥70% for new widgets; zero analyzer warnings.

## Implementation Tasks & Sequencing
1) **Scaffold & Navigation**: add HistoryView route; connect from existing nav/quick actions.
2) **Models**: define `HistoryGroupItem`, `HistoryFilters` (pure data classes with equality).
3) **Service Layer**: add `HistoryService` helper (or extend ReadingService) to fetch grouped summaries and member readings with filters + pagination.
4) **ViewModel**: implement `HistoryViewModel` with load, paginate, toggle, expand, refresh, and error states.
5) **UI Components**: build HistoryView, FilterBar, HistoryList/HistoryGroupTile, RawModeList, EmptyState.
6) **Tests**: unit tests for viewmodel/service; widget tests for HistoryView behaviors; integration-style test for expand/paginate flow.
7) **Performance Check**: large fixture test, scroll smoothness, no jank; ensure memory stable with caching invalidation.

## Risks & Mitigations
- **Large data jank**: mitigate with pagination, prefetch threshold, const widgets.
- **Expand fetch latency**: show per-group loading; cache results to avoid repeat hits.
- **Toggle mode state loss**: preserve filters and scroll where practical; document expected behavior if reset is needed.
- **DB query complexity**: if grouping table access is heavy, consider precomputed summaries via AveragingService recompute and indexed columns.

## Acceptance Criteria (aligns with Implementation Schedule)
- Averaged view is default; raw details one tap away via expansion.
- Filters (date range/profile/tags) work and persist during session; averaged/raw toggle functional.
- Smooth scrolling with 100+ groups; pagination in place; no noticeable jank.
- Tests: ≥70% widget coverage for new UI; ≥85% viewmodel/service; all tests pass; `flutter analyze` clean.
- Follows Coding_Standards (import order, 80 cols, trailing commas, doc comments for public APIs).

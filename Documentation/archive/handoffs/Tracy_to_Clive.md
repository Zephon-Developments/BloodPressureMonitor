# Handoff: Tracy → Clive

**Date:** 2026-01-06  
**From:** Tracy (Planning & Architecture)  
**To:** Clive (Plan Review)  
# Handoff: Tracy → Clive

**Date:** January 20, 2026  
**Branch:** `chore/pr47-cleanup`  
**Plan:** Documentation/Plans/Phase_26_Issues_Resolution_Plan.md

## Summary of Plan
- **BP Charts (MAJOR):** Stacked systolic+diastolic charts with shared X-axis; NICE bands per axis (Sys 90-134/135-149/150-179/≥180; Dia 60-84/85-94/95-119/≥120). Shared domain/tick generator; ensure tooltips show positive values; keep performance at 500+ points.
- **Settings Nav:** Remove duplicate "Intake History" tile from Settings; keep History-only access; adjust affected tests.
- **Medication History Fixes:** Enforce DESC ordering (most recent first); remove 7-day average and adherence from summary card; drop unused calculations; add ordering test.
- **Export Metadata:** Extend metadata with profileName, DOB, patientId, doctorName, clinicName; include in JSON; add CSV header rows with `_sanitizeCsvCell`; keep data tables unchanged.
- **Import Metadata & Warning:** Parse profile info; compare to active profile; block with dialog on mismatch (show both names, default cancel, allow proceed); no DB writes before confirmation; legacy files without names skip warning.

## Key Files to Modify
- Charts: lib/views/analytics/widgets/bp_dual_axis_chart.dart (or new bp_split_chart.dart), painters, analytics_viewmodel.dart.
- Settings: lib/views/home_view.dart.
- Med History: lib/views/medication/medication_history_view.dart; viewmodels/services; summary card widget.
- Export: lib/models/export_import.dart; lib/services/export_service.dart; export tests.
- Import: lib/models/export_import.dart; lib/services/import_service.dart; lib/viewmodels/import_viewmodel.dart; lib/views/import_view.dart; import tests.

## Sequencing
1) Models/services metadata (export/import) + tests.  
2) Import warning UX (viewmodel/view) with no writes pre-confirm.  
3) Export metadata CSV/JSON + sanitization tests.  
4) Medication history fixes + navigation cleanup.  
5) BP chart split + bands + tests.

## Risks / Mitigations
- Legacy exports without metadata: tolerate missing fields, skip warning.  
- X-axis sync complexity: use shared domain and single tick generator; widget test.  
- CSV header consumers: document added rows; table shape unchanged.  
- Over-warning: clear copy, proceed option.

## Decisions Applied
1) PDF export unchanged this phase; redesign deferred to next phase.  
2) Bands use NICE colour guidelines (not current palette).  
3) Medication front card is on History page cards (BP, Weight, Sleep, Medication); adjust that card.  
4) Profile mismatch warning compares name only; do not surface medical metadata differences.

## Ready for Review
Plan complete and aligned with CODING_STANDARDS (§1.1 security, §2.4 CI, §3 style, §8 testing). Please review and confirm or flag adjustments before implementation.


# Plan Review: Phase 10 - Export & Reports

**Reviewer:** Clive (Review Specialist)  
**Date:** December 30, 2025  
**Artifact:** [Documentation/Plans/Phase_10_Export_Reports_Plan.md](Documentation/Plans/Phase_10_Export_Reports_Plan.md)  
**Status:** ⚠️ ADJUSTMENTS REQUIRED

## 1. Scope & Acceptance Criteria
The scope correctly captures the requirements from the [Implementation_Schedule.md](../Plans/Implementation_Schedule.md). The inclusion of medications and intakes in the export/import scope is approved as it ensures full data portability.

## 2. Coding Standards Compliance
- **TypeScript/Dart Typing:** Ensure no `dynamic` types are used in the `ImportService` parsers without explicit justification. Use typed DTOs for all intermediate data structures.
- **Test Coverage:** **BLOCKER.** The plan specifies "widgets ≥70%". Per team standards, all new code must target **≥80% coverage** across all layers (Services, ViewModels, and Widgets).
- **Documentation:** DartDoc for all public APIs in the new services is required.

## 3. Technical Design Observations
- **PDF Charts:** Rasterizing `fl_chart` widgets via `RepaintBoundary` can lead to pixelation and scaling issues in PDF documents. The "vector fallback" should be more clearly defined. If rasterization is used, ensure high-DPI capture (pixelRatio ≥ 3.0).
- **Conflict Resolution:** The composite keys for duplicate detection (e.g., `timestamp + systolic + diastolic + profileId`) are sound.
- **Performance:** Streaming CSV writes is a critical inclusion for large datasets.

## 4. Findings & Required Adjustments

### Severity: High (Blocker)
1. **Test Coverage Target:** Update Section 1 and Section 5 to reflect a minimum of **80% coverage for Widgets**. The current 70% target is below the project's quality gate.

### Severity: Medium
2. **PDF Quality:** Clarify the rendering strategy in Section 2.2. If using `RepaintBoundary`, specify the pixel ratio to ensure print quality.
3. **Public API Documentation:** Explicitly list DartDoc generation for all public methods in `ExportService`, `ImportService`, and `PdfReportService` in Section 3.7.

### Severity: Low
4. **Export Metadata:** In Section 2.1 (CSV), include a header row or a separate metadata file that includes a "Sensitive Health Data" warning and the export timestamp.

## 5. Conclusion
The plan is structurally sound and addresses the core complexities of data portability and report generation. Once the test coverage targets are aligned with team standards and the PDF rendering strategy is clarified, the plan will be ready for implementation.

---
**Instructions for Tracy:** Please revise the plan to address the High and Medium severity findings above. Specifically, align the widget test coverage with the 80% standard and provide more detail on ensuring PDF chart quality.

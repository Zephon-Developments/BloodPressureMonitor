# Phase 25 Plan: PDF Report v2

**Objective**: Enhanced PDF report layout with new profile fields, time period selector, improved formatting, and proper rounding.

## Current State (Audit)
- **Phase 10**: Basic PDF report generation exists with profile info, averages, chart snapshots, and readings tables.
- **User Feedback**: Doctors require more detailed patient metadata (DOB, patient ID, doctor name, clinic name) and time period selection.
- **Gap**: Report lacks medical metadata; no time period selector; rounding inconsistent; medication not grouped; sleep metrics not detailed.

## Scope
- Update PDF report to include new profile fields: DOB, Patient ID, Doctor Name, Clinic Name (from Phase 20).
- Add time period selector to PDF generation UI (7/30/90 days).
- Implement enhanced report layout per user feedback:
  - **Front Page**: Patient details (name, DOB, gender, patient ID, report date, doctor, clinic).
  - **Summary**: Most recent readings (BP, pulse, medication, weight, sleep) with proper rounding.
  - **Detailed Readings**: Time period-filtered data with graphs and tables.
  - **Notes Section**: Space for doctor annotations.
  - **Footer**: Disclaimer (informational only, not medical advice).
- Proper rounding per spec:
  - BP/pulse: Nearest integer.
  - Weight: 0.1 kg or 0.05 lbs (based on units preference from Phase 24).
- Medication grouping in report: Group by medication name; show last date for each different medication.
- Sleep metrics: Display REM/Light/Deep when available (Phase 21); fall back to total + notes for basic entries.
- Unit tests for PDF generation with new fields and rounding logic.

## Architecture & Components

### 1. PDF Report Service Extension
**Modified File**: `lib/services/pdf_report_service.dart`
- Update `generateReport` method to accept:
  - `Profile profile` (with new fields: DOB, patient ID, doctor, clinic).
  - `TimePeriod period` (enum: sevenDays, thirtyDays, ninetyDays).
  - `UnitsPreference unitsPreference` (from Phase 24).
- Generate enhanced report layout with new sections.

**New Model**: `lib/models/pdf_report_config.dart`
- Configuration model:
  ```dart
  class PdfReportConfig {
    final Profile profile;
    final TimePeriod period;
    final UnitsPreference unitsPreference;
    final DateTime reportDate;
    
    const PdfReportConfig({
      required this.profile,
      required this.period,
      required this.unitsPreference,
      DateTime? reportDate,
    }) : reportDate = reportDate ?? DateTime.now();
  }
  
  enum TimePeriod { sevenDays, thirtyDays, ninetyDays }
  ```

### 2. Enhanced PDF Layout

#### Front Page (Page 1)
**Patient Details Section**:
- Header: "Patient Health Report" (centered, large font).
- Patient Name: [Full Name]
- Date of Birth: [MM/DD/YYYY]
- Gender: [Gender]
- Patient ID: [Unique Identifier] (or "Not provided" if null)
- Report Date: [MM/DD/YYYY]
- Doctor's Name: [Doctor's Full Name] (or "Not provided")
- Clinic Name: [Clinic Name] (or "Not provided")

**Summary of Most Recent Readings**:
- Blood Pressure: [Systolic/Diastolic mmHg] (Date) - rounded to nearest integer
- Pulse: [BPM] (Date) - rounded to nearest integer
- Medication: [Last Medication Taken] (Date) - last date for each different medication (grouped)
- Weight: [kg/lbs] (Date) - rounded to 0.1 kg or 0.05 lbs
- Sleep: [Total Hours] (Date) - include REM/Light/Deep if available

#### Detailed Readings (Pages 2+)
**Time Period Header**: "Readings from [Start Date] to [End Date] ([7/30/90] days)"

**Blood Pressure Section**:
- Graph: Systolic/Diastolic over time (use dual Y-axis from Phase 23 if implemented, else single chart).
- Table:
  - Columns: Date, Time, Systolic (mmHg), Diastolic (mmHg), Pulse (BPM)
  - All values rounded to nearest integer.
  - Sorted by date/time descending (most recent first).

**Pulse Section**:
- Graph: Pulse over time.
- Table:
  - Columns: Date, Time, Pulse (BPM)
  - Rounded to nearest integer.

**Medication Section**:
- Table (grouped by medication name):
  - Group header: [Medication Name] - [Dosage] [Unit]
  - Rows: Date, Time, Notes (if any)
  - Sorted by medication name, then date/time descending.
- Summary: Last date taken for each unique medication.

**Weight Section**:
- Graph: Weight over time.
- Table:
  - Columns: Date, Time, Weight (kg or lbs based on preference)
  - Rounded to 0.1 kg or 0.05 lbs.

**Sleep Section**:
- Graph: Sleep metrics over time.
  - If detailed data available: Stacked area (REM/Light/Deep).
  - If basic data: Bar chart (total hours).
- Table:
  - Columns: Date, Total Hours, REM, Light, Deep, Notes
  - REM/Light/Deep columns show "N/A" if basic mode entry.
  - Total Hours rounded to 0.1 hours.

#### Notes Section (Last Page)
- Header: "Doctor's Notes"
- Blank space (1/2 page) for handwritten annotations.

#### Footer (All Pages)
- Small text at bottom: "Disclaimer: This report is for informational purposes only and does not constitute medical advice. Please consult your healthcare provider for medical decisions."
- Page numbers: "Page X of Y" (bottom right).

### 3. PDF Generation UI Enhancement
**Modified File**: `lib/views/export/export_view.dart`
- Add time period selector (radio buttons or dropdown): 7 Days / 30 Days / 90 Days.
- Pre-populate doctor name and clinic name from profile (if set); allow override in form.
- Display patient ID from profile (read-only in report form).
- Ensure DOB is displayed and included in report.
- "Generate PDF" button disabled until all required fields present (name, DOB).

### 4. Rounding Utilities
**Modified File**: `lib/utils/formatting.dart` (or create if not exists)
- Add rounding helpers:
  ```dart
  int roundToInteger(double value) => value.round();
  double roundToDecimal(double value, int decimalPlaces) {
    final factor = pow(10, decimalPlaces);
    return (value * factor).round() / factor;
  }
  String formatBP(int systolic, int diastolic) => '$systolic/$diastolic';
  String formatWeight(double weight, WeightUnit unit) {
    final rounded = unit == WeightUnit.kg
        ? roundToDecimal(weight, 1)
        : roundToDecimal(kgToLbs(weight), 2); // 0.05 lbs = 2 decimals
    return '${rounded.toStringAsFixed(unit == WeightUnit.kg ? 1 : 2)} ${unit.name}';
  }
  ```

### 5. Medication Grouping Logic
**New Method** in `PdfReportService`:
```dart
Map<String, List<MedicationIntake>> groupMedicationsByName(List<MedicationIntake> intakes) {
  // Group intakes by medication name
  // Return map: {medicationName: [intakes]}
}

Map<String, DateTime> getLastTakenDates(List<MedicationIntake> intakes) {
  // Return map: {medicationName: lastDate}
}
```

## Implementation Tasks (Detailed)

### Task 1: PDF Report Config Model
**New File**: `lib/models/pdf_report_config.dart`
**Subtasks**:
1. Define `PdfReportConfig` class with profile, period, unitsPreference, reportDate.
2. Define `TimePeriod` enum.
3. Add DartDoc explaining model purpose.

**Estimated Lines**: ~40 lines.

### Task 2: Enhanced PDF Layout Implementation
**Modified File**: `lib/services/pdf_report_service.dart`
**Subtasks**:
1. Update `generateReport` signature to accept `PdfReportConfig`.
2. Implement front page layout:
   - Patient details section with all new fields.
   - Summary of most recent readings with proper rounding.
3. Implement detailed readings sections for BP, Pulse, Medication, Weight, Sleep.
4. Add graphs (reuse existing chart rendering or use `pdf` package charting).
5. Add tables with proper formatting and rounding.
6. Implement medication grouping logic.
7. Add notes section (blank space for annotations).
8. Add disclaimer footer on all pages.
9. Add page numbers.

**Estimated Changes**: +400 lines (major enhancement).

### Task 3: Rounding & Formatting Utilities
**New/Modified File**: `lib/utils/formatting.dart`
**Subtasks**:
1. Implement `roundToInteger`, `roundToDecimal` helpers.
2. Implement `formatBP`, `formatWeight` with unit support.
3. Implement `formatSleep` for sleep hours/minutes.
4. Add unit tests for all formatting functions.

**Estimated Lines**: ~80 lines.

### Task 4: Medication Grouping in Report
**Modified File**: `lib/services/pdf_report_service.dart`
**Subtasks**:
1. Implement `groupMedicationsByName` method.
2. Implement `getLastTakenDates` method.
3. Use grouping in medication section of PDF:
   - Group header for each medication.
   - Rows for each intake of that medication.
   - Summary line: "Last taken: [Date]".

**Estimated Changes**: +60 lines.

### Task 5: Sleep Metrics in Report
**Modified File**: `lib/services/pdf_report_service.dart`
**Subtasks**:
1. Detect sleep entry mode (detailed vs basic) for each entry.
2. For detailed entries: display REM/Light/Deep in table and stacked graph.
3. For basic entries: display total hours + notes; show "N/A" for REM/Light/Deep columns.
4. Graph: stacked area for detailed, bar chart for basic (mixed mode if needed).

**Estimated Changes**: +80 lines.

### Task 6: Time Period Filtering
**Modified File**: `lib/services/pdf_report_service.dart`
**Subtasks**:
1. Calculate date range based on `TimePeriod`:
   - sevenDays: last 7 days from reportDate.
   - thirtyDays: last 30 days.
   - ninetyDays: last 90 days.
2. Filter all readings (BP, pulse, medication, weight, sleep) by date range.
3. Display filtered data in report.

**Estimated Changes**: +30 lines.

### Task 7: PDF Generation UI Enhancement
**Modified File**: `lib/views/export/export_view.dart`
**Subtasks**:
1. Add time period selector (radio buttons: 7 / 30 / 90 Days).
2. Display profile fields: Name, DOB, Patient ID, Doctor Name, Clinic Name.
3. Pre-populate doctor/clinic from profile; allow override (optional fields).
4. Validate: Name and DOB required for PDF generation.
5. On "Generate PDF" tap:
   - Create `PdfReportConfig` with selected period and profile.
   - Call `PdfReportService.generateReport(config)`.
   - Save PDF with filename: `health_report_[profileName]_[period]_[date].pdf`.

**Estimated Changes**: +100 lines.

### Task 8: Units Preference Integration
**Modified File**: `lib/services/pdf_report_service.dart`
**Subtasks**:
1. Accept `UnitsPreference` in report config.
2. Use preference to format weight values in report (kg or lbs).
3. Display unit in weight table header: "Weight (kg)" or "Weight (lbs)".

**Estimated Changes**: +20 lines.

## Acceptance Criteria

### Functional
- ✅ PDF report includes all new profile fields: DOB, Patient ID, Doctor Name, Clinic Name.
- ✅ User can select time period (7/30/90 days) for report generation.
- ✅ Front page displays patient details and summary of most recent readings.
- ✅ Detailed sections include graphs and tables for BP, Pulse, Medication, Weight, Sleep.
- ✅ Rounding is correct per spec:
  - BP/pulse: Nearest integer.
  - Weight: 0.1 kg or 0.05 lbs.
  - Sleep: 0.1 hours.
- ✅ Medication intakes grouped by medication name; last date shown for each.
- ✅ Sleep metrics display REM/Light/Deep when available; fall back to total + notes.
- ✅ Notes section provides space for doctor annotations.
- ✅ Disclaimer footer on all pages.
- ✅ Page numbers on all pages.

### Quality
- ✅ All new code follows [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §3 (Dart/Flutter standards).
- ✅ DartDoc comments on all new services and utilities (§3.2).
- ✅ Unit tests for formatting utilities (≥90% coverage per §8.1).
- ✅ Unit tests for PdfReportService with new fields (≥85% coverage per §8.1).
- ✅ Integration tests for PDF generation with various configurations.
- ✅ `flutter analyze` passes with zero warnings/errors (§2.4).
- ✅ `dart format --set-exit-if-changed lib test` passes (§2.4).

### Accessibility
- ✅ PDF generation form is accessible (screen reader compatible).
- ✅ Time period selector has semantic labels.

## Dependencies
- Phase 20 (Profile Model Extensions): DOB, Patient ID, Doctor Name, Clinic Name fields available.
- Phase 21 (Enhanced Sleep): Sleep metrics (REM/Light/Deep) available for detailed display.
- Phase 24 (Units & Accessibility): UnitsPreference available for weight formatting.

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| PDF generation fails with missing optional fields | Medium | Gracefully handle null values; display "Not provided" for optional fields |
| Charts in PDF don't render correctly | High | Use `pdf` package chart widgets; fallback to tables-only if charts fail |
| Large datasets cause PDF generation to hang | Medium | Limit PDF to selected time period (max 90 days); add progress indicator |
| Medication grouping logic complex | Low | Thoroughly test with various medication scenarios; add unit tests |

## Testing Strategy

### Unit Tests
**New File**: `test/utils/formatting_test.dart`
- Test `roundToInteger` with various values.
- Test `roundToDecimal` with various decimal places.
- Test `formatBP`, `formatWeight`, `formatSleep`.
- Test edge cases: 0, negative, very large values.

**Modified File**: `test/services/pdf_report_service_test.dart`
- Test PDF generation with new profile fields (all present).
- Test PDF generation with missing optional fields (patient ID, doctor, clinic).
- Test time period filtering (7/30/90 days).
- Test medication grouping logic.
- Test sleep metrics display (detailed vs basic).
- Test rounding accuracy in generated PDF data.

**New File**: `test/models/pdf_report_config_test.dart`
- Test config model creation and serialization.

**Estimated**: 35 unit tests.

### Integration Tests
**New File**: `test_driver/pdf_report_generation_test.dart`
- Create profile with all fields; add readings for 90 days.
- Generate PDF for 7-day period; verify content.
- Generate PDF for 30-day period; verify filtering.
- Generate PDF for 90-day period; verify completeness.
- Test PDF generation with missing optional fields.

**Estimated**: 5 integration tests.

### Manual Testing
- Visual inspection of generated PDF:
  - Verify layout matches spec (front page, detailed sections, notes, footer).
  - Verify rounding accuracy for all metrics.
  - Verify medication grouping displays correctly.
  - Verify sleep metrics display (detailed vs basic).
  - Verify doctor/clinic name pre-populated from profile.
- Test with real-world data (various profiles, time periods).

## Branching & Workflow
- **Branch**: `feature/phase-25-pdf-report-v2`
- Follow [CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md) §2.1 (branching) and §2.4 (CI gates).
- All changes via PR; require CI green + review approval before merge.

## Rollback Plan
- Feature-flag new PDF layout; fall back to Phase 10 PDF format if critical issues.
- Optional fields gracefully handle null values; no breaking changes.
- No schema changes; rollback is non-destructive.

## Performance Considerations
- **PDF Generation**: For large datasets (>1000 readings), generation may take 5-10 seconds; add progress indicator.
- **Chart Rendering**: Use optimized chart widgets from `pdf` package; downsample data if >500 points.
- **File Size**: Enhanced PDF with charts may be larger (1-5 MB); acceptable for modern devices.

## Documentation Updates
- **User-facing**: Add note to QUICKSTART.md explaining PDF report features and time period selection.
- **Developer-facing**: Update [Implementation_Schedule.md](Implementation_Schedule.md) to mark Phase 25 complete upon merge.
- **Sample PDF**: Generate sample PDF with mock data; include in documentation for reference.

---

**Phase Owner**: Implementation Agent  
**Reviewer**: Clive (Review Specialist)  
**Estimated Effort**: 4-6 days (including PDF layout, testing, and review)  
**Target Completion**: TBD based on sprint schedule

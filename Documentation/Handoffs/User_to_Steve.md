
# User Feedback & Feature Requests

## Medications
- Entry screen does not time out to login if left open (idle timeout should match other entry screens)
- **Grouping functionality**: Currently missing
- **Add Medication**:
    - Restrict dosage to numeric entry
    - Make unit a combo box (select common units or type custom)
    - Add an X on the search bar to clear instantly

## Sleep
- **Schema**:
    - Date: Record at end of sleep period
    - Details: Record either sleep metrics (REM, Light, Deep) or basic details (total hours, notes)

## Profile Homepage
1. **Post-Unlock Profile Selection**: Good as is
2. **Layout**: Array of large, friendly buttons:
     - Log Blood Pressure
     - Log Medication
     - Log Sleep
     - Log Weight
3. **Button Functionality**: Each opens respective entry screen

## History Page
### Sections
    - Blood Pressure
    - Pulse
    - Medication
    - Weight
    - Sleep
### Features
1. Each section collapsible (closed by default)
2. Each section displays:
     - Button to open full history
     - Summary of most recent 10 readings
     - **Mini-Stats**: e.g., "Latest: 128/82 (avg last 7 days)"

## Settings Page
- Remove the medication log
- **Units Consistency**: Add toggle for preferred units (kg/lbs, °C/°F) in Appearance or new Units section

## Analytics
- **Graph Style**: Default to raw line graph (bezier curves are hard to read); add toggle for smoothing (rolling average, window = 10% of displayed readings)
- **Blood Pressure Graph Structure**:
    - **Upper Y-Axis (Systolic: 50-200 mmHg)**
        - Red: 180-200 (Hypertensive Crisis)
        - Yellow: 140-179 (High)
        - Green: 90-139 (Normal)
        - Yellow: 50-89 (Low)
    - **X-Axis**: Time/Date, in clear zone
    - **Lower Y-Axis (Diastolic: 30-150 mmHg)**
        - Red: 120-150 (Hypertensive Crisis)
        - Yellow: 90-119 (High)
        - Green: 60-89 (Normal)
        - Yellow: 30-59 (Low)
    - **Clear Zone**: Neutral band with X-axis labels, separates systolic/diastolic
    - Each reading: plot two points (systolic/diastolic), align vertically

## Doctor's PDF Report
### Required Schema/UI Updates
- **Profile Model Extensions**:
    - Add date of birth (required)
    - Add optional: patient ID (NHS number), doctor's name, clinic name
    - One-time migration to add these fields

### Layout
#### Front Page: Patient Details
    - Patient Name
    - Date of Birth
    - Gender
    - Patient ID (if supplied)
    - Report Date
    - Doctor's Name (if supplied)
    - Clinic Name (if supplied)
#### Summary of Most Recent Readings
    - Blood Pressure: Systolic/Diastolic (rounded to nearest integer, date)
    - Pulse: BPM (rounded to nearest integer, date)
    - Medication: Last taken (date, per medication)
    - Weight: Rounded to nearest 0.1kg / 0.05lb (date)
    - Sleep: Total hours (date)
#### Detailed Readings
    - Time Period: 7/30/90 days
    - Blood Pressure: Graph + table (rounded to nearest integer)
    - Pulse: Graph + table (rounded to nearest integer)
    - Medication: Table, grouped by name
    - Weight: Graph + table
    - Sleep: Graph + table
#### Notes Section
    - Space for doctor notes
#### Footer
    - Disclaimer: Informational only, not medical advice
#### Export/Report Selector
    - Add time period selector (7/30/90/all days) to PDF export

## Accessibility
- Ensure all large buttons have semantic labels for screen readers
- Check color contrast for all chart zones and UI elements (especially high-contrast mode)

## General Enhancements
- **Medication Log Quick Action**: After grouping, Log Medication button should open group picker first (showing most common meds), with fallback to individual picker
- **Idle Timeout Consistency**: Apply uniform idle-to-lock timeout across all entry screens


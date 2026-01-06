# HealthLog Import Formats

This document describes the supported formats for importing health data into HealthLog. HealthLog supports importing data from JSON and CSV files for the following data types:

- Blood pressure readings
- Weight entries
- Sleep logs
- Medications
- Medication intakes

## JSON Format

The JSON import file should be a single object containing arrays of data for each supported type. All top-level keys are optional - you can include only the data types you want to import.

### Schema

```json
{
  "readings": [
    {
      "profileId": 1,
      "systolic": 120,
      "diastolic": 80,
      "pulse": 72,
      "takenAt": "2024-01-15T10:30:00.000Z",
      "localOffsetMinutes": 0,
      "posture": "sitting",
      "arm": "left",
      "medsContext": "1,2",
      "irregularFlag": false,
      "tags": "morning,fasting",
      "note": "Felt good today"
    }
  ],
  "weight": [
    {
      "profileId": 1,
      "takenAt": "2024-01-15T07:00:00.000Z",
      "localOffsetMinutes": 0,
      "weightValue": 70.5,
      "unit": "kg",
      "notes": "Morning weight",
      "saltIntake": "moderate",
      "exerciseLevel": "light",
      "stressLevel": "low",
      "sleepQuality": "good"
    }
  ],
  "sleep": [
    {
      "profileId": 1,
      "startedAt": "2024-01-14T22:00:00.000Z",
      "endedAt": "2024-01-15T06:00:00.000Z",
      "durationMinutes": 480,
      "quality": 4,
      "deepMinutes": 120,
      "lightMinutes": 300,
      "remMinutes": 60,
      "awakeMinutes": 0,
      "localOffsetMinutes": 0,
      "notes": "Good night's sleep"
    }
  ],
  "medications": [
    {
      "profileId": 1,
      "name": "Lisinopril",
      "dosage": "10",
      "unit": "mg",
      "frequency": "once daily",
      "scheduleMetadata": "{\"v\":1,\"frequency\":\"daily\",\"times\":[\"08:00\"],\"daysOfWeek\":[1,2,3,4,5,6,7],\"graceMinutesLate\":15,\"graceMinutesMissed\":60}"
    }
  ],
  "medicationIntakes": [
    {
      "medicationId": 1,
      "profileId": 1,
      "takenAt": "2024-01-15T08:00:00.000Z",
      "localOffsetMinutes": 0,
      "scheduledFor": "2024-01-15T08:00:00.000Z",
      "groupId": null,
      "note": "Taken with breakfast"
    }
  ]
}
```

### Field Descriptions

#### Readings
- `profileId`: Integer - The profile ID this reading belongs to (will be overridden during import)
- `systolic`: Integer - Systolic blood pressure in mmHg (70-250)
- `diastolic`: Integer - Diastolic blood pressure in mmHg (40-150)
- `pulse`: Integer - Pulse rate in bpm (30-200)
- `takenAt`: String - ISO 8601 timestamp when reading was taken
- `localOffsetMinutes`: Integer - UTC offset in minutes at time of reading
- `posture`: String (optional) - Posture during measurement (e.g., "sitting", "lying")
- `arm`: String (optional) - Arm used ("left" or "right")
- `medsContext`: String (optional) - Comma-separated medication intake IDs
- `irregularFlag`: Boolean - Whether irregular heartbeat was detected
- `tags`: String (optional) - Comma-separated tags
- `note`: String (optional) - Additional notes

#### Weight Entries
- `profileId`: Integer - The profile ID this entry belongs to (will be overridden during import)
- `takenAt`: String - ISO 8601 timestamp when weight was recorded
- `localOffsetMinutes`: Integer - UTC offset in minutes at time of recording
- `weightValue`: Number - Weight value as entered
- `unit`: String - Unit of measurement ("kg" or "lbs")
- `notes`: String (optional) - General notes
- `saltIntake`: String (optional) - Salt intake level
- `exerciseLevel`: String (optional) - Exercise level
- `stressLevel`: String (optional) - Stress level
- `sleepQuality`: String (optional) - Sleep quality

#### Sleep Entries
- `profileId`: Integer - The profile ID this entry belongs to (will be overridden during import)
- `startedAt`: String - ISO 8601 timestamp when sleep started
- `endedAt`: String (optional) - ISO 8601 timestamp when sleep ended
- `durationMinutes`: Integer - Total sleep duration in minutes
- `quality`: Integer (optional) - Sleep quality rating (1-5)
- `deepMinutes`: Integer (optional) - Minutes in deep sleep
- `lightMinutes`: Integer (optional) - Minutes in light sleep
- `remMinutes`: Integer (optional) - Minutes in REM sleep
- `awakeMinutes`: Integer (optional) - Minutes awake
- `localOffsetMinutes`: Integer - UTC offset in minutes at end of sleep
- `notes`: String (optional) - Notes about the sleep

#### Medications
- `profileId`: Integer - The profile ID this medication belongs to (will be overridden during import)
- `name`: String - Name of the medication
- `dosage`: String (optional) - Dosage amount
- `unit`: String (optional) - Dosage unit (e.g., "mg", "tablets")
- `frequency`: String (optional) - Frequency description
- `scheduleMetadata`: String (optional) - JSON string with scheduling information

#### Medication Intakes
- `medicationId`: Integer - ID of the medication taken
- `profileId`: Integer - The profile ID this intake belongs to (will be overridden during import)
- `takenAt`: String - ISO 8601 timestamp when medication was taken
- `localOffsetMinutes`: Integer - UTC offset in minutes at time of intake
- `scheduledFor`: String (optional) - ISO 8601 timestamp when intake was scheduled
- `groupId`: Integer (optional) - Group ID if part of a group intake
- `note`: String (optional) - Notes about the intake

## CSV Format

The CSV import file uses section headers to separate different data types. Each section starts with a comment line `# SECTION_NAME`, followed by a header row, then data rows.

Currently, only readings are supported in CSV format. Support for other data types may be added in future versions.

**Note**: CSV format does not support profile ID columns. The profile ID is assigned during import based on the selected profile in the app.

### Format

```
# READINGS
systolic,diastolic,pulse,takenAt,localOffsetMinutes,posture,arm,medsContext,irregularFlag,tags,note
120,80,72,2024-01-15T10:30:00.000Z,0,sitting,left,,0,morning\,fasting,Felt good today
125,85,75,2024-01-15T14:30:00.000Z,0,standing,right,1\,2,1,afternoon\,after lunch,Bit stressed
```

### Field Descriptions

#### Readings Headers
- `systolic`: Integer - Systolic blood pressure in mmHg
- `diastolic`: Integer - Diastolic blood pressure in mmHg
- `pulse`: Integer - Pulse rate in bpm
- `takenAt`: String - ISO 8601 timestamp when reading was taken
- `localOffsetMinutes`: Integer - UTC offset in minutes at time of reading
- `posture`: String (optional) - Posture during measurement
- `arm`: String (optional) - Arm used
- `medsContext`: String (optional) - Comma-separated medication intake IDs
- `irregularFlag`: Integer - Whether irregular heartbeat was detected (1 = irregular heartbeat detected, 0 = no irregular heartbeat). In the JSON format this field is a Boolean (`true`/`false`).
- `tags`: String (optional) - Comma-separated tags (escape commas with backslash)
- `note`: String (optional) - Additional notes

## Import Behavior

- **Profile Assignment**: The `profileId` field in imported data is ignored and replaced with the selected profile during import.
- **Conflict Resolution**: You can choose to append new data or overwrite existing data.
- **Duplicates**: When appending, duplicate readings (same systolic/diastolic/pulse at same time) are skipped.
- **Validation**: Invalid data will be reported as errors but won't stop the import of valid records.
- **Date Formats**: All timestamps must be in ISO 8601 format (e.g., "2024-01-15T10:30:00.000Z").

## Examples

### Sample JSON File
```json
{
  "readings": [
    {
      "systolic": 118,
      "diastolic": 78,
      "pulse": 70,
      "takenAt": "2024-01-15T08:00:00.000Z",
      "localOffsetMinutes": -300,
      "posture": "sitting",
      "arm": "left",
      "irregularFlag": false,
      "tags": "morning",
      "note": "Before breakfast"
    }
  ]
}
```

### Sample CSV File
```
# READINGS
systolic,diastolic,pulse,takenAt,localOffsetMinutes,posture,arm,medsContext,irregularFlag,tags,note
118,78,70,2024-01-15T08:00:00.000Z,-300,sitting,left,,0,morning,Before breakfast
```
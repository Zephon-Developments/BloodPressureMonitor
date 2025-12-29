# Handoff: Steve → Tracy

**Date**: 2025-12-29  
**From**: Steve (Project Lead / Workflow Conductor)  
**To**: Tracy (Planning & Architecture)  
**Task**: Phase 4 - Weight & Sleep Data Management  
**Status**: 🎯 **READY FOR PLANNING**

---

## Objective

Design and plan the implementation of Phase 4: Weight & Sleep data management, including:
- Data models and database schema
- CRUD services for weight and sleep entries
- UI components for data input
- Basic correlation hooks for morning BP readings
- Comprehensive test coverage

---

## Scope & Requirements

### Core Features Required

#### 1. Weight Management
- **WeightEntry Model**: timestamp, weight value, unit (kg/lbs), optional notes
- **Optional Context Fields**: salt intake, exercise level, stress/sleep quality indicators
- **CRUD Operations**: Create, read, update, delete weight entries
- **UI Input Form**: Simple form for manual weight entry with validation
- **History View**: List of weight entries with trend visualization (future enhancement hook)

#### 2. Sleep Management
- **SleepEntry Model**: date, sleep start/end times, total duration, sleep quality rating
- **Source Metadata**: Manual entry vs device import (hook for future integrations)
- **CRUD Operations**: Create, read, update, delete sleep entries
- **UI Input Form**: Form for manual sleep logging (start time, end time, quality)
- **Device Import Hook**: Architecture for future import from sleep trackers

#### 3. Correlation Foundation
- **Morning BP Correlation**: Link morning BP readings with previous night's sleep
- **Weight Correlation**: Track weight trends alongside BP patterns
- **Data Retrieval**: Services to fetch correlated data for analytics (Phase 8)
- **No Advice Yet**: Just data storage and retrieval; correlation analytics come later

---

## Constraints

### Technical Constraints
- **Database**: Use existing encrypted SQLite schema from Phase 1
- **Models**: Follow established patterns (toMap/fromMap, equality, DartDoc)
- **Services**: Maintain MVVM architecture with repository pattern
- **Testing**: Achieve ≥85% coverage for services, ≥70% for widgets
- **Standards**: Follow Documentation/Standards/Coding_Standards.md

### Design Constraints
- **UI Consistency**: Match Phase 6 UI patterns (CustomTextField, form validation, etc.)
- **Accessibility**: Ensure WCAG AA compliance
- **Performance**: Efficient queries for large datasets
- **Privacy**: All data remains local-only (encrypted at rest)

### Dependency Constraints
- **Phase 1**: Database schema must be extended (new tables for weight/sleep)
- **Phase 2**: No dependencies on averaging engine
- **Phase 6**: UI components should follow existing patterns

---

## Success Metrics

### Functional Success
- [ ] Users can manually log weight entries with optional context
- [ ] Users can manually log sleep data with start/end times and quality
- [ ] Data persists correctly and retrieves efficiently
- [ ] Basic correlation hooks are in place for future analytics
- [ ] UI forms validate input and provide clear feedback

### Quality Success
- [ ] Unit tests ≥85% for services (models, DAOs, business logic)
- [ ] Widget tests ≥70% for UI components
- [ ] `flutter analyze` reports zero issues
- [ ] All tests pass (no regressions from existing 555 tests)
- [ ] Code reviewed and approved by Clive

### User Experience Success
- [ ] Weight/sleep input is quick and intuitive
- [ ] Forms follow established UI patterns from Phase 6
- [ ] Clear navigation from home screen to weight/sleep entry
- [ ] Data is immediately visible after entry (confirmation)

---

## Architecture Considerations

### Database Schema Extensions
Based on Phase 1 foundation, we need:

**Table: weight_entries**
- `id` (INTEGER PRIMARY KEY)
- `profile_id` (INTEGER, FK to profiles)
- `recorded_at` (INTEGER, timestamp)
- `weight_kg` (REAL, normalized to kg)
- `unit` (TEXT, 'kg' or 'lbs')
- `notes` (TEXT, optional)
- `salt_level` (TEXT, optional: 'low', 'medium', 'high')
- `exercise_level` (TEXT, optional: 'none', 'light', 'moderate', 'intense')
- `stress_level` (INTEGER, optional: 1-5 scale)

**Table: sleep_entries**
- `id` (INTEGER PRIMARY KEY)
- `profile_id` (INTEGER, FK to profiles)
- `sleep_date` (TEXT, ISO date for the night)
- `sleep_start` (INTEGER, timestamp)
- `sleep_end` (INTEGER, timestamp)
- `duration_minutes` (INTEGER, calculated)
- `quality_rating` (INTEGER, 1-5 scale)
- `notes` (TEXT, optional)
- `source` (TEXT, 'manual' or 'device')
- `source_metadata` (TEXT, JSON for future device data)

### Service Layer
- `WeightService`: CRUD operations, unit conversion
- `SleepService`: CRUD operations, duration calculation, overlap detection
- `CorrelationService`: Future hook for linking BP/weight/sleep data

### ViewModel Layer
- `WeightViewModel`: State management for weight tracking
- `SleepViewModel`: State management for sleep logging
- Extend `BloodPressureViewModel`: Add correlation data retrieval

### UI Components
- `AddWeightView`: Form for weight entry
- `WeightHistoryView`: List of weight entries (basic; enhanced in Phase 7)
- `AddSleepView`: Form for sleep logging
- `SleepHistoryView`: List of sleep entries
- Navigation integration: Quick actions from home screen

---

## Reference Materials

### Existing Patterns to Follow
- **Forms**: See [lib/views/readings/add_reading_view.dart](lib/views/readings/add_reading_view.dart)
- **Validation**: See [lib/utils/validators.dart](lib/utils/validators.dart)
- **Widgets**: See [lib/widgets/common/custom_text_field.dart](lib/widgets/common/custom_text_field.dart)
- **Services**: See [lib/services/database_service.dart](lib/services/database_service.dart)
- **ViewModels**: See [lib/viewmodels/blood_pressure_viewmodel.dart](lib/viewmodels/blood_pressure_viewmodel.dart)

### Standards & Guidelines
- **Coding Standards**: [Documentation/Standards/Coding_Standards.md](Documentation/Standards/Coding_Standards.md)
- **Implementation Schedule**: [Documentation/Plans/Implementation_Schedule.md](Documentation/Plans/Implementation_Schedule.md)

---

## Tracy's Deliverables

Please create a comprehensive implementation plan that includes:

1. **Database Schema**: Detailed table definitions with migrations
2. **Model Definitions**: Dart classes with full documentation
3. **Service Architecture**: CRUD operations and business logic
4. **UI Mockup/Wireframe**: Description of forms and navigation flow
5. **Test Strategy**: Unit and widget test scenarios
6. **Implementation Tasks**: Broken down for Georgina/Claudette
7. **Acceptance Criteria**: Clear definition of "done"
8. **Risk Assessment**: Potential blockers and mitigation strategies

### Output Format
Create the plan in: `Documentation/Plans/Phase_4_Weight_Sleep_Plan.md`

Include:
- Complete technical specifications
- Step-by-step implementation sequence
- Dependency mapping
- Test scenarios and coverage targets
- Rollback points if issues arise

---

## Next Steps

1. **Tracy**: Review this handoff and create the detailed implementation plan
2. **Tracy**: Review against CODING_STANDARDS.md for compliance
3. **Tracy**: Hand off to Clive for plan review (Documentation/Handoffs/Tracy_to_Clive.md)
4. **Clive**: Review plan for completeness and feasibility
5. **Steve**: Select implementer (Georgina or Claudette) based on plan complexity
6. **Implementation**: Execute Phase 4 with continuous quality checks

---

## Timeline Expectations

- **Planning**: 1 session (Tracy)
- **Plan Review**: 1 session (Clive)
- **Implementation**: 2-3 sessions (Georgina/Claudette)
- **QA Review**: 1 session (Clive)
- **Integration**: 1 session (Steve)

**Target Completion**: Within 1 week

---

## Questions for Tracy

- Should we implement both weight and sleep in one phase, or split them?
- What's the best approach for unit conversion (kg ↔ lbs)?
- How should we handle sleep entries that cross midnight?
- Should we validate sleep duration (min/max reasonable hours)?
- What's the UX for quick weight entry vs detailed entry?

---

**Handoff Complete**: Tracy, please proceed with Phase 4 planning and reference CODING_STANDARDS.md throughout.


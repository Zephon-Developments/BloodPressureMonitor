# Handoff: Steve → Tracy
## Phase 24B Implementation Spec Request: Units Preference

**Date:** 2026-01-02  
**From:** Steve (Project Manager / Lead)  
**To:** Tracy (Planning & Architecture)

---

## Context

Phase 24A (Navigation & Date Range Selector Resilience) has been **successfully completed** and approved by Clive. All tests are passing (939 tests), and the analytics view now maintains the TimeRangeSelector visibility across all states.

We are now proceeding to **Phase 24B: Units Preference Implementation**.

---

## Objective for Phase 24B

Implement app-wide units preference system that allows users to select their preferred weight units (kg vs lbs) with future support for temperature units (°C vs °F).

### Key Requirements:
1. **Storage Convention**: All data stored internally in SI units (kg, °C) — never convert storage layer
2. **Display Conversion**: Convert to user's preferred units only at display/input boundaries
3. **User Settings**: Add units preference UI in Settings (likely extending appearance_view.dart)
4. **Persistence**: Use SharedPreferences for preference storage
5. **Accuracy**: Conversion must be precise and reversible
6. **Future-Ready**: Architecture should accommodate temperature units when needed

---

## Scope Reference Documents

Tracy, please review these existing planning documents:

1. **[Documentation/Plans/Phase_24_Units_Accessibility_Plan.md](../Plans/Phase_24_Units_Accessibility_Plan.md)**
   - Contains detailed architecture for units preference
   - Defines models, services, and conversion utilities
   - Specifies UI integration points

2. **[Documentation/Plans/Phase_24_Implementation_Spec.md](../Plans/Phase_24_Implementation_Spec.md)**
   - Provides broader context for Phase 24
   - Outlines sequencing: 24A (complete) → 24B (current) → 24C → 24D

3. **[Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)**
   - Must be followed for all implementations
   - Section 3: Dart/Flutter standards
   - Section 8: Testing requirements (≥85% service coverage, ≥70% widget coverage)

---

## Key Files to Be Created (from existing plan):

### 1. Model Layer
- **lib/models/units_preference.dart**
  - `UnitsPreference` class with `weightUnit` and `temperatureUnit`
  - `WeightUnit` enum (kg, lbs)
  - `TemperatureUnit` enum (celsius, fahrenheit)
  - JSON serialization for SharedPreferences

### 2. Service Layer
- **lib/services/units_preference_service.dart**
  - `getUnitsPreference()` → loads from SharedPreferences
  - `saveUnitsPreference(UnitsPreference pref)` → persists
  - Defaults: kg for weight, Celsius for temperature

### 3. Utilities
- **lib/utils/unit_conversion.dart**
  - `kgToLbs(double kg)` and `lbsToKg(double lbs)`
  - `celsiusToFahrenheit(double c)` and `fahrenheitToCelsius(double f)`
  - `formatWeight(double value, WeightUnit unit)` → display helper
  - Comprehensive unit tests required

### 4. UI Integration
- **Modify: lib/views/appearance_view.dart** OR **Create: lib/views/units_settings_view.dart**
  - Radio buttons or dropdown for weight unit selection
  - Temperature unit selector (disabled/greyed out with "Coming soon" tooltip)
  - Save preference on selection; apply immediately

### 5. Weight Display Updates
- **lib/views/weight/add_weight_view.dart** (or add_edit_weight_view.dart)
- **lib/views/weight/weight_history_view.dart**
- **lib/views/analytics/widgets/** (any weight charts)
- **Important**: Input always stored as kg; display converts to preferred unit

---

## Tracy's Deliverables

Please create a **comprehensive implementation specification** for Phase 24B with the following sections:

### 1. Architecture Design
- Detailed class diagrams for UnitsPreference model
- Service layer interaction with SharedPreferences
- Data flow diagram: User Input → Conversion → Storage (SI) → Retrieval → Display Conversion

### 2. Implementation Tasks
Break down into atomic tasks:
- Task 1: Create UnitsPreference model with tests
- Task 2: Create UnitsPreferenceService with tests
- Task 3: Create unit conversion utilities with comprehensive tests
- Task 4: Integrate units selector UI in Settings
- Task 5: Update weight input views
- Task 6: Update weight display views (history, charts)
- Each task should specify:
  - Files to create/modify
  - Code patterns to follow
  - Test requirements
  - Estimated lines of code

### 3. Data Migration Considerations
- Existing weight data is already in kg (confirm with codebase audit)
- No migration needed if storage is already SI
- Document verification process

### 4. Quality Gates
- Unit test coverage targets (≥85% for services per CODING_STANDARDS.md)
- Widget test scenarios for Settings UI
- Integration test for end-to-end preference flow
- Error handling scenarios (SharedPreferences failure, invalid conversions)

### 5. Edge Cases & Error Handling
- What happens if SharedPreferences fails?
- What if preference is corrupted?
- How to handle very large/small values in conversion?
- Precision considerations (decimal places for display)

### 6. Success Metrics
Define clear acceptance criteria:
- User can select kg/lbs in Settings ✓
- Preference persists across app restarts ✓
- Weight input is stored in kg regardless of display unit ✓
- All weight displays show correct converted value ✓
- Conversion is bidirectional and accurate ✓

### 7. Clive Review Preparation
- Checklist of items for Clive to verify during review
- Test execution proof requirements
- Code quality verification points

---

## Important Constraints

1. **No Breaking Changes**: Existing weight data must continue to work
2. **SI Storage Only**: Never store converted values; always store kg
3. **Immediate Application**: Preference change should reflect immediately in UI (no restart required)
4. **Future-Proof**: Architecture must support temperature units without major refactoring
5. **CODING_STANDARDS.md Compliance**: All code must pass `flutter analyze` and `dart format`

---

## Timeline Expectations

Phase 24B is a critical foundation for Phase 24C (Accessibility) and 24D (Landscape). Please prioritize:
1. **Architecture clarity** (prevent rework)
2. **Test coverage** (catch conversion bugs early)
3. **Clean handoff to Clive** (detailed review checklist)

Expected timeline: 2-3 days for spec creation, then handoff to Clive for review before implementation.

---

## Questions for Tracy

Before creating the spec, please audit:
1. **Current weight storage**: Verify that existing weight entries are already stored in kg (check database schema/service layer)
2. **Existing preference patterns**: Check if there's an existing preference service we should extend (e.g., theme preferences)
3. **Settings UI structure**: Confirm whether to extend appearance_view.dart or create new units_settings_view.dart
4. **Chart integration**: Identify all weight chart widgets that need updating

Document your findings in the spec.

---

## Next Steps

1. **Tracy**: Create detailed implementation spec at `Documentation/Plans/Phase_24B_Units_Preference_Spec.md`
2. **Tracy**: When complete, create handoff document at `Documentation/Handoffs/Tracy_to_Clive.md` (overwrite prior)
3. **Tracy**: Notify user when handoff is ready for Clive's review
- Document current behavior when no data is present
- Propose implementation changes to keep selectors visible with appropriate messaging

### 4. Implementation Specification
Create a comprehensive spec including:
- **Module structure**: List all files to be created or modified
- **Component dependencies**: Service → ViewModel → View flow
- **Data flow diagrams**: How units preference flows through the app
- **Responsive design patterns**: Specific breakpoints and layout rules
- **Accessibility checklist**: Specific widgets/screens requiring semantic labels
- **Test coverage plan**: Which tests to write for each module

### 5. Risk Assessment
- Identify potential integration conflicts
- Flag any screens that may be challenging for landscape support
- Assess complexity of accessibility audit scope
- Highlight any dependencies on external packages

## Reference Materials
- Review existing ViewModel patterns: [lib/viewmodels/](../../lib/viewmodels/)
- Review existing Service patterns: [lib/services/](../../lib/services/)
- Review existing responsive widgets (if any): [lib/widgets/](../../lib/widgets/)
- Check current navigation setup: [lib/views/navigation/](../../lib/views/navigation/) or similar
- Review coding standards: [Documentation/Standards/CODING_STANDARDS.md](../Standards/CODING_STANDARDS.md)

## Timeline
- Phase 24 is estimated at 5-7 days
- Your spec should break this into manageable sub-phases (24A, 24B, etc.)
- Consider prioritizing: Navigation fixes → Date selector fixes → Units → Accessibility → Landscape

## Output Format
Create your specification in:
- **Documentation/Plans/Phase_24_Implementation_Spec.md**

The spec should be detailed enough for Claudette or Georgina to implement without ambiguity.

## Handoff to Clive
After completing the spec:
1. Update **Documentation/Handoffs/Tracy_to_Clive.md** with your findings and spec location
2. Request Clive to review the spec for architectural soundness and completeness
3. Clive will validate the spec against coding standards before implementation begins

## Questions to Address
- Are there existing responsive design utilities, or should we create `lib/utils/responsive_utils.dart`?
- Does the app currently use semantic labels anywhere, or is this entirely new?
- Is there a high-contrast theme already defined, or does this need to be created?
- What is the current pattern for persisting user preferences (SharedPreferences wrapper service)?

---
**Next Agent**: Tracy (Architecture Specialist)
**After Tracy**: Clive (Review Specialist) to validate the implementation spec
**After Clive**: Claudette or Georgina (Implementation) to execute the plan


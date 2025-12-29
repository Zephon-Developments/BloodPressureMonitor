# Steve to Tracy Handoff - Phase 6: UI Foundation

## Assignment: Phase 6 - UI Foundation (Home & Add Reading)

Tracy, you are receiving the assignment for Phase 6: UI Foundation. This phase focuses on building the primary user interface for the Blood Pressure Monitor app.

## Phase 6 Scope

### Objectives
Build the foundational UI components for:
1. **Home/Dashboard** - Main screen with profile switcher and quick actions
2. **Add Reading Form** - Manual blood pressure entry with validation
3. **Navigation Shell** - Base navigation structure for future screens

### Key Requirements

#### 1. Home/Dashboard Screen
- Profile selector (if multiple profiles exist)
- Quick add reading button (prominent, accessible)
- Recent readings summary (show last 3-5 averaged readings)
- Navigation to other major sections (History, Charts, Settings)
- Clean, medical-focused design with Material Design 3

#### 2. Add Reading Form
- **Basic fields**:
  - Systolic (70-250 mmHg)
  - Diastolic (40-150 mmHg)
  - Pulse (30-200 bpm)
  - Timestamp (default: now, allow manual override)
  
- **Advanced section** (collapsible/expandable):
  - Arm selection (Left/Right)
  - Posture (Sitting/Standing/Lying)
  - Notes (free text)
  - Tags (comma-separated or chips)
  
- **Medication integration**:
  - Quick checkbox: "Log medication taken before this reading"
  - Link to medication intake form (if time permits, otherwise stub)
  
- **Session control**:
  - Toggle: "Start new averaging session"
  - Info tooltip explaining 30-minute averaging

- **Validation**:
  - Real-time validation using existing validators
  - Warning/error states with proper colors
  - Override confirmation for out-of-range values
  - Clear error messages

#### 3. Navigation Shell
- Bottom navigation or drawer (your design choice based on UX)
- Routes for: Home, History (stub), Charts (stub), Settings (existing)
- Proper route management with named routes
- Deep link support structure (prepare for future)

### Technical Requirements

#### Dependencies
- Phase 1 ✅ (Core Data Layer)
- Phase 2A ✅ (Averaging Engine)
- Phase 2B ✅ (Validation & ViewModel Integration)
- Phase 5 ✅ (App Security Gate - integrate with navigation)

#### Integration Points
- Wire Add Reading form to `BloodPressureViewModel`
- Trigger averaging automatically on reading creation
- Respect validation rules from `Validators`
- Lock screen should intercept navigation when locked
- Use existing `HomeView` as starting point (currently minimal)

### Acceptance Criteria

1. **Functional**:
   - ✅ User can create a reading via form
   - ✅ Validation prevents invalid data submission
   - ✅ Override confirmation works for warnings
   - ✅ Readings persist and appear in recent list
   - ✅ Averaging triggers automatically
   - ✅ Session override works when toggled

2. **Code Quality**:
   - ✅ Widget tests ≥70% coverage for new widgets
   - ✅ `flutter analyze` clean
   - ✅ `dart format` applied
   - ✅ Proper separation: widgets, forms, validation UI
   - ✅ DartDoc for public widget APIs

3. **UX/Accessibility**:
   - ✅ Keyboard navigation works
   - ✅ Screen reader labels present
   - ✅ Touch targets ≥48dp
   - ✅ Color contrast meets WCAG AA
   - ✅ Form submission feedback (loading, success, error)

4. **Performance**:
   - ✅ Form input feels responsive (<100ms)
   - ✅ No jank during navigation
   - ✅ Smooth scrolling in recent readings list

### Design Notes

- **Material Design 3**: Use `ThemeData` with Material 3 enabled
- **Medical context**: Clean, professional, trustworthy aesthetic
- **Error states**: Use red for errors, amber for warnings, green for valid
- **Icons**: Use Material Icons (already available)
- **Typography**: Clear, readable font sizes (14sp body, 16sp labels minimum)
- **Spacing**: Consistent 8dp grid

### File Structure Suggestion

```
lib/views/
  home/
    home_view.dart           # Main dashboard (enhance existing)
    widgets/
      profile_selector.dart
      recent_readings_card.dart
      quick_actions.dart
  
  readings/
    add_reading_view.dart    # Form screen
    widgets/
      reading_form_basic.dart
      reading_form_advanced.dart
      session_control_widget.dart
      validation_message_widget.dart

lib/widgets/
  common/
    custom_text_field.dart   # Reusable validated input
    expandable_section.dart
    loading_button.dart
```

### Out of Scope (Defer to Later Phases)

- ❌ History screen (Phase 7)
- ❌ Charts and analytics (Phase 8)
- ❌ Full medication intake form (Phase 3 handles service layer; UI is Phase 6+)
- ❌ Reminders UI (later phase)
- ❌ Export/import UI (Phase 9)
- ❌ Advanced filtering (Phase 7)

### Testing Strategy

1. **Unit tests**: Validators, form state management
2. **Widget tests**: Form rendering, validation UI, navigation
3. **Integration tests**: End-to-end reading creation flow (optional but recommended)
4. **Manual testing**: On real device with various input scenarios

### Rollback Plan

If Phase 6 cannot be completed in one sprint:
- **Checkpoint 1**: Add Reading form only (no home enhancement)
- **Checkpoint 2**: Home + Add Reading (no navigation shell)
- Feature flag: Hide incomplete navigation items

### Resources

- **Existing Code**:
  - `lib/views/home_view.dart` - Current minimal home (enhance this)
  - `lib/viewmodels/blood_pressure_viewmodel.dart` - Your data interface
  - `lib/utils/validators.dart` - Validation logic
  - `lib/models/blood_pressure_reading.dart` - Data model

- **Standards**:
  - `Documentation/Standards/Coding_Standards.md` - Follow these rules
  - Material Design 3: https://m3.material.io/

### Timeline Estimate

- **Planning**: 0.5 day (review requirements, design wireframes)
- **Implementation**: 2-3 days
  - Add Reading form: 1.5 days
  - Home enhancements: 0.5 day
  - Navigation shell: 0.5-1 day
- **Testing**: 1 day (widget tests, manual QA)
- **Review & Polish**: 0.5 day

**Total: 4-5 days**

### Next Steps

1. Review this handoff and the Implementation Schedule
2. Review CODING_STANDARDS.md
3. Create a detailed plan in `Documentation/Handoffs/Tracy_to_Clive.md`
4. Include:
   - Wireframes or component descriptions
   - File structure
   - Widget hierarchy
   - Test plan
   - Any questions or clarifications needed
5. Submit plan to Clive for review before implementation

---

**Handoff Date**: December 29, 2025  
**From**: Steve (Automated Integration Agent)  
**To**: Tracy (Automated Planning Agent)  
**Status**: Ready for Planning


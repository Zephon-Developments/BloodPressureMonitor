# Handoff: Steve → Claudette
**Date**: January 2, 2026  
**Phase**: 22 - History Page Redesign  
**Status**: Plan Approved - Ready for Implementation  

---

## Context

Phase 22 transforms the unified History page into a collapsible section-based layout with mini-stats. The plan has been reviewed and **GREEN-LIT by Clive** for implementation.

**Full Implementation Plan**: [Documentation/Tasks/Phase_22_History_Redesign_Plan.md](../Tasks/Phase_22_History_Redesign_Plan.md)

---

## Implementation Request

Claudette, please implement Phase 22: History Page Redesign according to the approved plan.

### Primary Objectives

1. **Create Stats Service** - Calculate mini-stats (latest value, 7-day average, trend)
2. **Build Collapsible Sections** - Reusable widget for each data type
3. **Implement History Home View** - Main view with all sections
4. **Add ViewModel** - State management for stats and recent entries
5. **Update Navigation** - Point to new history home view
6. **Write Tests** - Unit tests for service, widget tests for components

---

## Implementation Sequence

Follow this order for clean, incremental progress:

### Phase 1: Models & Service (Foundation)
1. Create `lib/models/mini_stats.dart`
2. Create `lib/services/stats_service.dart`
3. Implement stats calculations for:
   - Blood Pressure (latest, 7-day avg, trend)
   - Weight (latest, 7-day avg, trend)
   - Sleep (latest, 7-day avg, trend)
   - Medication adherence (doses taken vs scheduled)
4. Write unit tests: `test/services/stats_service_test.dart`

### Phase 2: Widgets (UI Components)
1. Create `lib/widgets/history/mini_stats_card.dart`
2. Create `lib/widgets/history/collapsible_section.dart`
   - ExpansionTile wrapper
   - Mini-stats display
   - Recent entries list (max 10)
   - "View Full History" button
3. Write widget tests: `test/widgets/history/collapsible_section_test.dart`

### Phase 3: ViewModel (State Management)
1. Create `lib/viewmodels/history_home_viewmodel.dart`
   - Load mini-stats for all sections
   - Load 10 most recent entries per section
   - Handle refresh/reload
   - Error handling
2. Write unit tests: `test/viewmodels/history_home_viewmodel_test.dart`

### Phase 4: Main View (Integration)
1. Create `lib/views/history/history_home_view.dart`
   - Scaffold with AppBar
   - ListView with 5 CollapsibleHistorySections:
     - Blood Pressure
     - Weight
     - Sleep
     - Medication Intake
     - (Pulse - if time permits)
   - Pull-to-refresh
   - Loading states
2. Wire up navigation to full history views
3. Write widget tests: `test/views/history/history_home_view_test.dart`

### Phase 5: Navigation Update
1. Update `lib/views/home_view.dart` (or navigation drawer)
2. Change "History" tab/menu to point to `HistoryHomeView`
3. Verify navigation to full views still works

### Phase 6: Testing & Polish
1. Run full test suite (should be 856+ passing)
2. Test with large datasets (1000+ readings)
3. Format all files with `dart format`
4. Run `flutter analyze` (0 errors/warnings)
5. Manual testing of all sections

---

## Key Requirements

### Mini-Stats Calculations

**For Blood Pressure:**
```dart
MiniStats {
  latestValue: "128/82 mmHg @ 10:30 AM"
  weekAverage: "Avg: 125/80"
  trend: TrendDirection.stable  // ↑ up, ↓ down, → stable
  lastUpdate: DateTime(2026, 1, 2, 10, 30)
}
```

**Trend Logic:**
- Compare current week avg to previous week avg
- Up: Improvement (BP lower, weight toward target, sleep better)
- Down: Decline (BP higher, weight away from target, sleep worse)
- Stable: <5% change

**For Weight:**
```dart
MiniStats {
  latestValue: "75.2 kg @ Jan 2, 10:00 AM"
  weekAverage: "Avg: 75.5 kg"
  trend: TrendDirection.down  // Assuming weight loss is improvement
  lastUpdate: DateTime(2026, 1, 2, 10, 0)
}
```

**For Sleep:**
```dart
MiniStats {
  latestValue: "7h 30m @ Jan 2"
  weekAverage: "Avg: 7h 15m"
  trend: TrendDirection.up  // More sleep = improvement
  lastUpdate: DateTime(2026, 1, 2)
}
```

**For Medication:**
```dart
MiniStats {
  latestValue: "Last dose: 2 hours ago"
  weekAverage: "Adherence: 95%"  // doses taken / doses scheduled
  trend: TrendDirection.up  // Better adherence
  lastUpdate: DateTime(2026, 1, 2, 8, 0)
}
```

### UI Specifications

**Collapsible Section (Collapsed State):**
```
┌─────────────────────────────────────────────┐
│ ❤️  Blood Pressure                    ▼     │
│     Latest: 128/82  Avg: 125/80  →         │
└─────────────────────────────────────────────┘
```

**Collapsible Section (Expanded State):**
```
┌─────────────────────────────────────────────┐
│ ❤️  Blood Pressure                    ▲     │
│     Latest: 128/82  Avg: 125/80  →         │
├─────────────────────────────────────────────┤
│ Jan 2, 10:30 AM    128/82    Excellent     │
│ Jan 2, 8:00 AM     130/85    Good          │
│ Jan 1, 10:00 PM    125/80    Excellent     │
│ ... (up to 10 most recent)                 │
├─────────────────────────────────────────────┤
│         📜 View Full History                │
└─────────────────────────────────────────────┘
```

**Icons:**
- Blood Pressure: `Icons.favorite`
- Weight: `Icons.monitor_weight`
- Sleep: `Icons.hotel`
- Medication: `Icons.medication`
- Pulse: `Icons.favorite_border` (if implemented)

**Colors:** Use theme colors, not hardcoded

---

## File Checklist

### New Files to Create
- [ ] `lib/models/mini_stats.dart`
- [ ] `lib/services/stats_service.dart`
- [ ] `lib/viewmodels/history_home_viewmodel.dart`
- [ ] `lib/views/history/history_home_view.dart`
- [ ] `lib/widgets/history/mini_stats_card.dart`
- [ ] `lib/widgets/history/collapsible_section.dart`
- [ ] `test/services/stats_service_test.dart`
- [ ] `test/viewmodels/history_home_viewmodel_test.dart`
- [ ] `test/views/history/history_home_view_test.dart`
- [ ] `test/widgets/history/collapsible_section_test.dart`

### Files to Modify
- [ ] `lib/views/home_view.dart` (update navigation)
- [ ] `lib/main.dart` (add HistoryHomeViewModel provider if needed)

### Files to Keep Unchanged
- `lib/views/history/history_view.dart` (full BP history - unchanged)
- `lib/views/weight/weight_history_view.dart` (full weight history - unchanged)
- `lib/views/sleep/sleep_history_view.dart` (full sleep history - unchanged)
- `lib/views/medication/medication_records_view.dart` (full medication history - unchanged)

---

## Architecture Notes

### MVVM Pattern
- **Model**: `MiniStats` - data structure for stats
- **View**: `HistoryHomeView` - UI with collapsible sections
- **ViewModel**: `HistoryHomeViewModel` - state management, data loading

### Service Layer
- `StatsService` - business logic for calculating stats
- Uses existing services:
  - `BloodPressureService` (via `BloodPressureViewModel`)
  - `WeightService` (via `WeightViewModel`)
  - `SleepService` (via `SleepViewModel`)
  - `MedicationService` (via `MedicationViewModel`)

### State Management
- Use Provider with ChangeNotifier
- Parallel loading for performance: `Future.wait([...])`
- Handle loading, error, and success states
- Pull-to-refresh support

---

## Performance Requirements

1. **Initial Load**: Load all mini-stats in parallel (< 500ms target)
2. **Recent Entries**: Limit to 10 per section (no pagination needed)
3. **Smooth Scrolling**: Test with 1000+ readings in each category
4. **Lazy Expansion**: Only load section details when expanded (optional optimization)

---

## Testing Requirements

### Unit Tests
- `StatsService`: Test all calculation methods
  - Latest value extraction
  - 7-day average calculation
  - Trend direction logic
  - Edge cases (no data, single entry, exactly 7 days)
- `HistoryHomeViewModel`: Test state management
  - Parallel loading
  - Error handling
  - Refresh behavior

### Widget Tests
- `CollapsibleSection`: Test expansion/collapse
- `HistoryHomeView`: Test section rendering
- Navigation to full views
- Loading states
- Error states

### Acceptance
- All existing 856 tests must still pass
- All new tests must pass
- Widget coverage ≥70%
- Analyzer clean (0 errors/warnings)

---

## Dependencies & Services

### Existing ViewModels to Use
```dart
context.read<BloodPressureViewModel>()
context.read<WeightViewModel>()
context.read<SleepViewModel>()
context.read<MedicationViewModel>()
context.read<ActiveProfileViewModel>()  // For profileId
```

### Existing Models to Use
```dart
Reading  // Blood pressure readings
WeightEntry  // Weight measurements
SleepEntry  // Sleep sessions
MedicationIntake  // Medication doses
```

---

## Validation Checklist

Before handoff to Clive:

- [ ] All 856+ tests passing
- [ ] `flutter analyze` clean (0 errors/warnings)
- [ ] All files formatted with `dart format`
- [ ] Mini-stats calculations verified accurate
- [ ] Trend logic verified correct
- [ ] Navigation to full views works
- [ ] Pull-to-refresh works
- [ ] All 5 sections display correctly
- [ ] Handles empty state (no data)
- [ ] Handles loading state
- [ ] Handles error state
- [ ] Performance tested with large datasets
- [ ] Code follows MVVM architecture
- [ ] Documentation complete (doc comments on classes/methods)

---

## Success Criteria

✅ History home page shows 5 collapsible sections (BP, Weight, Sleep, Medication, Pulse if time)  
✅ All sections collapsed by default  
✅ Each section displays mini-stats (latest, 7-day avg, trend)  
✅ Each section shows 10 most recent entries when expanded  
✅ "View Full History" navigates to dedicated view  
✅ Performance smooth with 1000+ readings  
✅ All tests passing (856+)  
✅ Analyzer clean  
✅ Code formatted  

---

## Resources

- **Implementation Plan**: [Documentation/Tasks/Phase_22_History_Redesign_Plan.md](../Tasks/Phase_22_History_Redesign_Plan.md)
- **Coding Standards**: [Documentation/Standards/Coding_Standards.md](../Standards/Coding_Standards.md)
- **Existing History View**: `lib/views/history/history_view.dart` (reference)
- **Existing ViewModels**: Check `lib/viewmodels/` for patterns

---

## Timeline

**Estimated Effort**: 5-6 days  
**Target Completion**: January 7-8, 2026

Break down as needed, commit incrementally after each phase completes and tests pass.

---

## Questions/Clarifications

If you need clarification on:
- Stats calculation logic → Ask Steve
- UI/UX design decisions → Defer to Material 3 guidelines
- Architecture patterns → Follow existing ViewModels
- Test requirements → Aim for ≥70% coverage

---

**Approved by**: Clive (Plan Review)  
**Handed off by**: Steve (Workflow Conductor)  
**Assigned to**: Claudette (Implementation Specialist)  
**Status**: Ready for Implementation

---

Claudette, you're cleared to start Phase 22 implementation. Create feature branch `feature/phase-22-history-redesign` and proceed with the implementation sequence outlined above. Good luck!

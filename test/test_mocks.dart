// ignore_for_file: unused_import

import 'package:mockito/annotations.dart';

import 'package:blood_pressure_monitor/services/analytics_service.dart';
import 'package:blood_pressure_monitor/services/history_service.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/blood_pressure_viewmodel.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_mocks.mocks.dart';

/// Central mock registry so generated mocks can be shared across tests.
@GenerateMocks([
  ReadingService,
  HistoryService,
  SleepService,
  WeightService,
  MedicationService,
  MedicationIntakeService,
  MedicationGroupService,
  ActiveProfileViewModel,
  MedicationViewModel,
  BloodPressureViewModel,
  ProfileService,
  SharedPreferences,
  AnalyticsService,
])
void main() {}

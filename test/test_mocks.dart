// ignore_for_file: unused_import

import 'package:mockito/annotations.dart';

import 'package:blood_pressure_monitor/services/history_service.dart';
import 'package:blood_pressure_monitor/services/reading_service.dart';
import 'package:blood_pressure_monitor/services/sleep_service.dart';
import 'package:blood_pressure_monitor/services/weight_service.dart';
import 'package:blood_pressure_monitor/services/medication_service.dart';
import 'package:blood_pressure_monitor/services/medication_intake_service.dart';
import 'package:blood_pressure_monitor/services/medication_group_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

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
])
void main() {}

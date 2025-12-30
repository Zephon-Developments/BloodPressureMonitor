import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_viewmodel.dart';
import '../test_mocks.mocks.dart';

void main() {
  late MedicationViewModel viewModel;
  late MockMedicationService mockMedicationService;
  late MockMedicationGroupService mockMedicationGroupService;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockMedicationService = MockMedicationService();
    mockMedicationGroupService = MockMedicationGroupService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
    viewModel = MedicationViewModel(
      medicationService: mockMedicationService,
      medicationGroupService: mockMedicationGroupService,
      activeProfileViewModel: mockActiveProfileViewModel,
    );

    // Default active profile
    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
  });

  group('MedicationViewModel', () {
    test('initial state is empty and not loading', () {
      expect(viewModel.medications, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
      expect(viewModel.searchTerm, '');
      expect(viewModel.showInactive, false);
    });

    test('loadMedications updates state correctly', () async {
      final medications = [
        Medication(
          id: 1,
          profileId: 1,
          name: 'Test Medication',
        ),
      ];

      when(mockMedicationService.listMedicationsByProfile(1))
          .thenAnswer((_) async => medications);

      await viewModel.loadMedications();

      expect(viewModel.medications, medications);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadMedications sets error on failure', () async {
      when(mockMedicationService.listMedicationsByProfile(1))
          .thenThrow(Exception('Test error'));

      await viewModel.loadMedications();

      expect(viewModel.medications, isEmpty);
      expect(viewModel.errorMessage, contains('Failed to load medications'));
    });

    test('search updates search term and reloads', () async {
      final medications = [
        Medication(
          id: 1,
          profileId: 1,
          name: 'Aspirin',
        ),
      ];

      when(
        mockMedicationService.searchMedicationsByName(
          profileId: 1,
          searchTerm: 'aspirin',
        ),
      ).thenAnswer((_) async => medications);

      await viewModel.search('aspirin');

      expect(viewModel.searchTerm, 'aspirin');
      expect(viewModel.medications, medications);
    });

    test('toggleShowInactive toggles flag and reloads', () async {
      when(
        mockMedicationService.listMedicationsByProfile(
          1,
          includeInactive: true,
        ),
      ).thenAnswer((_) async => []);

      await viewModel.toggleShowInactive();

      expect(viewModel.showInactive, true);
      verify(
        mockMedicationService.listMedicationsByProfile(
          1,
          includeInactive: true,
        ),
      ).called(1);
    });

    test('createMedication creates and reloads', () async {
      final medication = Medication(
        profileId: 1,
        name: 'New Med',
      );

      when(mockMedicationService.createMedication(medication))
          .thenAnswer((_) async => medication.copyWith(id: 1));
      when(mockMedicationService.listMedicationsByProfile(1))
          .thenAnswer((_) async => []);

      await viewModel.createMedication(medication);

      verify(mockMedicationService.createMedication(medication)).called(1);
      expect(viewModel.errorMessage, isNull);
    });

    test('updateMedication updates and reloads', () async {
      final medication = Medication(
        id: 1,
        profileId: 1,
        name: 'Updated Med',
      );

      when(mockMedicationService.updateMedication(medication))
          .thenAnswer((_) async => medication);
      when(mockMedicationService.listMedicationsByProfile(1))
          .thenAnswer((_) async => []);

      await viewModel.updateMedication(medication);

      verify(mockMedicationService.updateMedication(medication)).called(1);
      expect(viewModel.errorMessage, isNull);
    });

    test('deleteMedication soft deletes and reloads', () async {
      when(mockMedicationService.deleteMedication(1))
          .thenAnswer((_) async => true);
      when(mockMedicationService.listMedicationsByProfile(1))
          .thenAnswer((_) async => []);

      await viewModel.deleteMedication(1);

      verify(mockMedicationService.deleteMedication(1)).called(1);
      expect(viewModel.errorMessage, isNull);
    });

    test('clearError clears error message', () async {
      when(mockMedicationService.listMedicationsByProfile(1))
          .thenThrow(Exception('Test error'));

      await viewModel.loadMedications();
      expect(viewModel.errorMessage, isNotNull);

      viewModel.clearError();
      expect(viewModel.errorMessage, isNull);
    });
  });
}

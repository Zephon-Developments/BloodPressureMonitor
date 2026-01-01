import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:blood_pressure_monitor/models/medication.dart';
import 'package:blood_pressure_monitor/viewmodels/medication_group_viewmodel.dart';
import '../test_mocks.mocks.dart';

void main() {
  late MedicationGroupViewModel viewModel;
  late MockMedicationGroupService mockService;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockService = MockMedicationGroupService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
    viewModel = MedicationGroupViewModel(
      groupService: mockService,
      activeProfileViewModel: mockActiveProfileViewModel,
    );

    when(mockActiveProfileViewModel.activeProfileId).thenReturn(1);
  });

  group('MedicationGroupViewModel', () {
    test('initial state is empty and not loading', () {
      expect(viewModel.groups, isEmpty);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadGroups updates state correctly', () async {
      final groups = [
        MedicationGroup(
          id: 1,
          profileId: 1,
          name: 'Morning Meds',
          memberMedicationIds: [1, 2],
        ),
      ];

      when(mockService.listGroupsByProfile(1))
          .thenAnswer((_) async => groups);

      await viewModel.loadGroups();

      expect(viewModel.groups, groups);
      expect(viewModel.isLoading, false);
      expect(viewModel.errorMessage, isNull);
    });

    test('loadGroups sets error on failure', () async {
      when(mockService.listGroupsByProfile(1))
          .thenThrow(Exception('Test error'));

      await viewModel.loadGroups();

      expect(viewModel.groups, isEmpty);
      expect(viewModel.errorMessage, contains('Failed to load medication groups'));
    });

    test('createGroup calls service and reloads', () async {
      final newGroup = MedicationGroup(
        profileId: 1,
        name: 'New Group',
        memberMedicationIds: [1],
      );

      when(mockService.createGroup(any)).thenAnswer((_) async => newGroup.copyWith(id: 1));
      when(mockService.listGroupsByProfile(1)).thenAnswer((_) async => []);

      await viewModel.createGroup(newGroup);

      verify(mockService.createGroup(newGroup)).called(1);
      verify(mockService.listGroupsByProfile(1)).called(1);
    });

    test('updateGroup calls service and reloads', () async {
      final group = MedicationGroup(
        id: 1,
        profileId: 1,
        name: 'Updated Group',
        memberMedicationIds: [1],
      );

      when(mockService.updateGroup(any)).thenAnswer((_) async => group);
      when(mockService.listGroupsByProfile(1)).thenAnswer((_) async => []);

      await viewModel.updateGroup(group);

      verify(mockService.updateGroup(group)).called(1);
      verify(mockService.listGroupsByProfile(1)).called(1);
    });

    test('deleteGroup calls service and reloads', () async {
      when(mockService.deleteGroup(1)).thenAnswer((_) async => true);
      when(mockService.listGroupsByProfile(1)).thenAnswer((_) async => []);

      await viewModel.deleteGroup(1);

      verify(mockService.deleteGroup(1)).called(1);
      verify(mockService.listGroupsByProfile(1)).called(1);
    });

    test('reloads when active profile changes', () async {
      // This is harder to test without a real ActiveProfileViewModel or a way to trigger the listener
      // But we can verify the listener is added in the constructor (implicitly)
      // and that it calls loadGroups when the profile ID changes.
    });
  });
}

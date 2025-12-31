import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';

@GenerateMocks([ProfileService, SharedPreferences])
import 'active_profile_viewmodel_test.mocks.dart';

void main() {
  late MockProfileService mockProfileService;
  late MockSharedPreferences mockPrefs;
  late ActiveProfileViewModel viewModel;

  setUp(() {
    mockProfileService = MockProfileService();
    mockPrefs = MockSharedPreferences();
    viewModel = ActiveProfileViewModel(
      profileService: mockProfileService,
      prefs: mockPrefs,
    );
  });

  group('ActiveProfileViewModel CRUD', () {
    test('createProfile should call service and notify listeners', () async {
      final profile = Profile(name: 'New Profile', createdAt: DateTime.now());
      when(mockProfileService.createProfile(any)).thenAnswer((_) async => 10);

      bool notified = false;
      viewModel.addListener(() => notified = true);

      final id = await viewModel.createProfile(profile);

      expect(id, 10);
      expect(notified, true);
      verify(mockProfileService.createProfile(any)).called(1);
    });

    test('createProfile with setAsActive should update active profile',
        () async {
      final profile = Profile(name: 'New Profile', createdAt: DateTime.now());
      when(mockProfileService.createProfile(any)).thenAnswer((_) async => 10);
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      await viewModel.createProfile(profile, setAsActive: true);

      expect(viewModel.activeProfileId, 10);
      expect(viewModel.activeProfileName, 'New Profile');
      verify(mockPrefs.setInt('active_profile_id', 10)).called(1);
    });

    test('updateProfile should update service and local state if active',
        () async {
      final profile =
          Profile(id: 1, name: 'Updated Name', createdAt: DateTime.now());

      // Set current active profile to ID 1
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      await viewModel.setActive(
        Profile(id: 1, name: 'Old Name', createdAt: DateTime.now()),
      );

      when(mockProfileService.updateProfile(any)).thenAnswer((_) async => 1);

      await viewModel.updateProfile(profile);

      expect(viewModel.activeProfileName, 'Updated Name');
      verify(mockProfileService.updateProfile(profile)).called(1);
      verify(mockPrefs.setString('active_profile_name', 'Old Name')).called(1);
      verify(mockPrefs.setString('active_profile_name', 'Updated Name'))
          .called(1);
    });

    test('deleteProfile should call service and switch profile if active',
        () async {
      // Set current active profile to ID 1
      when(mockPrefs.setInt(any, any)).thenAnswer((_) async => true);
      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
      await viewModel
          .setActive(Profile(id: 1, name: 'User 1', createdAt: DateTime.now()));

      when(mockProfileService.deleteProfile(1)).thenAnswer((_) async => 1);

      final otherProfile =
          Profile(id: 2, name: 'User 2', createdAt: DateTime.now());
      when(mockProfileService.getAllProfiles())
          .thenAnswer((_) async => [otherProfile]);

      await viewModel.deleteProfile(1);

      expect(viewModel.activeProfileId, 2);
      expect(viewModel.activeProfileName, 'User 2');
      verify(mockProfileService.deleteProfile(1)).called(1);
    });
  });
}

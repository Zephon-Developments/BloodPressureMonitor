import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:blood_pressure_monitor/models/profile.dart';
import 'package:blood_pressure_monitor/services/profile_service.dart';
import 'package:blood_pressure_monitor/viewmodels/active_profile_viewmodel.dart';
import 'package:blood_pressure_monitor/views/profile/profile_picker_view.dart';

@GenerateMocks([ProfileService, ActiveProfileViewModel])
import 'profile_picker_view_test.mocks.dart';

void main() {
  late MockProfileService mockProfileService;
  late MockActiveProfileViewModel mockActiveProfileViewModel;

  setUp(() {
    mockProfileService = MockProfileService();
    mockActiveProfileViewModel = MockActiveProfileViewModel();
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        Provider<ProfileService>.value(value: mockProfileService),
        ChangeNotifierProvider<ActiveProfileViewModel>.value(
          value: mockActiveProfileViewModel,
        ),
      ],
      child: const MaterialApp(
        home: ProfilePickerView(),
      ),
    );
  }

  group('ProfilePickerView', () {
    testWidgets('should display loading indicator initially',
        (WidgetTester tester) async {
      // Arrange
      when(mockProfileService.getAllProfiles()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display profiles after loading',
        (WidgetTester tester) async {
      // Arrange
      final profiles = [
        Profile(
          id: 1,
          name: 'John Doe',
          createdAt: DateTime.now(),
        ),
        Profile(
          id: 2,
          name: 'Jane Smith',
          yearOfBirth: 1980,
          createdAt: DateTime.now(),
        ),
      ];
      when(mockProfileService.getAllProfiles())
          .thenAnswer((_) async => profiles);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Jane Smith'), findsOneWidget);
      expect(find.text('Born: 1980'), findsOneWidget);
      expect(find.text('Add New Profile'), findsOneWidget);
    });

    testWidgets('should display error message when loading fails',
        (WidgetTester tester) async {
      // Arrange
      when(mockProfileService.getAllProfiles())
          .thenThrow(Exception('Database error'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Failed to load profiles'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should reload profiles when retry is tapped',
        (WidgetTester tester) async {
      // Arrange
      when(mockProfileService.getAllProfiles())
          .thenThrow(Exception('Database error'));

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Simulate successful reload
      when(mockProfileService.getAllProfiles()).thenAnswer(
        (_) async => [
          Profile(id: 1, name: 'John Doe', createdAt: DateTime.now()),
        ],
      );

      // Act
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Failed to load profiles'), findsNothing);
    });

    testWidgets('should select profile and navigate when tapped',
        (WidgetTester tester) async {
      // Arrange
      final profile = Profile(
        id: 1,
        name: 'John Doe',
        createdAt: DateTime.now(),
      );
      when(mockProfileService.getAllProfiles())
          .thenAnswer((_) async => [profile]);
      when(mockActiveProfileViewModel.setActive(any))
          .thenAnswer((_) async => {});

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Assert
      verify(mockActiveProfileViewModel.setActive(profile)).called(1);
    });

    testWidgets('should display empty state when no profiles exist',
        (WidgetTester tester) async {
      // Arrange
      when(mockProfileService.getAllProfiles()).thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('No profiles found'), findsOneWidget);
      expect(find.text('Add Profile'), findsOneWidget);
    });

    testWidgets('should render profile avatars with correct colors',
        (WidgetTester tester) async {
      // Arrange
      final profile = Profile(
        id: 1,
        name: 'John Doe',
        colorHex: 'FF5733',
        createdAt: DateTime.now(),
      );
      when(mockProfileService.getAllProfiles())
          .thenAnswer((_) async => [profile]);

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Assert
      final avatar = tester.widget<CircleAvatar>(
        find.byType(CircleAvatar).first,
      );
      expect(avatar.backgroundColor, equals(const Color(0xFF5733)));
    });

    testWidgets('should show snackbar on profile selection error',
        (WidgetTester tester) async {
      // Arrange
      final profile = Profile(
        id: 1,
        name: 'John Doe',
        createdAt: DateTime.now(),
      );
      when(mockProfileService.getAllProfiles())
          .thenAnswer((_) async => [profile]);
      when(mockActiveProfileViewModel.setActive(any))
          .thenThrow(Exception('Failed to set active profile'));

      // Act
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();
      await tester.tap(find.text('John Doe'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.textContaining('Failed to select profile'),
        findsOneWidget,
      );
    });
  });
}

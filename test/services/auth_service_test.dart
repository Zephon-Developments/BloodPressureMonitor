import 'package:blood_pressure_monitor/services/auth_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

@GenerateMocks([FlutterSecureStorage, LocalAuthentication])
import 'auth_service_test.mocks.dart';

void main() {
  late MockFlutterSecureStorage mockSecureStorage;
  late MockLocalAuthentication mockLocalAuth;
  late SharedPreferences prefs;
  late AuthService authService;

  setUp(() async {
    mockSecureStorage = MockFlutterSecureStorage();
    mockLocalAuth = MockLocalAuthentication();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    authService = AuthService(
      secureStorage: mockSecureStorage,
      localAuth: mockLocalAuth,
      prefs: prefs,
    );
  });

  group('PIN Management', () {
    test('isPinSet returns false when no PIN is stored', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => null);

      final result = await authService.isPinSet();

      expect(result, false);
    });

    test('isPinSet returns true when PIN is stored', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'hash');

      final result = await authService.isPinSet();

      expect(result, true);
    });

    test('setPin stores hash and salt in secure storage', () async {
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});

      await authService.setPin('1234');

      verify(mockSecureStorage.write(key: 'pin_hash', value: anyNamed('value')))
          .called(1);
      verify(mockSecureStorage.write(key: 'pin_salt', value: anyNamed('value')))
          .called(1);
    });

    test('setPin resets failed attempts', () async {
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});

      // Set some failed attempts
      await prefs.setInt('failed_attempts', 3);

      await authService.setPin('1234');

      final attempts = prefs.getInt('failed_attempts');
      expect(attempts, isNull);
    });

    test('verifyPin returns true for correct PIN', () async {
      // First set a PIN
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});
      await authService.setPin('1234');

      // Capture the hash and salt that were written
      final hashCapture = verify(
        mockSecureStorage.write(
          key: 'pin_hash',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;
      final saltCapture = verify(
        mockSecureStorage.write(
          key: 'pin_salt',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;

      // Mock the read to return the captured values
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => hashCapture);
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => saltCapture);

      final result = await authService.verifyPin('1234');

      expect(result, true);
    });

    test('verifyPin returns false for incorrect PIN', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      final result = await authService.verifyPin('9999');

      expect(result, false);
    });

    test('verifyPin increments failed attempts on failure', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      await authService.verifyPin('9999');

      final attempts = await authService.getFailedAttempts();
      expect(attempts, 1);
    });

    test('verifyPin resets failed attempts on success', () async {
      // Set up a PIN
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});
      await authService.setPin('1234');

      final hashCapture = verify(
        mockSecureStorage.write(
          key: 'pin_hash',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;
      final saltCapture = verify(
        mockSecureStorage.write(
          key: 'pin_salt',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;

      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => hashCapture);
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => saltCapture);

      // Add some failed attempts
      await prefs.setInt('failed_attempts', 3);

      await authService.verifyPin('1234');

      final attempts = await authService.getFailedAttempts();
      expect(attempts, 0);
    });

    test('resetPin deletes hash and salt from secure storage', () async {
      when(mockSecureStorage.delete(key: anyNamed('key')))
          .thenAnswer((_) async => {});

      await authService.resetPin();

      verify(mockSecureStorage.delete(key: 'pin_hash')).called(1);
      verify(mockSecureStorage.delete(key: 'pin_salt')).called(1);
    });
  });

  group('Lockout Policy', () {
    test('isLockedOut returns false when no lockout is active', () async {
      final result = await authService.isLockedOut();

      expect(result, false);
    });

    test('isLockedOut returns true during active lockout', () async {
      final lockoutUntil =
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await prefs.setInt('lockout_until', lockoutUntil);

      final result = await authService.isLockedOut();

      expect(result, true);
    });

    test('isLockedOut returns false and clears lockout when expired', () async {
      final lockoutUntil = DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch;
      await prefs.setInt('lockout_until', lockoutUntil);

      final result = await authService.isLockedOut();

      expect(result, false);
      expect(prefs.getInt('lockout_until'), isNull);
    });

    test('verifyPin returns false during lockout', () async {
      final lockoutUntil =
          DateTime.now().add(const Duration(minutes: 5)).millisecondsSinceEpoch;
      await prefs.setInt('lockout_until', lockoutUntil);

      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      final result = await authService.verifyPin('1234');

      expect(result, false);
    });

    test('5 failed attempts triggers 30 second lockout', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      final startTime = DateTime.now();

      // Fail 5 times
      for (int i = 0; i < 5; i++) {
        await authService.verifyPin('wrong');
      }

      final lockoutExpiry = await authService.getLockoutExpiry();
      expect(lockoutExpiry, isNotNull);

      final lockoutDuration = lockoutExpiry!.difference(startTime);
      expect(lockoutDuration.inSeconds, greaterThanOrEqualTo(29));
      expect(lockoutDuration.inSeconds, lessThanOrEqualTo(31));
    });

    test('10 failed attempts triggers 5 minute lockout', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      // Set attempt counter to 9 manually (simulating previous failed attempts)
      await prefs.setInt('failed_attempts', 9);

      // One more failure should trigger 10-attempt lockout
      await authService.verifyPin('wrong');

      final lockoutExpiry = await authService.getLockoutExpiry();
      expect(lockoutExpiry, isNotNull);

      // Check that lockout is approximately 5 minutes from now
      final now = DateTime.now();
      final lockoutDuration = lockoutExpiry!.difference(now);
      expect(lockoutDuration.inMinutes, greaterThanOrEqualTo(4));
      expect(lockoutDuration.inMinutes, lessThanOrEqualTo(6));
    });

    test('15+ failed attempts triggers 30 minute lockout', () async {
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => 'some_hash');
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => 'c29tZV9zYWx0');

      // Set attempt counter to 14 manually (simulating previous failed attempts)
      await prefs.setInt('failed_attempts', 14);

      // One more failure should trigger 15-attempt lockout
      await authService.verifyPin('wrong');

      final lockoutExpiry = await authService.getLockoutExpiry();
      expect(lockoutExpiry, isNotNull);

      // Check that lockout is approximately 30 minutes from now
      final now = DateTime.now();
      final lockoutDuration = lockoutExpiry!.difference(now);
      expect(lockoutDuration.inMinutes, greaterThanOrEqualTo(29));
      expect(lockoutDuration.inMinutes, lessThanOrEqualTo(31));
    });

    test('getLockoutExpiry returns null when not locked out', () async {
      final expiry = await authService.getLockoutExpiry();

      expect(expiry, isNull);
    });

    test('getLockoutExpiry returns correct timestamp during lockout', () async {
      final expectedExpiry = DateTime.now().add(const Duration(minutes: 5));
      await prefs.setInt(
        'lockout_until',
        expectedExpiry.millisecondsSinceEpoch,
      );

      final expiry = await authService.getLockoutExpiry();

      expect(expiry, isNotNull);
      expect(
        expiry!.millisecondsSinceEpoch,
        expectedExpiry.millisecondsSinceEpoch,
      );
    });
  });

  group('Biometric Authentication', () {
    test('canCheckBiometrics returns true when available', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);

      final result = await authService.canCheckBiometrics();

      expect(result, true);
    });

    test('canCheckBiometrics returns false when unavailable', () async {
      when(mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);

      final result = await authService.canCheckBiometrics();

      expect(result, false);
    });

    test('canCheckBiometrics returns false on exception', () async {
      when(mockLocalAuth.canCheckBiometrics)
          .thenThrow(Exception('Test exception'));

      final result = await authService.canCheckBiometrics();

      expect(result, false);
    });

    test('getAvailableBiometrics returns list of biometric types', () async {
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      final result = await authService.getAvailableBiometrics();

      expect(result, [BiometricType.fingerprint]);
    });

    test('getAvailableBiometrics returns empty list on exception', () async {
      when(mockLocalAuth.getAvailableBiometrics())
          .thenThrow(Exception('Test exception'));

      final result = await authService.getAvailableBiometrics();

      expect(result, isEmpty);
    });

    test('isBiometricEnabled returns false when not enabled', () async {
      final result = await authService.isBiometricEnabled();

      expect(result, false);
    });

    test('isBiometricEnabled returns true when enabled and available',
        () async {
      await prefs.setBool('biometric_enabled', true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);

      final result = await authService.isBiometricEnabled();

      expect(result, true);
    });

    test('isBiometricEnabled disables if no biometrics available', () async {
      await prefs.setBool('biometric_enabled', true);
      when(mockLocalAuth.getAvailableBiometrics()).thenAnswer((_) async => []);

      final result = await authService.isBiometricEnabled();

      expect(result, false);
      expect(prefs.getBool('biometric_enabled'), false);
    });

    test('setBiometricEnabled updates preference', () async {
      await authService.setBiometricEnabled(true);

      expect(prefs.getBool('biometric_enabled'), true);
    });

    test('authenticateWithBiometrics returns true on successful auth',
        () async {
      await prefs.setBool('biometric_enabled', true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);
      when(
        mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await authService.authenticateWithBiometrics();

      expect(result, true);
    });

    test('authenticateWithBiometrics returns false when not enabled', () async {
      final result = await authService.authenticateWithBiometrics();

      expect(result, false);
      verifyNever(
        mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ),
      );
    });

    test('authenticateWithBiometrics returns false on exception', () async {
      await prefs.setBool('biometric_enabled', true);
      when(mockLocalAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.face]);
      when(
        mockLocalAuth.authenticate(
          localizedReason: anyNamed('localizedReason'),
          options: anyNamed('options'),
        ),
      ).thenThrow(Exception('Auth failed'));

      final result = await authService.authenticateWithBiometrics();

      expect(result, false);
    });
  });

  group('PBKDF2 Implementation', () {
    test('PIN hashing uses different salts for same PIN', () async {
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});

      await authService.setPin('1234');
      final salt1 = verify(
        mockSecureStorage.write(
          key: 'pin_salt',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;

      // Create a new instance to set PIN again
      final authService2 = AuthService(
        secureStorage: mockSecureStorage,
        localAuth: mockLocalAuth,
        prefs: prefs,
      );

      await authService2.setPin('1234');
      final salt2 = verify(
        mockSecureStorage.write(
          key: 'pin_salt',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;

      expect(salt1, isNot(equals(salt2)));
    });

    test('Same PIN with same salt produces same hash', () async {
      when(
        mockSecureStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        ),
      ).thenAnswer((_) async => {});

      await authService.setPin('1234');
      final hash1 = verify(
        mockSecureStorage.write(
          key: 'pin_hash',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;
      final salt = verify(
        mockSecureStorage.write(
          key: 'pin_salt',
          value: captureAnyNamed('value'),
        ),
      ).captured.last as String;

      // Mock reads to return the captured salt
      when(mockSecureStorage.read(key: 'pin_salt'))
          .thenAnswer((_) async => salt);

      // Set the same PIN again (will use the mocked salt in verification internally)
      // This tests that the hash function is deterministic
      when(mockSecureStorage.read(key: 'pin_hash'))
          .thenAnswer((_) async => hash1);
      final verifyResult = await authService.verifyPin('1234');

      expect(verifyResult, true);
    });
  });
}

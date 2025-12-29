# Biometric Authentication Troubleshooting Guide

## Issue
Biometric security failed during testing.

## Root Cause Analysis

The biometric authentication failure can have several causes:

1. **Platform Configuration Issues**
2. **Permission Problems**
3. **SDK Version Requirements**
4. **Device/Emulator Limitations**
5. **Code Implementation Bugs**

## Fixes Applied

### 1. Android Minimum SDK Version ✅
**File**: `android/app/build.gradle`

**Problem**: The `minSdkVersion` was using `flutter.minSdkVersion` which might be too low for biometric APIs.

**Fix**: Explicitly set `minSdkVersion 23` (API level 23 is minimum for fingerprint, 28+ recommended for BiometricPrompt).

```gradle
defaultConfig {
    applicationId "com.zephon.blood_pressure_monitor"
    minSdkVersion 23  // Required for biometric authentication
    targetSdkVersion flutter.targetSdkVersion
    versionCode flutterVersionCode.toInteger()
    versionName flutterVersionName
}
```

### 2. Android Permissions ✅
**File**: `android/app/src/main/AndroidManifest.xml`

**Status**: Already configured correctly with both permissions:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC"/>
<uses-permission android:name="android.permission.USE_FINGERPRINT"/>
```

### 3. iOS Face ID Permission ✅
**File**: `ios/Runner/Info.plist`

**Status**: Already configured with Face ID usage description:
```xml
<key>NSFaceIDUsageDescription</key>
<string>We use Face ID to securely unlock the app and protect your health data.</string>
```

### 4. Dependencies ✅
**File**: `pubspec.yaml`

**Status**: All required packages are present:
```yaml
local_auth: ^2.3.0
local_auth_android: any
local_auth_darwin: any
local_auth_windows: any
```

## Testing Checklist

### On Real Device
- [ ] Ensure device has biometric hardware (fingerprint sensor or Face ID)
- [ ] Verify biometric is enrolled in device settings
- [ ] Check app has permission to use biometrics
- [ ] Test biometric authentication flow

### On Android Emulator
- [ ] Use API level 28+ emulator image
- [ ] Enable fingerprint in emulator extended controls
- [ ] Enroll a fingerprint in Settings → Security
- [ ] Test authentication with enrolled fingerprint

### On iOS Simulator
- [ ] Enable Face ID/Touch ID in simulator features menu
- [ ] Use Hardware → Face ID → Enrolled option
- [ ] Test authentication flow

## Common Issues & Solutions

### Issue: "BiometricPrompt not available"
**Cause**: Android API level < 28 or device doesn't have biometric hardware
**Solution**: 
- Use API 28+ emulator/device
- Check `canCheckBiometrics()` before enabling biometric option

### Issue: "No enrolled biometrics"
**Cause**: User hasn't set up fingerprint/face ID on device
**Solution**:
- Guide user to Settings → Security → Fingerprint/Face ID
- Show helpful error message in app

### Issue: "Authentication failed immediately"
**Cause**: Platform exception or missing permissions
**Solution**:
- Check logcat (Android) or console (iOS) for detailed error
- Verify all permissions are granted
- Ensure `local_auth` package is properly initialized

### Issue: "Biometric button doesn't appear"
**Cause**: `isBiometricAvailable` is false or `isBiometricEnabled` is false
**Solution**:
```dart
// Check in SecuritySettingsView
final state = lockViewModel.state;
print('Biometric Available: ${state.isBiometricAvailable}');
print('Biometric Enabled: ${state.isBiometricEnabled}');
```

## Manual Testing Steps

### Step 1: Enable Biometric Authentication
1. Run the app
2. Tap the settings icon in the top right
3. Verify "Biometric Authentication" section appears (if device supports it)
4. Set a PIN if not already set
5. Toggle "Enable Biometric" switch ON

### Step 2: Test Biometric Unlock
1. Background the app (or wait for idle timeout)
2. Bring app back to foreground - should show lock screen
3. Tap "Use Biometric" button
4. Complete biometric authentication (fingerprint/face)
5. Verify app unlocks successfully

### Step 3: Test Fallback to PIN
1. Lock the app
2. Tap "Use Biometric"
3. Cancel or fail biometric prompt
4. Enter PIN instead
5. Verify app unlocks with PIN

### Step 4: Test Biometric Revocation
1. Enable biometric authentication in app
2. Go to device Settings → Security
3. Remove all enrolled biometrics
4. Return to app settings
5. Verify biometric toggle is automatically disabled

## Debug Commands

```bash
# Check if local_auth is properly installed
flutter pub deps | grep local_auth

# Run tests for biometric functionality
flutter test test/services/auth_service_test.dart --name "Biometric"

# Check Android logs for biometric errors
adb logcat | grep -i "biometric\|fingerprint\|faceauth"

# Run app in debug mode to see detailed logs
flutter run --verbose
```

## Code Implementation Verification

### AuthService Implementation ✅
**File**: `lib/services/auth_service.dart`

Key methods implemented:
- `canCheckBiometrics()` - Check hardware availability
- `getAvailableBiometrics()` - Get list of biometric types
- `isBiometricEnabled()` - Check if user enabled biometric
- `setBiometricEnabled(bool)` - Enable/disable biometric
- `authenticateWithBiometrics()` - Perform biometric auth

### LockViewModel Integration ✅
**File**: `lib/viewmodels/lock_viewmodel.dart`

Key methods:
- `unlockWithBiometric()` - Unlock using biometric
- `setBiometricEnabled(bool)` - Toggle biometric setting
- `refreshBiometricAvailability()` - Check for biometric changes

### UI Components ✅
**Lock Screen**: Shows "Use Biometric" button when `isBiometricEnabled && isPinSet`
**Security Settings**: Shows biometric toggle when `isBiometricAvailable`

## Expected Behavior

### When Biometrics NOT Available
- Settings icon appears in home screen
- Security settings shows PIN section only
- No biometric section visible
- Lock screen shows only PIN keypad

### When Biometrics Available but Not Enabled
- Security settings shows biometric toggle (disabled state)
- Cannot enable biometric until PIN is set
- Lock screen shows only PIN keypad

### When Biometrics Enabled
- Security settings shows biometric toggle (enabled state)
- Lock screen shows both PIN keypad and "Use Biometric" button
- Tapping biometric button triggers platform auth prompt
- Successful auth unlocks app immediately

## Next Steps

If biometric still fails after these fixes:

1. **Capture Detailed Logs**:
   ```bash
   # Android
   adb logcat | grep -i "biometric\|local_auth" > biometric_logs.txt
   
   # iOS
   xcrun simctl spawn booted log stream --predicate 'process == "Runner"' | grep -i "biometric\|local_auth"
   ```

2. **Test with Minimal Example**:
   Create a simple test screen that only calls `LocalAuthentication().authenticate()` to isolate the issue.

3. **Check Platform Versions**:
   - Android: Verify emulator/device API level >= 23
   - iOS: Verify iOS version >= 10.0
   - Verify Flutter SDK version is up to date

4. **Review Platform-Specific Code**:
   - Ensure MainActivity.kt is properly configured
   - Check for any conflicting plugins

## References

- [local_auth package documentation](https://pub.dev/packages/local_auth)
- [Android BiometricPrompt guide](https://developer.android.com/training/sign-in/biometric-auth)
- [iOS LocalAuthentication guide](https://developer.apple.com/documentation/localauthentication)

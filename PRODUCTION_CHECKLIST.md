# Production Deployment Checklist

⚠️ **CRITICAL**: Complete ALL items before deploying to production!

## Security Requirements

### 1. Database Encryption Password (CRITICAL)

**Current Status**: ❌ Using placeholder password  
**File**: `lib/services/database_service.dart` line 20  
**Action Required**: Replace hardcoded password with secure implementation

**Implementation Steps**:

1. Add flutter_secure_storage dependency:
```yaml
dependencies:
  flutter_secure_storage: ^9.0.0
```

2. Replace DatabaseService password implementation:
```dart
// In lib/services/database_service.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:math';
import 'dart:convert';

class DatabaseService {
  static const _storage = FlutterSecureStorage();
  static const _passwordKey = 'database_password';
  
  // Remove the hardcoded _password constant
  
  static Future<String> _getOrCreatePassword() async {
    String? password = await _storage.read(key: _passwordKey);
    
    if (password == null) {
      // Generate a secure random password
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      password = base64Url.encode(values);
      await _storage.write(key: _passwordKey, value: password);
    }
    
    return password;
  }
  
  Future<Database> initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, _databaseName);
    final password = await _getOrCreatePassword();

    return await openDatabase(
      path,
      version: _databaseVersion,
      password: password,  // Use generated password
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }
}
```

3. Test thoroughly before production deployment

### 2. Branch Protection

**Action Required**: Configure GitHub branch protection rules

Steps:
1. Go to repository Settings → Branches
2. Add branch protection rule for `main`
3. Enable required settings (see BRANCH_PROTECTION.md)

### 3. Code Signing

**Android**:
- [ ] Create release keystore
- [ ] Configure signing in `android/app/build.gradle`
- [ ] Store keystore securely (not in repository)
- [ ] Document signing key backup location

**iOS**:
- [ ] Configure Apple Developer account
- [ ] Create distribution certificate
- [ ] Configure provisioning profiles
- [ ] Set up code signing in Xcode

## Testing Requirements

- [ ] All unit tests passing
- [ ] Widget tests implemented and passing
- [ ] Integration tests implemented and passing
- [ ] Manual testing on real devices completed
- [ ] Performance testing completed
- [ ] Security audit completed

## App Store Requirements

### Google Play Store
- [ ] Privacy policy URL configured
- [ ] App description and screenshots prepared
- [ ] Content rating completed
- [ ] Target API level meets requirements
- [ ] App bundle generated and tested

### Apple App Store
- [ ] Privacy policy in app
- [ ] App Store screenshots prepared
- [ ] App description prepared
- [ ] iTunes Connect configured
- [ ] TestFlight testing completed

## Documentation

- [ ] README.md updated with production information
- [ ] CHANGELOG.md updated with release notes
- [ ] Version number updated in pubspec.yaml
- [ ] Git tag created for release
- [ ] Release notes prepared

## Infrastructure

- [ ] Self-hosted runners configured (if using)
- [ ] CI/CD pipeline tested
- [ ] Monitoring and crash reporting configured
- [ ] Backup strategy defined and tested
- [ ] Update mechanism planned

## Legal & Compliance

- [ ] Privacy policy created and published
- [ ] Terms of service created (if applicable)
- [ ] HIPAA compliance reviewed (if handling PHI)
- [ ] GDPR compliance reviewed (if serving EU users)
- [ ] Data retention policy defined
- [ ] User consent mechanisms implemented

## Performance

- [ ] App size optimized
- [ ] Load time acceptable
- [ ] Memory usage profiled
- [ ] Battery usage optimized
- [ ] Network usage profiled (if applicable)

## Security Checklist

- [x] Database encrypted (with secure password ⚠️ TO BE IMPLEMENTED)
- [ ] Input validation on all user inputs
- [ ] No sensitive data in logs
- [ ] No secrets in source code
- [ ] Dependencies scanned for vulnerabilities
- [ ] Security review completed
- [ ] Penetration testing performed (recommended)

## Deployment

- [ ] Production environment prepared
- [ ] Rollback plan documented
- [ ] Support contact information configured
- [ ] Error tracking configured
- [ ] Analytics configured (if desired)
- [ ] User feedback mechanism implemented

## Post-Deployment

- [ ] Monitor crash reports
- [ ] Monitor user reviews
- [ ] Monitor performance metrics
- [ ] Plan for first update
- [ ] Support channels monitored

---

## Quick Verification

Run this before deployment:

```bash
# 1. Verify no placeholder password
grep -n "REPLACE_IN_PRODUCTION" lib/services/database_service.dart
# Should return: no matches

# 2. Run all quality checks
flutter format --set-exit-if-changed .
flutter analyze
flutter test

# 3. Build release
flutter build apk --release
flutter build ios --release

# 4. Verify version
grep "version:" pubspec.yaml
```

## Emergency Contacts

- Technical Lead: [Add contact]
- Security Team: [Add contact]
- DevOps: [Add contact]

---

**Last Updated**: 2024-12-27  
**Next Review**: Before production deployment

⚠️ **Remember**: This checklist should be reviewed and updated before each production release!

# Security Policy

## Supported Versions

Currently supported versions for security updates:

| Version | Supported          |
| ------- | ------------------ |
| 1.0.x   | :white_check_mark: |

## Security Features

### Data Encryption

- **SQLCipher Encryption**: All local data is encrypted using AES-256 encryption via SQLCipher
- **Per-Installation Password**: Each installation generates a unique, cryptographically secure database password (48 bytes, 384 bits of entropy)
- **Secure Storage**: Database password stored in platform-specific secure storage (iOS Keychain, Android Keystore)
- **Automatic Migration**: Seamless migration from legacy placeholder password to secure password
- No data is transmitted over the network
- All data remains on the device

### Authentication & Access Control

1. **PIN Protection**
   - PBKDF2-based PIN hashing with 10,000 iterations (HMAC-SHA256)
   - 32-byte cryptographically secure salt per PIN
   - Hash and salt stored in platform secure storage
   - Never stored in plaintext

2. **Biometric Authentication**
   - Support for Face ID, Fingerprint, and other platform biometrics
   - Requires PIN to be set first (PIN is fallback)
   - Automatic biometric revocation detection
   - Falls back to PIN when device biometrics are removed

3. **Lockout Policy**
   - Progressive lockout on failed PIN attempts:
     - 5 failed attempts: 30 second lockout
     - 10 failed attempts: 5 minute lockout
     - 15+ failed attempts: 30 minute lockout (capped)
   - Lockout timers persist across app restarts

4. **Auto-Lock**
   - Configurable idle timeout (1, 2, 5, 10, or 30 minutes)
   - Default timeout: 2 minutes
   - Immediate lock when app is backgrounded
   - Activity tracking resets idle timer

5. **Privacy Screen**
   - App switcher shows logo overlay instead of sensitive data
   - Prevents medical information leakage in task switcher

### Data Privacy

- No analytics or tracking
- No external API calls
- No cloud synchronization (by default)
- All data stored locally
- User has full control over their data

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue, please follow these steps:

### DO NOT

- Open a public GitHub issue
- Disclose the vulnerability publicly before it's fixed
- Test the vulnerability on production systems you don't own

### DO

1. **Email the security team** (configure your security contact email)
2. **Include in your report**:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if any)
   - Your contact information (for follow-up)

3. **Wait for acknowledgment**
   - We aim to respond within 48 hours
   - We'll provide a timeline for fixing the issue
   - We'll keep you updated on progress

4. **Coordinated disclosure**
   - Work with us on a disclosure timeline
   - Allow time for fix implementation and testing
   - We'll credit you in the security advisory (unless you prefer anonymity)

## Security Best Practices for Developers

When contributing to this project:

### Code Security

1. **Never commit secrets**
   - No API keys, passwords, or tokens
   - Use `.gitignore` for sensitive files
   - Use environment variables or secure storage

2. **Input validation**
   - Validate all user inputs
   - Sanitize data before database operations
   - Use parameterized queries (automatically handled by sqflite)

3. **Dependencies**
   - Keep dependencies updated
   - Review security advisories
   - Use `flutter pub outdated` regularly
   - Run `flutter pub upgrade` for security patches

4. **Secure coding**
   - Follow OWASP Mobile Security guidelines
   - Implement proper error handling
   - Don't expose sensitive information in logs
   - Use secure random number generation

### Database Security

1. **Encryption**
   - Always use encrypted databases
   - Use strong, unique passwords
   - Never use default or hardcoded passwords

2. **Queries**
   - Use parameterized queries (prevents SQL injection)
   - Validate data types
   - Handle errors securely

3. **Backup**
   - Encrypted backups only
   - Secure backup locations
   - User-controlled backup/restore

### Mobile Platform Security

1. **Android**
   - Use ProGuard/R8 for code obfuscation
   - Implement certificate pinning (if using network)
   - Request minimal permissions
   - Store sensitive data in encrypted storage

2. **iOS**
   - Use Keychain for sensitive data
   - Enable App Transport Security
   - Implement certificate pinning (if using network)
   - Request minimal permissions

## Security Checklist for Releases

Before each release:

- [ ] All dependencies updated to latest secure versions
- [ ] No hardcoded secrets or credentials
- [ ] Input validation implemented
- [ ] Error messages don't expose sensitive information
- [ ] Database encryption verified
- [ ] Security review completed
- [ ] Penetration testing performed (for major releases)
- [ ] Security documentation updated

## Known Security Considerations

### Current Implementation

1. **Database Password**: Implemented with secure storage
   - **Status**: ✅ Implemented using flutter_secure_storage
   - **Security**: Each installation has a unique, cryptographically secure password
   - **Storage**: Platform-specific secure storage (iOS Keychain, Android Keystore)

2. **No Network Security**: App doesn't use network
   - **Risk**: None currently
   - **Future**: Implement certificate pinning if network features added

3. **Local Data Access**: Data accessible via device file system (with root/jailbreak)
   - **Risk**: Medium (requires compromised device)
   - **Mitigation**: Encrypted database provides protection
   - **Recommendation**: Users should secure their devices

## Security Updates

Security updates will be:
- Released as soon as possible
- Documented in CHANGELOG.md
- Announced via GitHub Security Advisories
- Backported to supported versions when critical

## Compliance

This application:
- Stores data locally only
- Does not collect personal information remotely
- Does not share data with third parties
- Gives users full control over their data
- Uses encryption for sensitive health data

For healthcare compliance (HIPAA, GDPR, etc.):
- Additional measures may be required
- Consult with compliance experts
- Implement additional security controls as needed

## Resources

- [OWASP Mobile Security Project](https://owasp.org/www-project-mobile-security/)
- [Flutter Security Best Practices](https://docs.flutter.dev/security)
- [SQLCipher Documentation](https://www.zetetic.net/sqlcipher/)
- [Dart Security Guidelines](https://dart.dev/guides/libraries/secure-programming)

## Contact

For security concerns, please contact:
- Security Team: [Configure your security email]
- GitHub Security Advisory: Use private vulnerability reporting

## Acknowledgments

We appreciate security researchers who responsibly disclose vulnerabilities. Contributors will be acknowledged in:
- Security advisories
- Release notes
- This document (with permission)

Thank you for helping keep HyperTrack secure! 🔒

# Quick Start Guide

Welcome to HyperTrack! This guide will help you get started quickly.

## Installation

### Prerequisites

- Flutter SDK (>=3.0.0)
- Android Studio or Xcode
- Git

### Clone and Setup

```bash
# Clone the repository
git clone https://github.com/Zephon-Development/BloodPressureMonitor.git
cd BloodPressureMonitor

# Install dependencies
flutter pub get

# Verify setup
flutter doctor
```

## Running the App

### Development Mode

```bash
# Run on connected device/emulator
flutter run

# Run in debug mode with hot reload
flutter run --debug

# Run in release mode
flutter run --release
```

### Platform-Specific

**Android:**
```bash
flutter run -d android
```

**iOS:**
```bash
flutter run -d ios
```

**Specific Device:**
```bash
# List devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

## Development Workflow

### 1. Create a Feature Branch

```bash
git checkout -b feature/my-new-feature
```

### 2. Make Changes

Edit files in the `lib/` directory following the MVVM structure:
- `models/` - Data structures
- `views/` - UI components
- `viewmodels/` - Business logic
- `services/` - Data access
- `utils/` - Helper functions

### 3. Test Your Changes

```bash
# Run tests
flutter test

# Run specific test file
flutter test test/models/blood_pressure_reading_test.dart
```

### 4. Format and Analyze

```bash
# Format code
flutter format .

# Analyze code
flutter analyze
```

### 5. Commit and Push

```bash
git add .
git commit -m "feat: add my new feature"
git push origin feature/my-new-feature
```

### 6. Create Pull Request

1. Go to GitHub
2. Click "New Pull Request"
3. Fill in the PR template
4. Wait for CI checks and review

## Common Commands

### Package Management

```bash
# Add a dependency
flutter pub add package_name

# Add a dev dependency
flutter pub add --dev package_name

# Update dependencies
flutter pub upgrade

# Check for outdated packages
flutter pub outdated
```

### Building

```bash
# Build APK (Android)
flutter build apk --release

# Build App Bundle (Android)
flutter build appbundle --release

# Build iOS
flutter build ios --release
```

### Cleaning

```bash
# Clean build artifacts
flutter clean

# Get dependencies again after clean
flutter pub get
```

### Code Quality

```bash
# Format all files
flutter format .

# Format specific file
flutter format lib/main.dart

# Analyze code
flutter analyze

# Fix analysis issues
dart fix --apply
```

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   └── blood_pressure_reading.dart
├── views/                    # UI screens
│   └── home_view.dart
├── viewmodels/              # Business logic
│   └── blood_pressure_viewmodel.dart
├── services/                # Data services
│   └── database_service.dart
└── utils/                   # Utilities
    └── validators.dart
```

## Testing

### Run All Tests

```bash
flutter test
```

### Run with Coverage

```bash
flutter test --coverage
```

### View Coverage Report

```bash
# Generate coverage report
genhtml coverage/lcov.info -o coverage/html

# Open in browser
open coverage/html/index.html
```

## Debugging

### Enable Verbose Logging

```bash
flutter run -v
```

### Debug in VS Code

1. Set breakpoints in code
2. Press F5 or click "Run and Debug"
3. Select device
4. Debug as normal

### Debug in Android Studio

1. Set breakpoints
2. Click debug button
3. Select device
4. Debug as normal

## Database

### View Database (Development)

The database is stored in the app's documents directory.

**Android:**
```bash
adb shell
cd /data/data/com.zephon.blood_pressure_monitor/app_flutter
ls *.db
```

**iOS:**
Use Xcode's device manager to download app container.

### Reset Database

```bash
# Uninstall and reinstall app
flutter clean
flutter run
```

## Troubleshooting

### Common Issues

**Issue: Dependencies not resolving**
```bash
flutter clean
flutter pub get
```

**Issue: Build failures**
```bash
flutter clean
cd android && ./gradlew clean
cd ..
flutter build apk
```

**Issue: Hot reload not working**
- Try hot restart (Shift+R in terminal)
- Stop and restart app
- Clean and rebuild

**Issue: Emulator not detected**
```bash
# Android
flutter emulators
flutter emulators --launch <emulator-id>

# iOS
open -a Simulator
```

## Environment Setup

### Android

1. Install Android Studio
2. Install Android SDK
3. Create emulator
4. Set environment variables:
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### iOS (macOS only)

1. Install Xcode from App Store
2. Install command line tools:
```bash
xcode-select --install
```
3. Open iOS Simulator:
```bash
open -a Simulator
```

## Helpful Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Documentation](https://dart.dev/guides)
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [README.md](README.md) - Full project documentation
- [VERSIONING.md](VERSIONING.md) - Version management

## Getting Help

- Check documentation in this repository
- Search existing issues on GitHub
- Create a new issue with details
- Ask in pull request comments

## Next Steps

1. Read [README.md](README.md) for full documentation
2. Review [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines
3. Check out [example issues](../../issues) to get started
4. Join the discussion in pull requests

Happy coding! 🚀

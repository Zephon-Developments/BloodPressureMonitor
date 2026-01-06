# HealthLog

A personal application for recording and visualising blood pressure and pulse readings over time.

## Features

- 📊 Record blood pressure readings (systolic/diastolic)
- ❤️ Track pulse rate
- 🔒 Encrypted local storage using SQLite with SQLCipher
- 📱 Clean MVVM architecture
- 🎨 Material Design 3 UI

## Architecture

This application follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models** (`lib/models/`): Data structures and business entities
- **Views** (`lib/views/`): UI components and screens
- **ViewModels** (`lib/viewmodels/`): Business logic and state management
- **Services** (`lib/services/`): Data access and external services
- **Utils** (`lib/utils/`): Utility functions and helpers

### Technology Stack

- **Flutter**: Cross-platform mobile framework
- **Provider**: State management
- **SQLCipher**: Encrypted SQLite database
- **Material Design 3**: UI components

## Getting Started

### Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode (for mobile development)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/Zephon-Development/BloodPressureMonitor.git
   cd BloodPressureMonitor
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the app:
   ```bash
   flutter run
   ```

## Development

### Project Structure

```
lib/
├── models/           # Data models
├── views/            # UI screens
├── viewmodels/       # Business logic
├── services/         # Data services
├── utils/            # Utility functions
└── main.dart         # Application entry point

test/
├── models/           # Model tests
├── viewmodels/       # ViewModel tests
└── services/         # Service tests
```

### Running Tests

```bash
flutter test
```

### Code Quality

Format code:
```bash
flutter format .
```

Analyze code:
```bash
flutter analyze
```

### Building

Build APK (Android):
```bash
flutter build apk --release
```

Build iOS:
```bash
flutter build ios --release
```

## Versioning

This project follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

Current version: **1.0.0+1**

The version is managed in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

Where:
- `1.0.0` is the semantic version
- `+1` is the build number

### Updating Version

When releasing a new version:

1. Update the version in `pubspec.yaml`
2. Create a git tag:
   ```bash
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin v1.0.0
   ```

## Database

The application uses **SQLCipher** for encrypted local storage. All data is stored securely on the device.

⚠️ **Security Note**: The database password is currently hardcoded for development. In production, you should:
- Store the password in secure storage (e.g., Flutter Secure Storage)
- Generate a unique password per installation
- Implement proper key management

## CI/CD

This project uses GitHub Actions for continuous integration:

- Automated testing on pull requests
- Code quality checks (formatting, analysis)
- Build verification
- Self-hosted runners supported

See `.github/workflows/ci.yml` for pipeline configuration.

## Contributing

Please read [BRANCH_PROTECTION.md](.github/BRANCH_PROTECTION.md) for details on our development workflow and branch protection rules.

### Development Workflow

1. Create a feature branch from `main`
2. Make your changes
3. Write/update tests
4. Ensure all tests pass and code is formatted
5. Submit a pull request
6. Wait for CI checks and code review
7. Merge after approval

## License

This project is licensed under the Apache License 2.0 - see the LICENSE file for details.

## Security

- All data is stored locally on the device
- Database is encrypted using SQLCipher
- No data is transmitted to external servers
- Follow security best practices when deploying

## Support

For issues and feature requests, please use the GitHub issue tracker.

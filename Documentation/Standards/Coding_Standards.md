# Coding Standards

## Overview

This document defines the coding standards for the Blood Pressure Monitor application. All code must adhere to these standards. The Review Specialist will enforce compliance during code review.

**Last Updated:** December 2024
**Applies To:** All Dart/Flutter code in this project

---

## 1. General Principles

### 1.1 Core Values

1. **Security First** - User health data is sensitive; protect it rigorously
2. **Reliability** - The app must work correctly; health data errors are unacceptable
3. **Maintainability** - Code should be easy to understand and modify
4. **Testability** - All logic should be testable in isolation
5. **Performance** - Mobile resources are limited; be efficient

### 1.2 Development Philosophy

- Write code for humans first, computers second
- Prefer explicit over implicit
- Fail fast and fail clearly
- Don't repeat yourself (DRY)
- Keep it simple (KISS)
- You aren't gonna need it (YAGNI)

---

## 2. Git Workflow & CI Standards

### 2.1 Branching Strategy

```
main (protected)
  ├── feature/feature-name
  ├── bugfix/bug-description
  ├── hotfix/critical-fix
  └── chore/maintenance-task
```

**Rules:**
- `main` branch is **protected** - no direct commits
- All changes must come through Pull Requests
- PRs require passing CI before merge
- PRs require at least one approval (from Review Specialist or human)

### 2.2 Branch Naming

| Type | Pattern | Example |
|------|---------|---------|
| Feature | `feature/short-description` | `feature/add-export-pdf` |
| Bug Fix | `bugfix/issue-description` | `bugfix/fix-date-parsing` |
| Hotfix | `hotfix/critical-description` | `hotfix/fix-crash-on-save` |
| Chore | `chore/task-description` | `chore/update-dependencies` |

### 2.3 Commit Messages

Follow Conventional Commits:

```
<type>(<scope>): <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Formatting (no code change)
- `refactor`: Code change that neither fixes nor adds
- `test`: Adding or correcting tests
- `chore`: Maintenance tasks

**Examples:**
```
feat(readings): add blood pressure trend chart
fix(database): prevent duplicate entries on rapid save
docs(readme): update installation instructions
test(viewmodel): add unit tests for validation logic
```

### 2.4 CI Requirements

All PRs must pass:

1. **`flutter analyze`** - Zero warnings or errors
2. **`flutter test`** - All tests pass
3. **`dart format --set-exit-if-changed .`** - Code is formatted
4. **`flutter build apk --release`** - Release build succeeds

### 2.5 Pre-Commit Checklist

Before creating a PR:

- [ ] Code is formatted (`dart format .`)
- [ ] Analyzer passes (`flutter analyze`)
- [ ] All tests pass (`flutter test`)
- [ ] New code has tests
- [ ] Documentation updated if needed
- [ ] No sensitive data in code
- [ ] Branch is up to date with main

---

## 3. Dart/Flutter Conventions

### 3.1 Naming Conventions

| Element | Convention | Example |
|---------|------------|---------|
| Classes | PascalCase | `BloodPressureReading` |
| Extensions | PascalCase | `DateTimeExtensions` |
| Mixins | PascalCase | `ValidationMixin` |
| Enums | PascalCase | `ReadingCategory` |
| Enum values | camelCase | `ReadingCategory.normal` |
| Functions | camelCase | `calculateAverage()` |
| Variables | camelCase | `systolicValue` |
| Constants | camelCase | `maxSystolic` |
| Private members | _camelCase | `_databaseService` |
| Files | snake_case | `blood_pressure_reading.dart` |
| Directories | snake_case | `view_models/` |

### 3.2 File Organization

```
lib/
├── main.dart
├── app.dart                    # App widget and theme
├── models/                     # Data models
│   └── blood_pressure_reading.dart
├── services/                   # Business logic services
│   ├── database_service.dart
│   └── export_service.dart
├── viewmodels/                 # State management
│   └── blood_pressure_viewmodel.dart
├── views/                      # UI screens
│   ├── home_view.dart
│   └── widgets/               # Reusable widgets
│       └── reading_card.dart
├── utils/                      # Utilities and helpers
│   ├── validators.dart
│   └── date_formats.dart
└── constants/                  # App-wide constants
    └── app_constants.dart

test/
├── models/                     # Model tests
├── services/                   # Service tests
├── viewmodels/                 # ViewModel tests
└── widgets/                    # Widget tests
```

### 3.3 Import Order

Organize imports in this order, with blank lines between groups:

```dart
// 1. Dart SDK imports
import 'dart:async';
import 'dart:convert';

// 2. Flutter imports
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// 3. Package imports (alphabetical)
import 'package:provider/provider.dart';
import 'package:sqflite/sqflite.dart';

// 4. Project imports (alphabetical)
import 'package:blood_pressure_monitor/models/reading.dart';
import 'package:blood_pressure_monitor/services/database.dart';
```

### 3.4 Code Style

**Line Length:** Maximum 80 characters

**Trailing Commas:** Always use for multi-line constructs:
```dart
// Good
Widget build(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Hello'),
        Text('World'),
      ],
    ),
  );
}
```

**Const Constructors:** Use wherever possible:
```dart
// Good
const EdgeInsets.all(16)
const Text('Static text')
const SizedBox(height: 8)

// Bad
EdgeInsets.all(16)
Text('Static text')
SizedBox(height: 8)
```

---

## 4. Architecture Patterns

### 4.1 State Management

Use Provider with ChangeNotifier for state management:

```dart
class BloodPressureViewModel extends ChangeNotifier {
  final DatabaseService _databaseService;
  
  List<BloodPressureReading> _readings = [];
  List<BloodPressureReading> get readings => List.unmodifiable(_readings);
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  BloodPressureViewModel(this._databaseService);

  Future<void> loadReadings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _readings = await _databaseService.getAllReadings();
    } catch (e) {
      _errorMessage = 'Failed to load readings';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### 4.2 Service Layer

Services encapsulate business logic and external dependencies:

```dart
abstract class DatabaseService {
  Future<List<BloodPressureReading>> getAllReadings();
  Future<void> insertReading(BloodPressureReading reading);
  Future<void> deleteReading(int id);
}

class SqliteDatabaseService implements DatabaseService {
  // Implementation
}
```

### 4.3 Dependency Injection

Use Provider for dependency injection:

```dart
void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<DatabaseService>(
          create: (_) => SqliteDatabaseService(),
        ),
        ChangeNotifierProxyProvider<DatabaseService, BloodPressureViewModel>(
          create: (context) => BloodPressureViewModel(
            context.read<DatabaseService>(),
          ),
          update: (_, db, vm) => vm!..updateDatabaseService(db),
        ),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 5. Error Handling

### 5.1 Error Handling Strategy

1. **Catch specific exceptions** where you can handle them
2. **Log unexpected errors** for debugging
3. **Present user-friendly messages** in the UI
4. **Never swallow exceptions silently**

### 5.2 Result Pattern

Use a Result type for operations that can fail:

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);
}

class Failure<T> extends Result<T> {
  final AppError error;
  const Failure(this.error);
}

// Usage
Future<Result<BloodPressureReading>> saveReading(BloodPressureReading reading) async {
  try {
    await _database.insert(reading);
    return Success(reading);
  } on DatabaseException catch (e) {
    return Failure(AppError.database(e.message));
  } catch (e, stackTrace) {
    _logger.error('Unexpected error saving reading', e, stackTrace);
    return Failure(AppError.unexpected());
  }
}
```

### 5.3 Error Types

Define typed errors for the application:

```dart
enum AppErrorType {
  database,
  network,
  validation,
  notFound,
  unexpected,
}

class AppError {
  final AppErrorType type;
  final String message;
  final String? debugInfo;

  const AppError({
    required this.type,
    required this.message,
    this.debugInfo,
  });

  String get userMessage {
    switch (type) {
      case AppErrorType.database:
        return 'Unable to save data. Please try again.';
      case AppErrorType.network:
        return 'Network error. Please check your connection.';
      case AppErrorType.validation:
        return message; // Validation messages are user-facing
      case AppErrorType.notFound:
        return 'The requested item was not found.';
      case AppErrorType.unexpected:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}
```

---

## 6. Resource Management

### 6.1 Disposing Resources

**CRITICAL:** All disposable resources must be properly cleaned up.

```dart
class _MyWidgetState extends State<MyWidget> {
  late final TextEditingController _systolicController;
  late final TextEditingController _diastolicController;
  late final ScrollController _scrollController;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _systolicController = TextEditingController();
    _diastolicController = TextEditingController();
    _scrollController = ScrollController();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_onConnectivityChange);
    _autoSaveTimer = Timer.periodic(const Duration(minutes: 1), _autoSave);
  }

  @override
  void dispose() {
    // Dispose ALL resources
    _systolicController.dispose();
    _diastolicController.dispose();
    _scrollController.dispose();
    _connectivitySubscription?.cancel();
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
```

### 6.2 Common Resource Leaks to Avoid

| Resource | Leak Pattern | Prevention |
|----------|--------------|------------|
| TextEditingController | Not disposed | Dispose in `dispose()` |
| AnimationController | Not disposed | Dispose in `dispose()` |
| ScrollController | Not disposed | Dispose in `dispose()` |
| StreamSubscription | Not cancelled | Cancel in `dispose()` |
| Timer | Not cancelled | Cancel in `dispose()` |
| ChangeNotifier listeners | Not removed | Remove in `dispose()` |
| Focus nodes | Not disposed | Dispose in `dispose()` |

### 6.3 Async Operations and Mounted Check

Always check `mounted` before calling `setState` after async operations:

```dart
Future<void> _loadData() async {
  final data = await _service.fetchData();
  
  // Widget might have been disposed during await
  if (!mounted) return;
  
  setState(() {
    _data = data;
  });
}
```

---

## 7. Security Standards

### 7.1 Data Classification

| Data Type | Classification | Storage |
|-----------|---------------|---------|
| Blood pressure readings | Sensitive Health Data | Encrypted local database |
| User preferences | Non-sensitive | SharedPreferences (OK) |
| API keys | Secret | flutter_secure_storage |
| Session tokens | Secret | flutter_secure_storage |

### 7.2 Secure Storage

**Never store sensitive data in:**
- SharedPreferences
- Plain text files
- Logs
- Source code

**Use for sensitive data:**
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'auth_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }
}
```

### 7.3 Logging Rules

**Never log:**
- Health data values
- Passwords or tokens
- Personal identifiable information
- Full stack traces in production

**Safe logging:**
```dart
// Bad - exposes health data
_logger.info('Saved reading: systolic=$systolic, diastolic=$diastolic');

// Good - logs action without data
_logger.info('Reading saved successfully');

// Good - logs error context without sensitive details
_logger.error('Failed to save reading', error: e.runtimeType);
```

### 7.4 Input Validation

Validate all user input:

```dart
class BloodPressureValidators {
  static const int minSystolic = 70;
  static const int maxSystolic = 250;
  static const int minDiastolic = 40;
  static const int maxDiastolic = 150;

  static String? validateSystolic(String? value) {
    if (value == null || value.isEmpty) {
      return 'Systolic pressure is required';
    }
    
    final number = int.tryParse(value);
    if (number == null) {
      return 'Please enter a valid number';
    }
    
    if (number < minSystolic || number > maxSystolic) {
      return 'Systolic must be between $minSystolic and $maxSystolic';
    }
    
    return null; // Valid
  }
}
```

---

## 8. Testing Standards

### 8.1 Test Coverage Requirements

| Component | Minimum Coverage | Priority |
|-----------|-----------------|----------|
| Models | 90% | High |
| ViewModels | 85% | High |
| Services | 85% | High |
| Utilities | 90% | High |
| Widgets | 70% | Medium |

### 8.2 Test File Organization

```
test/
├── models/
│   └── blood_pressure_reading_test.dart
├── services/
│   └── database_service_test.dart
├── viewmodels/
│   └── blood_pressure_viewmodel_test.dart
├── utils/
│   └── validators_test.dart
├── widgets/
│   └── reading_card_test.dart
└── test_helpers/
    ├── mocks.dart
    └── fixtures.dart
```

### 8.3 Test Naming

Use descriptive test names that explain the scenario:

```dart
group('BloodPressureReading', () {
  group('validation', () {
    test('should reject systolic below minimum threshold', () {
      // ...
    });

    test('should accept systolic at minimum threshold', () {
      // ...
    });

    test('should reject systolic above maximum threshold', () {
      // ...
    });
  });

  group('fromMap', () {
    test('should correctly parse all fields from valid map', () {
      // ...
    });

    test('should throw FormatException when required field is missing', () {
      // ...
    });
  });
});
```

### 8.4 Test Structure (AAA Pattern)

```dart
test('should calculate correct average when readings exist', () {
  // Arrange
  final readings = [
    BloodPressureReading(systolic: 120, diastolic: 80),
    BloodPressureReading(systolic: 130, diastolic: 85),
  ];
  final calculator = AverageCalculator();

  // Act
  final result = calculator.calculateAverage(readings);

  // Assert
  expect(result.systolic, equals(125));
  expect(result.diastolic, equals(82.5));
});
```

### 8.5 Mocking

Use `mocktail` for mocking:

```dart
import 'package:mocktail/mocktail.dart';

class MockDatabaseService extends Mock implements DatabaseService {}

void main() {
  late MockDatabaseService mockDatabase;
  late BloodPressureViewModel viewModel;

  setUp(() {
    mockDatabase = MockDatabaseService();
    viewModel = BloodPressureViewModel(mockDatabase);
  });

  test('should load readings from database on init', () async {
    // Arrange
    final expectedReadings = [testReading];
    when(() => mockDatabase.getAllReadings())
        .thenAnswer((_) async => expectedReadings);

    // Act
    await viewModel.loadReadings();

    // Assert
    expect(viewModel.readings, equals(expectedReadings));
    verify(() => mockDatabase.getAllReadings()).called(1);
  });
}
```

---

## 9. Performance Guidelines

### 9.1 Widget Optimization

**Use const constructors:**
```dart
// Good - widget is const, won't rebuild unnecessarily
const SizedBox(height: 16)

// Bad - new instance created each build
SizedBox(height: 16)
```

**Extract static widgets:**
```dart
// Good - static content extracted as const
class MyWidget extends StatelessWidget {
  static const _header = Text('Blood Pressure Monitor');
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _header,  // Reused, not rebuilt
        // Dynamic content
      ],
    );
  }
}
```

### 9.2 List Optimization

**Use ListView.builder for long lists:**
```dart
// Good - items built lazily
ListView.builder(
  itemCount: readings.length,
  itemBuilder: (context, index) => ReadingCard(reading: readings[index]),
)

// Bad - all items built immediately
ListView(
  children: readings.map((r) => ReadingCard(reading: r)).toList(),
)
```

### 9.3 Image Optimization

- Use appropriate image sizes (don't load 4K for a thumbnail)
- Use `cached_network_image` for network images
- Prefer vector graphics (SVG) for icons

### 9.4 Avoid Expensive Operations in Build

```dart
// Bad - parsing done every build
Widget build(BuildContext context) {
  final parsed = expensiveParsing(data); // DON'T DO THIS
  return Text(parsed);
}

// Good - parsing done once, result cached
class _MyWidgetState extends State<MyWidget> {
  late final String _parsed;
  
  @override
  void initState() {
    super.initState();
    _parsed = expensiveParsing(widget.data);
  }
  
  @override
  Widget build(BuildContext context) {
    return Text(_parsed);
  }
}
```

---

## 10. Documentation Standards

### 10.1 Public API Documentation

All public classes, methods, and properties must have documentation:

```dart
/// A single blood pressure reading with systolic and diastolic values.
///
/// Blood pressure is measured in millimeters of mercury (mmHg).
/// Normal blood pressure is typically around 120/80 mmHg.
///
/// Example:
/// ```dart
/// final reading = BloodPressureReading(
///   systolic: 120,
///   diastolic: 80,
///   timestamp: DateTime.now(),
/// );
/// ```
class BloodPressureReading {
  /// The systolic (upper) blood pressure value in mmHg.
  ///
  /// This represents the pressure when the heart beats.
  /// Normal range: 90-120 mmHg.
  final int systolic;

  /// The diastolic (lower) blood pressure value in mmHg.
  ///
  /// This represents the pressure when the heart rests between beats.
  /// Normal range: 60-80 mmHg.
  final int diastolic;

  /// Creates a new blood pressure reading.
  ///
  /// Throws [ArgumentError] if [systolic] or [diastolic] are outside
  /// the valid range (systolic: 70-250, diastolic: 40-150).
  BloodPressureReading({
    required this.systolic,
    required this.diastolic,
  });
}
```

### 10.2 Implementation Comments

Use comments to explain **why**, not **what**:

```dart
// Bad - explains what (obvious from code)
// Increment counter by 1
counter++;

// Good - explains why
// Use insertion sort for small arrays as it outperforms quicksort below n=10
if (items.length < 10) {
  insertionSort(items);
} else {
  quickSort(items);
}
```

### 10.3 TODO Comments

TODOs must reference an issue:

```dart
// TODO(#123): Implement export to PDF when design is finalized

// NOT acceptable:
// TODO: Fix this later
```

---

## 11. Accessibility

### 11.1 Semantic Labels

Provide semantic labels for screen readers:

```dart
IconButton(
  icon: const Icon(Icons.delete),
  onPressed: _deleteReading,
  tooltip: 'Delete reading',  // For screen readers
)

Image.asset(
  'assets/heart.png',
  semanticLabel: 'Heart icon indicating health data',
)
```

### 11.2 Minimum Touch Targets

Interactive elements must be at least 48x48 logical pixels:

```dart
SizedBox(
  width: 48,
  height: 48,
  child: IconButton(
    icon: const Icon(Icons.add),
    onPressed: _addReading,
  ),
)
```

### 11.3 Color Contrast

- Text must have sufficient contrast against background
- Don't rely solely on color to convey information
- Test with color blindness simulators

---

## 12. Enforcement

### 12.1 Automated Enforcement

The following are enforced by CI:

- `flutter analyze` - Static analysis
- `dart format` - Code formatting
- `flutter test` - Test execution

### 12.2 Review Enforcement

The Review Specialist enforces:

- Architectural patterns
- Security requirements
- Documentation completeness
- Test coverage
- Resource management

### 12.3 Violation Handling

| Severity | Action |
|----------|--------|
| Critical | Must fix before merge |
| Important | Must fix before merge |
| Minor | May merge, fix in follow-up |

---

## Appendix A: Analysis Options

Use this `analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  errors:
    missing_return: error
    missing_required_param: error
    must_be_immutable: error
  language:
    strict-casts: true
    strict-raw-types: true

linter:
  rules:
    - always_declare_return_types
    - always_use_package_imports
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - avoid_slow_async_io
    - avoid_type_to_string
    - avoid_types_as_parameter_names
    - avoid_web_libraries_in_flutter
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - deprecated_consistency
    - directives_ordering
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - prefer_const_constructors
    - prefer_const_declarations
    - prefer_final_fields
    - prefer_final_locals
    - require_trailing_commas
    - sort_pub_dependencies
    - test_types_in_equals
    - throw_in_finally
    - unawaited_futures
    - unnecessary_statements
    - unsafe_html
    - use_key_in_widget_constructors
```

---

## Appendix B: Quick Reference

### File Naming
- `snake_case.dart` for all files

### Class Naming
- `PascalCase` for classes, enums, extensions

### Function Naming
- `camelCase` for functions and methods

### Variable Naming
- `camelCase` for variables
- `_camelCase` for private members

### Const vs Final
- `const` for compile-time constants
- `final` for runtime constants

### Required Verification Before PR
1. `dart format .`
2. `flutter analyze`
3. `flutter test`
4. `flutter build apk --release`

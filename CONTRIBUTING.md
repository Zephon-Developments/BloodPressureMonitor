# Contributing to Blood Pressure Monitor

Thank you for your interest in contributing to the Blood Pressure Monitor project! This document provides guidelines for contributing to this project.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/YOUR_USERNAME/BloodPressureMonitor.git
   cd BloodPressureMonitor
   ```
3. **Set up the development environment**:
   ```bash
   flutter pub get
   ```

## Development Workflow

### Creating a Feature Branch

Always create a new branch for your work:

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `bugfix/` - Bug fixes
- `hotfix/` - Urgent fixes
- `refactor/` - Code refactoring
- `docs/` - Documentation updates

### Making Changes

1. **Write clean code** following Dart/Flutter conventions
2. **Add tests** for new functionality
3. **Update documentation** if needed
4. **Keep commits focused** - one logical change per commit

### Commit Messages

Write clear, descriptive commit messages:

```
<type>: <subject>

<body>

<footer>
```

Types:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Maintenance tasks

Example:
```
feat: add chart visualization for blood pressure trends

- Implemented line chart using fl_chart package
- Added date range selector
- Updated home view to include chart tab

Closes #123
```

### Code Quality

Before submitting, ensure your code meets quality standards:

```bash
# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test
```

All of these checks must pass without errors.

### Testing

- Write unit tests for new models and business logic
- Write widget tests for new UI components
- Ensure all tests pass before submitting PR
- Aim for meaningful test coverage (not just 100%)

### Documentation

Update documentation when:
- Adding new features
- Changing public APIs
- Modifying configuration
- Updating dependencies

Documentation to update:
- Code comments (for complex logic)
- README.md (for user-facing changes)
- CHANGELOG.md (for all changes)
- API documentation (for public methods)

## Submitting Changes

### Creating a Pull Request

1. **Push your branch** to your fork:
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub
   - Use the PR template
   - Link related issues
   - Provide clear description
   - Add screenshots if UI changes

3. **Wait for CI checks** to complete
   - All tests must pass
   - Code analysis must pass
   - Build must succeed

4. **Respond to review feedback**
   - Address reviewer comments
   - Make requested changes
   - Push updates to the same branch

5. **Merge** (after approval)
   - Maintainer will merge your PR
   - Your branch will be deleted

### PR Review Process

- At least one approval required
- All CI checks must pass
- All conversations must be resolved
- Code must follow project conventions

## Coding Standards

### Dart/Flutter Conventions

- Follow [Effective Dart](https://dart.dev/guides/language/effective-dart)
- Use `flutter format` for consistent formatting
- Prefer `const` constructors when possible
- Use trailing commas for better formatting
- Use package imports (not relative)

### MVVM Architecture

- **Models**: Data structures only, no business logic
- **Views**: UI components, minimal logic
- **ViewModels**: Business logic and state management
- **Services**: Data access and external integrations

### File Organization

```
lib/
├── models/          # Data models
├── views/           # UI screens and widgets
├── viewmodels/      # Business logic
├── services/        # Data services
└── utils/           # Utility functions
```

### Naming Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables/Functions: `camelCase`
- Constants: `SCREAMING_SNAKE_CASE`
- Private members: prefix with `_`

### Code Comments

```dart
/// Public API documentation using triple slash
/// 
/// Detailed description here.
/// 
/// Example:
/// ```dart
/// final reading = BloodPressureReading(...);
/// ```
class BloodPressureReading {
  // Regular comments for implementation details
  final int systolic;
  
  /// Creates a new blood pressure reading.
  BloodPressureReading({required this.systolic});
}
```

## Security

### Reporting Security Issues

**DO NOT** create public issues for security vulnerabilities.

Instead:
1. Email security concerns privately
2. Include detailed description
3. Wait for response before disclosure

### Security Guidelines

- Never commit secrets or API keys
- Use encrypted storage for sensitive data
- Validate all user inputs
- Follow secure coding practices
- Keep dependencies updated

## Project-Specific Guidelines

### Database Changes

When modifying the database schema:
1. Update the version number in `DatabaseService`
2. Implement migration in `_onUpgrade`
3. Test migration from previous versions
4. Document breaking changes

### Adding Dependencies

Before adding a new dependency:
1. Check if it's necessary
2. Verify it's actively maintained
3. Review security implications
4. Update documentation

To add a dependency:
```bash
flutter pub add package_name
```

### UI Changes

- Follow Material Design 3 guidelines
- Ensure accessibility
- Test on multiple screen sizes
- Add screenshots to PR

## Questions?

If you have questions:
- Check existing documentation
- Search closed issues/PRs
- Open a discussion on GitHub
- Ask in PR comments

## License

By contributing, you agree that your contributions will be licensed under the Apache License 2.0.

## Recognition

Contributors will be recognized in:
- GitHub contributors page
- Release notes (for significant contributions)

Thank you for contributing! 🎉

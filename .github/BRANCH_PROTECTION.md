# Branch Protection and Workflow Guidelines

## Branch Protection Rules

This repository uses a protected `main` branch strategy to ensure code quality and stability.

### Main Branch Protection

The `main` branch should be configured with the following protection rules:

1. **Require pull request reviews before merging**
   - At least 1 approval required
   - Dismiss stale pull request approvals when new commits are pushed

2. **Require status checks to pass before merging**
   - Require branches to be up to date before merging
   - Required status checks:
     - `build-and-test` (CI workflow)

3. **Require conversation resolution before merging**
   - All conversations must be resolved

4. **Do not allow bypassing the above settings**
   - Even administrators should follow these rules

5. **Restrict who can push to matching branches**
   - Only allow merges via pull requests
   - Direct pushes to `main` are blocked

### Configuring Branch Protection

To set up branch protection rules in GitHub:

1. Go to your repository on GitHub
2. Click on **Settings**
3. Navigate to **Branches** in the left sidebar
4. Under "Branch protection rules", click **Add rule**
5. For "Branch name pattern", enter: `main`
6. Enable the following options:
   - ✓ Require a pull request before merging
     - ✓ Require approvals (1)
     - ✓ Dismiss stale pull request approvals when new commits are pushed
   - ✓ Require status checks to pass before merging
     - ✓ Require branches to be up to date before merging
     - Search for and select: `build-and-test`
   - ✓ Require conversation resolution before merging
   - ✓ Do not allow bypassing the above settings
   - ✓ Restrict who can push to matching branches
7. Click **Create** or **Save changes**

## Development Workflow

### Feature Branch Workflow

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write code following the project conventions
   - Add tests for new functionality
   - Update documentation as needed

3. **Commit your changes**
   ```bash
   git add .
   git commit -m "Description of changes"
   ```

4. **Push to remote**
   ```bash
   git push origin feature/your-feature-name
   ```

5. **Create a Pull Request**
   - Go to the repository on GitHub
   - Click "New Pull Request"
   - Select your feature branch
   - Fill in the PR template with:
     - Description of changes
     - Related issue numbers
     - Testing notes
   - Request reviewers

6. **Address review feedback**
   - Make requested changes
   - Push updates to the same branch
   - Respond to comments

7. **Merge**
   - Once approved and CI passes, merge via the GitHub UI
   - Use "Squash and merge" for cleaner history (recommended)
   - Delete the feature branch after merging

### Branch Naming Conventions

- `feature/` - New features (e.g., `feature/add-chart-view`)
- `bugfix/` - Bug fixes (e.g., `bugfix/fix-date-parsing`)
- `hotfix/` - Urgent fixes for production (e.g., `hotfix/critical-crash`)
- `refactor/` - Code refactoring (e.g., `refactor/database-layer`)
- `docs/` - Documentation updates (e.g., `docs/update-readme`)

### Self-Hosted Runners

This project uses self-hosted GitHub Actions runners. To set up a self-hosted runner:

1. Go to **Settings** > **Actions** > **Runners**
2. Click **New self-hosted runner**
3. Follow the instructions for your operating system
4. Ensure the runner has:
   - Flutter SDK installed
   - Android SDK (for Android builds)
   - Xcode (for iOS builds on macOS)
   - All necessary dependencies

## Continuous Integration

The CI pipeline runs automatically on:
- All pushes to `main`
- All pull requests targeting `main`

The pipeline includes:
- Dependency installation
- Code formatting verification
- Static analysis
- Test execution
- Release build generation

### Running CI Locally

Before pushing, you can run the same checks locally:

```bash
# Get dependencies
flutter pub get

# Format code
flutter format .

# Analyze code
flutter analyze

# Run tests
flutter test

# Build (optional)
flutter build apk --release
```

## Code Review Guidelines

When reviewing pull requests:

1. **Check functionality**
   - Does it work as intended?
   - Are there any edge cases?

2. **Review code quality**
   - Follows Dart/Flutter conventions
   - Proper error handling
   - Appropriate comments for complex logic

3. **Verify tests**
   - New features have tests
   - Tests are meaningful and pass
   - Edge cases are covered

4. **Check documentation**
   - README updated if needed
   - Code comments where necessary
   - API documentation for public methods

5. **Security considerations**
   - No sensitive data exposed
   - Proper input validation
   - Secure data storage practices

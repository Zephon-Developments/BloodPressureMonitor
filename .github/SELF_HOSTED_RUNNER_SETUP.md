# Self-Hosted Runner Setup Guide

This guide explains how to set up self-hosted GitHub Actions runners for the Blood Pressure Monitor project.

## Why Self-Hosted Runners?

- Full control over build environment
- Access to specific hardware/software
- Better performance for large builds
- Cost-effective for frequent builds
- Support for offline or restricted networks

## Prerequisites

- A machine to host the runner (Linux, macOS, or Windows)
- GitHub repository admin access
- Flutter SDK installed on the runner machine
- For Android builds: Android SDK
- For iOS builds: macOS with Xcode

## Setting Up a Runner

### 1. Navigate to Repository Settings

1. Go to your repository on GitHub
2. Click **Settings**
3. Navigate to **Actions** > **Runners**
4. Click **New self-hosted runner**

### 2. Choose Operating System

Select your runner's operating system:
- Linux (recommended for CI/CD)
- macOS (required for iOS builds)
- Windows (optional)

### 3. Download and Configure

Follow GitHub's instructions to download and configure the runner:

```bash
# Example for Linux
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L \
  https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz

# Configure the runner
./config.sh --url https://github.com/YOUR_ORG/BloodPressureMonitor --token YOUR_TOKEN

# Run the runner
./run.sh
```

### 4. Install as a Service (Recommended)

For production runners, install as a service:

**Linux (systemd):**
```bash
sudo ./svc.sh install
sudo ./svc.sh start
sudo ./svc.sh status
```

**macOS (launchd):**
```bash
./svc.sh install
./svc.sh start
./svc.sh status
```

**Windows (service):**
```powershell
./svc.sh install
./svc.sh start
./svc.sh status
```

## Runner Environment Setup

### Install Flutter SDK

**Linux/macOS:**
```bash
# Clone Flutter
git clone https://github.com/flutter/flutter.git -b stable ~/flutter

# Add to PATH
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

# Verify installation
flutter doctor
```

**Pre-download dependencies:**
```bash
flutter precache
flutter config --no-analytics
```

### Install Android SDK (for Android builds)

1. Download Android Command Line Tools
2. Install required SDK components:
```bash
sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"
```

3. Set environment variables:
```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools
```

### Install Xcode (for iOS builds - macOS only)

```bash
# Install Xcode from App Store
xcode-select --install

# Accept license
sudo xcodebuild -license accept

# Install CocoaPods
sudo gem install cocoapods
```

## Docker-Based Runner (Alternative)

For consistent environments, use Docker:

### Create Dockerfile

```dockerfile
FROM ubuntu:22.04

# Install dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    openjdk-11-jdk \
    wget

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git -b stable /flutter
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter precache
RUN flutter config --no-analytics

# Install Android SDK
ENV ANDROID_SDK_ROOT=/opt/android-sdk
RUN mkdir -p ${ANDROID_SDK_ROOT}/cmdline-tools
RUN wget https://dl.google.com/android/repository/commandlinetools-linux-9477386_latest.zip
RUN unzip commandlinetools-linux-9477386_latest.zip -d ${ANDROID_SDK_ROOT}/cmdline-tools
RUN mv ${ANDROID_SDK_ROOT}/cmdline-tools/cmdline-tools ${ANDROID_SDK_ROOT}/cmdline-tools/latest

ENV PATH="${ANDROID_SDK_ROOT}/cmdline-tools/latest/bin:${PATH}"

# Accept licenses and install SDK components
RUN yes | sdkmanager --licenses
RUN sdkmanager "platform-tools" "platforms;android-33" "build-tools;33.0.0"

WORKDIR /workspace
```

### Build and Run

```bash
# Build image
docker build -t flutter-runner .

# Run container
docker run -d \
  --name flutter-runner \
  -v /var/run/docker.sock:/var/run/docker.sock \
  flutter-runner
```

## Runner Configuration

### Labels

Add labels to runners for targeted workflows:

```yaml
# In workflow file
runs-on: [self-hosted, linux, flutter]
```

Configure labels during runner setup:
```bash
./config.sh --url REPO_URL --token TOKEN --labels flutter,android,linux
```

### Resource Limits

For Docker runners:

```bash
docker run -d \
  --name flutter-runner \
  --memory=4g \
  --cpus=2 \
  flutter-runner
```

### Security Considerations

1. **Run in isolated environment**
   - Use dedicated machines or containers
   - Don't run on development machines

2. **Network security**
   - Firewall configuration
   - Restrict outbound connections if needed

3. **Access control**
   - Limit who can trigger workflows
   - Use separate runners for different trust levels

4. **Secrets management**
   - Never log secrets
   - Use GitHub encrypted secrets
   - Rotate secrets regularly

## Monitoring and Maintenance

### Check Runner Status

```bash
# Linux/macOS
sudo ./svc.sh status

# View logs
journalctl -u actions.runner.* -f
```

### Update Runner

```bash
# Stop runner
sudo ./svc.sh stop

# Update
./config.sh remove --token TOKEN
# Download new version and reconfigure
./config.sh --url REPO_URL --token NEW_TOKEN

# Restart
sudo ./svc.sh start
```

### Common Issues

**Runner offline:**
- Check network connectivity
- Verify service is running
- Check GitHub runner page for errors

**Build failures:**
- Ensure Flutter SDK is up to date
- Verify Android SDK installation
- Check available disk space
- Review workflow logs

**Permission issues:**
- Ensure runner user has necessary permissions
- Check file ownership in work directory

## Multi-Runner Setup

For redundancy and load balancing:

1. Set up multiple runners with same labels
2. GitHub automatically distributes jobs
3. Configure runners on different machines/regions

## Cleanup

Remove runner:

```bash
# Stop service
sudo ./svc.sh stop

# Uninstall service
sudo ./svc.sh uninstall

# Remove from GitHub
./config.sh remove --token TOKEN
```

## Best Practices

1. **Regular updates**
   - Update runner software monthly
   - Keep Flutter SDK updated
   - Update SDKs and dependencies

2. **Resource monitoring**
   - Monitor disk space
   - Track build times
   - Set up alerts for failures

3. **Backup configuration**
   - Document runner setup
   - Version control configuration
   - Maintain setup scripts

4. **Testing**
   - Test runner setup with sample workflow
   - Verify all build types work
   - Test failure scenarios

## Support

For issues with self-hosted runners:
- GitHub Actions documentation
- Repository issues
- Runner logs in `./_diag` directory

## Additional Resources

- [GitHub Self-Hosted Runners Documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Flutter CI/CD Documentation](https://docs.flutter.dev/deployment/cd)
- [Docker for GitHub Actions](https://docs.github.com/en/actions/creating-actions/creating-a-docker-container-action)

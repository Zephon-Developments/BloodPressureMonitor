import 'package:package_info_plus/package_info_plus.dart';

/// Provides runtime application metadata such as version numbers.
class AppInfoService {
  const AppInfoService();

  /// Returns the current semantic version of the application.
  Future<String> getAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}

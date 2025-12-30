import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

/// Simple fake that returns a deterministic application documents directory.
class TestPathProviderPlatform extends PathProviderPlatform {
  TestPathProviderPlatform(this.applicationDocumentsPath);

  final String applicationDocumentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async =>
      applicationDocumentsPath;
}

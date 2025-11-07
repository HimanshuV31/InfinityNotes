import 'package:package_info_plus/package_info_plus.dart';

/// Service to get app version information
class AppVersion {
  static PackageInfo? _packageInfo;

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
  }

  /// Get formatted version string (e.g., "v1.0.0")
  static String get version {
    if (_packageInfo == null) return 'v1.0.0';
    return 'v${_packageInfo!.version}';
  }

  /// Get full version with build number (e.g., "v1.0.0 (1)")
  static String get fullVersion {
    if (_packageInfo == null) return 'v1.0.0 (1)';
    return 'v${_packageInfo!.version} (${_packageInfo!.buildNumber})';
  }

  /// Get just the version number (e.g., "1.0.0")
  static String get versionNumber {
    if (_packageInfo == null) return '1.0.0';
    return _packageInfo!.version;
  }

  /// Get just the build number (e.g., "1")
  static String get buildNumber {
    if (_packageInfo == null) return '1';
    return _packageInfo!.buildNumber;
  }
}

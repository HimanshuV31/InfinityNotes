import 'package:flutter/foundation.dart';

class PlatformUtils {
  const PlatformUtils._(); // Prevent instantiation

   // Returns true if running on the web.
  static bool get isWeb => kIsWeb;

   // Returns true if running on Android (native, NOT web).
  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

   // Returns true if running on iOS (native, NOT web).
  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

   // Returns true if running on Windows (native, NOT web).
  static bool get isWindows =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;

   // Returns true if running on macOS (native, NOT web).
  static bool get isMacOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

   // Returns true if running on Linux (native, NOT web).
  static bool get isLinux =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.linux;

   // Returns true if running on any mobile platform (native, NOT web).
  static bool get isMobile => isAndroid || isIOS;

   // Returns true if running on any desktop platform (native, NOT web).
  static bool get isDesktop => isWindows || isMacOS || isLinux;

   // Returns a string describing the current platform.
  static String get name {
    if (isWeb) return "Web";
    if (isAndroid) return "Android";
    if (isIOS) return "iOS";
    if (isWindows) return "Windows";
    if (isMacOS) return "macOS";
    if (isLinux) return "Linux";
    return "Unknown";
  }
}

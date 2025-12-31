import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinity_notes/services/platform/app_version.dart';

class VersionTracker {
  static const String _keyLastSeenVersion = 'last_seen_version';
/*
  Check if "What's New" should be shown
  Returns true if:
  - First time user (never seen any version)
  - App was updated (version changed)
*/

  static Future<bool> shouldShowWhatsNew() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSeenVersion = prefs.getString(_keyLastSeenVersion);
    final currentVersion = AppVersion.versionNumber;

    // Show if never seen OR version is different
    return lastSeenVersion == null || lastSeenVersion != currentVersion;
  }

  // Mark current version as seen by user
  static Future<void> markVersionAsSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSeenVersion, AppVersion.versionNumber);
  }
}

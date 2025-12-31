import 'package:shared_preferences/shared_preferences.dart';

class AnimationStorage {
  static const String _titleAnimationKey = 'has_played_title_animation';

  static Future<bool> hasPlayedTitleAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_titleAnimationKey) ?? false;
  }

  static Future<void> setTitleAnimationPlayed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_titleAnimationKey, true);
  }

  // Optional: Reset for testing
  static Future<void> resetTitleAnimation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_titleAnimationKey);
  }
}

import 'package:flutter/foundation.dart';

class GlobalAnimationController {
  static bool _shouldShowTitleAnimation = false;

  // Call this when user logs in or app starts
  static void triggerTitleAnimation() {
    _shouldShowTitleAnimation = true;
    debugPrint("🎯 Title animation TRIGGERED");
  }

  // Call this when animation plays to prevent repeat
  static void consumeTitleAnimation() {
    _shouldShowTitleAnimation = false;
    debugPrint("🎯 Title animation CONSUMED");
  }

  // Check if animation should play
  static bool shouldShowTitleAnimation() {
    return _shouldShowTitleAnimation;
  }

  // Reset for testing
  static void resetForTesting() {
    _shouldShowTitleAnimation = true;
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart';

class FirestoreFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Now that device_info_plus is stable again, turn this on
  static const bool _useDeviceInfo = false;

  static Future<bool> submitBugReport({
    required String userEmail,
    required String description,
    required Map<String, dynamic> deviceInfo,
  }) async {
    try {
      await _firestore.collection('bug_reports').add({
        'userEmail': userEmail,
        'description': description,
        'deviceInfo': deviceInfo,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
        'type': 'bug',
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting bug report: $e');
      return false;
    }
  }

  static Future<bool> submitFeedback({
    required String userEmail,
    required String message,
  }) async {
    try {
      await _firestore.collection('feedback').add({
        'userEmail': userEmail,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'new',
        'type': 'feedback',
      });
      return true;
    } catch (e) {
      debugPrint('❌ Error submitting feedback: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> getDeviceInfoMap() async {
    // TEMP: device_info_plus disabled due to AGP compatibility
    return {
      'platform': kIsWeb
          ? 'Web'
          : (PlatformUtils.isAndroid
          ? 'Android'
          : (PlatformUtils.isIOS ? 'iOS' : 'Desktop')),
      'version': 'Unknown',
      'device': 'Information temporarily unavailable',
      'note': 'Full device details will be available in future updates',
    };

    /*//Original Implementation
    if (!_useDeviceInfo) {
      return {
        'platform': kIsWeb
            ? 'Web'
            : (PlatformUtils.isAndroid
                  ? 'Android'
                  : (PlatformUtils.isIOS ? 'iOS' : 'Desktop')),
        'version': 'Unknown',
        'device': 'Information temporarily unavailable',
        'note': 'Full device details will be available in future updates',
      };
    }

    final deviceInfo = DeviceInfoPlugin();

    if (kIsWeb) {
      return {'platform': 'Web', 'device': 'Browser'};
    }

    if (PlatformUtils.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return {
        'platform': 'Android',
        'version': androidInfo.version.release,
        'sdk': androidInfo.version.sdkInt,
        'device': androidInfo.model,
        'manufacturer': androidInfo.manufacturer,
        'brand': androidInfo.brand,
      };
    } else if (PlatformUtils.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return {
        'platform': 'iOS',
        'version': iosInfo.systemVersion,
        'device': iosInfo.model,
        'name': iosInfo.name,
      };
    }

    return {'platform': 'Desktop', 'device': 'Unknown'};
    */
  }
}

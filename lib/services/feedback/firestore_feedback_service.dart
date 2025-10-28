import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';

class FirestoreFeedbackService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Submit bug report directly to Firestore (triggers Cloud Function)
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
      debugPrint('Error submitting bug report: $e');
      return false;
    }
  }

  /// Submit general feedback
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
      debugPrint('Error submitting feedback: $e');
      return false;
    }
  }

  /// Get device info as structured map
  static Future<Map<String, dynamic>> getDeviceInfoMap() async {
    // Reuse your existing _getDeviceInfo() logic
    // but return as Map instead of String
    final deviceInfo = DeviceInfoPlugin();

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
    }
    // Add other platforms similarly
    return {'platform': 'Unknown'};
  }
}

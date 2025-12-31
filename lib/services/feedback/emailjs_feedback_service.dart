import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:infinity_notes/services/platform/platform_utils.dart';

enum EmailJSFeedbackType {
  bugReport,
  generalFeedback,
}

class EmailJSFeedbackService {
  static const String serviceId = 'service_emailfeedback';
  static const String templateId = 'template_feedback';
  static const String publicKey = 'FrqsP6FVsfWpMRsFw';
  static const String supportEmail = 'himanshuv31.dev@gmail.com';
  static const String apiEndpoint = 'https://api.emailjs.com/api/v1.0/email/send';

  /// Initialize EmailJS - not needed for HTTP approach
  static void init() {
    debugPrint('EmailJS service initialized (HTTP mode)');
  }

  static Future<bool> sendFeedback({
    required String userEmail,
    required String userName,
    required String message,
    required EmailJSFeedbackType type,
  }) async {
    try {
      debugPrint('📤 Sending feedback via EmailJS API...');

      // Gather device info for bug reports
      final deviceInfo = type == EmailJSFeedbackType.bugReport
          ? await _getDeviceInfo()
          : 'N/A (General Feedback)';
      final appInfo = await _getAppInfo();
      final timestamp = DateTime.now().toIso8601String();

      // Define colors based on feedback type
      final bool isBugReport = type == EmailJSFeedbackType.bugReport;
      final String headerColor = isBugReport ? '#dc3545' : '#3993ad';        // Red for bugs, Blue for feedback
      final String headerColorDark = isBugReport ? '#c82333' : '#2980b9';   // Darker shade for gradient
      final String accentColor = isBugReport ? '#dc3545' : '#3993ad';       // Accent color for labels

      // Build request body with color variables
      final requestBody = {
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'to_email': supportEmail,
          'user_email': userEmail,
          'user_name': userName,
          'feedback_type': isBugReport ? 'Bug Report' : 'User Feedback',
          'message': message,
          'timestamp': timestamp,
          'app_info': appInfo,
          'device_info': deviceInfo,
          'header_color': headerColor,
          'header_color_dark': headerColorDark,
          'accent_color': accentColor,
        },
      };

      debugPrint('📧 Request body: ${json.encode(requestBody)}');

      // Send POST request to EmailJS API
      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode(requestBody),
      );

      debugPrint('📬 EmailJS Response: ${response.statusCode} - ${response.body}');

      if (response.statusCode == 200) {
        debugPrint('Feedback email sent successfully!');
        return true;
      } else {
        debugPrint('EmailJS Error: ${response.statusCode} - ${response.body}');
        return false;
      }

    } catch (error) {
      debugPrint('❌ Error sending feedback: $error');
      return false;
    }
  }

  // Helper: Get device information
  static Future<String> _getDeviceInfo() async {
    if (kIsWeb) return 'Platform: Web Browser';

    final deviceInfo = DeviceInfoPlugin();

    if (PlatformUtils.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'Platform: Android ${androidInfo.version.release} (SDK ${androidInfo.version.sdkInt})\n'
          'Device: ${androidInfo.manufacturer} ${androidInfo.model}\n'
          'Brand: ${androidInfo.brand}';
    } else if (PlatformUtils.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return 'Platform: iOS ${iosInfo.systemVersion}\n'
          'Device: ${iosInfo.model}\n'
          'Name: ${iosInfo.name}';
    }

    return 'Platform: Desktop';
  }

  // Helper: Get app information
  static Future<String> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'App Version: ${packageInfo.version} (Build ${packageInfo.buildNumber})\n'
        'Package: ${packageInfo.packageName}';
  }
}
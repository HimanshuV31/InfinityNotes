import 'dart:convert';
import 'package:http/http.dart' as http;
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:infinitynotes/services/platform/platform_utils.dart';

enum EmailJSFeedbackType { bugReport, generalFeedback }

class EmailJSFeedbackService {
  static const String serviceId = 'service_emailfeedback';
  static const String templateId = 'template_feedback';
  static const String publicKey = 'FrqsP6FVsfWpMRsFw';
  static const String supportEmail = 'himanshuv31.dev@gmail.com';
  static const String apiEndpoint =
      'https://api.emailjs.com/api/v1.0/email/send';

  // Now that device_info_plus is stable again, turn this on
  static const bool _useDeviceInfo = false;

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

      final deviceInfo = type == EmailJSFeedbackType.bugReport
          ? await _getDeviceInfo()
          : 'N/A (General Feedback)';
      final appInfo = await _getAppInfo();
      final timestamp = DateTime.now().toIso8601String();

      final bool isBugReport = type == EmailJSFeedbackType.bugReport;
      final String headerColor = isBugReport ? '#dc3545' : '#3993ad';
      final String headerColorDark = isBugReport ? '#c82333' : '#2980b9';
      final String accentColor = isBugReport ? '#dc3545' : '#3993ad';

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

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'origin': 'http://localhost',
        },
        body: json.encode(requestBody),
      );

      debugPrint(
        '📬 EmailJS Response: ${response.statusCode} - ${response.body}',
      );

      return response.statusCode == 200;
    } catch (error) {
      debugPrint('❌ Error sending feedback: $error');
      return false;
    }
  }

  static Future<Object> _getDeviceInfo() async {
    // TEMP: device_info_plus disabled due to AGP compatibility
    return 'Platform: ${kIsWeb ? 'Web' : (PlatformUtils.isAndroid ? 'Android' : (PlatformUtils.isIOS ? 'iOS' : 'Desktop'))}\n'
        'Device: Information temporarily unavailable\n'
        'Note: Full device details will be available in future updates';
    /*//The Original Implementation
    if (!_useDeviceInfo) {
      return 'Platform: ${kIsWeb ? 'Web' : (PlatformUtils.isAndroid ? 'Android' : (PlatformUtils.isIOS ? 'iOS' : 'Desktop'))}\n'
          'Device: Information temporarily unavailable\n'
          'Note: Full device details will be available in future updates';
    }

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
    } else {
      return {'Platform: Desktop', 'Device: Unknown'};
    }*/
  }

  static Future<String> _getAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return 'App Version: ${packageInfo.version} (Build ${packageInfo.buildNumber})\n'
        'Package: ${packageInfo.packageName}';
  }
}

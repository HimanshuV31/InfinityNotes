import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:infinitynotes/constants/routes.dart';

// ============================================================================
// BACKGROUND HANDLER (top-level, required by FCM)
// ============================================================================
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('📦 Background message: ${message.notification?.title}');
  }
}

// ============================================================================
// NOTIFICATION SERVICE
// ============================================================================
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isInitialized = false;
  String? _currentUserId;

  static GlobalKey<NavigatorState>? _navigatorKey;

  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  // ============================================================================
  // PUBLIC: INITIALIZE
  // ============================================================================
  Future<void> initialize(String userId) async {
    if (_isInitialized && _currentUserId == userId) return;
    _currentUserId = userId;

    try {
      final permissionGranted = await _requestPermission();
      if (!permissionGranted) {
        if (kDebugMode) print('❌ Notification permission denied');
        return;
      }

      await _initializeLocalNotifications();
      _setupMessageHandlers();
      await _saveDeviceToken(userId);
      await _handleLaunchNotification();

      _isInitialized = true;
      if (kDebugMode) print('✅ NotificationService initialized for user: $userId');
    } catch (e) {
      if (kDebugMode) print('❌ NotificationService initialization failed: $e');
    }
  }

  // ============================================================================
  // PRIVATE: PERMISSION
  // ============================================================================
  Future<bool> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      switch (settings.authorizationStatus) {
        case AuthorizationStatus.authorized:
          if (kDebugMode) print('✅ Notification permission: GRANTED');
          return true;
        case AuthorizationStatus.provisional:
          if (kDebugMode) print('⚠️ Notification permission: PROVISIONAL');
          return true;
        default:
          if (kDebugMode) print('❌ Notification permission: DENIED');
          return false;
      }
    } catch (e) {
      if (kDebugMode) print('❌ Permission request failed: $e');
      return false;
    }
  }

  // ============================================================================
  // PRIVATE: LOCAL NOTIFICATIONS INIT
  // ============================================================================
  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
    AndroidInitializationSettings('@drawable/ic_notification');

    const iOSSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iOSSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // ✅ CREATE NOTIFICATION CHANNEL (required for foreground notifications)
    const androidChannel = AndroidNotificationChannel(
      'infinity_notes_channel',
      'Infinity Notes',
      description: 'Important app updates and announcements',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    if (kDebugMode) print('✅ Local notifications initialized');
  }


  // ============================================================================
  // PRIVATE: SAVE DEVICE TOKEN
  // ✅ FIX: Flat document — serverTimestamp() at top level only
  //         FieldValue.serverTimestamp() cannot be nested inside arrayUnion()
  // ============================================================================
  Future<void> _saveDeviceToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token == null) {
        if (kDebugMode) print('❌ Failed to get FCM token');
        return;
      }

      if (kDebugMode) print('📱 FCM Token: ${token.substring(0, 20)}...');

      await _firestore.collection('device_tokens').doc(userId).set(
        {
          'token': token,
          'platform': defaultTargetPlatform.name.toLowerCase(),
          'updatedAt': FieldValue.serverTimestamp(), // ✅ top-level only
          'isActive': true,
          'notificationPreferences': {
            'enabled': true,
            'updates': true,
            'features': true,
            'marketing': true,
          },
          'timezone': 'Asia/Kolkata',
        },
        SetOptions(merge: true),
      );

      if (kDebugMode) print('✅ Device token saved to Firestore');

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _updateDeviceToken(userId, newToken);
      });
    } catch (e) {
      if (kDebugMode) print('❌ Error saving device token: $e');
    }
  }

  // ============================================================================
  // PRIVATE: UPDATE TOKEN ON REFRESH
  // ✅ FIX: update() with top-level serverTimestamp only
  // ============================================================================
  Future<void> _updateDeviceToken(String userId, String newToken) async {
    try {
      await _firestore.collection('device_tokens').doc(userId).update({
        'token': newToken,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (kDebugMode) print('✅ Token refreshed: ${newToken.substring(0, 20)}...');
    } catch (e) {
      if (kDebugMode) print('❌ Error updating token: $e');
    }
  }

  // ============================================================================
  // PRIVATE: MESSAGE HANDLERS
  // ============================================================================
  void _setupMessageHandlers() {
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    if (kDebugMode) print('✅ Message handlers configured');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('📬 Foreground message: ${message.notification?.title}');
      print('   Data: ${message.data}');
    }

    final notification = message.notification;
    if (notification == null) return;
    const androidDetails = AndroidNotificationDetails(
      'infinity_notes_channel',
      'Infinity Notes',
      channelDescription: 'Important app updates and announcements',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@drawable/ic_notification',
      color: Color(0xFF3993AD),
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: jsonEncode(message.data),
    );
  }

  // ============================================================================
  // PRIVATE: NOTIFICATION TAP HANDLERS
  // ============================================================================
  void _onNotificationTapped(NotificationResponse response) {
    if (kDebugMode) print('🔔 Local notification tapped');

    final payload = response.payload;
    if (payload == null || payload.isEmpty) return;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (e) {
      if (kDebugMode) print('❌ Failed to parse notification payload: $e');
    }
  }

  Future<void> _handleLaunchNotification() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) print('🚀 App launched from notification');
      await Future.delayed(const Duration(milliseconds: 500));
      _handleNotificationTap(initialMessage);
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    if (kDebugMode) print('📲 FCM notification tapped: ${message.data}');
    _navigateFromData(message.data);
  }

  // ============================================================================
  // PRIVATE: NAVIGATION
  // FCM payload: { "screen": "note", "noteId": "abc123" }
  //              { "screen": "home" }
  // ============================================================================
  void _navigateFromData(Map<String, dynamic> data) {
    final navigator = _navigatorKey?.currentState;
    if (navigator == null) {
      if (kDebugMode) print('❌ NavigatorKey not set — cannot navigate');
      return;
    }

    final screen = data['screen'] as String?;
    final noteId = data['noteId'] as String?;

    if (kDebugMode) print('🧭 Navigating to: $screen | noteId: $noteId');

    switch (screen) {
      case 'note':
        if (noteId != null && noteId.isNotEmpty) {
          navigator.pushNamed(
            CreateUpdateNoteRoute,
            arguments: {'noteId': noteId, 'isEditing': true},
          );
        }
        break;

      case 'home':
      default:
        navigator.popUntil((route) => route.isFirst);
        break;
    }
  }

  // ============================================================================
  // PUBLIC: UTILITIES
  // ============================================================================
  Future<bool> areNotificationsEnabled() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  Future<String?> getToken() async => _messaging.getToken();

  Future<void> dispose() async {
    _isInitialized = false;
    _currentUserId = null;
    if (kDebugMode) print('🧹 NotificationService disposed');
  }
}

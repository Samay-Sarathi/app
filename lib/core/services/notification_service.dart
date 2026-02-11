import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level handler for background FCM messages.
/// Must be a top-level function (not a class method).
@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message: ${message.messageId}');
}

/// Manages Firebase Cloud Messaging + local notification display.
///
/// Usage:
/// ```dart
/// await NotificationService.instance.init();
/// final token = await NotificationService.instance.getDeviceToken();
/// ```
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  /// Callback invoked when user taps a notification.
  void Function(String? payload)? onNotificationTap;

  static const _channel = AndroidNotificationChannel(
    'lifeline_emergency',
    'Emergency Alerts',
    description: 'High-priority alerts for incoming emergencies',
    importance: Importance.high,
  );

  /// Initialize FCM, request permissions, register handlers, set up local
  /// notifications. Call once from main.dart after Firebase.initializeApp().
  Future<void> init() async {
    // Request permission (iOS + Android 13+)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // Create Android notification channel
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // Initialize local notifications plugin
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    await _local.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    // Handle foreground messages → show local notification
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Handle notification tap when app was in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final payload = message.data.isNotEmpty ? jsonEncode(message.data) : null;
      onNotificationTap?.call(payload);
    });

    // Check if app was launched from a notification
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      final payload = initialMessage.data.isNotEmpty
          ? jsonEncode(initialMessage.data)
          : null;
      onNotificationTap?.call(payload);
    }
  }

  /// Get the FCM device token for backend registration.
  Future<String?> getDeviceToken() async {
    try {
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] Failed to get token: $e');
      return null;
    }
  }

  /// Listen for token refresh events.
  Stream<String> get onTokenRefresh => _fcm.onTokenRefresh;

  void _showForegroundNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _local.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }
}

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Android-specific notification helper using flutter_local_notifications
class AndroidNotificationHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Initialize notifications
  static Future<void> init() async {
    if (_initialized || kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android 8.0+
    const channel = AndroidNotificationChannel(
      'fancy_notifications',
      'FANCY Notifications',
      description: 'Notifications for messages, likes, and matches',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
  }

  /// Handle notification tap
  static void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload != null) {
      // Parse payload and navigate
      // Format: "type:id" e.g., "chat:123" or "profile:456"
      final parts = payload.split(':');
      if (parts.length == 2) {
        final type = parts[0];
        final id = parts[1];
        // Navigation will be handled by the app when it opens
        debugPrint('Notification tapped: $type - $id');
      }
    }
  }

  /// Request notification permission (Android 13+)
  static Future<bool> requestPermission() async {
    if (kIsWeb) return false;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? false;
    }
    return true; // Pre-Android 13 doesn't need explicit permission
  }

  /// Check if notifications are supported
  static bool get isSupported => !kIsWeb;

  /// Show a notification
  static Future<void> show({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (kIsWeb || !_initialized) return;

    final notificationId = id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000;

    const androidDetails = AndroidNotificationDetails(
      'fancy_notifications',
      'FANCY Notifications',
      channelDescription: 'Notifications for messages, likes, and matches',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
      styleInformation: BigTextStyleInformation(''),
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      notificationId,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Show message notification
  static Future<void> showMessage({
    required String senderName,
    required String message,
    String? chatId,
  }) async {
    await show(
      title: senderName,
      body: message,
      payload: chatId != null ? 'chat:$chatId' : null,
    );
  }

  /// Show like notification
  static Future<void> showLike({
    required String userName,
    String? userId,
    bool isSuperLike = false,
  }) async {
    await show(
      title: isSuperLike ? '⭐ Super Like!' : '❤️ New Like!',
      body: isSuperLike
          ? '$userName super liked you!'
          : '$userName liked your profile!',
      payload: userId != null ? 'profile:$userId' : null,
    );
  }

  /// Show match notification
  static Future<void> showMatch({
    required String userName,
    String? matchId,
  }) async {
    await show(
      title: "🎉 It's a Match!",
      body: 'You and $userName liked each other!',
      payload: matchId != null ? 'match:$matchId' : null,
    );
  }

  /// Cancel all notifications
  static Future<void> cancelAll() async {
    if (!kIsWeb && _initialized) {
      await _notifications.cancelAll();
    }
  }
}

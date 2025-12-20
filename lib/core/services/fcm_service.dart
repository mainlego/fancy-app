import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../router/app_router.dart';

/// Background message handler - must be top-level function
/// IMPORTANT: When a notification payload is present, FCM automatically displays
/// the notification when the app is in background. This handler is only called
/// for data-only messages or when you need to process data in background.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 Background message received: ${message.messageId}');
  debugPrint('🔔 Notification: ${message.notification?.title} - ${message.notification?.body}');
  debugPrint('🔔 Data: ${message.data}');

  // FCM automatically shows notification when app is in background
  // if the message contains a 'notification' payload.
  // We don't need to show it manually - FCM handles this.
}

/// Firebase Cloud Messaging service for push notifications
class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  String? _fcmToken;

  String? get fcmToken => _fcmToken;

  /// Initialize FCM service
  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    try {
      // Initialize Firebase
      await Firebase.initializeApp();

      // Initialize local notifications for showing FCM messages
      await _initLocalNotifications();

      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request permission
      await _requestPermission();

      // Get FCM token
      _fcmToken = await FirebaseMessaging.instance.getToken();
      debugPrint('FCM Token: $_fcmToken');

      // Save token to Supabase
      if (_fcmToken != null) {
        await _saveTokenToSupabase(_fcmToken!);
      }

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        _fcmToken = token;
        debugPrint('FCM Token refreshed: $token');
        await _saveTokenToSupabase(token);
      });

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // Handle notification tap when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      // Check if app was opened from notification
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      _initialized = true;
      debugPrint('FCM Service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing FCM: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Local notification tapped: ${response.payload}');
        _handleLocalNotificationTap(response.payload);
      },
    );

    // Create notification channel
    const channel = AndroidNotificationChannel(
      'fancy_fcm_channel',
      'FANCY Notifications',
      description: 'Push notifications for messages, likes, and matches',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request notification permission
  Future<bool> _requestPermission() async {
    final messaging = FirebaseMessaging.instance;

    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    final granted = settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;

    debugPrint('FCM Permission: ${settings.authorizationStatus}');
    return granted;
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Foreground message: ${message.notification?.title}');
    _showLocalNotification(message);
  }

  /// Handle notification tap - navigate to appropriate screen based on notification type
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Notification tapped: ${message.data}');

    final data = message.data;
    final type = data['type'] as String?;

    // Wait a moment for the app to be ready before navigating
    Future.delayed(const Duration(milliseconds: 500), () {
      switch (type) {
        case 'chat':
        case 'message':
          // Navigate to chat detail
          final chatId = data['chat_id'] as String?;
          final userId = data['user_id'] as String?;
          if (chatId != null) {
            appRouter.push('/chats/$chatId');
          } else if (userId != null) {
            // Find or create chat with user
            appRouter.push('/chats/$userId');
          } else {
            // Go to chats list
            appRouter.go(AppRoutes.chats);
          }
          break;

        case 'match':
        case 'like':
        case 'superlike':
          // Navigate to chats (likes tab shows matches)
          appRouter.go(AppRoutes.chats);
          break;

        case 'verification':
          // Navigate to verification screen
          final status = data['status'] as String?;
          if (status == 'approved' || status == 'rejected') {
            appRouter.push(AppRoutes.verification);
          }
          break;

        case 'profile_view':
          // Someone viewed your profile - go to home
          appRouter.go(AppRoutes.home);
          break;

        default:
          // Default: go to home
          debugPrint('Unknown notification type: $type');
          appRouter.go(AppRoutes.home);
      }
    });
  }

  /// Handle local notification tap (when app is in foreground)
  static void _handleLocalNotificationTap(String? payload) {
    if (payload == null) return;

    try {
      // Parse payload - it's stringified map from message.data
      // Format: {type: chat, chat_id: xxx, ...}
      final payloadStr = payload.replaceAll(RegExp(r'^\{|\}$'), '');
      final parts = payloadStr.split(', ');
      final data = <String, String>{};
      for (final part in parts) {
        final keyValue = part.split(': ');
        if (keyValue.length == 2) {
          data[keyValue[0].trim()] = keyValue[1].trim();
        }
      }

      final type = data['type'];
      debugPrint('Handling local notification tap: type=$type, data=$data');

      switch (type) {
        case 'chat':
        case 'message':
          final chatId = data['chat_id'];
          if (chatId != null) {
            appRouter.push('/chats/$chatId');
          } else {
            appRouter.go(AppRoutes.chats);
          }
          break;

        case 'match':
        case 'like':
        case 'superlike':
          appRouter.go(AppRoutes.chats);
          break;

        case 'verification':
          appRouter.push(AppRoutes.verification);
          break;

        default:
          appRouter.go(AppRoutes.home);
      }
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
      appRouter.go(AppRoutes.home);
    }
  }

  /// Show local notification from FCM message
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'fancy_fcm_channel',
      'FANCY Notifications',
      channelDescription: 'Push notifications for messages, likes, and matches',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@mipmap/ic_launcher',
    );

    const details = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }

  /// Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.subscribeToTopic(topic);
    debugPrint('Subscribed to topic: $topic');
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    debugPrint('Unsubscribed from topic: $topic');
  }

  /// Save FCM token to Supabase (public method - call after login)
  /// Will retry up to 5 times if token is not yet available
  Future<void> saveTokenToSupabase() async {
    // If token is not yet available, wait for it
    if (_fcmToken == null) {
      debugPrint('FCM token not yet available, waiting...');

      // Try to get token if not initialized
      if (!_initialized && !kIsWeb) {
        await init();
      }

      // Wait for token with retry
      for (int i = 0; i < 5; i++) {
        if (_fcmToken != null) break;
        debugPrint('Waiting for FCM token... attempt ${i + 1}/5');
        await Future.delayed(const Duration(milliseconds: 500));

        // Try to get token again
        if (_fcmToken == null) {
          _fcmToken = await FirebaseMessaging.instance.getToken();
        }
      }

      if (_fcmToken == null) {
        debugPrint('Cannot save FCM token: token is still null after retries');
        return;
      }
    }

    await _saveTokenToSupabaseInternal(_fcmToken!);
  }

  /// Save FCM token to Supabase (internal)
  Future<void> _saveTokenToSupabaseInternal(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('Cannot save FCM token: user not authenticated');
        return;
      }

      debugPrint('Saving FCM token for user: $userId');
      debugPrint('Token: ${token.substring(0, 20)}...');

      await Supabase.instance.client
          .from('profiles')
          .update({
            'fcm_token': token,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('FCM token saved to Supabase successfully');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Alias for backward compatibility
  Future<void> _saveTokenToSupabase(String token) => _saveTokenToSupabaseInternal(token);

  /// Clear FCM token from Supabase (call on logout)
  Future<void> clearToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'fcm_token': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('FCM token cleared from Supabase');
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }
}

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific notification helper using browser Notification API
class WebNotificationHelper {
  /// Check if notifications are supported
  static bool get isSupported {
    try {
      return html.Notification.supported;
    } catch (e) {
      return false;
    }
  }

  /// Request notification permission
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;

    try {
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check current permission status
  static String get permissionStatus {
    if (!isSupported) return 'unsupported';
    try {
      return html.Notification.permission ?? 'default';
    } catch (e) {
      return 'unsupported';
    }
  }

  /// Show a notification
  static Future<void> show({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    if (!isSupported) return;
    if (permissionStatus != 'granted') return;

    try {
      final notification = html.Notification(
        title,
        body: body,
        icon: icon ?? '/icons/Icon-192.png',
        tag: tag,
      );

      // Handle notification click
      notification.onClick.listen((event) {
        notification.close();

        // Handle navigation based on notification type
        if (data != null) {
          final chatId = data['chatId'];
          final userId = data['userId'];
          final matchId = data['matchId'];

          if (chatId != null) {
            // Navigate to chat
            html.window.location.hash = '/chats/$chatId';
          } else if (userId != null) {
            // Navigate to profile
            html.window.location.hash = '/profile/$userId';
          } else if (matchId != null) {
            // Navigate to matches
            html.window.location.hash = '/chats';
          }
        }
      });

      // Auto close after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        notification.close();
      });
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Register service worker for push notifications
  static Future<void> registerServiceWorker() async {
    try {
      final navigator = html.window.navigator;
      final serviceWorker = navigator.serviceWorker;

      if (serviceWorker != null) {
        await serviceWorker.register('/flutter_service_worker.js');
        print('Service worker registered');
      }
    } catch (e) {
      print('Error registering service worker: $e');
    }
  }
}

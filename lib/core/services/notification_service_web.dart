// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// Web-specific notification helper using browser Notification API
class WebNotificationHelper {
  static html.ServiceWorkerRegistration? _swRegistration;

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
      if (permission == 'granted') {
        // Register service worker after permission granted
        await registerServiceWorker();
      }
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

  /// Show a notification (uses service worker if available for background support)
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
      // Try to show via service worker for background notification support
      if (_swRegistration != null && _swRegistration!.active != null) {
        await _showViaServiceWorker(
          title: title,
          body: body,
          icon: icon,
          tag: tag,
          data: data,
        );
        return;
      }

      // Fallback to standard notification
      _showStandardNotification(
        title: title,
        body: body,
        icon: icon,
        tag: tag,
        data: data,
      );
    } catch (e) {
      print('Error showing notification: $e');
    }
  }

  /// Show standard browser notification
  static void _showStandardNotification({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) {
    final notification = html.Notification(
      title,
      body: body,
      icon: icon ?? '/icons/Icon-192.png',
      tag: tag,
    );

    // Handle notification click
    notification.onClick.listen((event) {
      notification.close();
      _handleNotificationClick(data);
    });

    // Auto close after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      notification.close();
    });
  }

  /// Show notification via service worker (works in background)
  static Future<void> _showViaServiceWorker({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {
    try {
      if (_swRegistration != null && _swRegistration!.active != null) {
        // Send message to service worker to show notification
        _swRegistration!.active!.postMessage({
          'type': 'SHOW_NOTIFICATION',
          'title': title,
          'body': body,
          'icon': icon ?? '/icons/Icon-192.png',
          'tag': tag ?? 'fancy-${DateTime.now().millisecondsSinceEpoch}',
          'data': data,
        });
      }
    } catch (e) {
      print('Error showing notification via SW: $e');
      // Fallback to standard notification
      _showStandardNotification(
        title: title,
        body: body,
        icon: icon,
        tag: tag,
        data: data,
      );
    }
  }

  /// Handle notification click navigation
  static void _handleNotificationClick(Map<String, dynamic>? data) {
    if (data == null) return;

    final chatId = data['chatId'];
    final userId = data['userId'];
    final matchId = data['matchId'];

    if (chatId != null) {
      html.window.location.hash = '/chats/$chatId';
    } else if (userId != null) {
      html.window.location.hash = '/profile/$userId';
    } else if (matchId != null) {
      html.window.location.hash = '/chats';
    }

    // Bring the window to front (best effort)
    // Note: Modern browsers restrict window.focus() for security
  }

  /// Register service worker for push notifications
  static Future<void> registerServiceWorker() async {
    try {
      final navigator = html.window.navigator;
      final serviceWorker = navigator.serviceWorker;

      if (serviceWorker != null) {
        // Register our custom service worker for push notifications
        _swRegistration = await serviceWorker.register('/firebase-messaging-sw.js');
        print('Custom service worker registered');

        // Listen for messages from service worker
        serviceWorker.onMessage.listen((event) {
          final data = event.data;
          if (data != null && data is Map && data['type'] == 'NOTIFICATION_CLICK') {
            final notificationData = data['data'];
            if (notificationData is Map<String, dynamic>) {
              _handleNotificationClick(notificationData);
            }
          }
        });

        // Also register Flutter's service worker for caching
        await serviceWorker.register('/flutter_service_worker.js');
        print('Flutter service worker registered');
      }
    } catch (e) {
      print('Error registering service worker: $e');
    }
  }

  /// Check if service worker is registered
  static bool get hasServiceWorker => _swRegistration != null;
}

/// Stub for non-web platforms
class WebNotificationHelper {
  static bool get isSupported => false;

  static Future<bool> requestPermission() async => false;

  static String get permissionStatus => 'unsupported';

  static Future<void> show({
    required String title,
    required String body,
    String? icon,
    String? tag,
    Map<String, dynamic>? data,
  }) async {}

  static Future<void> registerServiceWorker() async {}
}

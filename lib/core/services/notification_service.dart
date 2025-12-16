import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Web-specific imports handled conditionally
import 'notification_service_web.dart' if (dart.library.io) 'notification_service_stub.dart';

/// Notification types
enum NotificationType {
  message,
  like,
  superLike,
  match,
  promotional,
}

/// Notification data model
class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String body;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final bool isRead;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.data,
    required this.createdAt,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'data': data,
        'createdAt': createdAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'],
      type: NotificationType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => NotificationType.message,
      ),
      title: json['title'],
      body: json['body'],
      imageUrl: json['imageUrl'],
      data: json['data'],
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      type: type,
      title: title,
      body: body,
      imageUrl: imageUrl,
      data: data,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification service for PWA notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final _notificationController = StreamController<AppNotification>.broadcast();
  Stream<AppNotification> get notificationStream => _notificationController.stream;

  bool _permissionGranted = false;
  bool get hasPermission => _permissionGranted;

  /// Initialize notification service
  Future<void> init() async {
    if (kIsWeb) {
      _permissionGranted = await WebNotificationHelper.requestPermission();
    }
  }

  /// Request notification permission
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      _permissionGranted = await WebNotificationHelper.requestPermission();
      return _permissionGranted;
    }
    return false;
  }

  /// Check if notifications are supported
  bool get isSupported => kIsWeb && WebNotificationHelper.isSupported;

  /// Show a notification
  Future<void> showNotification(AppNotification notification) async {
    // Always emit to stream for in-app handling (regardless of permission)
    _notificationController.add(notification);

    // Save to local storage
    await _saveNotification(notification);

    // Show browser notification only if permission granted
    if (_permissionGranted && kIsWeb) {
      await WebNotificationHelper.show(
        title: notification.title,
        body: notification.body,
        icon: notification.imageUrl ?? '/icons/Icon-192.png',
        tag: notification.id,
        data: notification.data,
      );
    }
  }

  /// Show message notification
  Future<void> showMessageNotification({
    required String senderName,
    required String message,
    String? avatarUrl,
    String? chatId,
  }) async {
    final notification = AppNotification(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.message,
      title: senderName,
      body: message,
      imageUrl: avatarUrl,
      data: {'chatId': chatId},
      createdAt: DateTime.now(),
    );
    await showNotification(notification);
  }

  /// Show like notification
  Future<void> showLikeNotification({
    required String userName,
    String? avatarUrl,
    String? userId,
    bool isSuperLike = false,
  }) async {
    final notification = AppNotification(
      id: 'like_${DateTime.now().millisecondsSinceEpoch}',
      type: isSuperLike ? NotificationType.superLike : NotificationType.like,
      title: isSuperLike ? 'Super Like!' : 'New Like!',
      body: isSuperLike
          ? '$userName super liked you!'
          : '$userName liked your profile!',
      imageUrl: avatarUrl,
      data: {'userId': userId},
      createdAt: DateTime.now(),
    );
    await showNotification(notification);
  }

  /// Show match notification
  Future<void> showMatchNotification({
    required String userName,
    String? avatarUrl,
    String? matchId,
  }) async {
    final notification = AppNotification(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.match,
      title: "It's a Match!",
      body: 'You and $userName liked each other!',
      imageUrl: avatarUrl,
      data: {'matchId': matchId},
      createdAt: DateTime.now(),
    );
    await showNotification(notification);
  }

  /// Show promotional notification
  Future<void> showPromotionalNotification({
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    final notification = AppNotification(
      id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
      type: NotificationType.promotional,
      title: title,
      body: body,
      imageUrl: imageUrl,
      createdAt: DateTime.now(),
    );
    await showNotification(notification);
  }

  /// Save notification to local storage
  Future<void> _saveNotification(AppNotification notification) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      notificationsJson.add(jsonEncode(notification.toJson()));

      // Keep only last 50 notifications
      if (notificationsJson.length > 50) {
        notificationsJson.removeRange(0, notificationsJson.length - 50);
      }

      await prefs.setStringList('notifications', notificationsJson);
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Get saved notifications
  Future<List<AppNotification>> getSavedNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      return notificationsJson
          .map((json) => AppNotification.fromJson(jsonDecode(json)))
          .toList()
          .reversed
          .toList();
    } catch (e) {
      print('Error loading notifications: $e');
      return [];
    }
  }

  /// Clear all notifications
  Future<void> clearNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('notifications');
  }

  /// Dispose
  void dispose() {
    _notificationController.close();
  }
}

/// Promotional notification service - shows activity-based notifications
class PromotionalNotificationService {
  static final PromotionalNotificationService _instance =
      PromotionalNotificationService._internal();
  factory PromotionalNotificationService() => _instance;
  PromotionalNotificationService._internal();

  Timer? _promotionalTimer;
  final _random = Random();

  /// Promotional messages for men (about women activity)
  final List<Map<String, String>> _menPromotions = [
    {
      'title': 'High Activity Now!',
      'body': 'Many girls are online right now. Don\'t miss your chance to find love!',
    },
    {
      'title': 'Someone is waiting for you',
      'body': 'Active girls nearby are looking for matches. Start swiping now!',
    },
    {
      'title': 'Popular time to match!',
      'body': 'Women activity is at its peak. Find your match today!',
    },
    {
      'title': 'New profiles near you',
      'body': 'Several new girls have joined recently. Check them out!',
    },
    {
      'title': 'Weekend vibes!',
      'body': 'More women are active on weekends. Perfect time to connect!',
    },
  ];

  /// Promotional messages for women (about men activity)
  final List<Map<String, String>> _womenPromotions = [
    {
      'title': 'High Activity Now!',
      'body': 'Many guys are online right now. Don\'t miss your chance to find love!',
    },
    {
      'title': 'Someone is waiting for you',
      'body': 'Active guys nearby are looking for matches. Start swiping now!',
    },
    {
      'title': 'Popular time to match!',
      'body': 'Men activity is at its peak. Find your match today!',
    },
    {
      'title': 'New profiles near you',
      'body': 'Several new guys have joined recently. Check them out!',
    },
    {
      'title': 'Weekend vibes!',
      'body': 'More men are active on weekends. Perfect time to connect!',
    },
  ];

  /// Start periodic promotional notifications
  void startPromotionalNotifications({
    required bool isMale,
    Duration interval = const Duration(hours: 4),
  }) {
    _promotionalTimer?.cancel();

    _promotionalTimer = Timer.periodic(interval, (_) {
      _showRandomPromotion(isMale: isMale);
    });

    // Show first notification after 30 minutes of app install
    Future.delayed(const Duration(minutes: 30), () {
      _showRandomPromotion(isMale: isMale);
    });
  }

  /// Show a random promotional notification
  Future<void> _showRandomPromotion({required bool isMale}) async {
    final notifications = NotificationService();
    if (!notifications.hasPermission) return;

    final promotions = isMale ? _menPromotions : _womenPromotions;
    final promo = promotions[_random.nextInt(promotions.length)];

    await notifications.showPromotionalNotification(
      title: promo['title']!,
      body: promo['body']!,
    );
  }

  /// Stop promotional notifications
  void stopPromotionalNotifications() {
    _promotionalTimer?.cancel();
    _promotionalTimer = null;
  }

  /// Show immediate promotional notification
  Future<void> showImmediatePromotion({required bool isMale}) async {
    await _showRandomPromotion(isMale: isMale);
  }
}

/// Notification service provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

/// Promotional notification service provider
final promotionalNotificationServiceProvider =
    Provider<PromotionalNotificationService>((ref) {
  return PromotionalNotificationService();
});

/// Unread notifications count provider
final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final notifications = await NotificationService().getSavedNotifications();
  return notifications.where((n) => !n.isRead).length;
});

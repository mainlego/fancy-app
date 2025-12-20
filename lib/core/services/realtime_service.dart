import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'notification_service.dart';

/// Realtime event types
enum RealtimeEventType {
  newMessage,
  newLike,
  newMatch,
  userOnline,
  userOffline,
  profileUpdate,
}

/// Realtime event model
class RealtimeEvent {
  final RealtimeEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  RealtimeEvent({
    required this.type,
    required this.data,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Realtime service for handling live updates
class RealtimeService {
  final SupabaseClient _client;
  final NotificationService _notificationService;
  final Map<String, RealtimeChannel> _channels = {};

  // Event callbacks
  void Function(RealtimeEvent)? onEvent;
  void Function(Map<String, dynamic>)? onNewMessage;
  void Function(Map<String, dynamic>)? onNewLike;
  void Function(Map<String, dynamic>)? onNewMatch;
  void Function(String, bool)? onUserPresenceChange;

  // Current chat ID to avoid notifications for open chat
  String? currentOpenChatId;

  RealtimeService(this._client) : _notificationService = NotificationService();

  /// Get current user ID
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Initialize all realtime subscriptions
  void initialize() {
    if (_currentUserId == null) {
      print('🔔 RealtimeService: No user ID, skipping initialization');
      return;
    }

    print('🔔 RealtimeService: Initializing for user $_currentUserId');

    _subscribeToMessages();
    _subscribeToLikes();
    _subscribeToMatches();
    _subscribeToPresence();
  }

  /// Subscribe to new messages for current user's chats
  void _subscribeToMessages() {
    final userId = _currentUserId;
    if (userId == null) return;

    print('🔔 Setting up messages realtime subscription for user: $userId');

    final channel = _client.channel('user_messages_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.messagesTable,
      callback: (payload) async {
        print('📨 Realtime: New message event received');
        final newMessage = payload.newRecord;
        final senderId = newMessage['sender_id'] as String?;
        final chatId = newMessage['chat_id'] as String?;
        final content = newMessage['content'] as String?;

        print('📨 Message from: $senderId, chat: $chatId');

        // Only process messages from other users and not in currently open chat
        if (senderId != null && senderId != userId && chatId != currentOpenChatId) {
          // Show notification (both browser notification and in-app stream)
          await _notificationService.showMessageNotification(
            senderName: 'New message',
            message: content ?? 'Sent you a message',
            chatId: chatId,
          );
        }

        onNewMessage?.call(newMessage);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.newMessage,
          data: newMessage,
        ));
      },
    );

    channel.subscribe((status, error) {
      print('🔔 Messages subscription status: $status');
      if (error != null) {
        print('❌ Messages subscription error: $error');
      }
    });

    _channels['messages'] = channel;
  }

  /// Subscribe to new likes received by current user
  void _subscribeToLikes() {
    final userId = _currentUserId;
    if (userId == null) return;

    print('🔔 Setting up likes realtime subscription for user: $userId');

    final channel = _client.channel('user_likes_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.likesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'to_user_id',
        value: userId,
      ),
      callback: (payload) async {
        print('❤️ Realtime: New like event received');
        final newLike = payload.newRecord;
        final fromUserId = newLike['from_user_id'] as String?;
        final isSuperLike = newLike['is_super_like'] as bool? ?? false;

        print('❤️ Like from: $fromUserId, super: $isSuperLike');

        // Show notification for new like
        if (fromUserId != null) {
          await _notificationService.showLikeNotification(
            userName: 'Someone',
            userId: fromUserId,
            isSuperLike: isSuperLike,
          );
        }

        onNewLike?.call(newLike);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.newLike,
          data: newLike,
        ));
      },
    );

    channel.subscribe((status, error) {
      print('🔔 Likes subscription status: $status');
      if (error != null) {
        print('❌ Likes subscription error: $error');
      }
    });

    _channels['likes'] = channel;
  }

  /// Subscribe to new matches for current user
  void _subscribeToMatches() {
    final userId = _currentUserId;
    if (userId == null) return;

    print('🔔 Setting up matches realtime subscription for user: $userId');

    final channel = _client.channel('user_matches_$userId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.matchesTable,
      callback: (payload) async {
        print('🎉 Realtime: New match event received');
        final newMatch = payload.newRecord;
        // Check if current user is part of this match
        final user1Id = newMatch['user1_id'] as String?;
        final user2Id = newMatch['user2_id'] as String?;

        print('🎉 Match between: $user1Id and $user2Id');

        if (user1Id == userId || user2Id == userId) {
          final otherUserId = user1Id == userId ? user2Id : user1Id;

          // Show match notification
          if (otherUserId != null) {
            await _notificationService.showMatchNotification(
              userName: 'Someone special',
              matchId: newMatch['id'] as String?,
            );
          }

          onNewMatch?.call(newMatch);
          onEvent?.call(RealtimeEvent(
            type: RealtimeEventType.newMatch,
            data: newMatch,
          ));
        }
      },
    );

    channel.subscribe((status, error) {
      print('🔔 Matches subscription status: $status');
      if (error != null) {
        print('❌ Matches subscription error: $error');
      }
    });

    _channels['matches'] = channel;
  }

  /// Subscribe to presence changes
  void _subscribeToPresence() {
    final userId = _currentUserId;
    if (userId == null) return;

    _channels['presence'] = _client
        .channel('online_users')
        .onPresenceSync((payload) {
          // Handle presence sync
        })
        .onPresenceJoin((payload) {
          final presences = payload.newPresences;
          for (final presence in presences) {
            final joinedUserId = presence.payload['user_id'] as String?;
            if (joinedUserId != null && joinedUserId != userId) {
              onUserPresenceChange?.call(joinedUserId, true);
              onEvent?.call(RealtimeEvent(
                type: RealtimeEventType.userOnline,
                data: {'user_id': joinedUserId},
              ));
            }
          }
        })
        .onPresenceLeave((payload) {
          final presences = payload.leftPresences;
          for (final presence in presences) {
            final leftUserId = presence.payload['user_id'] as String?;
            if (leftUserId != null && leftUserId != userId) {
              onUserPresenceChange?.call(leftUserId, false);
              onEvent?.call(RealtimeEvent(
                type: RealtimeEventType.userOffline,
                data: {'user_id': leftUserId},
              ));
            }
          }
        })
        .subscribe((status, error) async {
          if (status == RealtimeSubscribeStatus.subscribed) {
            // Track current user's presence
            await _channels['presence']?.track({
              'user_id': userId,
              'online_at': DateTime.now().toIso8601String(),
            });
          }
        });
  }

  /// Subscribe to messages in a specific chat
  RealtimeChannel subscribeToChat(String chatId, void Function(Map<String, dynamic>) onMessage) {
    final channel = _client
        .channel('chat_$chatId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: SupabaseConfig.messagesTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_id',
            value: chatId,
          ),
          callback: (payload) {
            onMessage(payload.newRecord);
          },
        )
        .subscribe();

    _channels['chat_$chatId'] = channel;
    return channel;
  }

  /// Unsubscribe from a specific chat
  void unsubscribeFromChat(String chatId) {
    _channels['chat_$chatId']?.unsubscribe();
    _channels.remove('chat_$chatId');
  }

  /// Subscribe to typing indicators in a chat
  RealtimeChannel subscribeToTyping(String chatId, void Function(String?, bool) onTyping) {
    final channel = _client
        .channel('typing_$chatId')
        .onBroadcast(
          event: 'typing',
          callback: (payload) {
            final typingUserId = payload['user_id'] as String?;
            final isTyping = payload['is_typing'] as bool? ?? false;
            onTyping(typingUserId, isTyping);
          },
        )
        .subscribe();

    _channels['typing_$chatId'] = channel;
    return channel;
  }

  /// Send typing indicator
  Future<void> sendTypingIndicator(String chatId, bool isTyping) async {
    final userId = _currentUserId;
    if (userId == null) return;

    final channel = _channels['typing_$chatId'];
    if (channel != null) {
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': userId,
          'is_typing': isTyping,
        },
      );
    }
  }

  /// Update user's online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userId = _currentUserId;
    if (userId == null) {
      print('🟢 Cannot set online status: no user ID');
      return;
    }

    print('🟢 Setting online status: $isOnline for user $userId');

    try {
      await _client.from(SupabaseConfig.profilesTable).update({
        'is_online': isOnline,
        'last_online': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      print('✅ Online status updated successfully');
    } catch (e) {
      print('❌ Error updating online status: $e');
    }
  }

  /// Dispose all subscriptions
  void dispose() {
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();
  }
}

/// Realtime service provider
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final client = Supabase.instance.client;
  final service = RealtimeService(client);

  // Initialize on creation
  service.initialize();

  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Stream of realtime events
final realtimeEventsProvider = StreamProvider<RealtimeEvent>((ref) {
  final service = ref.watch(realtimeServiceProvider);

  return Stream.multi((controller) {
    service.onEvent = (event) {
      controller.add(event);
    };
  });
});

/// Online users provider
final onlineUsersProvider = StateNotifierProvider<OnlineUsersNotifier, Set<String>>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return OnlineUsersNotifier(service);
});

class OnlineUsersNotifier extends StateNotifier<Set<String>> {
  final RealtimeService _service;

  OnlineUsersNotifier(this._service) : super({}) {
    _service.onUserPresenceChange = (userId, isOnline) {
      if (isOnline) {
        state = {...state, userId};
      } else {
        state = {...state}..remove(userId);
      }
    };
  }

  bool isUserOnline(String userId) => state.contains(userId);
}

/// Unread notifications count provider
final unreadNotificationsProvider = StateProvider<int>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  int count = 0;

  service.onNewLike = (_) {
    count++;
  };

  service.onNewMatch = (_) {
    count++;
  };

  return count;
});

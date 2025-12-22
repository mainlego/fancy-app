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
  chatDeleted,
  likeDeleted,
  matchDeleted,
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
  // Delete event callbacks
  void Function(Map<String, dynamic>)? onChatDeleted;
  void Function(Map<String, dynamic>)? onLikeDeleted;
  void Function(Map<String, dynamic>)? onMatchDeleted;

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
    _subscribeToDeleteEvents();
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
  /// Uses two separate subscriptions - one for user1_id and one for user2_id
  void _subscribeToMatches() {
    final userId = _currentUserId;
    if (userId == null) return;

    print('🔔 Setting up matches realtime subscription for user: $userId');

    // Subscribe to matches where current user is user1
    final channel1 = _client.channel('user_matches_as_user1_$userId');
    channel1.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.matchesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user1_id',
        value: userId,
      ),
      callback: (payload) async {
        print('🎉 Realtime: New match event received (as user1)');
        _handleNewMatch(payload.newRecord, userId);
      },
    );
    channel1.subscribe((status, error) {
      print('🔔 Matches (user1) subscription status: $status');
      if (error != null) {
        print('❌ Matches (user1) subscription error: $error');
      }
    });
    _channels['matches_user1'] = channel1;

    // Subscribe to matches where current user is user2
    final channel2 = _client.channel('user_matches_as_user2_$userId');
    channel2.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.matchesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user2_id',
        value: userId,
      ),
      callback: (payload) async {
        print('🎉 Realtime: New match event received (as user2)');
        _handleNewMatch(payload.newRecord, userId);
      },
    );
    channel2.subscribe((status, error) {
      print('🔔 Matches (user2) subscription status: $status');
      if (error != null) {
        print('❌ Matches (user2) subscription error: $error');
      }
    });
    _channels['matches_user2'] = channel2;
  }

  /// Handle new match event
  Future<void> _handleNewMatch(Map<String, dynamic> newMatch, String userId) async {
    final user1Id = newMatch['user1_id'] as String?;
    final user2Id = newMatch['user2_id'] as String?;

    print('🎉 Match between: $user1Id and $user2Id, current user: $userId');

    final otherUserId = user1Id == userId ? user2Id : user1Id;

    // Show match notification
    if (otherUserId != null) {
      await _notificationService.showMatchNotification(
        userName: 'Someone special',
        matchId: newMatch['id'] as String?,
      );
    }

    print('🎉 Calling onNewMatch callback: ${onNewMatch != null}');
    onNewMatch?.call(newMatch);
    onEvent?.call(RealtimeEvent(
      type: RealtimeEventType.newMatch,
      data: newMatch,
    ));
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

  /// Subscribe to DELETE events for chats, likes, and matches
  /// This ensures both users see updates when one deletes
  void _subscribeToDeleteEvents() {
    final userId = _currentUserId;
    if (userId == null) return;

    print('🔔 Setting up DELETE events subscription for user: $userId');

    // Subscribe to chat deletions where current user is a participant
    final chatDeleteChannel1 = _client.channel('chat_delete_p1_$userId');
    chatDeleteChannel1.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.chatsTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'participant1_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Chat deleted (as participant1)');
        final oldRecord = payload.oldRecord;
        print('🗑️ Deleted chat: $oldRecord');
        onChatDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.chatDeleted,
          data: oldRecord,
        ));
      },
    );
    chatDeleteChannel1.subscribe((status, error) {
      print('🔔 Chat delete (p1) subscription status: $status');
      if (error != null) print('❌ Error: $error');
    });
    _channels['chat_delete_p1'] = chatDeleteChannel1;

    final chatDeleteChannel2 = _client.channel('chat_delete_p2_$userId');
    chatDeleteChannel2.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.chatsTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'participant2_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Chat deleted (as participant2)');
        final oldRecord = payload.oldRecord;
        print('🗑️ Deleted chat: $oldRecord');
        onChatDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.chatDeleted,
          data: oldRecord,
        ));
      },
    );
    chatDeleteChannel2.subscribe((status, error) {
      print('🔔 Chat delete (p2) subscription status: $status');
      if (error != null) print('❌ Error: $error');
    });
    _channels['chat_delete_p2'] = chatDeleteChannel2;

    // Subscribe to like deletions (where current user sent the like)
    final likeDeleteChannel1 = _client.channel('like_delete_from_$userId');
    likeDeleteChannel1.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.likesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'from_user_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Like deleted (from current user)');
        final oldRecord = payload.oldRecord;
        onLikeDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.likeDeleted,
          data: oldRecord,
        ));
      },
    );
    likeDeleteChannel1.subscribe();
    _channels['like_delete_from'] = likeDeleteChannel1;

    // Subscribe to like deletions (where current user received the like)
    final likeDeleteChannel2 = _client.channel('like_delete_to_$userId');
    likeDeleteChannel2.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.likesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'to_user_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Like deleted (to current user)');
        final oldRecord = payload.oldRecord;
        onLikeDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.likeDeleted,
          data: oldRecord,
        ));
      },
    );
    likeDeleteChannel2.subscribe();
    _channels['like_delete_to'] = likeDeleteChannel2;

    // Subscribe to match deletions (user1)
    final matchDeleteChannel1 = _client.channel('match_delete_u1_$userId');
    matchDeleteChannel1.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.matchesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user1_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Match deleted (as user1)');
        final oldRecord = payload.oldRecord;
        onMatchDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.matchDeleted,
          data: oldRecord,
        ));
      },
    );
    matchDeleteChannel1.subscribe();
    _channels['match_delete_u1'] = matchDeleteChannel1;

    // Subscribe to match deletions (user2)
    final matchDeleteChannel2 = _client.channel('match_delete_u2_$userId');
    matchDeleteChannel2.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: SupabaseConfig.matchesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user2_id',
        value: userId,
      ),
      callback: (payload) {
        print('🗑️ Realtime: Match deleted (as user2)');
        final oldRecord = payload.oldRecord;
        onMatchDeleted?.call(oldRecord);
        onEvent?.call(RealtimeEvent(
          type: RealtimeEventType.matchDeleted,
          data: oldRecord,
        ));
      },
    );
    matchDeleteChannel2.subscribe();
    _channels['match_delete_u2'] = matchDeleteChannel2;

    print('🔔 DELETE events subscriptions setup complete');
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

/// Unread notifications count notifier
class UnreadNotificationsNotifier extends StateNotifier<int> {
  UnreadNotificationsNotifier() : super(0);

  void increment() {
    state++;
  }

  void reset() {
    state = 0;
  }
}

/// Unread notifications count provider
final unreadNotificationsProvider = StateNotifierProvider<UnreadNotificationsNotifier, int>((ref) {
  return UnreadNotificationsNotifier();
});

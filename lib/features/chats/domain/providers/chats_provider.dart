import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/chat_model.dart';

/// Chats tab enum
enum ChatsTab { chats, likes, favs }

/// Current tab provider
final chatsTabProvider = StateProvider<ChatsTab>((ref) => ChatsTab.chats);

/// User presence info (online status + last seen)
class UserPresenceInfo {
  final bool isOnline;
  final DateTime? lastSeen;

  const UserPresenceInfo({
    required this.isOnline,
    this.lastSeen,
  });
}

/// Provider for user's online status (fetches fresh from DB and subscribes to changes)
final userOnlineStatusProvider = StreamProvider.family<bool, String>((ref, userId) async* {
  final supabase = ref.watch(supabaseServiceProvider);

  // First, yield the current status
  try {
    final profile = await supabase.getProfile(userId);
    yield profile?['is_online'] as bool? ?? false;
  } catch (e) {
    print('Error getting initial user online status: $e');
    yield false;
  }

  // Then subscribe to changes
  final channel = Supabase.instance.client.channel('presence_$userId');

  channel.onPostgresChanges(
    event: PostgresChangeEvent.update,
    schema: 'public',
    table: 'profiles',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'id',
      value: userId,
    ),
    callback: (payload) {
      final newRecord = payload.newRecord;
      if (newRecord.containsKey('is_online')) {
        // Status changed - provider will automatically refresh on next read
        ref.invalidateSelf();
      }
    },
  );

  channel.subscribe();

  // Keep the stream alive
  ref.onDispose(() {
    channel.unsubscribe();
  });
});

/// Provider for user presence info (online status + last seen)
final userPresenceProvider = FutureProvider.family<UserPresenceInfo, String>((ref, userId) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final profile = await supabase.getProfile(userId);
    final isOnline = profile?['is_online'] as bool? ?? false;
    // DB column is last_online
    final lastOnlineStr = profile?['last_online'] as String?;
    final lastSeen = lastOnlineStr != null ? DateTime.tryParse(lastOnlineStr) : null;

    return UserPresenceInfo(isOnline: isOnline, lastSeen: lastSeen);
  } catch (e) {
    print('Error getting user presence: $e');
    return const UserPresenceInfo(isOnline: false);
  }
});

/// Chats from Supabase
final chatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final currentUserId = supabase.currentUser?.id;

  if (currentUserId == null) return [];

  try {
    final data = await supabase.getChats();
    return data.map((json) => ChatModel.fromSupabase(json, currentUserId)).toList();
  } catch (e) {
    print('Error loading chats: $e');
    return [];
  }
});

/// Chats state notifier for managing chats with realtime
class ChatsNotifier extends StateNotifier<AsyncValue<List<ChatModel>>> {
  final SupabaseService _supabase;
  final Ref _ref;
  RealtimeChannel? _subscription;
  bool _isFirstLoad = true;

  ChatsNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    print('💬 ChatsNotifier created');
    loadChats();
    _subscribeToChats();
  }

  /// Load chats - shows loading state only on first load
  Future<void> loadChats({bool silent = false}) async {
    final currentUserId = _supabase.currentUser?.id;
    if (currentUserId == null) {
      print('💬 No current user, returning empty chats');
      state = const AsyncValue.data([]);
      return;
    }

    print('💬 Loading chats for user: $currentUserId (silent: $silent)');

    // Only show loading state on first load, not on refresh
    if (_isFirstLoad && !silent) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _supabase.getChats();
      final chats = data.map((json) => ChatModel.fromSupabase(json, currentUserId)).toList();
      print('💬 Loaded ${chats.length} chats');
      state = AsyncValue.data(chats);
      _isFirstLoad = false;
    } catch (e, st) {
      print('❌ Error loading chats: $e');
      // Only set error state if we don't have existing data
      if (_isFirstLoad) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void _subscribeToChats() {
    final currentUserId = _supabase.currentUser?.id;
    if (currentUserId == null) return;

    print('💬 Setting up chats realtime subscription');

    // Subscribe to new messages to update chat list
    final channel = Supabase.instance.client.channel('chats_updates_$currentUserId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        print('💬 Chats: Received message update event');
        // Silent refresh - don't show loading state
        // Use unawaited pattern to avoid blocking callback
        Future.microtask(() => loadChats(silent: true));
      },
    );

    // Also subscribe to new matches/chats
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'matches',
      callback: (payload) {
        print('💬 Chats: New match received');
        // Reload chats when a new match is created
        Future.microtask(() => loadChats(silent: true));
      },
    );

    // Subscribe to chat updates (e.g., deletions)
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'chats',
      callback: (payload) {
        print('💬 Chats: Chat updated');
        Future.microtask(() => loadChats(silent: true));
      },
    );

    channel.subscribe((status, error) {
      print('💬 Chats subscription status: $status');
      if (error != null) {
        print('❌ Chats subscription error: $error');
      }
    });

    _subscription = channel;
  }

  /// Refresh chats without showing loading indicator
  Future<void> refresh() async {
    await loadChats(silent: true);
  }

  @override
  void dispose() {
    print('💬 ChatsNotifier disposing');
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Chats notifier provider
final chatsNotifierProvider = StateNotifierProvider<ChatsNotifier, AsyncValue<List<ChatModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ChatsNotifier(supabase, ref);
});

/// Likes from Supabase (users who liked current user)
final likesProvider = FutureProvider<List<LikeModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getLikers();
    return data.map((json) => LikeModel.fromSupabase(json)).toList();
  } catch (e) {
    print('Error loading likes: $e');
    return [];
  }
});

/// Likes state notifier with realtime subscription
class LikesNotifier extends StateNotifier<AsyncValue<List<LikeModel>>> {
  final SupabaseService _supabase;
  final Ref _ref;
  bool _isFirstLoad = true;
  RealtimeChannel? _subscription;

  LikesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadLikes();
    _subscribeToLikes();
  }

  void _subscribeToLikes() {
    final currentUserId = _supabase.currentUser?.id;
    if (currentUserId == null) return;

    print('❤️ LikesNotifier: Setting up realtime subscription');

    final channel = Supabase.instance.client.channel('likes_updates_$currentUserId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'likes',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'to_user_id',
        value: currentUserId,
      ),
      callback: (payload) {
        print('❤️ LikesNotifier: New like received');
        // Reload likes when a new like is received
        Future.microtask(() => loadLikes(silent: true));
      },
    );

    channel.subscribe((status, error) {
      print('❤️ Likes subscription status: $status');
      if (error != null) {
        print('❌ Likes subscription error: $error');
      }
    });

    _subscription = channel;
  }

  Future<void> loadLikes({bool silent = false}) async {
    // Only show loading on first load
    if (_isFirstLoad && !silent) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _supabase.getLikers();
      final likes = data.map((json) => LikeModel.fromSupabase(json)).toList();
      state = AsyncValue.data(likes);
      _isFirstLoad = false;
    } catch (e, st) {
      if (_isFirstLoad) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Refresh likes without showing loading indicator
  Future<void> refresh() async {
    await loadLikes(silent: true);
  }

  /// Like back a user (creates a match)
  Future<bool> likeBack(String userId) async {
    try {
      final isMatch = await _supabase.likeUser(userId);
      // Remove from likes list after action
      state.whenData((likes) {
        state = AsyncValue.data(likes.where((l) => l.userId != userId).toList());
      });
      return isMatch;
    } catch (e) {
      print('Error liking back user: $e');
      return false;
    }
  }

  /// Pass on a user who liked you
  Future<void> passUser(String userId) async {
    try {
      await _supabase.passUser(userId);
      // Remove from likes list after action
      state.whenData((likes) {
        state = AsyncValue.data(likes.where((l) => l.userId != userId).toList());
      });
    } catch (e) {
      print('Error passing user: $e');
    }
  }

  /// Delete a like (removes like, match, and chat)
  Future<void> deleteLike(String userId) async {
    try {
      await _supabase.deleteLike(userId);
      // Remove from likes list after action
      state.whenData((likes) {
        state = AsyncValue.data(likes.where((l) => l.userId != userId).toList());
      });
    } catch (e) {
      print('Error deleting like: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('❤️ LikesNotifier disposing');
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Likes notifier provider
final likesNotifierProvider = StateNotifierProvider<LikesNotifier, AsyncValue<List<LikeModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return LikesNotifier(supabase, ref);
});

/// Favorites from Supabase
final favoritesProvider = FutureProvider<List<FavoriteModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getFavorites();
    return data.map((json) => FavoriteModel.fromSupabase(json)).toList();
  } catch (e) {
    print('Error loading favorites: $e');
    return [];
  }
});

/// Favorites state notifier
class FavoritesNotifier extends StateNotifier<AsyncValue<List<FavoriteModel>>> {
  final SupabaseService _supabase;
  bool _isFirstLoad = true;

  FavoritesNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites({bool silent = false}) async {
    if (_isFirstLoad && !silent) {
      state = const AsyncValue.loading();
    }

    try {
      final data = await _supabase.getFavorites();
      final favorites = data.map((json) => FavoriteModel.fromSupabase(json)).toList();
      state = AsyncValue.data(favorites);
      _isFirstLoad = false;
    } catch (e, st) {
      if (_isFirstLoad) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<void> refresh() async {
    await loadFavorites(silent: true);
  }

  /// Add user to favorites
  Future<void> addToFavorites(String userId, {
    required String userName,
    String? userAvatarUrl,
    required int userAge,
    bool isOnline = false,
  }) async {
    try {
      await _supabase.addToFavorites(userId);
      // Add to local state
      state.whenData((favorites) {
        final newFavorite = FavoriteModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          oderId: userId,
          userName: userName,
          userAvatarUrl: userAvatarUrl,
          userAge: userAge,
          isOnline: isOnline,
          createdAt: DateTime.now(),
        );
        state = AsyncValue.data([newFavorite, ...favorites]);
      });
    } catch (e) {
      print('Error adding to favorites: $e');
    }
  }

  /// Remove user from favorites
  Future<void> removeFromFavorites(String userId) async {
    try {
      await _supabase.removeFromFavorites(userId);
      // Remove from local state
      state.whenData((favorites) {
        state = AsyncValue.data(favorites.where((f) => f.oderId != userId).toList());
      });
    } catch (e) {
      print('Error removing from favorites: $e');
    }
  }
}

/// Favorites notifier provider
final favoritesNotifierProvider = StateNotifierProvider<FavoritesNotifier, AsyncValue<List<FavoriteModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return FavoritesNotifier(supabase);
});

/// Unread chats count provider
final unreadChatsCountProvider = Provider<int>((ref) {
  final chatsAsync = ref.watch(chatsNotifierProvider);
  return chatsAsync.when(
    data: (chats) => chats.fold(0, (sum, chat) => sum + chat.unreadCount),
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// New likes count provider
final newLikesCountProvider = Provider<int>((ref) {
  final likesAsync = ref.watch(likesNotifierProvider);
  return likesAsync.when(
    data: (likes) => likes.where((like) => !like.isMatched).length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Single chat provider - loads chat by ID directly from database
final singleChatProvider = FutureProvider.family<ChatModel?, String>((ref, chatId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final currentUserId = supabase.currentUser?.id;

  if (currentUserId == null) return null;

  try {
    final data = await supabase.getChat(chatId);
    if (data == null) return null;
    return ChatModel.fromSupabase(data, currentUserId);
  } catch (e) {
    print('Error loading single chat: $e');
    return null;
  }
});

/// Chat by participant provider - finds chat with a specific user
/// Used when navigating to chat from match dialog (using user ID instead of chat ID)
final chatByParticipantProvider = FutureProvider.family<ChatModel?, String>((ref, participantId) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final currentUserId = supabase.currentUser?.id;

  if (currentUserId == null) return null;

  try {
    final data = await supabase.getChatByParticipant(participantId);
    if (data == null) return null;
    return ChatModel.fromSupabase(data, currentUserId);
  } catch (e) {
    print('Error loading chat by participant: $e');
    return null;
  }
});

/// Messages provider for a specific chat
final messagesProvider = FutureProvider.family<List<MessageModel>, String>((ref, chatId) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getMessages(chatId);
    return data.map((json) => MessageModel.fromSupabase(json)).toList();
  } catch (e) {
    print('Error loading messages: $e');
    return [];
  }
});

/// Messages state notifier for a specific chat
class MessagesNotifier extends StateNotifier<AsyncValue<List<MessageModel>>> {
  final SupabaseService _supabase;
  final String chatId;
  RealtimeChannel? _subscription;

  MessagesNotifier(this._supabase, this.chatId) : super(const AsyncValue.loading()) {
    print('📱 MessagesNotifier created for chat: $chatId');
    loadMessages();
    _subscribeToMessages();
  }

  Future<void> loadMessages() async {
    print('📱 Loading messages for chat: $chatId');
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getMessages(chatId);
      final messages = data.map((json) => MessageModel.fromSupabase(json)).toList();
      print('📱 Loaded ${messages.length} messages for chat: $chatId');
      state = AsyncValue.data(messages);
      // Mark messages as read
      await _supabase.markMessagesAsRead(chatId);
    } catch (e, st) {
      print('❌ Error loading messages: $e');
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    print('📱 Setting up message subscription for chat: $chatId');
    _subscription = _supabase.subscribeToMessages(chatId, (newMessage) {
      print('📨 MessagesNotifier received new message in chat $chatId: ${newMessage['id']}');
      // Add new message to the list
      state.whenData((messages) {
        final message = MessageModel.fromSupabase(newMessage);
        // Add to beginning since messages are ordered by created_at desc
        if (!messages.any((m) => m.id == message.id)) {
          print('📱 Adding new message to state: ${message.id}');
          state = AsyncValue.data([message, ...messages]);
        } else {
          print('📱 Message already exists in state: ${message.id}');
        }
        // Mark new messages as read immediately since user is viewing the chat
        _supabase.markMessagesAsRead(chatId);
      });
    });
  }

  Future<void> sendMessage(String content, {String? imageUrl}) async {
    try {
      final response = await _supabase.sendMessage(
        chatId: chatId,
        content: content,
        imageUrl: imageUrl,
      );
      // Add message immediately to local state for instant feedback
      final message = MessageModel.fromSupabase(response);
      state.whenData((messages) {
        // Check if message already exists (from realtime)
        if (!messages.any((m) => m.id == message.id)) {
          state = AsyncValue.data([message, ...messages]);
        }
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }

  /// Send media message (video, voice, etc.)
  Future<void> sendMediaMessage({
    required String mediaUrl,
    required MessageType type,
    String? content,
    int? durationMs,
  }) async {
    try {
      final response = await _supabase.sendMediaMessage(
        chatId: chatId,
        mediaUrl: mediaUrl,
        messageType: type.name,
        content: content,
        mediaDurationMs: durationMs,
      );
      // Add message immediately to local state for instant feedback
      final message = MessageModel.fromSupabase(response);
      state.whenData((messages) {
        // Check if message already exists (from realtime)
        if (!messages.any((m) => m.id == message.id)) {
          state = AsyncValue.data([message, ...messages]);
        }
      });
    } catch (e) {
      print('Error sending media message: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadMessages();
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId, {bool deleteForBoth = false}) async {
    try {
      await _supabase.deleteMessage(messageId, deleteForBoth: deleteForBoth);
      // Remove message from local state
      state.whenData((messages) {
        state = AsyncValue.data(messages.where((m) => m.id != messageId).toList());
      });
    } catch (e) {
      print('Error deleting message: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    print('📱 MessagesNotifier disposing for chat: $chatId');
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Messages notifier provider factory
final messagesNotifierProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, chatId) {
  final supabase = ref.watch(supabaseServiceProvider);
  return MessagesNotifier(supabase, chatId);
});


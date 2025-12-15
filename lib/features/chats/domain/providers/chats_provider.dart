import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/chat_model.dart';
import '../../../ai_profiles/domain/services/ai_chat_service.dart';
import '../../../ai_profiles/domain/providers/ai_profiles_provider.dart';

/// Chats tab enum
enum ChatsTab { chats, likes, favs }

/// Current tab provider
final chatsTabProvider = StateProvider<ChatsTab>((ref) => ChatsTab.chats);

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

  ChatsNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadChats();
    _subscribeToChats();
  }

  Future<void> loadChats() async {
    final currentUserId = _supabase.currentUser?.id;
    if (currentUserId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getChats();
      final chats = data.map((json) => ChatModel.fromSupabase(json, currentUserId)).toList();
      state = AsyncValue.data(chats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToChats() {
    final currentUserId = _supabase.currentUser?.id;
    if (currentUserId == null) return;

    // Subscribe to new messages to update chat list
    _subscription = Supabase.instance.client
        .channel('chats_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            // Refresh chats when a new message arrives
            loadChats();
          },
        )
        .subscribe();
  }

  Future<void> refresh() async {
    await loadChats();
  }

  @override
  void dispose() {
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

/// Likes state notifier
class LikesNotifier extends StateNotifier<AsyncValue<List<LikeModel>>> {
  final SupabaseService _supabase;

  LikesNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadLikes();
  }

  Future<void> loadLikes() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getLikers();
      final likes = data.map((json) => LikeModel.fromSupabase(json)).toList();
      state = AsyncValue.data(likes);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadLikes();
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
}

/// Likes notifier provider
final likesNotifierProvider = StateNotifierProvider<LikesNotifier, AsyncValue<List<LikeModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return LikesNotifier(supabase);
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

  FavoritesNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getFavorites();
      final favorites = data.map((json) => FavoriteModel.fromSupabase(json)).toList();
      state = AsyncValue.data(favorites);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadFavorites();
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
    loadMessages();
    _subscribeToMessages();
  }

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getMessages(chatId);
      final messages = data.map((json) => MessageModel.fromSupabase(json)).toList();
      state = AsyncValue.data(messages);
      // Mark messages as read
      await _supabase.markMessagesAsRead(chatId);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _subscribeToMessages() {
    _subscription = _supabase.subscribeToMessages(chatId, (newMessage) {
      // Add new message to the list
      state.whenData((messages) {
        final message = MessageModel.fromSupabase(newMessage);
        // Add to beginning since messages are ordered by created_at desc
        state = AsyncValue.data([message, ...messages]);
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
  }) async {
    try {
      final response = await _supabase.sendMediaMessage(
        chatId: chatId,
        mediaUrl: mediaUrl,
        messageType: type.name,
        content: content,
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

  @override
  void dispose() {
    _subscription?.unsubscribe();
    super.dispose();
  }
}

/// Messages notifier provider factory
final messagesNotifierProvider = StateNotifierProvider.family<MessagesNotifier, AsyncValue<List<MessageModel>>, String>((ref, chatId) {
  final supabase = ref.watch(supabaseServiceProvider);
  return MessagesNotifier(supabase, chatId);
});

/// AI Chats as ChatModel provider - converts AI chat history to ChatModel format
final aiChatsAsChatsProvider = FutureProvider<List<ChatModel>>((ref) async {
  final chatService = ref.watch(aiChatServiceProvider);
  final aiProfiles = ref.watch(aiProfilesProvider);

  // Get all AI chat IDs (profiles with chat history)
  final aiChatIds = await chatService.getAllAIChatIds();

  final aiChats = <ChatModel>[];

  for (final aiProfileId in aiChatIds) {
    // Find the AI profile
    final profile = aiProfiles.whenOrNull(
      data: (profiles) => profiles.where((p) => p.id == aiProfileId).firstOrNull,
    );

    if (profile == null) continue;

    // Get chat history
    final history = await chatService.getChatHistory(aiProfileId);
    if (history.isEmpty) continue;

    // Get last message
    final lastMsg = history.last;
    final lastMessage = MessageModel(
      id: lastMsg['id'] as String? ?? '',
      chatId: aiProfileId,
      senderId: lastMsg['is_from_ai'] == true ? aiProfileId : 'user',
      text: lastMsg['content'] as String? ?? '',
      createdAt: DateTime.tryParse(lastMsg['created_at'] as String? ?? '') ?? DateTime.now(),
    );

    aiChats.add(ChatModel(
      id: aiProfileId, // Use AI profile ID as chat ID
      participantId: aiProfileId,
      participantName: profile.name,
      participantAvatarUrl: profile.photos.isNotEmpty ? profile.photos.first : null,
      participantOnline: true, // AI profiles are always online
      participantVerified: profile.isVerified,
      lastMessage: lastMessage,
      unreadCount: 0, // AI chats don't track unread
      createdAt: DateTime.tryParse(history.first['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: lastMessage.createdAt,
    ));
  }

  // Sort by last message date (newest first)
  aiChats.sort((a, b) => (b.lastMessage?.createdAt ?? b.updatedAt).compareTo(a.lastMessage?.createdAt ?? a.updatedAt));

  return aiChats;
});

/// Combined chats provider - merges real chats with AI chats
final combinedChatsProvider = Provider<AsyncValue<List<ChatModel>>>((ref) {
  final realChatsAsync = ref.watch(chatsNotifierProvider);
  final aiChatsAsync = ref.watch(aiChatsAsChatsProvider);

  // If real chats are loading, show loading
  if (realChatsAsync.isLoading && aiChatsAsync.isLoading) {
    return const AsyncValue.loading();
  }

  // Get real chats (empty list if loading/error)
  final realChats = realChatsAsync.valueOrNull ?? [];

  // Get AI chats (empty list if loading/error)
  final aiChats = aiChatsAsync.valueOrNull ?? [];

  // Combine and sort by last message date
  final allChats = [...aiChats, ...realChats];
  allChats.sort((a, b) => (b.lastMessage?.createdAt ?? b.updatedAt).compareTo(a.lastMessage?.createdAt ?? a.updatedAt));

  return AsyncValue.data(allChats);
});

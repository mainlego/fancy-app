import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Current authenticated user provider
final currentUserProvider = StreamProvider<User?>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange.map((data) => data.session?.user);
});

/// Auth session provider
final authSessionProvider = Provider<Session?>((ref) {
  return Supabase.instance.client.auth.currentSession;
});

/// Supabase service for database operations
class SupabaseService {
  final SupabaseClient _client;

  SupabaseService(this._client);

  // ===================
  // AUTH OPERATIONS
  // ===================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
  }

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with OAuth (Google, Apple, etc.)
  Future<bool> signInWithOAuth(OAuthProvider provider) async {
    return await _client.auth.signInWithOAuth(provider);
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user
  User? get currentUser => _client.auth.currentUser;

  /// Get current session
  Session? get currentSession => _client.auth.currentSession;

  /// Reset password
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  // ===================
  // PROFILE OPERATIONS
  // ===================

  /// Get user profile by ID
  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final response = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .eq('id', userId)
        .maybeSingle();
    return response;
  }

  /// Get current user's profile
  Future<Map<String, dynamic>?> getCurrentProfile() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    return await getProfile(userId);
  }

  /// Update profile
  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    await _client
        .from(SupabaseConfig.profilesTable)
        .update(data)
        .eq('id', userId);
  }

  /// Create profile
  Future<void> createProfile(Map<String, dynamic> data) async {
    await _client.from(SupabaseConfig.profilesTable).insert(data);
  }

  /// Get profiles for discovery (excluding current user and blocked users)
  Future<List<Map<String, dynamic>>> getDiscoveryProfiles({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    String? gender,
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    // Build query - note: filters applied conditionally using or/and if needed
    final response = await _client
        .from(SupabaseConfig.profilesTable)
        .select()
        .neq('id', userId)
        .limit(limit)
        .range(offset, offset + limit - 1);

    // Filter results in memory for now (age, gender filters)
    // TODO: Move to RPC function for better performance
    var profiles = List<Map<String, dynamic>>.from(response);

    if (minAge != null || maxAge != null) {
      profiles = profiles.where((p) {
        final birthDateStr = p['birth_date'] as String?;
        if (birthDateStr == null) return true;
        final birthDate = DateTime.tryParse(birthDateStr);
        if (birthDate == null) return true;
        final age = DateTime.now().difference(birthDate).inDays ~/ 365;
        if (minAge != null && age < minAge) return false;
        if (maxAge != null && age > maxAge) return false;
        return true;
      }).toList();
    }

    if (gender != null) {
      profiles = profiles.where((p) => p['gender'] == gender).toList();
    }

    return profiles;
  }

  // ===================
  // LIKES OPERATIONS
  // ===================

  /// Like a user
  Future<bool> likeUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    await _client.from(SupabaseConfig.likesTable).insert({
      'from_user_id': userId,
      'to_user_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Check for mutual like (match)
    final mutualLike = await _client
        .from(SupabaseConfig.likesTable)
        .select()
        .eq('from_user_id', targetUserId)
        .eq('to_user_id', userId)
        .maybeSingle();

    if (mutualLike != null) {
      // Create a match!
      await _createMatch(userId, targetUserId);
      return true; // Return true if it's a match
    }
    return false;
  }

  /// Pass on a user (dislike)
  Future<void> passUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.likesTable).insert({
      'from_user_id': userId,
      'to_user_id': targetUserId,
      'is_pass': true,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get users who liked current user
  Future<List<Map<String, dynamic>>> getLikers() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.likesTable)
        .select('from_user_id, is_super_like, created_at, profiles!from_user_id(*)')
        .eq('to_user_id', userId)
        .eq('is_pass', false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===================
  // MATCHES OPERATIONS
  // ===================

  /// Create a match between two users
  Future<void> _createMatch(String userId1, String userId2) async {
    await _client.from(SupabaseConfig.matchesTable).insert({
      'user1_id': userId1,
      'user2_id': userId2,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Create a chat for the match
    await _createChat(userId1, userId2);
  }

  /// Get all matches for current user
  Future<List<Map<String, dynamic>>> getMatches() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.matchesTable)
        .select('*, profiles!user1_id(*), profiles!user2_id(*)')
        .or('user1_id.eq.$userId,user2_id.eq.$userId');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Unmatch a user
  Future<void> unmatch(String matchId) async {
    await _client.from(SupabaseConfig.matchesTable).delete().eq('id', matchId);
  }

  // ===================
  // CHAT OPERATIONS
  // ===================

  /// Create a chat between two users
  Future<String> _createChat(String userId1, String userId2) async {
    final response = await _client.from(SupabaseConfig.chatsTable).insert({
      'participant1_id': userId1,
      'participant2_id': userId2,
      'created_at': DateTime.now().toIso8601String(),
    }).select('id').single();

    return response['id'];
  }

  /// Get all chats for current user
  Future<List<Map<String, dynamic>>> getChats() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from(SupabaseConfig.chatsTable)
          .select()
          .or('participant1_id.eq.$userId,participant2_id.eq.$userId')
          .order('updated_at', ascending: false);

      // Load participant profiles separately
      final chats = List<Map<String, dynamic>>.from(response);
      for (var chat in chats) {
        final participant1Id = chat['participant1_id'] as String?;
        final participant2Id = chat['participant2_id'] as String?;

        if (participant1Id != null) {
          final profile1 = await getProfile(participant1Id);
          chat['participant1'] = profile1;
        }
        if (participant2Id != null) {
          final profile2 = await getProfile(participant2Id);
          chat['participant2'] = profile2;
        }
      }

      return chats;
    } catch (e) {
      print('Error getting chats: $e');
      return [];
    }
  }

  /// Get chat by ID
  Future<Map<String, dynamic>?> getChat(String chatId) async {
    try {
      final response = await _client
          .from(SupabaseConfig.chatsTable)
          .select()
          .eq('id', chatId)
          .maybeSingle();

      if (response == null) return null;

      // Load participant profiles separately
      final participant1Id = response['participant1_id'] as String?;
      final participant2Id = response['participant2_id'] as String?;

      if (participant1Id != null) {
        final profile1 = await getProfile(participant1Id);
        response['participant1'] = profile1;
      }
      if (participant2Id != null) {
        final profile2 = await getProfile(participant2Id);
        response['participant2'] = profile2;
      }

      return response;
    } catch (e) {
      print('Error getting chat: $e');
      return null;
    }
  }

  /// Get messages for a chat
  Future<List<Map<String, dynamic>>> getMessages(String chatId, {int limit = 50, int offset = 0}) async {
    final response = await _client
        .from(SupabaseConfig.messagesTable)
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Send a message
  Future<Map<String, dynamic>> sendMessage({
    required String chatId,
    required String content,
    String? imageUrl,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from(SupabaseConfig.messagesTable).insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': content,
      'image_url': imageUrl,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // Update chat's updated_at
    await _client
        .from(SupabaseConfig.chatsTable)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    return response;
  }

  /// Subscribe to new messages in a chat
  RealtimeChannel subscribeToMessages(String chatId, void Function(Map<String, dynamic>) onMessage) {
    return _client
        .channel('messages:$chatId')
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
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String chatId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.messagesTable)
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', userId);
  }

  // ===================
  // BLOCKED USERS
  // ===================

  /// Block a user
  Future<void> blockUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.blockedUsersTable).insert({
      'blocker_id': userId,
      'blocked_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unblock a user
  Future<void> unblockUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.blockedUsersTable)
        .delete()
        .eq('blocker_id', userId)
        .eq('blocked_id', targetUserId);
  }

  /// Get blocked users
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.blockedUsersTable)
        .select('*, profiles!blocked_id(*)')
        .eq('blocker_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===================
  // FAVORITES
  // ===================

  /// Add user to favorites
  Future<void> addToFavorites(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from('favorites').insert({
      'user_id': userId,
      'favorite_user_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove user from favorites
  Future<void> removeFromFavorites(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from('favorites')
        .delete()
        .eq('user_id', userId)
        .eq('favorite_user_id', targetUserId);
  }

  /// Get favorites list
  Future<List<Map<String, dynamic>>> getFavorites() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('favorites')
        .select('*, profiles!favorite_user_id(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  // ===================
  // SETTINGS
  // ===================

  /// Get user settings
  Future<Map<String, dynamic>?> getSettings() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(SupabaseConfig.settingsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Update settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.settingsTable)
        .upsert(
          {
            'user_id': userId,
            ...settings,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id',
        );
  }

  // ===================
  // STORAGE
  // ===================

  /// Upload avatar image
  Future<String> uploadAvatar(String fileName, List<int> bytes) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final path = '$userId/$fileName';
    await _client.storage.from(SupabaseConfig.avatarsBucket).uploadBinary(path, bytes as dynamic);

    return _client.storage.from(SupabaseConfig.avatarsBucket).getPublicUrl(path);
  }

  /// Upload photo
  Future<String> uploadPhoto(String fileName, List<int> bytes) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final path = '$userId/$fileName';
    await _client.storage.from(SupabaseConfig.photosBucket).uploadBinary(path, bytes as dynamic);

    return _client.storage.from(SupabaseConfig.photosBucket).getPublicUrl(path);
  }

  /// Delete photo
  Future<void> deletePhoto(String path) async {
    await _client.storage.from(SupabaseConfig.photosBucket).remove([path]);
  }

  // ===================
  // FILTERS OPERATIONS
  // ===================

  /// Get user filters
  Future<Map<String, dynamic>?> getFilters() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(SupabaseConfig.filtersTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Save/update user filters
  Future<void> saveFilters(Map<String, dynamic> filters) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.filtersTable).upsert(
      {
        'user_id': userId,
        'filters': filters,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  // ===================
  // SUBSCRIPTION OPERATIONS
  // ===================

  /// Get user subscription
  Future<Map<String, dynamic>?> getSubscription() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(SupabaseConfig.subscriptionsTable)
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  /// Create or update subscription
  Future<void> saveSubscription({
    required String planType,
    required DateTime startDate,
    required DateTime endDate,
    bool isActive = true,
    String? transactionId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.subscriptionsTable).upsert(
      {
        'user_id': userId,
        'plan_type': planType,
        'start_date': startDate.toIso8601String(),
        'end_date': endDate.toIso8601String(),
        'is_active': isActive,
        'transaction_id': transactionId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );

    // Update profile is_premium field
    await updateProfile(userId, {'is_premium': isActive});
  }

  /// Cancel subscription
  Future<void> cancelSubscription() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.subscriptionsTable)
        .update({
          'is_active': false,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);

    // Update profile is_premium field
    await updateProfile(userId, {'is_premium': false});
  }

  // ===================
  // AI PROFILES
  // ===================

  /// Get all active AI profiles (not expired)
  Future<List<Map<String, dynamic>>> getAIProfiles() async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(SupabaseConfig.aiProfilesTable)
        .select()
        .eq('is_ai', true)
        .gte('expires_at', now)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get AI profiles for admin (all profiles including expired)
  Future<List<Map<String, dynamic>>> getAIProfilesAdmin() async {
    final response = await _client
        .from(SupabaseConfig.aiProfilesTable)
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Create AI profile
  Future<String> createAIProfile(Map<String, dynamic> profile) async {
    final response = await _client
        .from(SupabaseConfig.aiProfilesTable)
        .insert({
          ...profile,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();

    return response['id'] as String;
  }

  /// Update AI profile
  Future<void> updateAIProfile(String profileId, Map<String, dynamic> updates) async {
    await _client
        .from(SupabaseConfig.aiProfilesTable)
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', profileId);
  }

  /// Delete AI profile
  Future<void> deleteAIProfile(String profileId) async {
    await _client
        .from(SupabaseConfig.aiProfilesTable)
        .delete()
        .eq('id', profileId);
  }

  /// Delete expired AI profiles (cleanup)
  Future<int> deleteExpiredAIProfiles() async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(SupabaseConfig.aiProfilesTable)
        .delete()
        .lt('expires_at', now)
        .select('id');

    return (response as List).length;
  }

  /// Increment AI profile message count
  Future<void> incrementAIMessageCount(String profileId) async {
    await _client.rpc('increment_ai_message_count', params: {
      'profile_id': profileId,
    });
  }

  // ===================
  // USER REPORTS & BANS (AI-triggered)
  // ===================

  /// Report user (can be triggered by AI)
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? reportedByAiProfileId,
    String? reportedByUserId,
    String? details,
  }) async {
    await _client.from(SupabaseConfig.userReportsTable).insert({
      'reported_user_id': reportedUserId,
      'reported_by_user_id': reportedByUserId,
      'reported_by_ai_profile_id': reportedByAiProfileId,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ban user (can be triggered by AI after multiple offenses)
  Future<void> banUser({
    required String userId,
    required String reason,
    String? bannedByAiProfileId,
    Duration? duration,
  }) async {
    final now = DateTime.now();
    final expiresAt = duration != null ? now.add(duration) : null;

    await _client.from(SupabaseConfig.userBansTable).insert({
      'user_id': userId,
      'reason': reason,
      'banned_by_ai_profile_id': bannedByAiProfileId,
      'expires_at': expiresAt?.toIso8601String(),
      'is_permanent': duration == null,
      'created_at': now.toIso8601String(),
    });

    // Also update user profile to mark as banned
    await _client
        .from(SupabaseConfig.profilesTable)
        .update({
          'is_banned': true,
          'ban_reason': reason,
          'ban_expires_at': expiresAt?.toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Check if user is banned
  Future<bool> isUserBanned(String userId) async {
    final now = DateTime.now().toIso8601String();
    final response = await _client
        .from(SupabaseConfig.userBansTable)
        .select('id')
        .eq('user_id', userId)
        .or('is_permanent.eq.true,expires_at.gte.$now')
        .maybeSingle();

    return response != null;
  }

  /// Get user reports (for admin)
  Future<List<Map<String, dynamic>>> getUserReports({String? status}) async {
    var query = _client
        .from(SupabaseConfig.userReportsTable)
        .select('*, reported_user:profiles!reported_user_id(name, avatar_url)');

    if (status != null) {
      query = query.eq('status', status);
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Update report status (for admin)
  Future<void> updateReportStatus(String reportId, String status) async {
    await _client
        .from(SupabaseConfig.userReportsTable)
        .update({
          'status': status,
          'reviewed_at': DateTime.now().toIso8601String(),
        })
        .eq('id', reportId);
  }

  // ===================
  // AI CHATS
  // ===================

  /// Get or create AI chat
  Future<Map<String, dynamic>> getOrCreateAIChat(String aiProfileId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Check if chat exists
    final existing = await _client
        .from(SupabaseConfig.aiChatsTable)
        .select()
        .eq('user_id', userId)
        .eq('ai_profile_id', aiProfileId)
        .maybeSingle();

    if (existing != null) return existing;

    // Create new chat
    final response = await _client
        .from(SupabaseConfig.aiChatsTable)
        .insert({
          'user_id': userId,
          'ai_profile_id': aiProfileId,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    return response;
  }

  /// Get AI chat messages
  Future<List<Map<String, dynamic>>> getAIChatMessages(String chatId) async {
    final response = await _client
        .from(SupabaseConfig.aiMessagesTable)
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Save AI chat message
  Future<void> saveAIChatMessage({
    required String chatId,
    required String aiProfileId,
    required String content,
    required bool isFromAI,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.aiMessagesTable).insert({
      'chat_id': chatId,
      'ai_profile_id': aiProfileId,
      'user_id': userId,
      'content': content,
      'is_from_ai': isFromAI,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Update chat last message
    await _client
        .from(SupabaseConfig.aiChatsTable)
        .update({
          'last_message': content,
          'last_message_at': DateTime.now().toIso8601String(),
        })
        .eq('id', chatId);
  }

  /// Get user's AI chats
  Future<List<Map<String, dynamic>>> getUserAIChats() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.aiChatsTable)
        .select('*, ai_profile:${SupabaseConfig.aiProfilesTable}(*)')
        .eq('user_id', userId)
        .order('last_message_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }
}

/// Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

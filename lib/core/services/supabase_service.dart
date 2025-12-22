import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../data/profile_data.dart';
import '../../features/referrals/domain/models/referral_model.dart';
import 'debug_logger.dart';

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

  /// Get the Supabase client for direct access (e.g., for support requests)
  SupabaseClient get client => _client;

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

  /// Update FCM token for push notifications
  Future<void> updateFcmToken(String token) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.profilesTable)
        .update({
          'fcm_token': token,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Clear FCM token (on logout)
  Future<void> clearFcmToken() async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.profilesTable)
        .update({
          'fcm_token': null,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', userId);
  }

  /// Get FCM token for a user (for sending notifications)
  Future<String?> getUserFcmToken(String userId) async {
    final response = await _client
        .from(SupabaseConfig.profilesTable)
        .select('fcm_token')
        .eq('id', userId)
        .maybeSingle();

    return response?['fcm_token'] as String?;
  }

  /// Create profile
  Future<void> createProfile(Map<String, dynamic> data) async {
    await _client.from(SupabaseConfig.profilesTable).insert(data);
  }

  /// Create or update profile (upsert) - handles existing profile case
  Future<void> createOrUpdateProfile(Map<String, dynamic> data) async {
    try {
      await _client.from(SupabaseConfig.profilesTable).upsert(data);
    } catch (e) {
      print('SupabaseService.createOrUpdateProfile ERROR: $e');
      print('Data being sent: $data');
      rethrow;
    }
  }

  /// Get profiles for discovery (excluding current user, blocked users, and already interacted)
  /// Filters bidirectionally: shows profiles that match user's preferences AND are looking for user's type
  Future<List<Map<String, dynamic>>> getDiscoveryProfiles({
    int? minAge,
    int? maxAge,
    int? maxDistance,
    List<String>? lookingFor,  // Profile types the user wants to see (e.g., ['woman', 'man'])
    String? myProfileType,     // Current user's profile type (for bidirectional matching)
    int limit = 20,
    int offset = 0,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) {
      logWarn('getDiscoveryProfiles: No current user', tag: 'Discovery');
      return [];
    }

    logInfo('getDiscoveryProfiles: Starting for user $userId', tag: 'Discovery');
    logInfo('getDiscoveryProfiles: Params - lookingFor=$lookingFor, myProfileType=$myProfileType, minAge=$minAge, maxAge=$maxAge, maxDistance=$maxDistance', tag: 'Discovery');

    try {
      // Get IDs of users we've already interacted with (liked/passed)
      final interactedResponse = await _client
          .from(SupabaseConfig.likesTable)
          .select('to_user_id')
          .eq('from_user_id', userId);

      final interactedIds = (interactedResponse as List)
          .map((e) => e['to_user_id'] as String)
          .toSet();
      logDebug('getDiscoveryProfiles: Excluded ${interactedIds.length} already interacted users', tag: 'Discovery');

      // Get IDs of blocked users (both directions)
      final blockedResponse = await _client
          .from(SupabaseConfig.blockedUsersTable)
          .select('blocked_id, blocker_id')
          .or('blocker_id.eq.$userId,blocked_id.eq.$userId');

      final blockedIds = <String>{};
      for (final block in blockedResponse as List) {
        final blockerId = block['blocker_id'] as String?;
        final blockedId = block['blocked_id'] as String?;
        if (blockerId != null && blockerId != userId) blockedIds.add(blockerId);
        if (blockedId != null && blockedId != userId) blockedIds.add(blockedId);
      }
      logDebug('getDiscoveryProfiles: Excluded ${blockedIds.length} blocked users', tag: 'Discovery');

      // Get IDs of hidden users (only users I've hidden)
      final hiddenResponse = await _client
          .from(SupabaseConfig.hiddenUsersTable)
          .select('hidden_id')
          .eq('hider_id', userId);

      final hiddenIds = (hiddenResponse as List)
          .map((e) => e['hidden_id'] as String)
          .toSet();
      logDebug('getDiscoveryProfiles: Excluded ${hiddenIds.length} hidden users', tag: 'Discovery');

      // Combine all IDs to exclude
      final excludeIds = {...interactedIds, ...blockedIds, ...hiddenIds, userId};
      logDebug('getDiscoveryProfiles: Total excluded IDs: ${excludeIds.length}', tag: 'Discovery');

      // Build query for profiles with gender filter on server side
      logInfo('getDiscoveryProfiles: Building query with lookingFor=$lookingFor, myProfileType=$myProfileType', tag: 'Discovery');

      PostgrestFilterBuilder query = _client
          .from(SupabaseConfig.profilesTable)
          .select()
          .eq('is_active', true); // Only show active profiles

      // Apply filter: show profiles whose profile_type matches what I'm looking for
      if (lookingFor != null && lookingFor.isNotEmpty) {
        // Filter by profile_type IN (lookingFor list)
        logDebug('getDiscoveryProfiles: Applying profile_type filter: $lookingFor', tag: 'Discovery');
        query = query.inFilter('profile_type', lookingFor);
      } else {
        logDebug('getDiscoveryProfiles: No lookingFor filter, showing all profile types', tag: 'Discovery');
      }

      // Note: We apply bidirectional filter client-side to handle profiles with empty looking_for

      final response = await query
          .limit((limit + excludeIds.length) * 2) // Get extra to account for filtering
          .order('last_online', ascending: false);

      logInfo('getDiscoveryProfiles: Raw query returned ${(response as List).length} profiles', tag: 'Discovery');

      // Log all raw profiles before any filtering
      int rawIndex = 0;
      for (final p in response) {
        final pId = p['id'] as String?;
        final pName = p['name'] as String? ?? 'Unknown';
        final pType = p['profile_type'] as String?;
        final pActive = p['is_active'] as bool?;
        final pLookingFor = p['looking_for'] as List<dynamic>?;
        logDebug('getDiscoveryProfiles: Raw[$rawIndex] id=$pId, name=$pName, type=$pType, active=$pActive, lookingFor=$pLookingFor', tag: 'Discovery');
        rawIndex++;
      }

      // Filter out excluded users and apply bidirectional matching
      var profiles = (response as List)
          .where((p) {
            final pId = p['id'] as String?;
            final isExcluded = excludeIds.contains(pId);
            if (isExcluded) {
              final pName = p['name'] as String? ?? 'Unknown';
              logDebug('getDiscoveryProfiles: EXCLUDED "$pName" (id=$pId) - already interacted/blocked/hidden', tag: 'Discovery');
            }
            return !isExcluded;
          })
          .where((p) {
            // Bidirectional filter: only show profiles who are looking for my profile type
            // Skip this check if my profile type is not set
            if (myProfileType == null || myProfileType.isEmpty) return true;

            // Get the profile's looking_for array
            final theirLookingFor = (p['looking_for'] as List<dynamic>?)?.cast<String>() ?? [];
            final pName = p['name'] as String? ?? 'Unknown';
            final pId = p['id'] as String?;

            // If their looking_for is empty, assume they're looking for everyone (haven't set preference)
            if (theirLookingFor.isEmpty) {
              logDebug('getDiscoveryProfiles: "$pName" (id=$pId) has empty looking_for, PASSING bidirectional check', tag: 'Discovery');
              return true;
            }

            // Check if my profile type is in their looking_for list
            final passes = theirLookingFor.contains(myProfileType);
            if (!passes) {
              logDebug('getDiscoveryProfiles: EXCLUDED "$pName" (id=$pId) - their looking_for=$theirLookingFor does NOT contain myType=$myProfileType', tag: 'Discovery');
            } else {
              logDebug('getDiscoveryProfiles: "$pName" (id=$pId) PASSES bidirectional check - their looking_for=$theirLookingFor contains myType=$myProfileType', tag: 'Discovery');
            }
            return passes;
          })
          .take(limit)
          .map((p) => Map<String, dynamic>.from(p))
          .toList();

      logInfo('getDiscoveryProfiles: After filtering: ${profiles.length} profiles remain', tag: 'Discovery');

      // Apply age filter
      if (minAge != null || maxAge != null) {
        profiles = profiles.where((p) {
          final birthDateStr = p['birth_date'] as String?;
          if (birthDateStr == null) return true; // Include profiles without birthdate
          final birthDate = DateTime.tryParse(birthDateStr);
          if (birthDate == null) return true;
          final age = DateTime.now().difference(birthDate).inDays ~/ 365;
          if (minAge != null && age < minAge) return false;
          if (maxAge != null && age > maxAge) return false;
          return true;
        }).toList();
      }

      // Get current user's location for distance calculation
      final currentUserProfile = await getProfile(userId);
      final myLat = currentUserProfile?['latitude'] as double?;
      final myLon = currentUserProfile?['longitude'] as double?;

      logInfo('getDiscoveryProfiles: My location: lat=$myLat, lon=$myLon, maxDistance=$maxDistance', tag: 'Discovery');

      // Calculate distance for each profile
      if (myLat != null && myLon != null) {
        int profilesWithLocation = 0;
        int profilesWithoutLocation = 0;
        for (var profile in profiles) {
          final theirLat = profile['latitude'] as double?;
          final theirLon = profile['longitude'] as double?;
          final profileName = profile['name'] as String? ?? 'Unknown';

          if (theirLat != null && theirLon != null) {
            final distance = _calculateDistance(myLat, myLon, theirLat, theirLon);
            profile['distance_km'] = distance.round();
            profilesWithLocation++;
            logDebug('getDiscoveryProfiles: Profile "$profileName" at ($theirLat, $theirLon), distance=${distance.round()}km', tag: 'Discovery');
          } else {
            profilesWithoutLocation++;
            logDebug('getDiscoveryProfiles: Profile "$profileName" has no location (lat=$theirLat, lon=$theirLon)', tag: 'Discovery');
          }
        }
        logInfo('getDiscoveryProfiles: Calculated distance for $profilesWithLocation/${profiles.length} profiles ($profilesWithoutLocation without location)', tag: 'Discovery');

        // Apply distance filter if specified
        if (maxDistance != null) {
          final beforeCount = profiles.length;
          profiles = profiles.where((p) {
            final distance = p['distance_km'] as int?;
            if (distance == null) return true; // Include profiles without location
            return distance <= maxDistance;
          }).toList();
          logDebug('getDiscoveryProfiles: Distance filter ($maxDistance km): $beforeCount -> ${profiles.length} profiles', tag: 'Discovery');
        }

        // Sort by distance (closest first)
        profiles.sort((a, b) {
          final distA = a['distance_km'] as int? ?? 999999;
          final distB = b['distance_km'] as int? ?? 999999;
          return distA.compareTo(distB);
        });
      } else {
        logWarn('getDiscoveryProfiles: User has no location data, skipping distance calculation', tag: 'Discovery');
      }

      logInfo('getDiscoveryProfiles: Returning ${profiles.length} profiles', tag: 'Discovery');
      return profiles;
    } catch (e) {
      logError('getDiscoveryProfiles: Error - $e', tag: 'Discovery');

      // Check if error is about missing is_active column
      final errorStr = e.toString().toLowerCase();
      final isColumnMissing = errorStr.contains('is_active') && errorStr.contains('does not exist');

      if (isColumnMissing) {
        logWarn('getDiscoveryProfiles: is_active column missing, using fallback WITHOUT is_active filter', tag: 'Discovery');
        // Fallback query WITHOUT is_active filter
        final response = await _client
            .from(SupabaseConfig.profilesTable)
            .select()
            .neq('id', userId)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }

      // Fallback to simple query with is_active
      logWarn('getDiscoveryProfiles: Using fallback query with is_active filter', tag: 'Discovery');
      try {
        final response = await _client
            .from(SupabaseConfig.profilesTable)
            .select()
            .eq('is_active', true)
            .neq('id', userId)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      } catch (e2) {
        logError('getDiscoveryProfiles: Fallback also failed - $e2', tag: 'Discovery');
        // Ultimate fallback - no filters
        final response = await _client
            .from(SupabaseConfig.profilesTable)
            .select()
            .neq('id', userId)
            .limit(limit);
        return List<Map<String, dynamic>>.from(response);
      }
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  /// Returns distance in kilometers
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Earth radius in kilometers

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
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

  /// Delete a like and cascade delete related chat/match
  /// Use this when removing a like from the likes tab
  Future<void> deleteLike(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    try {
      // Delete the like from targetUser to current user
      await _client
          .from(SupabaseConfig.likesTable)
          .delete()
          .eq('from_user_id', targetUserId)
          .eq('to_user_id', userId);

      // Also delete the reverse like if exists (mutual like)
      await _client
          .from(SupabaseConfig.likesTable)
          .delete()
          .eq('from_user_id', userId)
          .eq('to_user_id', targetUserId);

      // Delete the match if exists
      await _client
          .from(SupabaseConfig.matchesTable)
          .delete()
          .or('and(user1_id.eq.$userId,user2_id.eq.$targetUserId),and(user1_id.eq.$targetUserId,user2_id.eq.$userId)');

      // Find and delete the chat if exists
      final chatResponse = await _client
          .from(SupabaseConfig.chatsTable)
          .select('id')
          .or('and(participant1_id.eq.$userId,participant2_id.eq.$targetUserId),and(participant1_id.eq.$targetUserId,participant2_id.eq.$userId)')
          .maybeSingle();

      if (chatResponse != null) {
        final chatId = chatResponse['id'] as String;
        // Delete all messages in the chat
        await _client
            .from(SupabaseConfig.messagesTable)
            .delete()
            .eq('chat_id', chatId);
        // Delete the chat
        await _client
            .from(SupabaseConfig.chatsTable)
            .delete()
            .eq('id', chatId);
      }
    } catch (e) {
      print('Error deleting like: $e');
      rethrow;
    }
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

  /// Delete a chat and all its messages (hard delete)
  /// Also deletes related likes and matches
  Future<void> deleteChat(String chatId) async {
    final userId = currentUser?.id;
    if (userId == null) {
      print('deleteChat: No current user');
      return;
    }

    print('deleteChat: Starting deletion for chatId=$chatId, userId=$userId');

    try {
      // First get the chat to find the other participant (before deleting)
      final chatResponse = await _client
          .from(SupabaseConfig.chatsTable)
          .select('participant1_id, participant2_id')
          .eq('id', chatId)
          .maybeSingle();

      print('deleteChat: Chat response = $chatResponse');

      if (chatResponse == null) {
        print('deleteChat: Chat not found, might already be deleted');
        return;
      }

      String? otherId;
      final participant1Id = chatResponse['participant1_id'] as String?;
      final participant2Id = chatResponse['participant2_id'] as String?;
      otherId = participant1Id == userId ? participant2Id : participant1Id;

      print('deleteChat: Other participant = $otherId');

      // Delete all messages in the chat first
      print('deleteChat: Deleting messages...');
      await _client
          .from(SupabaseConfig.messagesTable)
          .delete()
          .eq('chat_id', chatId);
      print('deleteChat: Messages deleted');

      // Delete the chat itself
      print('deleteChat: Deleting chat...');
      await _client
          .from(SupabaseConfig.chatsTable)
          .delete()
          .eq('id', chatId);
      print('deleteChat: Chat deleted');

      // Also delete the match and likes if exists
      if (otherId != null) {
        // Delete match
        print('deleteChat: Deleting match...');
        await _client
            .from(SupabaseConfig.matchesTable)
            .delete()
            .or('and(user1_id.eq.$userId,user2_id.eq.$otherId),and(user1_id.eq.$otherId,user2_id.eq.$userId)');
        print('deleteChat: Match deleted');

        // Delete likes in both directions
        print('deleteChat: Deleting likes...');
        await _client
            .from(SupabaseConfig.likesTable)
            .delete()
            .eq('from_user_id', userId)
            .eq('to_user_id', otherId);

        await _client
            .from(SupabaseConfig.likesTable)
            .delete()
            .eq('from_user_id', otherId)
            .eq('to_user_id', userId);
        print('deleteChat: Likes deleted');
      }

      print('deleteChat: All deletions completed successfully');
    } catch (e) {
      print('deleteChat ERROR: $e');
      rethrow;
    }
  }

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

      // Load participant profiles and last message separately
      final chats = List<Map<String, dynamic>>.from(response);

      for (var chat in chats) {
        final chatId = chat['id'] as String;
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

        // Fetch last message for this chat
        final lastMessageResponse = await _client
            .from(SupabaseConfig.messagesTable)
            .select()
            .eq('chat_id', chatId)
            .order('created_at', ascending: false)
            .limit(1);

        if ((lastMessageResponse as List).isNotEmpty) {
          chat['messages'] = lastMessageResponse;
        }

        // Count unread messages (messages not from current user that are unread)
        final unreadResponse = await _client
            .from(SupabaseConfig.messagesTable)
            .select('id')
            .eq('chat_id', chatId)
            .neq('sender_id', userId)
            .eq('is_read', false);

        chat['unread_count'] = (unreadResponse as List).length;
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

  /// Get chat by participant ID (finds chat with specific user)
  Future<Map<String, dynamic>?> getChatByParticipant(String participantId) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      // Find chat where current user and participant are both participants
      final response = await _client
          .from(SupabaseConfig.chatsTable)
          .select()
          .or('and(participant1_id.eq.$userId,participant2_id.eq.$participantId),and(participant1_id.eq.$participantId,participant2_id.eq.$userId)')
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
      print('Error getting chat by participant: $e');
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
      'message_type': imageUrl != null ? 'image' : 'text',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // Update chat's updated_at
    await _client
        .from(SupabaseConfig.chatsTable)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    return response;
  }

  /// Send a media message (video, voice, gif, sticker)
  Future<Map<String, dynamic>> sendMediaMessage({
    required String chatId,
    required String mediaUrl,
    required String messageType,
    String? content,
    int? mediaDurationMs,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from(SupabaseConfig.messagesTable).insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': content ?? '', // Empty string if no content (required by DB)
      'image_url': mediaUrl, // Using image_url for all media for simplicity
      'message_type': messageType,
      'media_duration_ms': mediaDurationMs,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // Update chat's updated_at
    await _client
        .from(SupabaseConfig.chatsTable)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    return response;
  }

  /// Delete a message
  /// If deleteForBoth is true, the message is permanently deleted
  /// Otherwise, it's just hidden for the current user
  Future<void> deleteMessage(String messageId, {bool deleteForBoth = false}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    if (deleteForBoth) {
      // Permanently delete the message
      await _client
          .from(SupabaseConfig.messagesTable)
          .delete()
          .eq('id', messageId);
    } else {
      // Soft delete - just mark as deleted for the sender
      // This uses a deleted_for array to track who has deleted the message
      final message = await _client
          .from(SupabaseConfig.messagesTable)
          .select('deleted_for')
          .eq('id', messageId)
          .single();

      final List<dynamic> deletedFor = message['deleted_for'] ?? [];
      if (!deletedFor.contains(userId)) {
        deletedFor.add(userId);
      }

      await _client
          .from(SupabaseConfig.messagesTable)
          .update({'deleted_for': deletedFor})
          .eq('id', messageId);
    }
  }

  /// Subscribe to new messages in a chat
  RealtimeChannel subscribeToMessages(String chatId, void Function(Map<String, dynamic>) onMessage) {
    print('🔔 Setting up realtime subscription for chat: $chatId');

    final channel = _client.channel('messages:$chatId');

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: SupabaseConfig.messagesTable,
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) {
        print('📨 Realtime: New message received in chat $chatId');
        onMessage(payload.newRecord);
      },
    );

    channel.subscribe((status, error) {
      print('🔔 Realtime subscription status for chat $chatId: $status');
      if (error != null) {
        print('❌ Realtime subscription error: $error');
      }
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('✅ Successfully subscribed to chat $chatId messages');
      }
    });

    return channel;
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

  /// Get blocked users with profile data
  Future<List<Map<String, dynamic>>> getBlockedUsers() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.blockedUsersTable)
        .select()
        .eq('blocker_id', userId)
        .order('created_at', ascending: false);

    // Fetch profiles separately for each blocked user
    final blockedList = List<Map<String, dynamic>>.from(response);
    for (var blocked in blockedList) {
      final profile = await getProfile(blocked['blocked_id'] as String);
      blocked['profiles'] = profile;
    }

    return blockedList;
  }

  // ===================
  // HIDDEN USERS
  // ===================

  /// Hide a user (they won't appear in discovery but can still contact you)
  Future<void> hideUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client.from(SupabaseConfig.hiddenUsersTable).insert({
      'hider_id': userId,
      'hidden_id': targetUserId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Unhide a user
  Future<void> unhideUser(String targetUserId) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.hiddenUsersTable)
        .delete()
        .eq('hider_id', userId)
        .eq('hidden_id', targetUserId);
  }

  /// Get hidden users with profile data
  Future<List<Map<String, dynamic>>> getHiddenUsers() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from(SupabaseConfig.hiddenUsersTable)
          .select()
          .eq('hider_id', userId)
          .order('created_at', ascending: false);

      // Fetch profiles separately for each hidden user
      final hiddenList = List<Map<String, dynamic>>.from(response);
      for (var hidden in hiddenList) {
        final profile = await getProfile(hidden['hidden_id'] as String);
        hidden['profiles'] = profile;
      }

      return hiddenList;
    } catch (e) {
      print('Error getting hidden users: $e');
      // Return empty list if table doesn't exist or other errors
      return [];
    }
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
  Future<String> uploadAvatar(String fileName, Uint8List bytes) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final path = '$userId/avatar_$timestamp.$extension';

    // Delete old avatar if exists
    try {
      final existingFiles = await _client.storage.from(SupabaseConfig.avatarsBucket).list(path: userId);
      if (existingFiles.isNotEmpty) {
        final oldPaths = existingFiles.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from(SupabaseConfig.avatarsBucket).remove(oldPaths);
      }
    } catch (e) {
      // Ignore errors if no existing files
    }

    await _client.storage.from(SupabaseConfig.avatarsBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _getContentType(extension),
        upsert: true,
      ),
    );

    final publicUrl = _client.storage.from(SupabaseConfig.avatarsBucket).getPublicUrl(path);

    // Update profile with new avatar URL
    await updateProfile(userId, {'avatar_url': publicUrl});

    return publicUrl;
  }

  /// Upload photo to user's gallery
  Future<String> uploadPhoto(String fileName, Uint8List bytes) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final path = '$userId/photo_$timestamp.$extension';

    await _client.storage.from(SupabaseConfig.photosBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _getContentType(extension),
        upsert: true,
      ),
    );

    final publicUrl = _client.storage.from(SupabaseConfig.photosBucket).getPublicUrl(path);

    // Add photo to profile's photos array
    await addPhotoToProfile(publicUrl);

    return publicUrl;
  }

  /// Upload profile photo (just upload, don't update profile - for onboarding)
  Future<String> uploadProfilePhoto({
    required String userId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    // Generate unique filename with timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final path = '$userId/photo_$timestamp.$extension';

    await _client.storage.from(SupabaseConfig.photosBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _getContentType(extension),
        upsert: true,
      ),
    );

    return _client.storage.from(SupabaseConfig.photosBucket).getPublicUrl(path);
  }

  /// Add photo URL to profile's photos array
  Future<void> addPhotoToProfile(String photoUrl) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final profile = await getProfile(userId);
    if (profile == null) return;

    final currentPhotos = List<String>.from(profile['photos'] ?? []);
    if (!currentPhotos.contains(photoUrl)) {
      currentPhotos.add(photoUrl);
      await updateProfile(userId, {'photos': currentPhotos});
    }
  }

  /// Remove photo from profile
  Future<void> removePhotoFromProfile(String photoUrl) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    final profile = await getProfile(userId);
    if (profile == null) return;

    final currentPhotos = List<String>.from(profile['photos'] ?? []);
    currentPhotos.remove(photoUrl);
    await updateProfile(userId, {'photos': currentPhotos});

    // Try to delete the file from storage
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      // URL format: /storage/v1/object/public/photos/userId/filename
      if (pathSegments.length >= 6) {
        final storagePath = '${pathSegments[5]}/${pathSegments[6]}';
        await deletePhoto(storagePath);
      }
    } catch (e) {
      print('Error deleting photo from storage: $e');
    }
  }

  /// Delete photo from storage
  Future<void> deletePhoto(String path) async {
    await _client.storage.from(SupabaseConfig.photosBucket).remove([path]);
  }

  /// Delete avatar from storage
  Future<void> deleteAvatar(String path) async {
    await _client.storage.from(SupabaseConfig.avatarsBucket).remove([path]);
  }

  /// Get content type from file extension
  String _getContentType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Get user's photos from storage
  Future<List<String>> getUserPhotos() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final profile = await getProfile(userId);
    if (profile == null) return [];

    return List<String>.from(profile['photos'] ?? []);
  }

  /// Upload chat media (photos, videos, voice messages)
  Future<String> uploadChatMedia({
    required String chatId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final path = '$chatId/$userId/$fileName';
    await _client.storage.from(SupabaseConfig.chatMediaBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

    return _client.storage.from(SupabaseConfig.chatMediaBucket).getPublicUrl(path);
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
    bool isTrialUsed = false,
    int referralMonths = 0,
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
        'is_trial_used': isTrialUsed,
        'referral_months': referralMonths,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );

    // Update profile is_premium field
    await updateProfile(userId, {'is_premium': isActive});
  }

  /// Update subscription end date (for referral bonuses)
  Future<void> updateSubscriptionEndDate(DateTime newEndDate) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    await _client
        .from(SupabaseConfig.subscriptionsTable)
        .update({
          'end_date': newEndDate.toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', userId);
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
  // IN-APP PURCHASES (CONSUMABLES)
  // ===================

  /// Get user's super likes balance
  Future<int> getSuperLikesBalance() async {
    final userId = currentUser?.id;
    if (userId == null) return 0;

    final response = await _client
        .from('user_purchases')
        .select('super_likes_balance')
        .eq('user_id', userId)
        .maybeSingle();

    return response?['super_likes_balance'] as int? ?? 0;
  }

  /// Add super likes to user's balance
  Future<void> addSuperLikes(int count) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    // Get current balance
    final currentBalance = await getSuperLikesBalance();

    await _client.from('user_purchases').upsert(
      {
        'user_id': userId,
        'super_likes_balance': currentBalance + count,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  /// Use one super like
  Future<bool> useSuperLike() async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    final currentBalance = await getSuperLikesBalance();
    if (currentBalance <= 0) return false;

    await _client.from('user_purchases').upsert(
      {
        'user_id': userId,
        'super_likes_balance': currentBalance - 1,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );

    return true;
  }

  /// Get invisible mode end date
  Future<DateTime?> getInvisibleModeUntil() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_purchases')
        .select('invisible_mode_until')
        .eq('user_id', userId)
        .maybeSingle();

    final dateStr = response?['invisible_mode_until'] as String?;
    if (dateStr == null) return null;

    final date = DateTime.parse(dateStr);
    return date.isAfter(DateTime.now()) ? date : null;
  }

  /// Activate invisible mode for N days
  Future<void> activateInvisibleMode(int days) async {
    final userId = currentUser?.id;
    if (userId == null) return;

    // Get current invisible mode end date
    final currentEnd = await getInvisibleModeUntil();
    final now = DateTime.now();

    // If already has invisible mode, extend it
    final baseDate = currentEnd != null && currentEnd.isAfter(now) ? currentEnd : now;
    final newEndDate = baseDate.add(Duration(days: days));

    await _client.from('user_purchases').upsert(
      {
        'user_id': userId,
        'invisible_mode_until': newEndDate.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id',
    );
  }

  /// Check if user has invisible mode active
  Future<bool> hasInvisibleMode() async {
    final endDate = await getInvisibleModeUntil();
    return endDate != null && endDate.isAfter(DateTime.now());
  }

  /// Get user purchases data
  Future<Map<String, dynamic>?> getUserPurchases() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('user_purchases')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return response;
  }

  // ===================
  // USER REPORTS & BANS
  // ===================

  /// Report user
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? reportedByUserId,
    String? details,
  }) async {
    await _client.from(SupabaseConfig.userReportsTable).insert({
      'reported_user_id': reportedUserId,
      'reported_by_user_id': reportedByUserId,
      'reason': reason,
      'details': details,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Ban user
  Future<void> banUser({
    required String userId,
    required String reason,
    Duration? duration,
  }) async {
    final now = DateTime.now();
    final expiresAt = duration != null ? now.add(duration) : null;

    await _client.from(SupabaseConfig.userBansTable).insert({
      'user_id': userId,
      'reason': reason,
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
  // ALBUMS OPERATIONS
  // ===================

  /// Get current user's albums with photos
  Future<List<Map<String, dynamic>>> getMyAlbums() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from(SupabaseConfig.albumsTable)
        .select('*, ${SupabaseConfig.albumPhotosTable}(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Get user's albums (for viewing other profiles)
  Future<List<Map<String, dynamic>>> getUserAlbums(String userId, {bool onlyPublic = false}) async {
    var query = _client
        .from(SupabaseConfig.albumsTable)
        .select('*, ${SupabaseConfig.albumPhotosTable}(*)')
        .eq('user_id', userId);

    if (onlyPublic) {
      query = query.eq('privacy', 'public');
    }

    final response = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Create a new album
  Future<Map<String, dynamic>> createAlbum({
    required String name,
    required String privacy, // 'public' or 'private'
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from(SupabaseConfig.albumsTable).insert({
      'user_id': userId,
      'name': name,
      'privacy': privacy,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).select().single();

    return response;
  }

  /// Update album
  Future<void> updateAlbum(String albumId, Map<String, dynamic> updates) async {
    await _client
        .from(SupabaseConfig.albumsTable)
        .update({
          ...updates,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', albumId);
  }

  /// Delete album and all its photos
  Future<void> deleteAlbum(String albumId) async {
    // First get all photos to delete from storage
    final photos = await _client
        .from(SupabaseConfig.albumPhotosTable)
        .select('url')
        .eq('album_id', albumId);

    // Delete photos from storage
    for (final photo in photos as List) {
      final url = photo['url'] as String?;
      if (url != null) {
        try {
          final uri = Uri.parse(url);
          final pathSegments = uri.pathSegments;
          if (pathSegments.length >= 6) {
            final storagePath = pathSegments.sublist(5).join('/');
            await _client.storage.from(SupabaseConfig.albumsBucket).remove([storagePath]);
          }
        } catch (e) {
          print('Error deleting photo from storage: $e');
        }
      }
    }

    // Delete all photos in album (cascade will handle this, but just in case)
    await _client
        .from(SupabaseConfig.albumPhotosTable)
        .delete()
        .eq('album_id', albumId);

    // Delete the album
    await _client
        .from(SupabaseConfig.albumsTable)
        .delete()
        .eq('id', albumId);
  }

  /// Upload photo to album
  Future<Map<String, dynamic>> uploadAlbumPhoto({
    required String albumId,
    required String fileName,
    required Uint8List bytes,
    bool isPrivate = false,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    debugPrint('uploadAlbumPhoto: userId=$userId, albumId=$albumId');

    // Verify the album exists and belongs to user
    final albumCheck = await _client
        .from(SupabaseConfig.albumsTable)
        .select('id, user_id')
        .eq('id', albumId)
        .maybeSingle();

    debugPrint('uploadAlbumPhoto: albumCheck=$albumCheck');

    if (albumCheck == null) {
      throw Exception('Album not found: $albumId');
    }

    if (albumCheck['user_id'] != userId) {
      throw Exception('Album does not belong to user');
    }

    // Generate unique filename
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = fileName.split('.').last;
    final path = '$userId/$albumId/photo_$timestamp.$extension';

    debugPrint('uploadAlbumPhoto: uploading to storage path=$path');

    // Upload to storage
    await _client.storage.from(SupabaseConfig.albumsBucket).uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: _getContentType(extension),
        upsert: true,
      ),
    );

    final publicUrl = _client.storage.from(SupabaseConfig.albumsBucket).getPublicUrl(path);
    debugPrint('uploadAlbumPhoto: storage uploaded, publicUrl=$publicUrl');

    // Insert photo record
    try {
      final response = await _client.from(SupabaseConfig.albumPhotosTable).insert({
        'album_id': albumId,
        'url': publicUrl,
        'type': 'photo',
        'is_private': isPrivate,
      }).select().single();

      debugPrint('uploadAlbumPhoto: photo record inserted, id=${response['id']}');

      // Update album's updated_at
      await _client
          .from(SupabaseConfig.albumsTable)
          .update({'updated_at': DateTime.now().toIso8601String()})
          .eq('id', albumId);

      return response;
    } catch (e) {
      debugPrint('uploadAlbumPhoto: Error inserting photo record: $e');
      // Try to clean up uploaded file
      try {
        await _client.storage.from(SupabaseConfig.albumsBucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  /// Delete photo from album
  Future<void> deleteAlbumPhoto(String photoId, String photoUrl) async {
    // Delete from storage
    try {
      final uri = Uri.parse(photoUrl);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 5) {
        final storagePath = pathSegments.sublist(5).join('/');
        await _client.storage.from(SupabaseConfig.albumsBucket).remove([storagePath]);
      }
    } catch (e) {
      print('Error deleting photo from storage: $e');
    }

    // Delete record
    await _client
        .from(SupabaseConfig.albumPhotosTable)
        .delete()
        .eq('id', photoId);
  }

  // ===================
  // ALBUM ACCESS REQUESTS
  // ===================

  /// Request access to a private album
  Future<void> requestAlbumAccess(String albumId, String ownerId) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    // Check if request already exists
    final existing = await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .select()
        .eq('album_id', albumId)
        .eq('requester_id', userId)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Access request already exists');
    }

    await _client.from(SupabaseConfig.albumAccessRequestsTable).insert({
      'album_id': albumId,
      'requester_id': userId,
      'owner_id': ownerId,
      'status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Get pending access requests for current user's albums (as owner)
  Future<List<Map<String, dynamic>>> getAccessRequestsAsOwner() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from(SupabaseConfig.albumAccessRequestsTable)
          .select()
          .eq('owner_id', userId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      // Fetch requester profiles and album names separately
      final requests = List<Map<String, dynamic>>.from(response);
      for (var request in requests) {
        // Get requester profile
        try {
          final profile = await _client
              .from(SupabaseConfig.profilesTable)
              .select('name, avatar_url, photos')
              .eq('id', request['requester_id'])
              .maybeSingle();
          if (profile != null) {
            request['profiles'] = profile;
          }
        } catch (_) {}

        // Get album name
        try {
          final album = await _client
              .from(SupabaseConfig.albumsTable)
              .select('name')
              .eq('id', request['album_id'])
              .maybeSingle();
          if (album != null) {
            request['albums'] = album;
          }
        } catch (_) {}
      }

      return requests;
    } catch (e) {
      debugPrint('Error getting access requests: $e');
      return [];
    }
  }

  /// Get access request status for a specific album (as requester)
  Future<Map<String, dynamic>?> getAccessRequestStatus(String albumId) async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .select()
        .eq('album_id', albumId)
        .eq('requester_id', userId)
        .maybeSingle();

    return response;
  }

  /// Respond to access request (approve or deny)
  Future<void> respondToAccessRequest(String requestId, bool approve) async {
    await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .update({
          'status': approve ? 'approved' : 'denied',
          'responded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', requestId);
  }

  /// Check if user has access to a private album
  Future<bool> hasAlbumAccess(String albumId) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    // Check if user is the owner
    final album = await _client
        .from(SupabaseConfig.albumsTable)
        .select('user_id')
        .eq('id', albumId)
        .maybeSingle();

    if (album != null && album['user_id'] == userId) {
      return true; // Owner always has access
    }

    // Check if access was approved
    final request = await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .select()
        .eq('album_id', albumId)
        .eq('requester_id', userId)
        .eq('status', 'approved')
        .maybeSingle();

    return request != null;
  }

  /// Get list of users who have approved access to an album
  Future<List<Map<String, dynamic>>> getApprovedAccessUsers(String albumId) async {
    final response = await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .select('*, profiles!requester_id(*)')
        .eq('album_id', albumId)
        .eq('status', 'approved');

    return List<Map<String, dynamic>>.from(response);
  }

  /// Revoke access to an album
  Future<void> revokeAlbumAccess(String requestId) async {
    await _client
        .from(SupabaseConfig.albumAccessRequestsTable)
        .delete()
        .eq('id', requestId);
  }

  // ===================
  // PRIVATE MEDIA MESSAGES
  // ===================

  /// Send a private media message (with timed/one-time view)
  Future<Map<String, dynamic>> sendPrivateMediaMessage({
    required String chatId,
    required String mediaUrl,
    required String messageType,
    bool isPrivateMedia = true,
    int? viewDurationSec,
    bool oneTimeView = false,
    String? content,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client.from(SupabaseConfig.messagesTable).insert({
      'chat_id': chatId,
      'sender_id': userId,
      'content': content ?? '',
      'image_url': mediaUrl,
      'message_type': messageType,
      'is_private_media': isPrivateMedia,
      'view_duration_sec': viewDurationSec,
      'one_time_view': oneTimeView,
      'has_been_viewed': false,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    // Update chat's updated_at
    await _client
        .from(SupabaseConfig.chatsTable)
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('id', chatId);

    return response;
  }

  /// Mark private media as viewed (for one-time view tracking)
  Future<void> markPrivateMediaAsViewed(String messageId) async {
    await _client
        .from(SupabaseConfig.messagesTable)
        .update({'has_been_viewed': true})
        .eq('id', messageId);
  }

  // ===================
  // VERIFICATION OPERATIONS
  // ===================

  /// Upload verification photo to storage
  Future<String> uploadVerificationPhoto({
    required Uint8List bytes,
    required String pose, // 'thumbs_up' or 'wave'
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final fileName = '${pose}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final path = '$userId/$fileName';

    await _client.storage
        .from(SupabaseConfig.verificationsBucket)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

    // Get signed URL for private bucket (valid for 1 hour)
    final signedUrl = await _client.storage
        .from(SupabaseConfig.verificationsBucket)
        .createSignedUrl(path, 3600);

    return signedUrl;
  }

  /// Get current verification request status
  Future<Map<String, dynamic>?> getVerificationRequest() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from(SupabaseConfig.verificationRequestsTable)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response;
  }

  /// Submit verification request via Edge Function
  Future<Map<String, dynamic>> submitVerification({
    required String photoThumbsUp,
    required String photoWave,
    String? referencePhoto,
  }) async {
    final session = currentSession;
    if (session == null) throw Exception('Not authenticated');

    final response = await _client.functions.invoke(
      'submit-verification',
      body: {
        'photo_thumbs_up': photoThumbsUp,
        'photo_wave': photoWave,
        'reference_photo': referencePhoto,
      },
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Unknown error';
      throw Exception(error);
    }

    return response.data as Map<String, dynamic>;
  }

  /// Watch verification request status changes (realtime)
  Stream<Map<String, dynamic>?> watchVerificationStatus() {
    final userId = currentUser?.id;
    if (userId == null) return Stream.value(null);

    return _client
        .from(SupabaseConfig.verificationRequestsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(1)
        .map((list) => list.isNotEmpty ? list.first : null);
  }

  /// Get default albums for user (creates if not exists)
  Future<Map<String, Map<String, dynamic>>> getOrCreateDefaultAlbums() async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    debugPrint('getOrCreateDefaultAlbums: userId=$userId');

    // Get existing albums
    final existing = await _client
        .from(SupabaseConfig.albumsTable)
        .select('*, ${SupabaseConfig.albumPhotosTable}(*)')
        .eq('user_id', userId)
        .inFilter('name', ['Public', 'Private']);

    debugPrint('getOrCreateDefaultAlbums: found ${(existing as List).length} existing albums');

    Map<String, dynamic>? publicAlbum;
    Map<String, dynamic>? privateAlbum;

    for (final album in existing) {
      debugPrint('getOrCreateDefaultAlbums: found album ${album['name']} with id ${album['id']}');
      if (album['name'] == 'Public') {
        publicAlbum = Map<String, dynamic>.from(album);
      } else if (album['name'] == 'Private') {
        privateAlbum = Map<String, dynamic>.from(album);
      }
    }

    // Create public album if not exists
    if (publicAlbum == null) {
      debugPrint('getOrCreateDefaultAlbums: creating Public album');
      publicAlbum = await createAlbum(name: 'Public', privacy: 'public');
      publicAlbum['album_photos'] = [];
      debugPrint('getOrCreateDefaultAlbums: created Public album with id ${publicAlbum['id']}');
    }

    // Create private album if not exists
    if (privateAlbum == null) {
      debugPrint('getOrCreateDefaultAlbums: creating Private album');
      privateAlbum = await createAlbum(name: 'Private', privacy: 'private');
      privateAlbum['album_photos'] = [];
      debugPrint('getOrCreateDefaultAlbums: created Private album with id ${privateAlbum['id']}');
    }

    return {
      'public': publicAlbum,
      'private': privateAlbum,
    };
  }

  // ===================
  // GDPR OPERATIONS
  // ===================

  /// Export all user data (GDPR Article 15 & 20)
  Future<Map<String, dynamic>> exportUserData() async {
    final session = currentSession;
    if (session == null) throw Exception('Not authenticated');

    final response = await _client.functions.invoke(
      'gdpr-export',
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Failed to export data';
      throw Exception(error);
    }

    return response.data as Map<String, dynamic>;
  }

  /// Delete account and all data (GDPR Article 17)
  Future<Map<String, dynamic>> deleteAccount() async {
    final session = currentSession;
    if (session == null) throw Exception('Not authenticated');

    final response = await _client.functions.invoke(
      'gdpr-delete',
      headers: {
        'Authorization': 'Bearer ${session.accessToken}',
      },
    );

    if (response.status != 200) {
      final error = response.data['error'] ?? 'Failed to delete account';
      throw Exception(error);
    }

    // Sign out after deletion
    await signOut();

    return response.data as Map<String, dynamic>;
  }

  /// Get user consents
  Future<List<Map<String, dynamic>>> getConsents() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('user_consents')
        .select()
        .eq('user_id', userId);

    return List<Map<String, dynamic>>.from(response);
  }

  /// Record user consent
  Future<void> recordConsent({
    required String consentType,
    required bool granted,
    String policyVersion = '1.0',
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    await _client.from('user_consents').upsert(
      {
        'user_id': userId,
        'consent_type': consentType,
        'granted': granted,
        'granted_at': granted ? DateTime.now().toIso8601String() : null,
        'revoked_at': !granted ? DateTime.now().toIso8601String() : null,
        'policy_version': policyVersion,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id,consent_type',
    );
  }

  /// Record multiple consents at once (for registration)
  Future<void> recordConsents(Map<String, bool> consents, {String policyVersion = '1.0'}) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now().toIso8601String();

    for (final entry in consents.entries) {
      await _client.from('user_consents').upsert(
        {
          'user_id': userId,
          'consent_type': entry.key,
          'granted': entry.value,
          'granted_at': entry.value ? now : null,
          'revoked_at': !entry.value ? now : null,
          'policy_version': policyVersion,
          'updated_at': now,
        },
        onConflict: 'user_id,consent_type',
      );
    }
  }

  /// Check if user has all required consents
  Future<bool> hasRequiredConsents() async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    final response = await _client
        .from('user_consents')
        .select()
        .eq('user_id', userId)
        .inFilter('consent_type', [
          'terms_of_service',
          'privacy_policy',
          'data_processing',
          'age_verification',
        ])
        .eq('granted', true);

    return (response as List).length >= 4;
  }

  // ==========================================
  // PROFILE OPTIONS (Interests, Fantasies, Occupations)
  // ==========================================

  /// Get all active interests
  Future<List<Interest>> getInterests() async {
    final response = await _client
        .from('interests')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((e) => Interest.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all active fantasies
  Future<List<Fantasy>> getFantasies() async {
    final response = await _client
        .from('fantasies')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((e) => Fantasy.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get all active occupations
  Future<List<Occupation>> getOccupations() async {
    final response = await _client
        .from('occupations')
        .select()
        .eq('is_active', true)
        .order('sort_order');

    return (response as List)
        .map((e) => Occupation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Get user's selected interest IDs
  Future<List<String>> getUserInterestIds() async {
    final userId = currentUser?.id;
    if (userId == null) {
      logWarn('getUserInterestIds: No user ID', tag: 'Supabase');
      return [];
    }

    try {
      logDebug('getUserInterestIds: Fetching for user $userId', tag: 'Supabase');
      final response = await _client
          .from('user_interests')
          .select('interest_id')
          .eq('user_id', userId);

      final ids = (response as List)
          .map((e) => e['interest_id'] as String)
          .toList();
      logDebug('getUserInterestIds: Found ${ids.length} interests', tag: 'Supabase');
      return ids;
    } catch (e, st) {
      logError('getUserInterestIds: Error', tag: 'Supabase', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get user's selected fantasy IDs
  Future<List<String>> getUserFantasyIds() async {
    final userId = currentUser?.id;
    if (userId == null) {
      logWarn('getUserFantasyIds: No user ID', tag: 'Supabase');
      return [];
    }

    try {
      logDebug('getUserFantasyIds: Fetching for user $userId', tag: 'Supabase');
      final response = await _client
          .from('user_fantasies')
          .select('fantasy_id')
          .eq('user_id', userId);

      final ids = (response as List)
          .map((e) => e['fantasy_id'] as String)
          .toList();
      logDebug('getUserFantasyIds: Found ${ids.length} fantasies', tag: 'Supabase');
      return ids;
    } catch (e, st) {
      logError('getUserFantasyIds: Error', tag: 'Supabase', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get user's occupation ID
  Future<String?> getUserOccupationId() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('profiles')
        .select('occupation_id')
        .eq('id', userId)
        .maybeSingle();

    return response?['occupation_id'] as String?;
  }

  /// Add custom interest
  Future<Interest?> addCustomInterest(String name) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('interests')
        .insert({
          'name': name,
          'category': 'Custom',
          'is_system': false,
          'created_by': userId,
        })
        .select()
        .single();

    return Interest.fromJson(response as Map<String, dynamic>);
  }

  /// Add custom fantasy
  Future<Fantasy?> addCustomFantasy(String name) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('fantasies')
        .insert({
          'name': name,
          'category': 'Custom',
          'is_system': false,
          'created_by': userId,
        })
        .select()
        .single();

    return Fantasy.fromJson(response as Map<String, dynamic>);
  }

  /// Add custom occupation
  Future<Occupation?> addCustomOccupation(String name) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    final response = await _client
        .from('occupations')
        .insert({
          'name': name,
          'category': 'Custom',
          'is_system': false,
          'created_by': userId,
        })
        .select()
        .single();

    return Occupation.fromJson(response as Map<String, dynamic>);
  }

  /// Update user's selections (interests, fantasies, occupation)
  Future<void> updateUserSelections({
    required List<String> interestIds,
    required List<String> fantasyIds,
    String? occupationId,
  }) async {
    final userId = currentUser?.id;
    if (userId == null) throw Exception('Not authenticated');

    logInfo('updateUserSelections: Starting for user $userId', tag: 'Supabase');
    logDebug('updateUserSelections: interests=${interestIds.length}, fantasies=${fantasyIds.length}, occupation=$occupationId', tag: 'Supabase');

    try {
      // Update interests
      logDebug('updateUserSelections: Deleting old interests...', tag: 'Supabase');
      await _client.from('user_interests').delete().eq('user_id', userId);
      if (interestIds.isNotEmpty) {
        logDebug('updateUserSelections: Inserting ${interestIds.length} interests...', tag: 'Supabase');
        await _client.from('user_interests').insert(
          interestIds.map((id) => ({
            'user_id': userId,
            'interest_id': id,
          })).toList(),
        );
      }

      // Update fantasies
      logDebug('updateUserSelections: Deleting old fantasies...', tag: 'Supabase');
      await _client.from('user_fantasies').delete().eq('user_id', userId);
      if (fantasyIds.isNotEmpty) {
        logDebug('updateUserSelections: Inserting ${fantasyIds.length} fantasies...', tag: 'Supabase');
        await _client.from('user_fantasies').insert(
          fantasyIds.map((id) => ({
            'user_id': userId,
            'fantasy_id': id,
          })).toList(),
        );
      }

      // Update occupation
      logDebug('updateUserSelections: Updating occupation...', tag: 'Supabase');
      await _client.from('profiles').update({
        'occupation_id': occupationId,
      }).eq('id', userId);

      logInfo('updateUserSelections: Completed successfully', tag: 'Supabase');
    } catch (e, st) {
      logError('updateUserSelections: Failed', tag: 'Supabase', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get user's interests with full data
  Future<List<Interest>> getUserInterests(String userId) async {
    final response = await _client
        .from('user_interests')
        .select('interests(*)')
        .eq('user_id', userId);

    return (response as List)
        .where((e) => e['interests'] != null)
        .map((e) => Interest.fromJson(e['interests'] as Map<String, dynamic>))
        .toList();
  }

  /// Get user's fantasies with full data
  Future<List<Fantasy>> getUserFantasies(String userId) async {
    final response = await _client
        .from('user_fantasies')
        .select('fantasies(*)')
        .eq('user_id', userId);

    return (response as List)
        .where((e) => e['fantasies'] != null)
        .map((e) => Fantasy.fromJson(e['fantasies'] as Map<String, dynamic>))
        .toList();
  }

  /// Get occupation by ID
  Future<Occupation?> getOccupationById(String occupationId) async {
    final response = await _client
        .from('occupations')
        .select()
        .eq('id', occupationId)
        .maybeSingle();

    if (response == null) return null;
    return Occupation.fromJson(response as Map<String, dynamic>);
  }
  // ===================
  // REFERRAL SYSTEM
  // ===================

  /// Get or create referral code for current user
  Future<String?> getOrCreateReferralCode() async {
    final userId = currentUser?.id;
    if (userId == null) return null;

    try {
      // First check if user already has a code
      final existing = await _client
          .from('referral_codes')
          .select('code')
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        return existing['code'] as String?;
      }

      // Create new code using database function
      final response = await _client.rpc(
        'create_referral_code_for_user',
        params: {'p_user_id': userId},
      );

      return response as String?;
    } catch (e) {
      print('Error getting/creating referral code: $e');
      return null;
    }
  }

  /// Get referral statistics for current user
  Future<ReferralStats> getReferralStats() async {
    final userId = currentUser?.id;
    if (userId == null) return const ReferralStats();

    try {
      final response = await _client
          .from('user_referral_stats')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return const ReferralStats();
      return ReferralStats.fromJson(response);
    } catch (e) {
      print('Error getting referral stats: $e');
      return const ReferralStats();
    }
  }

  /// Get list of referrals made by current user
  Future<List<ReferralModel>> getUserReferrals() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('referrals')
          .select('*, profiles!referrals_referred_id_fkey(name, avatar_url)')
          .eq('referrer_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ReferralModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user referrals: $e');
      return [];
    }
  }

  /// Apply referral code during registration
  Future<bool> applyReferralCode(String code) async {
    final userId = currentUser?.id;
    if (userId == null) return false;

    try {
      final response = await _client.rpc(
        'apply_referral_code',
        params: {
          'p_referred_user_id': userId,
          'p_referral_code': code.toUpperCase(),
        },
      );

      return response == true;
    } catch (e) {
      print('Error applying referral code: $e');
      return false;
    }
  }

  /// Check if a referral code is valid
  Future<bool> isReferralCodeValid(String code) async {
    try {
      final response = await _client
          .from('referral_codes')
          .select('code')
          .eq('code', code.toUpperCase())
          .maybeSingle();

      return response != null;
    } catch (e) {
      print('Error checking referral code: $e');
      return false;
    }
  }

  /// Get referral rewards for current user
  Future<List<ReferralReward>> getReferralRewards() async {
    final userId = currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _client
          .from('referral_rewards')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((e) => ReferralReward.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting referral rewards: $e');
      return [];
    }
  }
}

/// Supabase service provider
final supabaseServiceProvider = Provider<SupabaseService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseService(client);
});

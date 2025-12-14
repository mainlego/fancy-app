import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../filters/domain/models/filter_model.dart';
import '../../../filters/domain/providers/filter_provider.dart';
import '../../../ai_profiles/domain/providers/ai_profiles_provider.dart';

/// Current filter state provider (alias for backward compatibility)
/// Use filterNotifierProvider for new code
final filterProvider = Provider<FilterModel>((ref) {
  return ref.watch(filterNotifierProvider);
});

/// Quick filter for dating goals - synced with main filter
final quickDatingGoalProvider = StateProvider<DatingGoal?>((ref) {
  // Initialize from saved filter if available
  final filterAsync = ref.watch(filterAsyncProvider);
  final filter = filterAsync.valueOrNull;
  if (filter != null && filter.datingGoals.isNotEmpty) {
    return filter.datingGoals.first;
  }
  return null;
});

/// Quick filter for relationship status - synced with main filter
final quickRelationshipStatusProvider = StateProvider<RelationshipStatus?>((ref) {
  // Initialize from saved filter if available
  final filterAsync = ref.watch(filterAsyncProvider);
  final filter = filterAsync.valueOrNull;
  if (filter != null && filter.relationshipStatuses.isNotEmpty) {
    return filter.relationshipStatuses.first;
  }
  return null;
});

/// Profiles from Supabase
final profilesProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getDiscoveryProfiles(limit: 50);
    return data.map((json) => UserModel.fromSupabase(json)).toList();
  } catch (e) {
    // Return empty list if there's an error (e.g., no auth, no data)
    print('Error loading profiles: $e');
    return [];
  }
});

/// Profiles state notifier for managing profile list and actions
class ProfilesNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SupabaseService _supabase;
  final Ref _ref;

  ProfilesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getDiscoveryProfiles(limit: 50);
      final profiles = data.map((json) => UserModel.fromSupabase(json)).toList();
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadProfiles();
  }

  Future<bool> likeUser(String userId) async {
    try {
      // AI profiles (id starts with 'ai_') always match back instantly!
      final isAIProfile = userId.startsWith('ai_');

      bool isMatch;
      if (isAIProfile) {
        // AI profiles always like back - it's always a match!
        isMatch = true;
      } else {
        // Real users - check for mutual like
        isMatch = await _supabase.likeUser(userId);
      }

      // Remove from current list after action
      state.whenData((profiles) {
        state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
      });
      return isMatch;
    } catch (e) {
      print('Error liking user: $e');
      return false;
    }
  }

  Future<void> passUser(String userId) async {
    try {
      // Don't call Supabase for AI profiles
      if (!userId.startsWith('ai_')) {
        await _supabase.passUser(userId);
      }
      // Remove from current list after action
      state.whenData((profiles) {
        state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
      });
    } catch (e) {
      print('Error passing user: $e');
    }
  }

  Future<void> addToFavorites(String userId) async {
    try {
      // Don't call Supabase for AI profiles - just show success
      if (!userId.startsWith('ai_')) {
        await _supabase.addToFavorites(userId);
      }
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      // Don't call Supabase for AI profiles
      if (!userId.startsWith('ai_')) {
        await _supabase.blockUser(userId);
      }
      // Remove blocked user from list
      state.whenData((profiles) {
        state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
      });
    } catch (e) {
      print('Error blocking user: $e');
      rethrow;
    }
  }
}

/// Profiles notifier provider
final profilesNotifierProvider = StateNotifierProvider<ProfilesNotifier, AsyncValue<List<UserModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ProfilesNotifier(supabase, ref);
});

/// Filtered profiles provider - applies local filters to loaded profiles
/// Includes AI profiles mixed with real profiles
final filteredProfilesProvider = Provider<List<UserModel>>((ref) {
  final profilesAsync = ref.watch(profilesNotifierProvider);
  final aiProfiles = ref.watch(aiProfilesAsUsersProvider);
  final filter = ref.watch(filterProvider);
  final quickGoal = ref.watch(quickDatingGoalProvider);
  final quickStatus = ref.watch(quickRelationshipStatusProvider);

  // Get real profiles (empty list if loading/error)
  final realProfiles = profilesAsync.valueOrNull ?? [];

  // Combine real profiles with AI profiles
  // AI profiles are always shown first (they're always online and nearby)
  final allProfiles = [...aiProfiles, ...realProfiles];

  return allProfiles.where((profile) {
    // Quick filter: dating goal
    if (quickGoal != null && profile.datingGoal != quickGoal) {
      return false;
    }

    // Quick filter: relationship status
    if (quickStatus != null && profile.relationshipStatus != quickStatus) {
      return false;
    }

    // AI profiles always pass distance filter (they're always nearby)
    final isAI = profile.id.startsWith('ai_');

    // Distance filter (skip for AI profiles)
    if (!isAI && profile.distanceKm != null && profile.distanceKm! > filter.distanceKm) {
      return false;
    }

    // Age filter
    if (profile.age < filter.minAge || profile.age > filter.maxAge) {
      return false;
    }

    // Dating goal filter
    if (filter.datingGoals.isNotEmpty &&
        profile.datingGoal != null &&
        !filter.datingGoals.contains(profile.datingGoal)) {
      return false;
    }

    // Relationship status filter
    if (filter.relationshipStatuses.isNotEmpty &&
        profile.relationshipStatus != null &&
        !filter.relationshipStatuses.contains(profile.relationshipStatus)) {
      return false;
    }

    // Online only filter
    if (filter.onlineOnly && !profile.isOnline) {
      return false;
    }

    // With photo filter
    if (filter.withPhoto && !profile.hasPhotos) {
      return false;
    }

    // Verified only filter
    if (filter.verifiedOnly && !profile.isVerified) {
      return false;
    }

    // Looking for filter
    if (filter.lookingFor.isNotEmpty &&
        !filter.lookingFor.contains(profile.profileType)) {
      return false;
    }

    // Height filter
    if (filter.minHeight != null &&
        profile.heightCm != null &&
        profile.heightCm! < filter.minHeight!) {
      return false;
    }
    if (filter.maxHeight != null &&
        profile.heightCm != null &&
        profile.heightCm! > filter.maxHeight!) {
      return false;
    }

    // Weight filter
    if (filter.minWeight != null &&
        profile.weightKg != null &&
        profile.weightKg! < filter.minWeight!) {
      return false;
    }
    if (filter.maxWeight != null &&
        profile.weightKg != null &&
        profile.weightKg! > filter.maxWeight!) {
      return false;
    }

    // Zodiac filter
    if (filter.zodiacSigns.isNotEmpty &&
        profile.zodiacSign != null &&
        !filter.zodiacSigns.contains(profile.zodiacSign)) {
      return false;
    }

    return true;
  }).toList();
});

/// Likes received by current user
final likesProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getLikers();
    return data.map((json) {
      // The profile data is nested under profiles key
      final profileData = json['profiles'] as Map<String, dynamic>?;
      if (profileData != null) {
        return UserModel.fromSupabase(profileData);
      }
      return UserModel.fromSupabase(json);
    }).toList();
  } catch (e) {
    print('Error loading likes: $e');
    return [];
  }
});

/// Matches provider
final matchesProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getMatches();
    final currentUserId = supabase.currentUser?.id;

    return data.map((json) {
      // Get the other user's profile from the match
      final user1Id = json['user1_id'] as String?;
      final profileData = user1Id == currentUserId
          ? json['profiles!user2_id'] as Map<String, dynamic>?
          : json['profiles!user1_id'] as Map<String, dynamic>?;

      if (profileData != null) {
        return UserModel.fromSupabase(profileData);
      }
      return UserModel.fromSupabase(json);
    }).toList();
  } catch (e) {
    print('Error loading matches: $e');
    return [];
  }
});

/// Favorites provider
final favoritesProvider = FutureProvider<List<UserModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getFavorites();
    return data.map((json) {
      // The profile data is nested under profiles key
      final profileData = json['profiles'] as Map<String, dynamic>?;
      if (profileData != null) {
        return UserModel.fromSupabase(profileData);
      }
      return UserModel.fromSupabase(json);
    }).toList();
  } catch (e) {
    print('Error loading favorites: $e');
    return [];
  }
});

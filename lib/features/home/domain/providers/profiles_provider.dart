import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
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
  bool _isLoading = false;

  ProfilesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    // Listen for current profile changes to reload with proper filters
    _ref.listen<AsyncValue<UserModel?>>(currentProfileProvider, (previous, next) {
      // When profile becomes available, reload profiles with proper filters
      if (next.hasValue && next.value != null) {
        print('DEBUG: Profile changed, reloading profiles...');
        loadProfiles();
      }
    });

    // Check if profile is already available
    final currentProfile = _ref.read(currentProfileProvider).valueOrNull;
    if (currentProfile != null) {
      loadProfiles();
    }
    // If profile not ready, wait for listener to trigger
  }

  Future<void> loadProfiles() async {
    // Prevent concurrent loads
    if (_isLoading) {
      print('DEBUG: Already loading, skipping...');
      return;
    }

    // Get current user's profile for bidirectional matching
    final currentProfile = _ref.read(currentProfileProvider).valueOrNull;

    // Don't load without profile - wait for it
    if (currentProfile == null) {
      print('DEBUG: No profile yet, waiting...');
      return;
    }

    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      final lookingFor = currentProfile.lookingFor;
      final myProfileType = currentProfile.profileType;

      // DEBUG: Print full profile info
      print('DEBUG: currentProfile = ${currentProfile.name}');
      print('DEBUG: currentProfile.lookingFor = $lookingFor');
      print('DEBUG: currentProfile.profileType = $myProfileType');

      // Convert Set<ProfileType> to List<String> for the query
      List<String>? lookingForStrings;
      if (lookingFor.isNotEmpty) {
        lookingForStrings = lookingFor.map((e) => e.name).toList();
      }

      // Get my profile type for bidirectional matching
      String? myProfileTypeString = myProfileType.name;

      print('Loading profiles with lookingFor: $lookingForStrings, myProfileType: $myProfileTypeString');

      final data = await _supabase.getDiscoveryProfiles(
        limit: 50,
        lookingFor: lookingForStrings,
        myProfileType: myProfileTypeString,
      );
      print('Loaded ${data.length} real profiles from Supabase');

      // DEBUG: Print each profile loaded
      for (final json in data) {
        print('DEBUG: Loaded profile: ${json['name']} (${json['profile_type']}) looking_for: ${json['looking_for']}');
      }

      final profiles = data.map((json) => UserModel.fromSupabase(json)).toList();
      state = AsyncValue.data(profiles);
    } catch (e, st) {
      print('Error loading real profiles: $e');
      state = AsyncValue.error(e, st);
    } finally {
      _isLoading = false;
    }
  }

  Future<void> refresh() async {
    await loadProfiles();
  }

  /// Like a user - pass the full UserModel to correctly detect AI profiles
  Future<bool> likeUserModel(UserModel user) async {
    try {
      bool isMatch;
      if (user.isAi) {
        // AI profiles always like back - it's always a match!
        isMatch = true;
      } else {
        // Real users - check for mutual like
        isMatch = await _supabase.likeUser(user.id);
      }

      // Remove from current list after action (only affects real profiles)
      state.whenData((profiles) {
        state = AsyncValue.data(profiles.where((p) => p.id != user.id).toList());
      });
      return isMatch;
    } catch (e) {
      print('Error liking user: $e');
      return false;
    }
  }

  /// Legacy method - kept for compatibility but prefer likeUserModel
  Future<bool> likeUser(String userId) async {
    try {
      // Check if this is an AI profile by ID prefix (for locally generated)
      // or by checking the profiles list
      bool isAIProfile = userId.startsWith('ai_');

      // Also check current profiles list for isAi flag
      state.whenData((profiles) {
        final profile = profiles.where((p) => p.id == userId).firstOrNull;
        if (profile != null && profile.isAi) {
          isAIProfile = true;
        }
      });

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

  // DEBUG: Log what we have
  print('DEBUG filteredProfilesProvider: realProfiles=${realProfiles.length}, aiProfiles=${aiProfiles.length}');
  print('DEBUG filteredProfilesProvider: profilesAsync state=${profilesAsync.isLoading ? "loading" : profilesAsync.hasError ? "error" : "data"}');
  for (final p in realProfiles) {
    print('DEBUG filteredProfilesProvider: Real profile: ${p.name} (${p.profileType})');
  }

  // Combine real profiles with AI profiles
  // Real users are shown FIRST, then AI profiles
  final allProfiles = [...realProfiles, ...aiProfiles];

  // DEBUG: Log filter settings
  print('DEBUG FILTER: lookingFor=${filter.lookingFor}, onlineOnly=${filter.onlineOnly}, withPhoto=${filter.withPhoto}, minAge=${filter.minAge}, maxAge=${filter.maxAge}');

  final filtered = allProfiles.where((profile) {
    final isAI = profile.isAi;

    // Quick filter: dating goal
    if (quickGoal != null && profile.datingGoal != quickGoal) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by quickGoal');
      return false;
    }

    // Quick filter: relationship status
    if (quickStatus != null && profile.relationshipStatus != quickStatus) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by quickStatus');
      return false;
    }

    // Distance filter (skip for AI profiles)
    if (!isAI && profile.distanceKm != null && profile.distanceKm! > filter.distanceKm) {
      print('DEBUG: ${profile.name} filtered by distance (${profile.distanceKm} > ${filter.distanceKm})');
      return false;
    }

    // Age filter
    if (profile.age < filter.minAge || profile.age > filter.maxAge) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by age (${profile.age} not in ${filter.minAge}-${filter.maxAge})');
      return false;
    }

    // Dating goal filter
    if (filter.datingGoals.isNotEmpty &&
        profile.datingGoal != null &&
        !filter.datingGoals.contains(profile.datingGoal)) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by datingGoals');
      return false;
    }

    // Relationship status filter
    if (filter.relationshipStatuses.isNotEmpty &&
        profile.relationshipStatus != null &&
        !filter.relationshipStatuses.contains(profile.relationshipStatus)) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by relationshipStatuses');
      return false;
    }

    // Online only filter
    if (filter.onlineOnly && !profile.isOnline) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by onlineOnly (isOnline=${profile.isOnline})');
      return false;
    }

    // With photo filter
    if (filter.withPhoto && !profile.hasPhotos) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by withPhoto (hasPhotos=${profile.hasPhotos})');
      return false;
    }

    // Verified only filter
    if (filter.verifiedOnly && !profile.isVerified) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by verifiedOnly');
      return false;
    }

    // Looking for filter
    if (filter.lookingFor.isNotEmpty &&
        !filter.lookingFor.contains(profile.profileType)) {
      if (!isAI) print('DEBUG: ${profile.name} filtered by lookingFor (profileType=${profile.profileType}, filter=${filter.lookingFor})');
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

  print('DEBUG filteredProfilesProvider: Final filtered count=${filtered.length}');
  return filtered;
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

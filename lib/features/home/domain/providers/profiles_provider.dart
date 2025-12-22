import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../../../filters/domain/models/filter_model.dart';
import '../../../filters/domain/providers/filter_provider.dart';

/// Current filter state provider (alias for backward compatibility)
/// Use filterNotifierProvider for new code
final filterProvider = Provider<FilterModel>((ref) {
  return ref.watch(filterNotifierProvider);
});

/// Quick filter for dating goals - synced with main filter (supports multiple selection)
final quickDatingGoalsProvider = StateProvider<Set<DatingGoal>>((ref) {
  // Initialize from saved filter if available
  final filterAsync = ref.watch(filterAsyncProvider);
  final filter = filterAsync.valueOrNull;
  if (filter != null && filter.datingGoals.isNotEmpty) {
    return filter.datingGoals;
  }
  return <DatingGoal>{};
});

/// Quick filter for relationship status - synced with main filter (supports multiple selection)
final quickRelationshipStatusesProvider = StateProvider<Set<RelationshipStatus>>((ref) {
  // Initialize from saved filter if available
  final filterAsync = ref.watch(filterAsyncProvider);
  final filter = filterAsync.valueOrNull;
  if (filter != null && filter.relationshipStatuses.isNotEmpty) {
    return filter.relationshipStatuses;
  }
  return <RelationshipStatus>{};
});

/// Legacy single-select providers for backward compatibility
final quickDatingGoalProvider = StateProvider<DatingGoal?>((ref) {
  final goals = ref.watch(quickDatingGoalsProvider);
  return goals.isEmpty ? null : goals.first;
});

final quickRelationshipStatusProvider = StateProvider<RelationshipStatus?>((ref) {
  final statuses = ref.watch(quickRelationshipStatusesProvider);
  return statuses.isEmpty ? null : statuses.first;
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
  bool _isLoadingMore = false;
  bool _hasMoreProfiles = true;
  int _loadCounter = 0; // Track load operations to prevent race conditions
  static const int _pageSize = 20;

  // Track liked profiles (user stays in feed until match)
  final Set<String> _likedProfileIds = {};

  ProfilesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    // Listen for current profile changes to reload with proper filters
    _ref.listen<AsyncValue<UserModel?>>(currentProfileProvider, (previous, next) {
      // When profile becomes available, reload profiles with proper filters
      if (next.hasValue && next.value != null) {
        loadProfiles();
      }
    });

    // Listen for filter changes that require reloading (distance, age)
    _ref.listen<FilterModel>(filterNotifierProvider, (previous, next) {
      if (previous == null) return;
      // Reload if distance or age filters changed (these are server-side filters)
      if (previous.maxDistanceKm != next.maxDistanceKm ||
          previous.minAge != next.minAge ||
          previous.maxAge != next.maxAge) {
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
    // Prevent concurrent loads using counter pattern
    if (_isLoading) return;
    final currentLoad = ++_loadCounter;

    // Get current user's profile for bidirectional matching
    final currentProfile = _ref.read(currentProfileProvider).valueOrNull;

    // Don't load without profile - wait for it
    if (currentProfile == null) return;

    _isLoading = true;
    state = const AsyncValue.loading();

    try {
      final lookingFor = currentProfile.lookingFor;
      final myProfileType = currentProfile.profileType;

      // Get current filter settings
      final filter = _ref.read(filterNotifierProvider);

      // Convert Set<ProfileType> to List<String> for the query
      List<String>? lookingForStrings;
      if (lookingFor.isNotEmpty) {
        lookingForStrings = lookingFor.map((e) => e.name).toList();
      }

      // Get my profile type for bidirectional matching
      String? myProfileTypeString = myProfileType.name;

      // Don't apply distance filter if set to 500+ (maxDistanceLimit means "no limit")
      final maxDistanceFilter = filter.maxDistanceKm >= FilterModel.maxDistanceLimit
          ? null
          : filter.maxDistanceKm;

      final data = await _supabase.getDiscoveryProfiles(
        limit: _pageSize,
        offset: 0,
        lookingFor: lookingForStrings,
        myProfileType: myProfileTypeString,
        // Pass distance and age filters to server
        maxDistance: maxDistanceFilter,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
      );

      final profiles = data.map((json) => UserModel.fromSupabase(json)).toList();
      // Only update state if this is still the latest load operation
      if (currentLoad == _loadCounter) {
        _hasMoreProfiles = profiles.length >= _pageSize;
        state = AsyncValue.data(profiles);
      }
    } catch (e, st) {
      if (currentLoad == _loadCounter) {
        state = AsyncValue.error(e, st);
      }
    } finally {
      _isLoading = false;
    }
  }

  /// Load more profiles (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMoreProfiles) return;

    final currentProfiles = state.valueOrNull;
    if (currentProfiles == null || currentProfiles.isEmpty) return;

    final currentProfile = _ref.read(currentProfileProvider).valueOrNull;
    if (currentProfile == null) return;

    _isLoadingMore = true;

    try {
      final lookingFor = currentProfile.lookingFor;
      final myProfileType = currentProfile.profileType;
      final filter = _ref.read(filterNotifierProvider);

      List<String>? lookingForStrings;
      if (lookingFor.isNotEmpty) {
        lookingForStrings = lookingFor.map((e) => e.name).toList();
      }

      String? myProfileTypeString = myProfileType.name;

      final maxDistanceFilter = filter.maxDistanceKm >= FilterModel.maxDistanceLimit
          ? null
          : filter.maxDistanceKm;

      final data = await _supabase.getDiscoveryProfiles(
        limit: _pageSize,
        offset: currentProfiles.length,
        lookingFor: lookingForStrings,
        myProfileType: myProfileTypeString,
        maxDistance: maxDistanceFilter,
        minAge: filter.minAge,
        maxAge: filter.maxAge,
      );

      final newProfiles = data.map((json) => UserModel.fromSupabase(json)).toList();
      _hasMoreProfiles = newProfiles.length >= _pageSize;

      // Append new profiles to existing list
      state = AsyncValue.data([...currentProfiles, ...newProfiles]);
    } catch (e) {
      // Don't replace state with error, just log it
      print('Error loading more profiles: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  /// Check if more profiles can be loaded
  bool get canLoadMore => _hasMoreProfiles && !_isLoadingMore;

  /// Check if currently loading more
  bool get isLoadingMore => _isLoadingMore;

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> refresh() async {
    await loadProfiles();
  }

  /// Check if a profile has been liked
  bool isProfileLiked(String profileId) => _likedProfileIds.contains(profileId);

  /// Like a user
  Future<bool> likeUserModel(UserModel user) async {
    try {
      final isMatch = await _supabase.likeUser(user.id);

      if (isMatch) {
        // Remove from current list ONLY if it's a match
        state.whenData((profiles) {
          state = AsyncValue.data(profiles.where((p) => p.id != user.id).toList());
        });
        _likedProfileIds.remove(user.id);
      } else {
        // Mark as liked but keep in feed
        _likedProfileIds.add(user.id);
        // Trigger rebuild to update UI
        state.whenData((profiles) {
          state = AsyncValue.data([...profiles]);
        });
      }
      return isMatch;
    } catch (e) {
      print('Error liking user: $e');
      return false;
    }
  }

  /// Like a user by ID
  Future<bool> likeUser(String userId) async {
    try {
      final isMatch = await _supabase.likeUser(userId);

      if (isMatch) {
        // Remove from current list ONLY if it's a match
        state.whenData((profiles) {
          state = AsyncValue.data(profiles.where((p) => p.id != userId).toList());
        });
        _likedProfileIds.remove(userId);
      } else {
        // Mark as liked but keep in feed
        _likedProfileIds.add(userId);
        // Trigger rebuild to update UI
        state.whenData((profiles) {
          state = AsyncValue.data([...profiles]);
        });
      }
      return isMatch;
    } catch (e) {
      print('Error liking user: $e');
      return false;
    }
  }

  Future<void> passUser(String userId) async {
    try {
      await _supabase.passUser(userId);
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
      await _supabase.addToFavorites(userId);
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _supabase.blockUser(userId);
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
final filteredProfilesProvider = Provider<List<UserModel>>((ref) {
  final profilesAsync = ref.watch(profilesNotifierProvider);
  final filter = ref.watch(filterProvider);
  final quickGoals = ref.watch(quickDatingGoalsProvider);
  final quickStatuses = ref.watch(quickRelationshipStatusesProvider);

  // Get profiles (empty list if loading/error)
  final profiles = profilesAsync.valueOrNull ?? [];

  return profiles.where((profile) {
    // Only show active profiles
    if (!profile.isActive) {
      return false;
    }

    // Quick filter: dating goals (supports multiple selection)
    if (quickGoals.isNotEmpty &&
        profile.datingGoal != null &&
        !quickGoals.contains(profile.datingGoal)) {
      return false;
    }

    // Quick filter: relationship statuses (supports multiple selection)
    if (quickStatuses.isNotEmpty &&
        profile.relationshipStatus != null &&
        !quickStatuses.contains(profile.relationshipStatus)) {
      return false;
    }

    // Distance filter (skip if set to 500+ which means "no limit")
    if (filter.maxDistanceKm < FilterModel.maxDistanceLimit &&
        profile.distanceKm != null &&
        profile.distanceKm! > filter.distanceKm) {
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

/// Single profile provider by ID - loads directly from database
/// Use this when you need to view a profile that may not be in the discovery feed
final profileByIdProvider = FutureProvider.family<UserModel?, String>((ref, userId) async {
  final supabase = ref.watch(supabaseServiceProvider);

  try {
    final data = await supabase.getProfile(userId);
    if (data == null) return null;
    return UserModel.fromSupabase(data);
  } catch (e) {
    print('Error loading profile by ID: $e');
    return null;
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

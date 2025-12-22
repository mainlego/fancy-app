import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/debug_logger.dart';
import '../models/user_model.dart';

/// Current user profile from Supabase
class CurrentProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseService _supabase;
  final Ref _ref;
  StreamSubscription<AuthState>? _authSubscription;

  CurrentProfileNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadProfile();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        loadProfile();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> loadProfile() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) {
      logInfo('No user ID, setting state to null', tag: 'Profile');
      state = const AsyncValue.data(null);
      return;
    }

    logInfo('Loading profile for user $userId', tag: 'Profile');
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getCurrentProfile();
      logDebug('Got data from Supabase: $data', tag: 'Profile');
      if (data != null) {
        logInfo('Parsing profile data...', tag: 'Profile');
        logDebug('Raw isActive from DB: ${data['is_active']}', tag: 'Profile');
        final profile = UserModel.fromSupabase(data);
        logInfo('Profile parsed successfully: ${profile.name}, isActive=${profile.isActive}', tag: 'Profile');
        state = AsyncValue.data(profile);
      } else {
        // No profile exists yet - user needs to complete onboarding
        logWarn('No profile data, setting state to null', tag: 'Profile');
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      logError('Failed to load profile', tag: 'Profile', error: e, stackTrace: st);
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> refresh() async {
    await loadProfile();
  }

  /// Check if profile is complete (has required fields)
  bool get isProfileComplete {
    final profile = state.valueOrNull;
    if (profile == null) return false;

    return profile.name.isNotEmpty &&
        profile.photos.isNotEmpty &&
        profile.datingGoal != null;
  }

  /// Update profile
  /// Note: To explicitly set a field to null, use the corresponding clear* parameter
  Future<bool> updateProfile({
    String? name,
    String? bio,
    DateTime? birthDate,
    DatingGoal? datingGoal,
    bool clearDatingGoal = false, // Set to true to explicitly clear dating goal
    RelationshipStatus? relationshipStatus,
    bool clearRelationshipStatus = false, // Set to true to explicitly clear relationship status
    ProfileType? profileType,
    Set<ProfileType>? lookingFor,
    int? heightCm,
    int? weightKg,
    String? city,
    String? country,
    String? occupation,
    List<String>? interests,
    List<String>? languages,
    ZodiacSign? zodiacSign,
    bool? isActive,
  }) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return false;

    final updates = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      logInfo('updateProfile: Starting update for user $userId', tag: 'Profile');

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String().split('T').first;
      // Note: gender is determined by profile_type (man/woman/couple)
      if (clearDatingGoal) {
        updates['dating_goal'] = null;
      } else if (datingGoal != null) {
        updates['dating_goal'] = datingGoal.name;
      }
      if (clearRelationshipStatus) {
        updates['relationship_status'] = null;
      } else if (relationshipStatus != null) {
        updates['relationship_status'] = relationshipStatus.name;
      }
      if (profileType != null) {
        updates['profile_type'] = profileType.name;
        // Check if profile type is actually changing and mark the change time
        final currentProfile = state.valueOrNull;
        if (currentProfile != null && currentProfile.profileType != profileType && currentProfile.canChangeProfileType) {
          updates['profile_type_changed_at'] = DateTime.now().toIso8601String();
        }
      }
      if (lookingFor != null) updates['looking_for'] = lookingFor.map((e) => e.name).toList();
      if (heightCm != null) updates['height_cm'] = heightCm;
      if (weightKg != null) updates['weight_kg'] = weightKg;
      if (city != null) updates['city'] = city;
      if (country != null) updates['country'] = country;
      if (occupation != null) updates['occupation'] = occupation;
      if (interests != null) updates['interests'] = interests;
      if (languages != null) updates['languages'] = languages;
      if (zodiacSign != null) updates['zodiac_sign'] = zodiacSign.name;
      if (isActive != null) {
        updates['is_active'] = isActive;
        logInfo('updateProfile: Setting is_active to $isActive', tag: 'Profile');
      }

      logDebug('updateProfile: Sending updates to DB: $updates', tag: 'Profile');
      await _supabase.updateProfile(userId, updates);
      logInfo('updateProfile: DB update successful, reloading profile...', tag: 'Profile');
      await loadProfile();
      logInfo('updateProfile: Profile reloaded successfully', tag: 'Profile');
      return true;
    } catch (e, stackTrace) {
      logError('updateProfile: Failed to update profile', tag: 'Profile', error: e, stackTrace: stackTrace);
      logDebug('updateProfile: Updates that failed: $updates', tag: 'Profile');
      return false;
    }
  }

  /// Create new profile during onboarding
  Future<bool> createProfile({
    required String name,
    required DateTime birthDate,
    required String gender,
    required DatingGoal datingGoal,
    ProfileType? profileType,
    RelationshipStatus? relationshipStatus,
    Set<ProfileType>? lookingFor,
    String? bio,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    List<String>? photos,
  }) async {
    final userId = _supabase.currentUser?.id;
    final email = _supabase.currentUser?.email;
    if (userId == null) {
      print('Error creating profile: userId is null');
      return false;
    }

    try {
      // Determine profile type based on gender if not provided
      final userProfileType = profileType?.name ?? (gender == 'male' ? 'man' : 'woman');

      // Default lookingFor based on user's gender (opposite gender)
      List<String> defaultLookingFor;
      if (lookingFor != null && lookingFor.isNotEmpty) {
        defaultLookingFor = lookingFor.map((e) => e.name).toList();
      } else {
        // Default: if user is man, looking for woman and vice versa
        defaultLookingFor = gender == 'male' ? ['woman'] : ['man'];
      }

      // Build profile data matching the actual database schema
      // Note: is_active defaults to false - user must explicitly activate profile
      final profileData = <String, dynamic>{
        'id': userId,
        'name': name,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'profile_type': userProfileType,
        'looking_for': defaultLookingFor,
        'photos': photos ?? [],
        'interests': [],
        'languages': [],
        'is_online': true,
        'is_verified': false,
        'is_premium': false,
        'is_active': false, // Profile inactive by default, user must activate
        'dating_goal': datingGoal.name,
        'relationship_status': relationshipStatus?.name ?? RelationshipStatus.single.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add optional fields only if they have values
      if (email != null) profileData['email'] = email;
      if (bio != null && bio.isNotEmpty) profileData['bio'] = bio;
      if (city != null && city.isNotEmpty) profileData['city'] = city;
      if (country != null && country.isNotEmpty) profileData['country'] = country;
      if (latitude != null) profileData['latitude'] = latitude;
      if (longitude != null) profileData['longitude'] = longitude;

      print('Creating profile for user: $userId');
      print('Profile data keys: ${profileData.keys.toList()}');

      await _supabase.createOrUpdateProfile(profileData);
      await loadProfile();
      return true;
    } catch (e, stackTrace) {
      print('Error creating profile: $e');
      print('Stack trace: $stackTrace');
      // Show more details about the error
      if (e.toString().contains('column')) {
        print('HINT: A column might be missing in the profiles table. Check Supabase schema.');
      }
      return false;
    }
  }

  /// Add photo to profile
  Future<String?> addPhoto(String fileName, Uint8List bytes) async {
    try {
      // uploadPhoto already adds to profile's photos array
      final url = await _supabase.uploadPhoto(fileName, bytes);
      await loadProfile();
      return url;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Upload avatar
  Future<String?> uploadAvatar(String fileName, Uint8List bytes) async {
    try {
      // uploadAvatar already updates profile's avatar_url
      final url = await _supabase.uploadAvatar(fileName, bytes);
      await loadProfile();
      return url;
    } catch (e) {
      print('Error uploading avatar: $e');
      return null;
    }
  }

  /// Remove photo from profile
  Future<bool> removePhoto(String photoUrl) async {
    try {
      // removePhotoFromProfile handles both profile update and storage deletion
      await _supabase.removePhotoFromProfile(photoUrl);
      await loadProfile();
      return true;
    } catch (e) {
      print('Error removing photo: $e');
      return false;
    }
  }

  /// Update online status
  Future<void> setOnlineStatus(bool isOnline) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return;

    try {
      await _supabase.updateProfile(userId, {
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error updating online status: $e');
    }
  }
}

/// Current profile provider
final currentProfileProvider = StateNotifierProvider<CurrentProfileNotifier, AsyncValue<UserModel?>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return CurrentProfileNotifier(supabase, ref);
});

/// Is profile complete provider
final isProfileCompleteProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return false;
      return profile.name.isNotEmpty &&
          profile.photos.isNotEmpty &&
          profile.datingGoal != null;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Needs onboarding provider - true if user is authenticated but has no profile
final needsOnboardingProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  return profileAsync.when(
    data: (profile) => profile == null,
    loading: () => false,
    error: (_, __) => false,
  );
});

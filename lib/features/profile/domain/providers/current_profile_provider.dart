import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/user_model.dart';

/// Current user profile from Supabase
class CurrentProfileNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final SupabaseService _supabase;
  final Ref _ref;

  CurrentProfileNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadProfile();
    _listenToAuthChanges();
  }

  void _listenToAuthChanges() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.signedIn) {
        loadProfile();
      } else if (data.event == AuthChangeEvent.signedOut) {
        state = const AsyncValue.data(null);
      }
    });
  }

  Future<void> loadProfile() async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getCurrentProfile();
      if (data != null) {
        state = AsyncValue.data(UserModel.fromSupabase(data));
      } else {
        // No profile exists yet - user needs to complete onboarding
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
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
  Future<bool> updateProfile({
    String? name,
    String? bio,
    DateTime? birthDate,
    String? gender,
    DatingGoal? datingGoal,
    RelationshipStatus? relationshipStatus,
    ProfileType? profileType,
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

    try {
      final updates = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) updates['name'] = name;
      if (bio != null) updates['bio'] = bio;
      if (birthDate != null) updates['birth_date'] = birthDate.toIso8601String().split('T').first;
      if (gender != null) updates['gender'] = gender;
      if (datingGoal != null) updates['dating_goal'] = datingGoal.name;
      if (relationshipStatus != null) updates['relationship_status'] = relationshipStatus.name;
      if (profileType != null) updates['profile_type'] = profileType.name;
      if (heightCm != null) updates['height_cm'] = heightCm;
      if (weightKg != null) updates['weight_kg'] = weightKg;
      if (city != null) updates['city'] = city;
      if (country != null) updates['country'] = country;
      if (occupation != null) updates['occupation'] = occupation;
      if (interests != null) updates['interests'] = interests;
      if (languages != null) updates['languages'] = languages;
      if (zodiacSign != null) updates['zodiac_sign'] = zodiacSign.name;
      if (isActive != null) updates['is_active'] = isActive;

      await _supabase.updateProfile(userId, updates);
      await loadProfile();
      return true;
    } catch (e) {
      print('Error updating profile: $e');
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
    String? bio,
    String? city,
    String? country,
  }) async {
    final userId = _supabase.currentUser?.id;
    final email = _supabase.currentUser?.email;
    if (userId == null) return false;

    try {
      final profileData = {
        'id': userId,
        'email': email,
        'name': name,
        'birth_date': birthDate.toIso8601String().split('T').first,
        'gender': gender,
        'dating_goal': datingGoal.name,
        'relationship_status': relationshipStatus?.name ?? RelationshipStatus.single.name,
        'profile_type': profileType?.name ?? (gender == 'male' ? 'man' : 'woman'),
        'bio': bio,
        'city': city,
        'country': country,
        'photos': <String>[],
        'interests': <String>[],
        'languages': <String>[],
        'is_online': true,
        'is_verified': false,
        'is_premium': false,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.createProfile(profileData);
      await loadProfile();
      return true;
    } catch (e) {
      print('Error creating profile: $e');
      return false;
    }
  }

  /// Add photo to profile
  Future<String?> addPhoto(String fileName, List<int> bytes) async {
    try {
      final url = await _supabase.uploadPhoto(fileName, bytes);

      // Update profile with new photo
      final currentProfile = state.valueOrNull;
      if (currentProfile != null) {
        final newPhotos = [...currentProfile.photos, url];
        final userId = _supabase.currentUser?.id;
        if (userId != null) {
          await _supabase.updateProfile(userId, {'photos': newPhotos});
          await loadProfile();
        }
      }
      return url;
    } catch (e) {
      print('Error uploading photo: $e');
      return null;
    }
  }

  /// Remove photo from profile
  Future<bool> removePhoto(String photoUrl) async {
    try {
      final currentProfile = state.valueOrNull;
      if (currentProfile != null) {
        final newPhotos = currentProfile.photos.where((p) => p != photoUrl).toList();
        final userId = _supabase.currentUser?.id;
        if (userId != null) {
          await _supabase.updateProfile(userId, {'photos': newPhotos});
          await loadProfile();
        }
      }
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/ai_profile_model.dart';
import '../../data/ai_profile_generator.dart';
import '../../../profile/domain/models/user_model.dart';

/// AI Profiles state notifier - loads from database with 24h rotation
class AIProfilesNotifier extends StateNotifier<AsyncValue<List<AIProfileModel>>> {
  final SupabaseService _supabase;
  final Ref _ref;

  static const int _targetProfileCount = 15; // Target number of active profiles

  AIProfilesNotifier(this._supabase, this._ref) : super(const AsyncValue.loading()) {
    loadProfiles();
  }

  /// Load profiles from database, generate new ones if needed
  Future<void> loadProfiles() async {
    state = const AsyncValue.loading();

    try {
      // First, clean up expired profiles
      final deletedCount = await _supabase.deleteExpiredAIProfiles();
      if (deletedCount > 0) {
        print('Deleted $deletedCount expired AI profiles');
      }

      // Load active profiles from database
      final data = await _supabase.getAIProfiles();
      var profiles = data.map((json) => AIProfileModel.fromJson(json)).toList();

      // If not enough profiles, generate more
      if (profiles.length < _targetProfileCount) {
        final needed = _targetProfileCount - profiles.length;
        print('Generating $needed new AI profiles');
        await _generateAndSaveProfiles(needed);

        // Reload after generation
        final newData = await _supabase.getAIProfiles();
        profiles = newData.map((json) => AIProfileModel.fromJson(json)).toList();
      }

      state = AsyncValue.data(profiles);
    } catch (e, st) {
      print('Error loading AI profiles: $e');
      // Fall back to local generation if database fails
      state = AsyncValue.data(_generateLocalProfiles());
    }
  }

  /// Generate and save new profiles to database
  Future<void> _generateAndSaveProfiles(int count) async {
    final profiles = AIProfileGenerator.generateBatch(count);

    for (final profile in profiles) {
      try {
        await _supabase.createAIProfile(profile.toSupabase());
      } catch (e) {
        print('Error saving AI profile: $e');
      }
    }
  }

  /// Generate local profiles as fallback
  List<AIProfileModel> _generateLocalProfiles() {
    return AIProfileGenerator.generateBatch(_targetProfileCount);
  }

  /// Refresh profiles from database
  Future<void> refresh() async {
    await loadProfiles();
  }

  /// Force regenerate all profiles (admin function)
  Future<void> forceRegenerate() async {
    state = const AsyncValue.loading();

    try {
      // Delete all existing AI profiles
      final existing = await _supabase.getAIProfilesAdmin();
      for (final profile in existing) {
        await _supabase.deleteAIProfile(profile['id'] as String);
      }

      // Generate new ones
      await _generateAndSaveProfiles(_targetProfileCount);

      // Reload
      await loadProfiles();
    } catch (e) {
      print('Error force regenerating profiles: $e');
      state = AsyncValue.data(_generateLocalProfiles());
    }
  }

  /// Get profile by ID
  AIProfileModel? getProfileById(String id) {
    return state.valueOrNull?.firstWhere(
      (p) => p.id == id,
      orElse: () => throw Exception('Profile not found'),
    );
  }

  /// Update profile stats after interaction
  Future<void> incrementMessageCount(String profileId) async {
    try {
      await _supabase.incrementAIMessageCount(profileId);
    } catch (e) {
      print('Error incrementing message count: $e');
    }
  }
}

/// AI Profiles provider
final aiProfilesProvider = StateNotifierProvider<AIProfilesNotifier, AsyncValue<List<AIProfileModel>>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AIProfilesNotifier(supabase, ref);
});

/// AI Profiles as UserModel list for display in feed
/// Applies current filters to AI profiles
final aiProfilesAsUsersProvider = Provider<List<UserModel>>((ref) {
  final aiProfilesAsync = ref.watch(aiProfilesProvider);

  final profiles = aiProfilesAsync.valueOrNull;

  if (profiles != null && profiles.isNotEmpty) {
    return profiles.map((p) => p.toUserModel()).toList();
  }

  // Return generated profiles as fallback
  return AIProfileGenerator.generateBatch(10).map((p) => p.toUserModel()).toList();
});

/// Single AI profile provider by ID
final aiProfileByIdProvider = Provider.family<AIProfileModel?, String>((ref, id) {
  final profiles = ref.watch(aiProfilesProvider).valueOrNull;
  if (profiles == null) return null;

  try {
    return profiles.firstWhere((p) => p.id == id);
  } catch (_) {
    return null;
  }
});

/// AI profiles count provider (for admin dashboard)
final aiProfilesCountProvider = Provider<int>((ref) {
  return ref.watch(aiProfilesProvider).valueOrNull?.length ?? 0;
});

/// Expired AI profiles count (for admin)
final expiredAIProfilesCountProvider = FutureProvider<int>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  final all = await supabase.getAIProfilesAdmin();
  final now = DateTime.now();
  return all.where((p) {
    final expiresAt = DateTime.tryParse(p['expires_at'] as String? ?? '');
    return expiresAt != null && expiresAt.isBefore(now);
  }).length;
});

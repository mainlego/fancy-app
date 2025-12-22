import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../models/filter_model.dart';

export '../models/filter_model.dart';

/// Async filter provider that properly loads from database
final filterAsyncProvider = AsyncNotifierProvider<FilterAsyncNotifier, FilterModel>(() {
  return FilterAsyncNotifier();
});

class FilterAsyncNotifier extends AsyncNotifier<FilterModel> {
  @override
  Future<FilterModel> build() async {
    final supabase = ref.watch(supabaseServiceProvider);

    try {
      final data = await supabase.getFilters();
      if (data != null && data['filters'] != null) {
        final filtersJson = data['filters'] as Map<String, dynamic>;
        return FilterModel.fromJson(filtersJson);
      }
    } catch (e) {
      print('Error loading filters: $e');
    }

    return FilterModel.defaultFilters;
  }

  /// Save filters to database
  Future<void> _saveFilters(FilterModel filters) async {
    final supabase = ref.read(supabaseServiceProvider);
    try {
      await supabase.saveFilters(filters.toJson());
    } catch (e) {
      print('Error saving filters: $e');
    }
  }

  /// Update filters and save to database
  Future<void> updateFilters(FilterModel filters) async {
    state = AsyncValue.data(filters);
    await _saveFilters(filters);
  }

  /// Update distance (max distance only for backward compatibility)
  Future<void> updateDistance(int distanceKm) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(maxDistanceKm: distanceKm);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Update distance range
  Future<void> updateDistanceRange(int minDistanceKm, int maxDistanceKm) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(minDistanceKm: minDistanceKm, maxDistanceKm: maxDistanceKm);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Update age range
  Future<void> updateAgeRange(int minAge, int maxAge) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(minAge: minAge, maxAge: maxAge);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle dating goal
  Future<void> toggleDatingGoal(DatingGoal goal) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final newGoals = Set<DatingGoal>.from(current.datingGoals);
    if (newGoals.contains(goal)) {
      newGoals.remove(goal);
    } else {
      newGoals.add(goal);
    }
    final updated = current.copyWith(datingGoals: newGoals);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle relationship status
  Future<void> toggleRelationshipStatus(RelationshipStatus status) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final newStatuses = Set<RelationshipStatus>.from(current.relationshipStatuses);
    if (newStatuses.contains(status)) {
      newStatuses.remove(status);
    } else {
      newStatuses.add(status);
    }
    final updated = current.copyWith(relationshipStatuses: newStatuses);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle profile type (looking for)
  Future<void> toggleLookingFor(ProfileType type) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final newTypes = Set<ProfileType>.from(current.lookingFor);
    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }
    final updated = current.copyWith(lookingFor: newTypes);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle online only
  Future<void> toggleOnlineOnly() async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(onlineOnly: !current.onlineOnly);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle with photo
  Future<void> toggleWithPhoto() async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(withPhoto: !current.withPhoto);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle verified only
  Future<void> toggleVerifiedOnly() async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(verifiedOnly: !current.verifiedOnly);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Update height range
  Future<void> updateHeightRange(int? minHeight, int? maxHeight) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(minHeight: minHeight, maxHeight: maxHeight);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Update weight range
  Future<void> updateWeightRange(int? minWeight, int? maxWeight) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final updated = current.copyWith(minWeight: minWeight, maxWeight: maxWeight);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle zodiac sign
  Future<void> toggleZodiacSign(ZodiacSign sign) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final newSigns = Set<ZodiacSign>.from(current.zodiacSigns);
    if (newSigns.contains(sign)) {
      newSigns.remove(sign);
    } else {
      newSigns.add(sign);
    }
    final updated = current.copyWith(zodiacSigns: newSigns);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Toggle language
  Future<void> toggleLanguage(String language) async {
    final current = state.valueOrNull ?? FilterModel.defaultFilters;
    final newLanguages = Set<String>.from(current.languages);
    if (newLanguages.contains(language)) {
      newLanguages.remove(language);
    } else {
      newLanguages.add(language);
    }
    final updated = current.copyWith(languages: newLanguages);
    state = AsyncValue.data(updated);
    await _saveFilters(updated);
  }

  /// Reset to default filters
  Future<void> resetFilters() async {
    state = AsyncValue.data(FilterModel.defaultFilters);
    await _saveFilters(FilterModel.defaultFilters);
  }

  /// Refresh filters from database
  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

/// Sync provider for components that need immediate access
final filterProvider = Provider<FilterModel>((ref) {
  final asyncFilter = ref.watch(filterAsyncProvider);
  return asyncFilter.valueOrNull ?? FilterModel.defaultFilters;
});

/// Legacy provider for backwards compatibility - now just wraps filterAsyncProvider
final filterNotifierProvider = Provider<FilterModel>((ref) {
  final asyncFilter = ref.watch(filterAsyncProvider);
  return asyncFilter.valueOrNull ?? FilterModel.defaultFilters;
});

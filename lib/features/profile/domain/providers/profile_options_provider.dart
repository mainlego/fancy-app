import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/data/profile_data.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/services/debug_logger.dart';

/// State for profile options
class ProfileOptionsState {
  final List<Interest> interests;
  final List<Fantasy> fantasies;
  final List<Occupation> occupations;
  final bool isLoading;
  final String? error;

  const ProfileOptionsState({
    this.interests = const [],
    this.fantasies = const [],
    this.occupations = const [],
    this.isLoading = false,
    this.error,
  });

  ProfileOptionsState copyWith({
    List<Interest>? interests,
    List<Fantasy>? fantasies,
    List<Occupation>? occupations,
    bool? isLoading,
    String? error,
  }) {
    return ProfileOptionsState(
      interests: interests ?? this.interests,
      fantasies: fantasies ?? this.fantasies,
      occupations: occupations ?? this.occupations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  /// Get interests grouped by category
  Map<String, List<Interest>> get interestsByCategory {
    final map = <String, List<Interest>>{};
    for (final interest in interests) {
      map.putIfAbsent(interest.category, () => []).add(interest);
    }
    return map;
  }

  /// Get fantasies grouped by category
  Map<String, List<Fantasy>> get fantasiesByCategory {
    final map = <String, List<Fantasy>>{};
    for (final fantasy in fantasies) {
      final cat = fantasy.category ?? 'Other';
      map.putIfAbsent(cat, () => []).add(fantasy);
    }
    return map;
  }

  /// Get occupations grouped by category
  Map<String, List<Occupation>> get occupationsByCategory {
    final map = <String, List<Occupation>>{};
    for (final occupation in occupations) {
      final cat = occupation.category ?? 'Other';
      map.putIfAbsent(cat, () => []).add(occupation);
    }
    return map;
  }
}

/// Provider for profile options (interests, fantasies, occupations)
class ProfileOptionsNotifier extends StateNotifier<ProfileOptionsState> {
  final SupabaseService _supabase;

  ProfileOptionsNotifier(this._supabase) : super(const ProfileOptionsState()) {
    loadAll();
  }

  /// Load all profile options from database
  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    logInfo('ProfileOptions: Loading all options...', tag: 'Profile');

    try {
      final results = await Future.wait([
        _supabase.getInterests(),
        _supabase.getFantasies(),
        _supabase.getOccupations(),
      ]);

      logInfo('ProfileOptions: Loaded ${(results[0] as List).length} interests, ${(results[1] as List).length} fantasies, ${(results[2] as List).length} occupations', tag: 'Profile');
      state = state.copyWith(
        interests: results[0] as List<Interest>,
        fantasies: results[1] as List<Fantasy>,
        occupations: results[2] as List<Occupation>,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logError('ProfileOptions: Failed to load', tag: 'Profile', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add custom interest
  Future<Interest?> addCustomInterest(String name) async {
    try {
      final interest = await _supabase.addCustomInterest(name);
      if (interest != null) {
        state = state.copyWith(
          interests: [...state.interests, interest],
        );
      }
      return interest;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Add custom fantasy
  Future<Fantasy?> addCustomFantasy(String name) async {
    try {
      final fantasy = await _supabase.addCustomFantasy(name);
      if (fantasy != null) {
        state = state.copyWith(
          fantasies: [...state.fantasies, fantasy],
        );
      }
      return fantasy;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Add custom occupation
  Future<Occupation?> addCustomOccupation(String name) async {
    try {
      final occupation = await _supabase.addCustomOccupation(name);
      if (occupation != null) {
        state = state.copyWith(
          occupations: [...state.occupations, occupation],
        );
      }
      return occupation;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  /// Search interests by name
  List<Interest> searchInterests(String query) {
    if (query.isEmpty) return state.interests;
    final lowerQuery = query.toLowerCase();
    return state.interests.where((i) =>
      i.name.toLowerCase().contains(lowerQuery) ||
      (i.nameRu?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Search fantasies by name
  List<Fantasy> searchFantasies(String query) {
    if (query.isEmpty) return state.fantasies;
    final lowerQuery = query.toLowerCase();
    return state.fantasies.where((f) =>
      f.name.toLowerCase().contains(lowerQuery) ||
      (f.nameRu?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  /// Search occupations by name
  List<Occupation> searchOccupations(String query) {
    if (query.isEmpty) return state.occupations;
    final lowerQuery = query.toLowerCase();
    return state.occupations.where((o) =>
      o.name.toLowerCase().contains(lowerQuery) ||
      (o.nameRu?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }
}

/// Profile options provider
final profileOptionsProvider =
    StateNotifierProvider<ProfileOptionsNotifier, ProfileOptionsState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ProfileOptionsNotifier(supabase);
});

/// State for user's selected interests/fantasies
class UserSelectionsState {
  final Set<String> selectedInterestIds;
  final Set<String> selectedFantasyIds;
  final String? selectedOccupationId;
  final bool isLoading;
  final String? error;

  const UserSelectionsState({
    this.selectedInterestIds = const {},
    this.selectedFantasyIds = const {},
    this.selectedOccupationId,
    this.isLoading = false,
    this.error,
  });

  UserSelectionsState copyWith({
    Set<String>? selectedInterestIds,
    Set<String>? selectedFantasyIds,
    String? selectedOccupationId,
    bool clearOccupation = false,
    bool? isLoading,
    String? error,
  }) {
    return UserSelectionsState(
      selectedInterestIds: selectedInterestIds ?? this.selectedInterestIds,
      selectedFantasyIds: selectedFantasyIds ?? this.selectedFantasyIds,
      selectedOccupationId: clearOccupation ? null : (selectedOccupationId ?? this.selectedOccupationId),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for user's selections
class UserSelectionsNotifier extends StateNotifier<UserSelectionsState> {
  final SupabaseService _supabase;

  UserSelectionsNotifier(this._supabase) : super(const UserSelectionsState()) {
    loadUserSelections();
  }

  /// Load user's current selections
  Future<void> loadUserSelections() async {
    state = state.copyWith(isLoading: true, error: null);
    logInfo('UserSelections: Loading user selections...', tag: 'Profile');

    try {
      final results = await Future.wait([
        _supabase.getUserInterestIds(),
        _supabase.getUserFantasyIds(),
        _supabase.getUserOccupationId(),
      ]);

      logInfo('UserSelections: Loaded ${(results[0] as List).length} interests, ${(results[1] as List).length} fantasies, occupation=${results[2]}', tag: 'Profile');
      state = state.copyWith(
        selectedInterestIds: (results[0] as List<String>).toSet(),
        selectedFantasyIds: (results[1] as List<String>).toSet(),
        selectedOccupationId: results[2] as String?,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      logError('UserSelections: Failed to load', tag: 'Profile', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Toggle interest selection
  void toggleInterest(String interestId) {
    final newSet = Set<String>.from(state.selectedInterestIds);
    if (newSet.contains(interestId)) {
      newSet.remove(interestId);
    } else if (newSet.length < 20) {
      newSet.add(interestId);
    }
    state = state.copyWith(selectedInterestIds: newSet);
  }

  /// Toggle fantasy selection
  void toggleFantasy(String fantasyId) {
    final newSet = Set<String>.from(state.selectedFantasyIds);
    if (newSet.contains(fantasyId)) {
      newSet.remove(fantasyId);
    } else if (newSet.length < 15) {
      newSet.add(fantasyId);
    }
    state = state.copyWith(selectedFantasyIds: newSet);
  }

  /// Set occupation
  void setOccupation(String? occupationId) {
    state = state.copyWith(
      selectedOccupationId: occupationId,
      clearOccupation: occupationId == null,
    );
  }

  /// Save selections to database
  Future<bool> saveSelections() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      logInfo('saveSelections: Starting save...', tag: 'Profile');
      logDebug('saveSelections: interests=${state.selectedInterestIds.length}, fantasies=${state.selectedFantasyIds.length}, occupation=${state.selectedOccupationId}', tag: 'Profile');

      await _supabase.updateUserSelections(
        interestIds: state.selectedInterestIds.toList(),
        fantasyIds: state.selectedFantasyIds.toList(),
        occupationId: state.selectedOccupationId,
      );

      logInfo('saveSelections: Saved successfully', tag: 'Profile');
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e, stackTrace) {
      logError('saveSelections: Failed to save', tag: 'Profile', error: e, stackTrace: stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

/// User selections provider
final userSelectionsProvider =
    StateNotifierProvider<UserSelectionsNotifier, UserSelectionsState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return UserSelectionsNotifier(supabase);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/models/user_model.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../models/subscription_model.dart';

/// Subscription notifier for managing user subscription state
class SubscriptionNotifier extends StateNotifier<AsyncValue<SubscriptionModel?>> {
  final SupabaseService _supabase;

  SubscriptionNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadSubscription();
  }

  /// Load subscription from database
  Future<void> loadSubscription() async {
    state = const AsyncValue.loading();
    try {
      final data = await _supabase.getSubscription();
      if (data != null) {
        state = AsyncValue.data(SubscriptionModel.fromJson(data));
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Subscribe to a plan
  Future<bool> subscribe(PremiumPlan plan, {String? transactionId, int referralMonths = 0}) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return false;

    try {
      final now = DateTime.now();
      final baseDuration = Duration(days: plan.durationInDays);
      final bonusDuration = Duration(days: referralMonths * 30);

      await _supabase.saveSubscription(
        planType: plan.name,
        startDate: now,
        endDate: now.add(baseDuration).add(bonusDuration),
        isActive: true,
        transactionId: transactionId,
        isTrialUsed: plan.isTrial,
        referralMonths: referralMonths,
      );

      await loadSubscription();
      return true;
    } catch (e) {
      print('Error subscribing: $e');
      return false;
    }
  }

  /// Start free trial (7 days)
  Future<bool> startFreeTrial() async {
    // Check if trial was already used
    final currentSub = state.valueOrNull;
    if (currentSub?.isTrialUsed == true) {
      return false;
    }
    return subscribe(PremiumPlan.trial);
  }

  /// Add referral bonus month
  Future<bool> addReferralMonth() async {
    final currentSub = state.valueOrNull;
    if (currentSub == null || !currentSub.isValid) return false;

    try {
      final newEndDate = currentSub.endDate.add(const Duration(days: 30));
      await _supabase.updateSubscriptionEndDate(newEndDate);
      await loadSubscription();
      return true;
    } catch (e) {
      print('Error adding referral month: $e');
      return false;
    }
  }

  /// Cancel subscription
  Future<bool> cancelSubscription() async {
    try {
      await _supabase.cancelSubscription();
      await loadSubscription();
      return true;
    } catch (e) {
      print('Error cancelling subscription: $e');
      return false;
    }
  }

  /// Refresh subscription status
  Future<void> refresh() async {
    await loadSubscription();
  }
}

/// Subscription provider
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, AsyncValue<SubscriptionModel?>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return SubscriptionNotifier(supabase);
});

/// Check if user's profile type requires premium (men and couples/pairs)
final requiresPremiumProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return true; // Default to requiring premium
      // Women are free, men and all pairs require premium
      return profile.profileType == ProfileType.man ||
             profile.profileType == ProfileType.manAndWoman ||
             profile.profileType == ProfileType.manPair ||
             profile.profileType == ProfileType.womanPair;
    },
    loading: () => true,
    error: (_, __) => true,
  );
});

/// Check if user is female (free access)
final isFemaleUserProvider = Provider<bool>((ref) {
  final profileAsync = ref.watch(currentProfileProvider);
  return profileAsync.when(
    data: (profile) {
      if (profile == null) return false;
      return profile.profileType == ProfileType.woman;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Is premium provider - checks subscription OR female gender
final isPremiumProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  final isFemale = ref.watch(isFemaleUserProvider);

  // Women get free premium access
  if (isFemale) return true;

  // Others need active subscription
  return subscriptionAsync.when(
    data: (subscription) => subscription?.isValid ?? false,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Can use feature provider
final canUseFeatureProvider = Provider.family<bool, PremiumFeature>((ref, feature) {
  final isPremium = ref.watch(isPremiumProvider);

  // Some features are available to everyone
  switch (feature) {
    case PremiumFeature.noAds:
    case PremiumFeature.unlimitedLikes:
    case PremiumFeature.seeWhoLikesYou:
    case PremiumFeature.advancedFilters:
    case PremiumFeature.hiddenAlbums:
    case PremiumFeature.profileVideo:
    case PremiumFeature.incognitoMode:
    case PremiumFeature.superLikes:
    case PremiumFeature.boostProfile:
      return isPremium;
  }
});

/// Trial available provider - check if user can start trial
final trialAvailableProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  final requiresPremium = ref.watch(requiresPremiumProvider);

  if (!requiresPremium) return false; // Women don't need trial

  return subscriptionAsync.when(
    data: (subscription) {
      // No subscription yet, trial available
      if (subscription == null) return true;
      // Check if trial was already used
      return !subscription.isTrialUsed;
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Current subscription plan provider
final currentPlanProvider = Provider<PremiumPlan?>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  return subscriptionAsync.when(
    data: (subscription) => subscription?.planType,
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Days remaining in subscription
final subscriptionDaysRemainingProvider = Provider<int>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  return subscriptionAsync.when(
    data: (subscription) => subscription?.daysRemaining ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

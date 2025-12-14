import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
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
  Future<bool> subscribe(PremiumPlan plan, {String? transactionId}) async {
    final userId = _supabase.currentUser?.id;
    if (userId == null) return false;

    try {
      final now = DateTime.now();
      await _supabase.saveSubscription(
        planType: plan.name,
        startDate: now,
        endDate: now.add(Duration(days: plan.durationInDays)),
        isActive: true,
        transactionId: transactionId,
      );

      await loadSubscription();
      return true;
    } catch (e) {
      print('Error subscribing: $e');
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

/// Is premium provider - convenient accessor for premium status
final isPremiumProvider = Provider<bool>((ref) {
  final subscriptionAsync = ref.watch(subscriptionProvider);
  return subscriptionAsync.when(
    data: (subscription) => subscription?.isValid ?? false,
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

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/referral_model.dart';

/// Referral stats provider
final referralStatsProvider = FutureProvider<ReferralStats>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getReferralStats();
});

/// User's referrals list provider
final userReferralsProvider = FutureProvider<List<ReferralModel>>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getUserReferrals();
});

/// Referral code provider
final referralCodeProvider = FutureProvider<String?>((ref) async {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.getOrCreateReferralCode();
});

/// Referral notifier for actions
class ReferralNotifier extends StateNotifier<AsyncValue<ReferralStats>> {
  final SupabaseService _supabase;

  ReferralNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = const AsyncValue.loading();
    try {
      final stats = await _supabase.getReferralStats();
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> getOrCreateCode() async {
    try {
      return await _supabase.getOrCreateReferralCode();
    } catch (e) {
      return null;
    }
  }

  Future<bool> applyReferralCode(String code) async {
    try {
      return await _supabase.applyReferralCode(code);
    } catch (e) {
      return false;
    }
  }

  void refresh() => loadStats();
}

/// Referral notifier provider
final referralNotifierProvider =
    StateNotifierProvider<ReferralNotifier, AsyncValue<ReferralStats>>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return ReferralNotifier(supabase);
});

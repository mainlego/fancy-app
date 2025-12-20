import 'package:equatable/equatable.dart';

/// Referral status
enum ReferralStatus {
  pending,    // User registered but hasn't subscribed yet
  subscribed, // Referred user purchased subscription
  rewarded,   // Referrer received their reward
  expired;    // Referral expired (no subscription within time limit)

  static ReferralStatus fromString(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ReferralStatus.pending,
    );
  }
}

/// Model for a single referral
class ReferralModel extends Equatable {
  final String id;
  final String referrerId;
  final String referredId;
  final String referralCode;
  final ReferralStatus status;
  final DateTime? subscribedAt;
  final DateTime? rewardedAt;
  final DateTime createdAt;

  // Joined data
  final String? referredUserName;
  final String? referredUserAvatar;

  const ReferralModel({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.referralCode,
    required this.status,
    this.subscribedAt,
    this.rewardedAt,
    required this.createdAt,
    this.referredUserName,
    this.referredUserAvatar,
  });

  factory ReferralModel.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] as Map<String, dynamic>?;

    return ReferralModel(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referredId: json['referred_id'] as String,
      referralCode: json['referral_code'] as String,
      status: ReferralStatus.fromString(json['status'] as String? ?? 'pending'),
      subscribedAt: json['subscribed_at'] != null
          ? DateTime.parse(json['subscribed_at'] as String)
          : null,
      rewardedAt: json['rewarded_at'] != null
          ? DateTime.parse(json['rewarded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      referredUserName: profiles?['name'] as String?,
      referredUserAvatar: profiles?['avatar_url'] as String?,
    );
  }

  @override
  List<Object?> get props => [
        id,
        referrerId,
        referredId,
        referralCode,
        status,
        subscribedAt,
        rewardedAt,
        createdAt,
      ];
}

/// Model for referral statistics
class ReferralStats extends Equatable {
  final String? referralCode;
  final int totalReferrals;
  final int successfulReferrals;
  final int pendingReferrals;
  final int totalRewardDaysEarned;
  final int pendingRewardDays;

  const ReferralStats({
    this.referralCode,
    this.totalReferrals = 0,
    this.successfulReferrals = 0,
    this.pendingReferrals = 0,
    this.totalRewardDaysEarned = 0,
    this.pendingRewardDays = 0,
  });

  factory ReferralStats.fromJson(Map<String, dynamic> json) {
    return ReferralStats(
      referralCode: json['referral_code'] as String?,
      totalReferrals: json['total_referrals'] as int? ?? 0,
      successfulReferrals: json['successful_referrals'] as int? ?? 0,
      pendingReferrals: json['pending_referrals'] as int? ?? 0,
      totalRewardDaysEarned: json['total_reward_days_earned'] as int? ?? 0,
      pendingRewardDays: json['pending_reward_days'] as int? ?? 0,
    );
  }

  /// Total months earned (rounded down)
  int get totalMonthsEarned => totalRewardDaysEarned ~/ 30;

  /// Check if user has earned any rewards
  bool get hasEarnedRewards => totalRewardDaysEarned > 0;

  @override
  List<Object?> get props => [
        referralCode,
        totalReferrals,
        successfulReferrals,
        pendingReferrals,
        totalRewardDaysEarned,
        pendingRewardDays,
      ];
}

/// Model for referral reward
class ReferralReward extends Equatable {
  final String id;
  final String userId;
  final String referralId;
  final String rewardType;
  final int rewardDays;
  final DateTime? appliedAt;
  final DateTime? expiresAt;
  final String status;
  final DateTime createdAt;

  const ReferralReward({
    required this.id,
    required this.userId,
    required this.referralId,
    required this.rewardType,
    required this.rewardDays,
    this.appliedAt,
    this.expiresAt,
    required this.status,
    required this.createdAt,
  });

  factory ReferralReward.fromJson(Map<String, dynamic> json) {
    return ReferralReward(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      referralId: json['referral_id'] as String,
      rewardType: json['reward_type'] as String? ?? 'premium_month',
      rewardDays: json['reward_days'] as int? ?? 30,
      appliedAt: json['applied_at'] != null
          ? DateTime.parse(json['applied_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
      status: json['status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApplied => status == 'applied';
  bool get isExpired => status == 'expired';

  @override
  List<Object?> get props => [
        id,
        userId,
        referralId,
        rewardType,
        rewardDays,
        appliedAt,
        expiresAt,
        status,
        createdAt,
      ];
}

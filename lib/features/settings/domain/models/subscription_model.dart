import 'package:equatable/equatable.dart';

/// Premium plan types for men and couples
enum PremiumPlan {
  trial,    // 7 days free trial
  weekly,   // $5/week
  monthly,  // $10/month
  yearly;   // $25/year

  String get displayName => switch (this) {
    trial => '7-Day Trial',
    weekly => '1 Week',
    monthly => '1 Month',
    yearly => '12 Months',
  };

  String get price => switch (this) {
    trial => 'FREE',
    weekly => '\$5',
    monthly => '\$10',
    yearly => '\$25',
  };

  String get pricePerWeek => switch (this) {
    trial => '\$0/week',
    weekly => '\$5/week',
    monthly => '\$2.50/week',
    yearly => '\$0.48/week',
  };

  int get durationInDays => switch (this) {
    trial => 7,
    weekly => 7,
    monthly => 30,
    yearly => 365,
  };

  /// Product ID for in-app purchases
  String get productId => switch (this) {
    trial => 'fancy_premium_trial',
    weekly => 'fancy_premium_weekly',
    monthly => 'fancy_premium_monthly',
    yearly => 'fancy_premium_yearly',
  };

  bool get isTrial => this == trial;
  bool get isPaid => this != trial;
}

/// In-app purchase item types
enum InAppPurchaseItem {
  // Super likes
  superLike1,     // 1 super like - $1
  superLike10,    // 10 super likes - $5 ($0.5 each)
  superLike50,    // 50 super likes - $20 ($0.4 each)

  // Invisible mode
  invisible7,     // 7 days - $5
  invisible30;    // 30 days - $20

  String get displayName => switch (this) {
    superLike1 => '1 Super Like',
    superLike10 => '10 Super Likes',
    superLike50 => '50 Super Likes',
    invisible7 => 'Invisible Mode (7 days)',
    invisible30 => 'Invisible Mode (30 days)',
  };

  String get price => switch (this) {
    superLike1 => '\$1',
    superLike10 => '\$5',
    superLike50 => '\$20',
    invisible7 => '\$5',
    invisible30 => '\$20',
  };

  String? get savings => switch (this) {
    superLike1 => null,
    superLike10 => 'Save 50%',
    superLike50 => 'Save 60%',
    invisible7 => null,
    invisible30 => 'Save 43%',
  };

  int get quantity => switch (this) {
    superLike1 => 1,
    superLike10 => 10,
    superLike50 => 50,
    invisible7 => 7,
    invisible30 => 30,
  };

  /// Product ID for in-app purchases
  String get productId => switch (this) {
    superLike1 => 'fancy_superlike_1',
    superLike10 => 'fancy_superlike_10',
    superLike50 => 'fancy_superlike_50',
    invisible7 => 'fancy_invisible_7',
    invisible30 => 'fancy_invisible_30',
  };

  bool get isSuperLike =>
    this == superLike1 || this == superLike10 || this == superLike50;

  bool get isInvisibleMode =>
    this == invisible7 || this == invisible30;
}

/// Premium features that require subscription
enum PremiumFeature {
  unlimitedLikes,
  seeWhoLikesYou,
  advancedFilters,      // Height, weight, age, zodiac, language
  hiddenAlbums,
  profileVideo,
  incognitoMode,
  noAds,
  superLikes,
  boostProfile,
}

/// Subscription model for user premium status
class SubscriptionModel extends Equatable {
  final String id;
  final String userId;
  final PremiumPlan planType;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String? transactionId;
  final bool isTrialUsed;        // Has user used their free trial?
  final int referralMonths;      // Bonus months from referrals
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.planType,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    this.transactionId,
    this.isTrialUsed = false,
    this.referralMonths = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Check if subscription is valid (active and not expired)
  bool get isValid => isActive && DateTime.now().isBefore(endDate);

  /// Days remaining in subscription
  int get daysRemaining {
    if (!isValid) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }

  /// Create from Supabase JSON
  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String,
      planType: PremiumPlan.values.byName(json['plan_type'] as String? ?? 'monthly'),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      isActive: json['is_active'] as bool? ?? false,
      transactionId: json['transaction_id'] as String?,
      isTrialUsed: json['is_trial_used'] as bool? ?? false,
      referralMonths: json['referral_months'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  /// Convert to JSON for Supabase
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'plan_type': planType.name,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'is_active': isActive,
      'transaction_id': transactionId,
      'is_trial_used': isTrialUsed,
      'referral_months': referralMonths,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a new subscription for a user
  factory SubscriptionModel.create({
    required String userId,
    required PremiumPlan planType,
    String? transactionId,
    int referralMonths = 0,
  }) {
    final now = DateTime.now();
    final baseDuration = Duration(days: planType.durationInDays);
    final bonusDuration = Duration(days: referralMonths * 30);

    return SubscriptionModel(
      id: '',
      userId: userId,
      planType: planType,
      startDate: now,
      endDate: now.add(baseDuration).add(bonusDuration),
      isActive: true,
      transactionId: transactionId,
      isTrialUsed: planType.isTrial,
      referralMonths: referralMonths,
      createdAt: now,
      updatedAt: now,
    );
  }

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    PremiumPlan? planType,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? transactionId,
    bool? isTrialUsed,
    int? referralMonths,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      planType: planType ?? this.planType,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      transactionId: transactionId ?? this.transactionId,
      isTrialUsed: isTrialUsed ?? this.isTrialUsed,
      referralMonths: referralMonths ?? this.referralMonths,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    planType,
    startDate,
    endDate,
    isActive,
    transactionId,
    isTrialUsed,
    referralMonths,
    createdAt,
    updatedAt,
  ];
}

/// User's in-app purchases balance
class UserPurchasesModel extends Equatable {
  final String userId;
  final int superLikesBalance;
  final DateTime? invisibleModeUntil;
  final DateTime? updatedAt;

  const UserPurchasesModel({
    required this.userId,
    this.superLikesBalance = 0,
    this.invisibleModeUntil,
    this.updatedAt,
  });

  bool get hasInvisibleMode =>
    invisibleModeUntil != null && DateTime.now().isBefore(invisibleModeUntil!);

  int get invisibleDaysRemaining {
    if (!hasInvisibleMode) return 0;
    return invisibleModeUntil!.difference(DateTime.now()).inDays;
  }

  factory UserPurchasesModel.fromJson(Map<String, dynamic> json) {
    return UserPurchasesModel(
      userId: json['user_id'] as String,
      superLikesBalance: json['super_likes_balance'] as int? ?? 0,
      invisibleModeUntil: json['invisible_mode_until'] != null
          ? DateTime.parse(json['invisible_mode_until'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'super_likes_balance': superLikesBalance,
      'invisible_mode_until': invisibleModeUntil?.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  UserPurchasesModel copyWith({
    String? userId,
    int? superLikesBalance,
    DateTime? invisibleModeUntil,
    DateTime? updatedAt,
  }) {
    return UserPurchasesModel(
      userId: userId ?? this.userId,
      superLikesBalance: superLikesBalance ?? this.superLikesBalance,
      invisibleModeUntil: invisibleModeUntil ?? this.invisibleModeUntil,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    superLikesBalance,
    invisibleModeUntil,
    updatedAt,
  ];
}

import 'package:equatable/equatable.dart';

/// Premium plan types
enum PremiumPlan {
  monthly,
  quarterly,
  yearly;

  String get displayName => switch (this) {
        monthly => '1 Month',
        quarterly => '3 Months',
        yearly => '12 Months',
      };

  String get price => switch (this) {
        monthly => '\$24.99',
        quarterly => '\$44.99',
        yearly => '\$9.99',
      };

  String get pricePerMonth => switch (this) {
        monthly => '\$24.99/mo',
        quarterly => '\$14.99/mo',
        yearly => '\$9.99/mo',
      };

  int get durationInDays => switch (this) {
        monthly => 30,
        quarterly => 90,
        yearly => 365,
      };
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
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// Create a new subscription for a user
  factory SubscriptionModel.create({
    required String userId,
    required PremiumPlan planType,
    String? transactionId,
  }) {
    final now = DateTime.now();
    return SubscriptionModel(
      id: '',
      userId: userId,
      planType: planType,
      startDate: now,
      endDate: now.add(Duration(days: planType.durationInDays)),
      isActive: true,
      transactionId: transactionId,
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
        createdAt,
        updatedAt,
      ];
}

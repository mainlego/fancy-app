import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../shared/widgets/fancy_button.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../../domain/models/subscription_model.dart';
import '../../domain/providers/subscription_provider.dart';

/// Selected plan provider
final selectedPlanProvider = StateProvider<PremiumPlan>((ref) {
  return PremiumPlan.yearly;
});

/// Premium subscription screen
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedPlan = ref.watch(selectedPlanProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final isFemale = ref.watch(isFemaleUserProvider);
    final trialAvailable = ref.watch(trialAvailableProvider);
    final subscriptionAsync = ref.watch(subscriptionProvider);
    final profileAsync = ref.watch(currentProfileProvider);

    // Get user's profile type for display
    final userProfileType = profileAsync.whenOrNull(data: (p) => p?.profileType.name) ?? 'man';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // App bar with gradient
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFD64557),
                      Color(0xFF8B2A3A),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 60,
                        color: AppColors.premium,
                      ),
                      AppSpacing.vGapMd,
                      Text(
                        'FANCY Premium',
                        style: AppTypography.displaySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      AppSpacing.vGapSm,
                      Text(
                        isPremium
                            ? 'You have premium access!'
                            : isFemale
                                ? 'Free for women!'
                                : 'Unlock all features',
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Show current subscription status if premium
                  if (isPremium) ...[
                    _buildCurrentSubscriptionCard(context, ref, subscriptionAsync, isFemale),
                    AppSpacing.vGapXxl,
                  ],

                  // Features section
                  Text(
                    'Premium Features',
                    style: AppTypography.headlineSmall,
                  ),
                  AppSpacing.vGapLg,

                  _buildFeatureItem(
                    Icons.favorite,
                    'Unlimited Likes',
                    'Like as many profiles as you want',
                    AppColors.like,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.visibility,
                    'See Who Likes You',
                    'View all your secret admirers',
                    AppColors.verified,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.tune,
                    'Advanced Filters',
                    'Height, weight, age, zodiac, language',
                    AppColors.primary,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.photo_album,
                    'Hidden Albums',
                    'Share private photos with matches',
                    AppColors.superLike,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.videocam,
                    'Profile Video',
                    'Add video to your profile',
                    AppColors.verified,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.security,
                    'Enhanced Security',
                    'Your data is always protected',
                    AppColors.textSecondary,
                  ),

                  // Only show plans if user needs premium (not female)
                  if (!isFemale) ...[
                    AppSpacing.vGapXxl,

                    // Pricing info
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline, color: AppColors.textSecondary, size: 20),
                              AppSpacing.hGapSm,
                              Expanded(
                                child: Text(
                                  userProfileType == 'woman'
                                      ? 'Women use FANCY for free!'
                                      : 'Men and couples need premium subscription',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vGapXxl,

                    // Plans section
                    Text(
                      'Choose Your Plan',
                      style: AppTypography.headlineSmall,
                    ),
                    AppSpacing.vGapLg,

                    // Trial card (if available)
                    if (trialAvailable) ...[
                      _buildTrialCard(context, ref),
                      AppSpacing.vGapMd,
                    ],

                    // Plan cards
                    _buildPlanCard(
                      ref,
                      plan: PremiumPlan.yearly,
                      title: '12 Months',
                      price: '\$25',
                      perWeek: '\$0.48/week',
                      savings: 'Save 90%',
                      isPopular: true,
                      isSelected: selectedPlan == PremiumPlan.yearly,
                    ),
                    AppSpacing.vGapMd,
                    _buildPlanCard(
                      ref,
                      plan: PremiumPlan.monthly,
                      title: '1 Month',
                      price: '\$10',
                      perWeek: '\$2.50/week',
                      savings: 'Save 50%',
                      isSelected: selectedPlan == PremiumPlan.monthly,
                    ),
                    AppSpacing.vGapMd,
                    _buildPlanCard(
                      ref,
                      plan: PremiumPlan.weekly,
                      title: '1 Week',
                      price: '\$5',
                      perWeek: '\$5/week',
                      isSelected: selectedPlan == PremiumPlan.weekly,
                    ),
                    AppSpacing.vGapXxl,

                    // Subscribe button
                    if (!isPremium) ...[
                      FancyButton(
                        text: 'Subscribe Now - ${selectedPlan.price}',
                        onPressed: () => _showSubscribeDialog(context, ref, selectedPlan),
                      ),
                      AppSpacing.vGapMd,
                    ],
                  ],

                  // In-App Purchases section (available for everyone)
                  AppSpacing.vGapXxl,
                  Text(
                    'Extras',
                    style: AppTypography.headlineSmall,
                  ),
                  AppSpacing.vGapMd,
                  Text(
                    'Available for all users',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  AppSpacing.vGapLg,

                  // Super Likes section
                  _buildExtrasSection(
                    context,
                    ref,
                    'Super Likes',
                    Icons.star,
                    AppColors.superLike,
                    [
                      InAppPurchaseItem.superLike1,
                      InAppPurchaseItem.superLike10,
                      InAppPurchaseItem.superLike50,
                    ],
                  ),
                  AppSpacing.vGapLg,

                  // Invisible Mode section
                  _buildExtrasSection(
                    context,
                    ref,
                    'Invisible Mode',
                    Icons.visibility_off,
                    AppColors.textSecondary,
                    [
                      InAppPurchaseItem.invisible7,
                      InAppPurchaseItem.invisible30,
                    ],
                  ),
                  AppSpacing.vGapXxl,

                  // Terms text
                  Text(
                    'By subscribing, you agree to our Terms of Service and Privacy Policy. Subscription automatically renews unless cancelled at least 24 hours before the end of the current period.',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  AppSpacing.vGapMd,

                  // Restore purchases
                  Center(
                    child: TextButton(
                      onPressed: () => _restorePurchases(context, ref),
                      child: Text(
                        'Restore Purchases',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.vGapXxl,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSubscriptionCard(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<SubscriptionModel?> subscriptionAsync,
    bool isFemale,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              AppSpacing.hGapMd,
              Text(
                isFemale ? 'Free Premium' : 'Premium Active',
                style: AppTypography.titleMedium.copyWith(
                  color: Colors.white,
                ),
              ),
            ],
          ),
          if (!isFemale) ...[
            AppSpacing.vGapMd,
            subscriptionAsync.when(
              data: (subscription) {
                if (subscription == null) return const SizedBox.shrink();
                return Text(
                  '${subscription.daysRemaining} days remaining',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ] else ...[
            AppSpacing.vGapMd,
            Text(
              'Women enjoy free premium access!',
              style: AppTypography.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureItem(
    IconData icon,
    String title,
    String description,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.15),
            borderRadius: BorderRadius.zero,
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
        AppSpacing.hGapLg,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall,
              ),
              Text(
                description,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.check_circle,
          color: AppColors.verified,
          size: 24,
        ),
      ],
    );
  }

  Widget _buildTrialCard(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _startTrial(context, ref),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.verified.withOpacity(0.2),
              AppColors.verified.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.verified, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.verified,
                borderRadius: BorderRadius.zero,
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 24,
              ),
            ),
            AppSpacing.hGapLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Free Trial',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.verified,
                    ),
                  ),
                  Text(
                    'Try premium for free!',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.verified,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    WidgetRef ref, {
    required PremiumPlan plan,
    required String title,
    required String price,
    required String perWeek,
    String? savings,
    bool isPopular = false,
    bool isSelected = false,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedPlanProvider.notifier).state = plan;
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            Row(
              children: [
                // Radio indicator
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.textTertiary,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                        )
                      : null,
                ),
                AppSpacing.hGapLg,

                // Plan details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: AppTypography.titleMedium,
                          ),
                          if (savings != null) ...[
                            AppSpacing.hGapSm,
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: AppSpacing.xs,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.verified,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(
                                savings,
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      AppSpacing.vGapXs,
                      Text(
                        perWeek,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Price
                Text(
                  price,
                  style: AppTypography.headlineMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            // Popular badge
            if (isPopular)
              Positioned(
                top: -AppSpacing.lg,
                right: AppSpacing.lg,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    'BEST VALUE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtrasSection(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    List<InAppPurchaseItem> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            AppSpacing.hGapMd,
            Text(title, style: AppTypography.titleMedium),
          ],
        ),
        AppSpacing.vGapMd,
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _buildExtraItem(context, ref, item),
        )),
      ],
    );
  }

  Widget _buildExtraItem(BuildContext context, WidgetRef ref, InAppPurchaseItem item) {
    return GestureDetector(
      onTap: () => _buyExtra(context, ref, item),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.displayName, style: AppTypography.bodyMedium),
                  if (item.savings != null)
                    Text(
                      item.savings!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.verified,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              item.price,
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTrial(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Start Free Trial'),
        content: const Text(
          'Start your 7-day free trial now!\n\n'
          'You can cancel anytime before the trial ends.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Start Trial',
              style: TextStyle(color: AppColors.verified),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ref.read(subscriptionProvider.notifier).startFreeTrial();
      if (context.mounted) {
        if (success) {
          _showSuccessSnackbar(context, 'Trial started! Enjoy 7 days of premium.');
        } else {
          _showErrorSnackbar(context, 'Failed to start trial. You may have already used it.');
        }
      }
    }
  }

  void _showSubscribeDialog(BuildContext context, WidgetRef ref, PremiumPlan plan) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('You\'re subscribing to:'),
            AppSpacing.vGapMd,
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.zero,
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: AppColors.premium,
                  ),
                  AppSpacing.hGapMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FANCY Premium - ${plan.displayName}',
                          style: AppTypography.titleSmall,
                        ),
                        Text(
                          plan.price,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Try IAP first
              final iap = ref.read(iapServiceProvider);
              final success = await iap.buySubscription(plan);

              // Fallback to direct subscription (for testing)
              if (!success && context.mounted) {
                final directSuccess = await ref.read(subscriptionProvider.notifier).subscribe(plan);
                if (context.mounted) {
                  if (directSuccess) {
                    _showSuccessSnackbar(context, 'Welcome to FANCY Premium!');
                  } else {
                    _showErrorSnackbar(context, 'Failed to subscribe. Please try again.');
                  }
                }
              }
            },
            child: Text(
              'Subscribe',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _buyExtra(BuildContext context, WidgetRef ref, InAppPurchaseItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Buy ${item.displayName}'),
        content: Text('Purchase ${item.displayName} for ${item.price}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Buy',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final iap = ref.read(iapServiceProvider);
      await iap.buyConsumable(item);
    }
  }

  void _restorePurchases(BuildContext context, WidgetRef ref) async {
    final iap = ref.read(iapServiceProvider);
    await iap.restorePurchases();
    if (context.mounted) {
      _showSuccessSnackbar(context, 'Purchases restored!');
    }
  }

  void _showSuccessSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.verified),
            AppSpacing.hGapMd,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error),
            AppSpacing.hGapMd,
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }
}

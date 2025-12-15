import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_button.dart';
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
                        'Unlock all features',
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
                    Icons.flash_on,
                    '1 Boost Per Month',
                    'Be a top profile for 30 minutes',
                    AppColors.primary,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.travel_explore,
                    'Passport Mode',
                    'Match with people anywhere in the world',
                    AppColors.verified,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.visibility_off,
                    'Incognito Mode',
                    'Browse profiles privately',
                    AppColors.textSecondary,
                  ),
                  AppSpacing.vGapMd,
                  _buildFeatureItem(
                    Icons.block,
                    'No Ads',
                    'Enjoy an ad-free experience',
                    AppColors.error,
                  ),
                  AppSpacing.vGapXxl,

                  // Plans section
                  Text(
                    'Choose Your Plan',
                    style: AppTypography.headlineSmall,
                  ),
                  AppSpacing.vGapLg,

                  // Plan cards
                  _buildPlanCard(
                    ref,
                    plan: PremiumPlan.yearly,
                    title: '12 Months',
                    price: '\$9.99',
                    perMonth: '\$9.99/mo',
                    savings: 'Save 60%',
                    isPopular: true,
                    isSelected: selectedPlan == PremiumPlan.yearly,
                  ),
                  AppSpacing.vGapMd,
                  _buildPlanCard(
                    ref,
                    plan: PremiumPlan.quarterly,
                    title: '3 Months',
                    price: '\$44.99',
                    perMonth: '\$14.99/mo',
                    savings: 'Save 40%',
                    isSelected: selectedPlan == PremiumPlan.quarterly,
                  ),
                  AppSpacing.vGapMd,
                  _buildPlanCard(
                    ref,
                    plan: PremiumPlan.monthly,
                    title: '1 Month',
                    price: '\$24.99',
                    perMonth: '\$24.99/mo',
                    isSelected: selectedPlan == PremiumPlan.monthly,
                  ),
                  AppSpacing.vGapXxl,

                  // Subscribe button
                  FancyButton(
                    text: 'Subscribe Now',
                    onPressed: () => _showSubscribeDialog(context, ref, selectedPlan),
                  ),
                  AppSpacing.vGapMd,

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
                      onPressed: () {},
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

  Widget _buildPlanCard(
    WidgetRef ref, {
    required PremiumPlan plan,
    required String title,
    required String price,
    required String perMonth,
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
                        perMonth,
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
                    'MOST POPULAR',
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
            Text('You\'re subscribing to:'),
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
              // Save subscription to database
              final success = await ref.read(subscriptionProvider.notifier).subscribe(plan);
              if (context.mounted) {
                if (success) {
                  _showSuccessSnackbar(context);
                } else {
                  _showErrorSnackbar(context);
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

  void _showSuccessSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.verified,
            ),
            AppSpacing.hGapMd,
            const Expanded(
              child: Text('Welcome to FANCY Premium!'),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }

  void _showErrorSnackbar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
            ),
            AppSpacing.hGapMd,
            const Expanded(
              child: Text('Failed to subscribe. Please try again.'),
            ),
          ],
        ),
        backgroundColor: AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }
}

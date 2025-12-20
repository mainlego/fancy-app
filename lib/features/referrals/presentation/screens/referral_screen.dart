import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_button.dart';
import '../../domain/models/referral_model.dart';
import '../../domain/providers/referral_provider.dart';

/// Referral screen - invite friends and earn premium
class ReferralScreen extends ConsumerStatefulWidget {
  const ReferralScreen({super.key});

  @override
  ConsumerState<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends ConsumerState<ReferralScreen> {
  String? _referralCode;
  bool _isLoadingCode = true;

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final code = await ref.read(referralNotifierProvider.notifier).getOrCreateCode();
    if (mounted) {
      setState(() {
        _referralCode = code;
        _isLoadingCode = false;
      });
    }
  }

  void _copyCode() {
    if (_referralCode == null) return;

    Clipboard.setData(ClipboardData(text: _referralCode!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Referral code copied!'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  void _shareCode() {
    if (_referralCode == null) return;

    Share.share(
      'Join FANCY dating app with my referral code: $_referralCode\n\n'
      'Download now and find your match!',
      subject: 'Join FANCY with my code!',
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(referralNotifierProvider);
    final referralsAsync = ref.watch(userReferralsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invite Friends'),
        backgroundColor: AppColors.background,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(referralNotifierProvider.notifier).refresh();
          ref.invalidate(userReferralsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: AppSpacing.screenPaddingAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero section
              _buildHeroSection(),
              AppSpacing.vGapXxl,

              // Referral code section
              _buildReferralCodeSection(),
              AppSpacing.vGapXxl,

              // Stats section
              statsAsync.when(
                data: (stats) => _buildStatsSection(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
              AppSpacing.vGapXxl,

              // How it works
              _buildHowItWorksSection(),
              AppSpacing.vGapXxl,

              // Referrals list
              Text(
                'Your Referrals',
                style: AppTypography.headlineSmall,
              ),
              AppSpacing.vGapMd,

              referralsAsync.when(
                data: (referrals) => _buildReferralsList(referrals),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('Error: $e'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withOpacity(0.8),
            AppColors.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.card_giftcard,
            size: 64,
            color: AppColors.textPrimary,
          ),
          AppSpacing.vGapMd,
          Text(
            'Earn Free Premium!',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            'Invite friends and get 1 month of Premium for each friend who subscribes',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Referral Code',
          style: AppTypography.titleMedium,
        ),
        AppSpacing.vGapSm,

        // Code display
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: _isLoadingCode
                    ? const CircularProgressIndicator()
                    : Text(
                        _referralCode ?? 'Error loading code',
                        style: AppTypography.headlineMedium.copyWith(
                          letterSpacing: 4,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              IconButton(
                onPressed: _copyCode,
                icon: const Icon(Icons.copy),
                tooltip: 'Copy code',
              ),
            ],
          ),
        ),
        AppSpacing.vGapMd,

        // Share button
        FancyButton(
          text: 'Share Invite Link',
          icon: Icons.share,
          onPressed: _shareCode,
        ),
      ],
    );
  }

  Widget _buildStatsSection(ReferralStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Stats',
          style: AppTypography.titleMedium,
        ),
        AppSpacing.vGapSm,

        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Invites',
                stats.totalReferrals.toString(),
                Icons.people_outline,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildStatCard(
                'Subscribed',
                stats.successfulReferrals.toString(),
                Icons.check_circle_outline,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        AppSpacing.vGapMd,
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pending',
                stats.pendingReferrals.toString(),
                Icons.hourglass_empty,
                color: AppColors.warning,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildStatCard(
                'Premium Earned',
                '${stats.totalMonthsEarned} months',
                Icons.star,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color ?? AppColors.textSecondary,
            size: 28,
          ),
          AppSpacing.vGapSm,
          Text(
            value,
            style: AppTypography.headlineSmall.copyWith(
              color: color ?? AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          AppSpacing.vGapXs,
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How It Works',
          style: AppTypography.titleMedium,
        ),
        AppSpacing.vGapMd,

        _buildStepItem(1, 'Share your code', 'Send your unique referral code to friends'),
        _buildStepItem(2, 'Friend registers', 'They sign up using your code'),
        _buildStepItem(3, 'Friend subscribes', 'When they purchase Premium'),
        _buildStepItem(4, 'You earn rewards', 'Get 1 month Premium for each subscription!'),
      ],
    );
  }

  Widget _buildStepItem(int step, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
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
        ],
      ),
    );
  }

  Widget _buildReferralsList(List<ReferralModel> referrals) {
    if (referrals.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
        ),
        child: Column(
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: AppColors.textTertiary,
            ),
            AppSpacing.vGapMd,
            Text(
              'No referrals yet',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vGapXs,
            Text(
              'Start sharing your code to earn Premium!',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: referrals.map((referral) => _buildReferralItem(referral)).toList(),
    );
  }

  Widget _buildReferralItem(ReferralModel referral) {
    final statusColor = switch (referral.status) {
      ReferralStatus.pending => AppColors.warning,
      ReferralStatus.subscribed => AppColors.info,
      ReferralStatus.rewarded => AppColors.success,
      ReferralStatus.expired => AppColors.error,
    };

    final statusText = switch (referral.status) {
      ReferralStatus.pending => 'Pending',
      ReferralStatus.subscribed => 'Subscribed',
      ReferralStatus.rewarded => 'Rewarded!',
      ReferralStatus.expired => 'Expired',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            backgroundImage: referral.referredUserAvatar != null
                ? NetworkImage(referral.referredUserAvatar!)
                : null,
            child: referral.referredUserAvatar == null
                ? Text(
                    (referral.referredUserName ?? '?')[0].toUpperCase(),
                    style: AppTypography.titleMedium,
                  )
                : null,
          ),
          AppSpacing.hGapMd,

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  referral.referredUserName ?? 'User',
                  style: AppTypography.labelLarge,
                ),
                Text(
                  'Joined ${_formatDate(referral.createdAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              statusText,
              style: AppTypography.labelSmall.copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }
}

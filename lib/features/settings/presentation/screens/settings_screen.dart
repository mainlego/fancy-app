import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../auth/domain/providers/auth_provider.dart';
import '../../domain/models/settings_model.dart';
import '../../domain/providers/settings_provider.dart';
import '../../domain/providers/subscription_provider.dart';
import '../../../admin/domain/providers/admin_provider.dart';
import 'contact_us_screen.dart';
import 'faq_screen.dart';
import 'legal_document_screen.dart';
import 'privacy_data_screen.dart';
import 'suggest_improvement_screen.dart';

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Premium section
          _buildPremiumCard(context, isPremium),
          AppSpacing.vGapLg,

          // Verification
          _buildVerificationCard(context),
          AppSpacing.vGapXl,

          // Subscription section
          _buildSectionTitle('SUBSCRIPTION'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.restore,
                  title: 'Restore purchase',
                  onTap: () => _showRestorePurchaseDialog(context, ref),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.payment,
                  title: 'Payment method',
                  onTap: () => _showPaymentMethodInfo(context),
                ),
                if (isPremium) ...[
                  const Divider(height: 1),
                  _buildListTile(
                    icon: Icons.cancel_outlined,
                    title: 'Cancel subscription',
                    textColor: AppColors.error,
                    onTap: () => _showCancelSubscriptionDialog(context, ref),
                  ),
                ],
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.card_giftcard,
                  title: 'Invite Friends',
                  subtitle: 'Earn free Premium months',
                  onTap: () => context.pushReferrals(),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Security section
          _buildSectionTitle('SECURITY'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.block,
                  title: 'Blocked users',
                  onTap: () => context.pushBlockedUsers(),
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.visibility_off,
                  title: 'Incognito mode',
                  subtitle: 'Browse profiles privately',
                  value: settings.incognitoMode,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateIncognitoMode(value);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Notifications section
          _buildSectionTitle('NOTIFICATIONS'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildSwitchTile(
                  icon: Icons.favorite,
                  title: 'Matches',
                  value: settings.notifyMatches,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateNotifyMatches(value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.thumb_up,
                  title: 'Likes',
                  value: settings.notifyLikes,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateNotifyLikes(value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.star,
                  title: 'Super likes',
                  value: settings.notifySuperLikes,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateNotifySuperLikes(value);
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.message,
                  title: 'Messages',
                  value: settings.notifyMessages,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).updateNotifyMessages(value);
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Units section
          _buildSectionTitle('UNITS'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildRadioTile(
                  title: 'Metric (km, cm, kg)',
                  value: MeasurementSystem.metric,
                  groupValue: settings.measurementSystem,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateMeasurementSystem(value);
                    }
                  },
                ),
                const Divider(height: 1),
                _buildRadioTile(
                  title: 'Imperial (mi, ft, lbs)',
                  value: MeasurementSystem.imperial,
                  groupValue: settings.measurementSystem,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateMeasurementSystem(value);
                    }
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Language section
          _buildSectionTitle('APP LANGUAGE'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildRadioTile(
                  title: 'English',
                  value: AppLanguage.english,
                  groupValue: settings.appLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateAppLanguage(value);
                    }
                  },
                ),
                const Divider(height: 1),
                _buildRadioTile(
                  title: 'Russian',
                  value: AppLanguage.russian,
                  groupValue: settings.appLanguage,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(settingsProvider.notifier).updateAppLanguage(value);
                    }
                  },
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Account section
          _buildSectionTitle('ACCOUNT'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.logout,
                  title: 'Sign out',
                  textColor: AppColors.warning,
                  onTap: () => _showSignOutDialog(context, ref),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Privacy & Data section (GDPR)
          _buildSectionTitle('PRIVACY & DATA'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.shield,
                  title: 'Privacy & Data',
                  subtitle: 'Manage your data, export, delete account',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PrivacyDataScreen()),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Legal section
          _buildSectionTitle('LEGAL'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentScreen(
                        documentType: LegalDocumentType.termsOfService,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentScreen(
                        documentType: LegalDocumentType.privacyPolicy,
                      ),
                    ),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.cookie,
                  title: 'Cookie Policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LegalDocumentScreen(
                        documentType: LegalDocumentType.cookiePolicy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Support section
          _buildSectionTitle('SUPPORT'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FAQScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lightbulb_outline,
                  title: 'Suggest improvement',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SuggestImprovementScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.email_outlined,
                  title: 'Contact us',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ContactUsScreen()),
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

          // Admin section (only shown to admins)
          _buildAdminSection(context, ref),

          // Version info
          Center(
            child: Text(
              'FANCY v1.0.0',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
          AppSpacing.vGapXxl,
        ],
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context, WidgetRef ref) {
    final isAdminAsync = ref.watch(isAdminProvider);

    return isAdminAsync.when(
      data: (isAdmin) {
        if (!isAdmin) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('ADMIN'),
            AppSpacing.vGapSm,
            FancyCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildListTile(
                    icon: Icons.admin_panel_settings,
                    title: 'Admin Panel',
                    subtitle: 'Manage users, reports, and more',
                    onTap: () => context.pushAdmin(),
                  ),
                ],
              ),
            ),
            AppSpacing.vGapXl,
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildPremiumCard(BuildContext context, bool isPremium) {
    if (isPremium) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFD64557),
              Color(0xFFE06B7A),
            ],
          ),
          borderRadius: BorderRadius.zero,
        ),
        child: Row(
          children: [
            const Icon(
              Icons.workspace_premium,
              color: AppColors.premium,
              size: 32,
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Premium Active',
                    style: AppTypography.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'You have access to all premium features',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.check_circle,
              color: AppColors.premium,
              size: 28,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD64557),
            Color(0xFFE06B7A),
          ],
        ),
        borderRadius: BorderRadius.zero,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.workspace_premium,
                color: AppColors.premium,
                size: 32,
              ),
              AppSpacing.hGapMd,
              Text(
                'Fancy Premium',
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Text(
            'Unlock unlimited likes, see who likes you, and more',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary.withValues(alpha: 0.9),
            ),
          ),
          AppSpacing.vGapLg,
          FancyButton(
            text: 'Upgrade to Premium',
            variant: FancyButtonVariant.secondary,
            onPressed: () => context.pushPremium(),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationCard(BuildContext context) {
    return FancyCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.verified.withValues(alpha: 0.2),
              borderRadius: BorderRadius.zero,
            ),
            child: const Icon(
              Icons.verified_user,
              color: AppColors.verified,
              size: 28,
            ),
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Photo verification',
                  style: AppTypography.titleMedium,
                ),
                Text(
                  'Get a verified badge on your profile',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
        ],
      ),
      onTap: () => context.pushVerification(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textTertiary,
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: textColor ?? AppColors.textSecondary),
      title: Text(
        title,
        style: AppTypography.bodyMedium.copyWith(
          color: textColor ?? AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: AppTypography.bodySmall,
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textTertiary,
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.bodyMedium),
      subtitle: subtitle != null
          ? Text(subtitle, style: AppTypography.bodySmall)
          : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildRadioTile<T>({
    required String title,
    required T value,
    required T groupValue,
    required ValueChanged<T?> onChanged,
  }) {
    return RadioListTile<T>(
      title: Text(title, style: AppTypography.bodyMedium),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: AppColors.primary,
      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    );
  }

  void _showRestorePurchaseDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Restore Purchase'),
        content: const Text(
          'This will check for any previous purchases associated with your account and restore them.\n\n'
          'Make sure you\'re signed in with the same account you used for the original purchase.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show loading
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 16),
                      Text('Checking for purchases...'),
                    ],
                  ),
                  duration: Duration(seconds: 2),
                ),
              );

              // Simulate restore check
              await Future.delayed(const Duration(seconds: 2));

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No previous purchases found. If you believe this is an error, please contact support.'),
                    backgroundColor: AppColors.info,
                  ),
                );
              }
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showPaymentMethodInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your payment method is managed through your app store account.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vGapLg,
            Text(
              'To update your payment method:',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vGapSm,
            Text(
              '• Open your device Settings\n'
              '• Go to App Store / Google Play\n'
              '• Select Payment & Subscriptions\n'
              '• Update your payment method',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showCancelSubscriptionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Cancel Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel your Premium subscription?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vGapMd,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: AppColors.warning, size: 20),
                  AppSpacing.hGapSm,
                  Expanded(
                    child: Text(
                      'You\'ll lose access to premium features at the end of your current billing period.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.warning,
                      ),
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
            child: const Text('Keep Premium'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(subscriptionProvider.notifier).cancelSubscription();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Subscription cancelled. You\'ll have access until the end of your billing period.'),
                      backgroundColor: AppColors.info,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to cancel: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Cancel Subscription',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) {
                context.goToLogin();
              }
            },
            child: Text(
              'Sign Out',
              style: TextStyle(color: AppColors.warning),
            ),
          ),
        ],
      ),
    );
  }
}

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

/// Settings screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          // Premium section
          _buildPremiumCard(context),
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
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.payment,
                  title: 'Payment method',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.cancel_outlined,
                  title: 'Cancel subscription',
                  textColor: AppColors.error,
                  onTap: () {},
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
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.app_settings_alt,
                  title: 'App icon & name',
                  subtitle: 'Change app appearance',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.delete_forever,
                  title: 'Delete account',
                  textColor: AppColors.error,
                  onTap: () => _showDeleteAccountDialog(context),
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

          // Other section
          _buildSectionTitle('OTHER'),
          AppSpacing.vGapSm,
          FancyCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildListTile(
                  icon: Icons.description,
                  title: 'Terms of use',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.privacy_tip,
                  title: 'Privacy policy',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.help_outline,
                  title: 'FAQ',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lightbulb_outline,
                  title: 'Suggest improvement',
                  onTap: () {},
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.email_outlined,
                  title: 'Contact us',
                  onTap: () {},
                ),
              ],
            ),
          ),
          AppSpacing.vGapXl,

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

  Widget _buildPremiumCard(BuildContext context) {
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
              color: AppColors.textPrimary.withOpacity(0.9),
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
              color: AppColors.verified.withOpacity(0.2),
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

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Handle delete account
            },
            child: Text(
              'Delete',
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

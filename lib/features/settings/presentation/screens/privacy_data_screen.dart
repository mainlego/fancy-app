import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/consent_model.dart';
import 'legal_document_screen.dart';

/// Privacy & Data management screen (GDPR compliance)
class PrivacyDataScreen extends ConsumerStatefulWidget {
  const PrivacyDataScreen({super.key});

  @override
  ConsumerState<PrivacyDataScreen> createState() => _PrivacyDataScreenState();
}

class _PrivacyDataScreenState extends ConsumerState<PrivacyDataScreen> {
  Map<ConsentType, bool> _consents = {};
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _loadConsents();
  }

  Future<void> _loadConsents() async {
    setState(() => _isLoading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final consents = await supabase.getConsents();

      final Map<ConsentType, bool> consentMap = {};
      for (final consent in consents) {
        final type = ConsentType.fromValue(consent['consent_type'] as String);
        if (type != null) {
          consentMap[type] = consent['granted'] as bool? ?? false;
        }
      }

      setState(() {
        _consents = consentMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load consents: $e')),
        );
      }
    }
  }

  Future<void> _updateConsent(ConsentType type, bool granted) async {
    // Don't allow revoking required consents
    if (type.isRequired && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This consent is required to use the app'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _consents[type] = granted);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.recordConsent(
        consentType: type.value,
        granted: granted,
      );
    } catch (e) {
      // Revert on error
      setState(() => _consents[type] = !granted);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update consent: $e')),
        );
      }
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final data = await supabase.exportUserData();

      // Save to file
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/fancy-data-export.json');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(data));

      // Share file
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'FANCY Data Export',
        text: 'Your FANCY app data export',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export data: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _deleteAccount() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Account',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.error),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This action is PERMANENT and cannot be undone.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            AppSpacing.vGapMd,
            Text(
              'The following will be deleted:',
              style: AppTypography.bodyMedium,
            ),
            AppSpacing.vGapSm,
            _buildDeleteItem('Your profile and photos'),
            _buildDeleteItem('All matches and conversations'),
            _buildDeleteItem('All likes and interactions'),
            _buildDeleteItem('Subscription history'),
            _buildDeleteItem('All stored data'),
            AppSpacing.vGapMd,
            Text(
              'Are you sure you want to proceed?',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete Everything',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Second confirmation
    final finalConfirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Final Confirmation'),
        content: Text(
          'Type "DELETE" to confirm account deletion.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'I Understand, Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (finalConfirm != true) return;

    setState(() => _isDeleting = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.deleteAccount();

      if (mounted) {
        // Navigate to login/welcome screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.remove, size: 16, color: AppColors.textTertiary),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy & Data'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // GDPR Info Card
                  _buildInfoCard(),
                  AppSpacing.vGapXl,

                  // Your Rights Section
                  _buildSectionTitle('Your Rights (GDPR)'),
                  AppSpacing.vGapMd,
                  _buildRightCard(
                    icon: Icons.download,
                    title: 'Download Your Data',
                    subtitle: 'Get a copy of all your personal data',
                    buttonText: _isExporting ? 'Exporting...' : 'Export Data',
                    onPressed: _isExporting ? null : _exportData,
                  ),
                  AppSpacing.vGapMd,
                  _buildRightCard(
                    icon: Icons.delete_forever,
                    title: 'Delete Your Account',
                    subtitle: 'Permanently delete all your data',
                    buttonText: _isDeleting ? 'Deleting...' : 'Delete Account',
                    onPressed: _isDeleting ? null : _deleteAccount,
                    isDestructive: true,
                  ),
                  AppSpacing.vGapXxl,

                  // Consent Management
                  _buildSectionTitle('Consent Management'),
                  AppSpacing.vGapSm,
                  Text(
                    'Manage how we use your data',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  AppSpacing.vGapMd,

                  // Required consents (read-only)
                  _buildConsentSection('Required', ConsentType.values.where((c) => c.isRequired)),

                  AppSpacing.vGapLg,

                  // Optional consents
                  _buildConsentSection('Optional', ConsentType.values.where((c) => !c.isRequired)),

                  AppSpacing.vGapXxl,

                  // Legal Links
                  _buildSectionTitle('Legal'),
                  AppSpacing.vGapMd,
                  _buildLegalLink(
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
                  _buildLegalLink(
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
                  _buildLegalLink(
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

                  AppSpacing.vGapXxl,
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.info.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield, color: AppColors.info, size: 32),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy Matters',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.info,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  'We comply with GDPR and respect your data rights. You can export or delete your data at any time.',
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTypography.titleMedium.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildRightCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback? onPressed,
    bool isDestructive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isDestructive ? AppColors.error.withOpacity(0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
            size: 32,
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: isDestructive ? AppColors.error : AppColors.textPrimary,
                  ),
                ),
                AppSpacing.vGapXs,
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          AppSpacing.hGapSm,
          SizedBox(
            width: 90,
            child: TextButton(
              onPressed: onPressed,
              style: TextButton.styleFrom(
                backgroundColor: isDestructive ? Colors.transparent : AppColors.primary,
                foregroundColor: isDestructive ? AppColors.error : Colors.white,
                side: isDestructive ? const BorderSide(color: AppColors.error) : null,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(fontSize: 11),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsentSection(String title, Iterable<ConsentType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.vGapSm,
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.zero,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: types.map((type) {
              final isLast = type == types.last;
              return Column(
                children: [
                  _buildConsentTile(type),
                  if (!isLast) const Divider(height: 1),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildConsentTile(ConsentType type) {
    final isGranted = _consents[type] ?? false;

    return ListTile(
      title: Text(
        type.displayName,
        style: AppTypography.bodyMedium,
      ),
      subtitle: type.isRequired
          ? Text(
              'Required',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            )
          : null,
      trailing: Switch(
        value: type.isRequired ? true : isGranted,
        onChanged: type.isRequired ? null : (value) => _updateConsent(type, value),
        activeColor: AppColors.primary,
        activeTrackColor: AppColors.primary.withOpacity(0.5),
        inactiveThumbColor: Colors.grey.shade400,
        inactiveTrackColor: Colors.grey.shade700,
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return Colors.grey.shade300;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }

  Widget _buildLegalLink({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title, style: AppTypography.bodyMedium),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }
}

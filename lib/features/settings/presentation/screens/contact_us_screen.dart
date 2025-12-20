import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/fancy_button.dart';

/// Contact reason type
enum ContactReason {
  general('General Inquiry'),
  technicalIssue('Technical Issue'),
  accountProblem('Account Problem'),
  billing('Billing Question'),
  report('Report a Problem'),
  other('Other');

  final String label;
  const ContactReason(this.label);
}

/// Contact Us Screen
class ContactUsScreen extends ConsumerStatefulWidget {
  const ContactUsScreen({super.key});

  @override
  ConsumerState<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends ConsumerState<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  ContactReason _selectedReason = ContactReason.general;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final userId = supabase.currentUser?.id;
      final userEmail = supabase.currentUser?.email;

      // Save support request to database
      await supabase.client.from('support_requests').insert({
        'user_id': userId,
        'user_email': userEmail,
        'reason': _selectedReason.name,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Your message has been sent. We\'ll get back to you soon!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      // If table doesn't exist, fall back to email
      await _sendViaEmail();
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _sendViaEmail() async {
    final subject = Uri.encodeComponent('[${_selectedReason.label}] ${_subjectController.text}');
    final body = Uri.encodeComponent(_messageController.text);
    final emailUri = Uri.parse('mailto:support@fancyapp.com?subject=$subject&body=$body');

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
      if (mounted) {
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open email client. Please try again later.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Contact Us'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'How can we help?',
                style: AppTypography.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGapSm,
              Text(
                'Fill out the form below and our support team will get back to you within 24-48 hours.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vGapXl,

              // Contact reason
              Text(
                'What is this about?',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGapSm,
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ContactReason>(
                    isExpanded: true,
                    value: _selectedReason,
                    dropdownColor: AppColors.surface,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    items: ContactReason.values.map((reason) {
                      return DropdownMenuItem(
                        value: reason,
                        child: Text(reason.label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedReason = value);
                      }
                    },
                  ),
                ),
              ),
              AppSpacing.vGapLg,

              // Subject
              Text(
                'Subject',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGapSm,
              TextFormField(
                controller: _subjectController,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Brief description of your issue',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a subject';
                  }
                  return null;
                },
              ),
              AppSpacing.vGapLg,

              // Message
              Text(
                'Message',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              AppSpacing.vGapSm,
              TextFormField(
                controller: _messageController,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: 'Describe your issue in detail...',
                  hintStyle: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide(color: AppColors.error),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a message';
                  }
                  if (value.trim().length < 20) {
                    return 'Message must be at least 20 characters';
                  }
                  return null;
                },
              ),
              AppSpacing.vGapXl,

              // Submit button
              FancyButton(
                text: 'Send Message',
                isLoading: _isSubmitting,
                onPressed: _isSubmitting ? null : _submitForm,
              ),
              AppSpacing.vGapLg,

              // Alternative contact
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Other ways to reach us',
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    AppSpacing.vGapMd,
                    _buildContactOption(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      subtitle: 'support@fancyapp.com',
                      onTap: () async {
                        final uri = Uri.parse('mailto:support@fancyapp.com');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                    ),
                    AppSpacing.vGapMd,
                    _buildContactOption(
                      icon: Icons.language,
                      title: 'Website',
                      subtitle: 'www.fancyapp.com/support',
                      onTap: () async {
                        final uri = Uri.parse('https://fancyapp.com/support');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          AppSpacing.hGapMd,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

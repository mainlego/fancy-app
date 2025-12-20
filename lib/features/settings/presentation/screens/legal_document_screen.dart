import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Legal document type
enum LegalDocumentType {
  termsOfService,
  privacyPolicy,
  cookiePolicy,
}

/// Screen for displaying legal documents
class LegalDocumentScreen extends StatelessWidget {
  final LegalDocumentType documentType;

  const LegalDocumentScreen({
    super.key,
    required this.documentType,
  });

  String get _title {
    switch (documentType) {
      case LegalDocumentType.termsOfService:
        return 'Terms of Service';
      case LegalDocumentType.privacyPolicy:
        return 'Privacy Policy';
      case LegalDocumentType.cookiePolicy:
        return 'Cookie Policy';
    }
  }

  String get _lastUpdated {
    return 'December 2025';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title,
              style: AppTypography.headlineMedium,
            ),
            AppSpacing.vGapSm,
            Text(
              'Last updated: $_lastUpdated',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
            AppSpacing.vGapXl,
            ..._buildContent(),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildContent() {
    switch (documentType) {
      case LegalDocumentType.termsOfService:
        return _buildTermsOfService();
      case LegalDocumentType.privacyPolicy:
        return _buildPrivacyPolicy();
      case LegalDocumentType.cookiePolicy:
        return _buildCookiePolicy();
    }
  }

  List<Widget> _buildTermsOfService() {
    return [
      _buildSection(
        '1. Acceptance of Terms',
        'By accessing or using the FANCY dating application ("App"), you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
      ),
      _buildSection(
        '2. Eligibility',
        'You must be at least 18 years old to use this App. By using the App, you represent and warrant that you are at least 18 years of age and have the legal capacity to enter into this agreement.',
      ),
      _buildSection(
        '3. Account Registration',
        '''To use certain features of the App, you must register for an account. You agree to:
• Provide accurate, current, and complete information
• Maintain and update your information
• Keep your password confidential
• Accept responsibility for all activities under your account
• Notify us immediately of unauthorized access''',
      ),
      _buildSection(
        '4. User Conduct',
        '''You agree NOT to:
• Post false, misleading, or deceptive content
• Harass, threaten, or intimidate other users
• Share explicit content without consent
• Use the App for commercial purposes without authorization
• Attempt to access other users\' accounts
• Upload viruses or malicious code
• Violate any applicable laws or regulations''',
      ),
      _buildSection(
        '5. Content Ownership',
        'You retain ownership of content you post. By posting content, you grant FANCY a non-exclusive, worldwide, royalty-free license to use, display, and distribute your content within the App.',
      ),
      _buildSection(
        '6. Photo Verification',
        'Our photo verification system uses AI to compare your selfies with your profile photos. Verification photos are deleted after processing. Verification status can be revoked if we detect misuse.',
      ),
      _buildSection(
        '7. Premium Services',
        'Some features require a paid subscription. Subscription terms, pricing, and cancellation policies are displayed at the time of purchase. Refunds are handled according to the app store policies.',
      ),
      _buildSection(
        '8. Safety',
        '''FANCY prioritizes user safety:
• We moderate content and profiles
• Users can report and block others
• We may remove content or accounts violating our policies
• We cooperate with law enforcement when required''',
      ),
      _buildSection(
        '9. Disclaimer',
        'The App is provided "as is" without warranties. We do not guarantee the accuracy of user profiles or the outcome of interactions. Use the App at your own risk.',
      ),
      _buildSection(
        '10. Limitation of Liability',
        'FANCY shall not be liable for any indirect, incidental, special, or consequential damages arising from your use of the App.',
      ),
      _buildSection(
        '11. Termination',
        'We may terminate or suspend your account at any time for violations of these terms. You may delete your account at any time through the Privacy & Data settings.',
      ),
      _buildSection(
        '12. Changes to Terms',
        'We may update these terms from time to time. Continued use of the App after changes constitutes acceptance of the new terms.',
      ),
      _buildSection(
        '13. Contact',
        'For questions about these Terms, contact us at: support@fancy.app',
      ),
    ];
  }

  List<Widget> _buildPrivacyPolicy() {
    return [
      _buildSection(
        '1. Introduction',
        'This Privacy Policy explains how FANCY ("we", "us", "our") collects, uses, and protects your personal data in compliance with the General Data Protection Regulation (GDPR) and other applicable privacy laws.',
      ),
      _buildSection(
        '2. Data Controller',
        '''FANCY is the data controller responsible for your personal data.
Contact: privacy@fancy.app''',
      ),
      _buildSection(
        '3. Data We Collect',
        '''We collect the following categories of data:

Account Information:
• Email address
• Name
• Date of birth
• Password (encrypted)

Profile Information:
• Photos
• Bio
• Interests
• Occupation
• Languages
• Physical attributes (optional)

Location Data:
• City/country (required for matching)
• Precise location (optional, with consent)

Usage Data:
• App interactions
• Matches, likes, messages
• Device information

Verification Data:
• Selfie photos (deleted after verification)''',
      ),
      _buildSection(
        '4. How We Use Your Data',
        '''We use your data for:
• Providing the dating service
• Matching you with potential partners
• Verifying your identity
• Improving our services
• Sending notifications (with consent)
• Ensuring safety and preventing fraud
• Complying with legal obligations''',
      ),
      _buildSection(
        '5. Legal Basis for Processing',
        '''We process your data based on:
• Consent: For optional features like marketing emails
• Contract: To provide our dating services
• Legitimate interests: For safety and fraud prevention
• Legal obligation: When required by law''',
      ),
      _buildSection(
        '6. Data Sharing',
        '''We may share your data with:
• Other users (profile information you choose to share)
• Service providers (cloud hosting, analytics)
• Law enforcement (when legally required)

We do NOT sell your personal data to third parties.''',
      ),
      _buildSection(
        '7. Data Retention',
        '''We retain your data for:
• Active accounts: As long as you use the service
• Inactive accounts: Up to 24 months, then deleted
• Verification photos: Deleted immediately after processing
• Messages: Until you or the other party deletes them
• Legal purposes: As required by law''',
      ),
      _buildSection(
        '8. Your Rights (GDPR)',
        '''Under GDPR, you have the right to:
• Access: Request a copy of your data
• Rectification: Correct inaccurate data
• Erasure: Delete your account and data
• Restriction: Limit how we process your data
• Portability: Export your data
• Object: Opt out of certain processing
• Withdraw consent: At any time

Exercise these rights in Settings → Privacy & Data.''',
      ),
      _buildSection(
        '9. Data Security',
        '''We protect your data using:
• Encryption in transit (HTTPS/TLS)
• Encryption at rest
• Secure authentication
• Regular security audits
• Access controls''',
      ),
      _buildSection(
        '10. International Transfers',
        'Your data may be processed in countries outside the EU. We ensure appropriate safeguards are in place for such transfers.',
      ),
      _buildSection(
        '11. Children\'s Privacy',
        'Our service is not intended for anyone under 18. We do not knowingly collect data from minors.',
      ),
      _buildSection(
        '12. Changes to This Policy',
        'We may update this policy. We will notify you of significant changes via the App or email.',
      ),
      _buildSection(
        '13. Contact & Complaints',
        '''For privacy-related inquiries:
Email: privacy@fancy.app

You have the right to lodge a complaint with a supervisory authority if you believe your rights have been violated.''',
      ),
    ];
  }

  List<Widget> _buildCookiePolicy() {
    return [
      _buildSection(
        '1. What Are Cookies',
        'Cookies are small text files stored on your device. They help us provide and improve our services.',
      ),
      _buildSection(
        '2. Cookies We Use',
        '''Essential Cookies:
• Authentication tokens
• Session management
• Security features

Functional Cookies:
• Language preferences
• Settings preferences

Analytics Cookies (with consent):
• Usage statistics
• Performance monitoring''',
      ),
      _buildSection(
        '3. Managing Cookies',
        'You can manage cookie preferences in the app settings under Privacy & Data. Essential cookies cannot be disabled as they are necessary for the app to function.',
      ),
      _buildSection(
        '4. Third-Party Services',
        '''We use the following third-party services:
• Supabase (authentication, database)
• Firebase (push notifications)
• OpenAI (AI features)

These services may use their own cookies subject to their privacy policies.''',
      ),
      _buildSection(
        '5. Updates',
        'We may update this policy as we add or change features. Check this page periodically for updates.',
      ),
    ];
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          AppSpacing.vGapMd,
          Text(
            content,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

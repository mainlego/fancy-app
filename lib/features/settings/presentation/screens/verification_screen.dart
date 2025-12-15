import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_button.dart';

/// Verification status
enum VerificationStatus {
  notStarted,
  inProgress,
  pending,
  verified,
  rejected,
}

/// Verification state provider
final verificationStatusProvider = StateProvider<VerificationStatus>((ref) {
  return VerificationStatus.notStarted;
});

/// Photo verification screen
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(verificationStatusProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Photo Verification'),
      ),
      body: _buildBody(status),
    );
  }

  Widget _buildBody(VerificationStatus status) {
    switch (status) {
      case VerificationStatus.notStarted:
        return _buildIntroStep();
      case VerificationStatus.inProgress:
        return _buildVerificationSteps();
      case VerificationStatus.pending:
        return _buildPendingState();
      case VerificationStatus.verified:
        return _buildVerifiedState();
      case VerificationStatus.rejected:
        return _buildRejectedState();
    }
  }

  Widget _buildIntroStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AppSpacing.vGapXl,
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.verified.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user,
              size: 60,
              color: AppColors.verified,
            ),
          ),
          AppSpacing.vGapXxl,

          // Title
          Text(
            'Get Verified',
            style: AppTypography.displaySmall,
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapMd,

          // Description
          Text(
            'Show others you\'re real by completing photo verification. This helps build trust in the community.',
            style: AppTypography.bodyLarge.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          AppSpacing.vGapXxl,

          // Benefits
          _buildBenefitItem(
            Icons.check_circle,
            'Verified badge on your profile',
          ),
          AppSpacing.vGapMd,
          _buildBenefitItem(
            Icons.trending_up,
            'Get more matches and likes',
          ),
          AppSpacing.vGapMd,
          _buildBenefitItem(
            Icons.security,
            'Help keep the community safe',
          ),
          AppSpacing.vGapXxl,
          AppSpacing.vGapXxl,

          // Start button
          FancyButton(
            text: 'Start Verification',
            onPressed: () {
              ref.read(verificationStatusProvider.notifier).state =
                  VerificationStatus.inProgress;
            },
          ),
          AppSpacing.vGapMd,

          // Learn more link
          TextButton(
            onPressed: () {},
            child: Text(
              'Learn more about verification',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.verified,
          size: 24,
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildVerificationSteps() {
    return Column(
      children: [
        // Progress indicator
        LinearProgressIndicator(
          value: (_currentStep + 1) / 3,
          backgroundColor: AppColors.surfaceVariant,
          valueColor: const AlwaysStoppedAnimation(AppColors.verified),
        ),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: _buildCurrentStep(),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        AppSpacing.vGapXl,
        Text(
          'Step 1 of 3',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.vGapMd,
        Text(
          'Strike a Pose',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapMd,
        Text(
          'Copy the pose shown in the example photo. Make sure your face is clearly visible.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXxl,

        // Example pose container
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 100,
                color: AppColors.textTertiary,
              ),
              AppSpacing.vGapMd,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.verified.withOpacity(0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.thumb_up,
                      color: AppColors.verified,
                      size: 20,
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      'Thumbs Up Pose',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.verified,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXxl,

        FancyButton(
          text: 'Take Photo',
          icon: Icons.camera_alt,
          onPressed: () {
            setState(() {
              _currentStep = 1;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      children: [
        AppSpacing.vGapXl,
        Text(
          'Step 2 of 3',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.vGapMd,
        Text(
          'Another Pose',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapMd,
        Text(
          'Now copy this second pose. This helps us verify it\'s really you.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXxl,

        // Example pose container
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.zero,
            border: Border.all(
              color: AppColors.border,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person,
                size: 100,
                color: AppColors.textTertiary,
              ),
              AppSpacing.vGapMd,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.verified.withOpacity(0.2),
                  borderRadius: BorderRadius.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      color: AppColors.verified,
                      size: 20,
                    ),
                    AppSpacing.hGapSm,
                    Text(
                      'Wave Pose',
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.verified,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXxl,

        FancyButton(
          text: 'Take Photo',
          icon: Icons.camera_alt,
          onPressed: () {
            setState(() {
              _currentStep = 2;
            });
          },
        ),
        AppSpacing.vGapMd,
        FancyButton(
          text: 'Retake Previous',
          variant: FancyButtonVariant.outline,
          onPressed: () {
            setState(() {
              _currentStep = 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      children: [
        AppSpacing.vGapXl,
        Text(
          'Step 3 of 3',
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        AppSpacing.vGapMd,
        Text(
          'Review & Submit',
          style: AppTypography.headlineMedium,
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapMd,
        Text(
          'Review your photos before submitting for verification.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXxl,

        // Photo previews
        Row(
          children: [
            Expanded(
              child: _buildPhotoPreview('Photo 1', Icons.thumb_up),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildPhotoPreview('Photo 2', Icons.waving_hand),
            ),
          ],
        ),
        AppSpacing.vGapXxl,

        // Terms
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.zero,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.textTertiary,
                size: 20,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Text(
                  'Your photos will be reviewed within 24-48 hours. They will not be shown on your profile.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        AppSpacing.vGapXxl,

        FancyButton(
          text: 'Submit for Verification',
          onPressed: () {
            ref.read(verificationStatusProvider.notifier).state =
                VerificationStatus.pending;
          },
        ),
        AppSpacing.vGapMd,
        FancyButton(
          text: 'Retake Photos',
          variant: FancyButtonVariant.outline,
          onPressed: () {
            setState(() {
              _currentStep = 0;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPhotoPreview(String label, IconData pose) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.verified,
            size: 40,
          ),
          AppSpacing.vGapSm,
          Text(
            label,
            style: AppTypography.labelMedium,
          ),
          AppSpacing.vGapXs,
          Icon(
            pose,
            color: AppColors.textTertiary,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated loading indicator
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_empty,
                size: 60,
                color: AppColors.warning,
              ),
            ),
            AppSpacing.vGapXxl,

            Text(
              'Verification Pending',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              'Your photos are being reviewed. This usually takes 24-48 hours. We\'ll notify you when it\'s complete.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXxl,

            // For demo: quick verify button
            FancyButton(
              text: 'Demo: Approve',
              variant: FancyButtonVariant.outline,
              onPressed: () {
                ref.read(verificationStatusProvider.notifier).state =
                    VerificationStatus.verified;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifiedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Success icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.verified.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.verified,
                size: 60,
                color: AppColors.verified,
              ),
            ),
            AppSpacing.vGapXxl,

            Text(
              'You\'re Verified!',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              'Congratulations! Your profile now has a verified badge. This shows others you\'re authentic.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXxl,

            FancyButton(
              text: 'Done',
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 60,
                color: AppColors.error,
              ),
            ),
            AppSpacing.vGapXxl,

            Text(
              'Verification Failed',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              'We couldn\'t verify your photos. Please make sure your face is clearly visible and matches the poses shown.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXxl,

            FancyButton(
              text: 'Try Again',
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
                ref.read(verificationStatusProvider.notifier).state =
                    VerificationStatus.notStarted;
              },
            ),
            AppSpacing.vGapMd,
            FancyButton(
              text: 'Contact Support',
              variant: FancyButtonVariant.outline,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

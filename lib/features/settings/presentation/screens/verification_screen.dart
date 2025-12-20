import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_button.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../../domain/models/verification_model.dart';
import '../../domain/providers/verification_provider.dart';

/// Photo verification screen
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  int _currentStep = 0;
  String? _lastShownError;

  @override
  void initState() {
    super.initState();
    // Refresh verification status on screen load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(verificationProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(verificationProvider);

    // Listen to realtime updates
    ref.listen<AsyncValue<VerificationRequest?>>(
      verificationStatusStreamProvider,
      (previous, next) {
        next.whenData((request) {
          if (request != null) {
            // Update local state when realtime update comes in
            ref.read(verificationProvider.notifier).refresh();

            // If verification is approved, refresh the current profile to get updated is_verified flag
            if (request.isApproved) {
              ref.read(currentProfileProvider.notifier).refresh();
            }
          }
        });
      },
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Photo Verification'),
      ),
      body: _buildBody(state),
    );
  }

  Widget _buildBody(VerificationState state) {
    // Show error snackbar only if it's a new error
    if (state.error != null && state.error != _lastShownError) {
      _lastShownError = state.error;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(state.error!),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        ref.read(verificationProvider.notifier).clearError();
      });
    } else if (state.error == null) {
      _lastShownError = null;
    }

    switch (state.status) {
      case VerificationStatus.notStarted:
        return _buildIntroStep();
      case VerificationStatus.takingPhotos:
        return _buildVerificationSteps(state);
      case VerificationStatus.uploading:
        return _buildUploadingState();
      case VerificationStatus.pending:
      case VerificationStatus.processing:
        return _buildPendingState(state);
      case VerificationStatus.manualReview:
        return _buildManualReviewState();
      case VerificationStatus.approved:
        return _buildVerifiedState();
      case VerificationStatus.rejected:
        return _buildRejectedState(state);
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
              ref.read(verificationProvider.notifier).startVerification();
              setState(() => _currentStep = 0);
            },
          ),
          AppSpacing.vGapMd,

          // Learn more link
          TextButton(
            onPressed: () {
              _showInfoDialog();
            },
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

  Widget _buildVerificationSteps(VerificationState state) {
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
            child: _buildCurrentStep(state),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentStep(VerificationState state) {
    switch (_currentStep) {
      case 0:
        return _buildStep1(state);
      case 1:
        return _buildStep2(state);
      case 2:
        return _buildStep3(state);
      default:
        return _buildStep1(state);
    }
  }

  Widget _buildStep1(VerificationState state) {
    final hasPhoto = state.hasThumbsUpPhoto;

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
          'Take a selfie showing your face with a thumbs up gesture.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXxl,

        // Photo preview or placeholder
        _buildPhotoContainer(
          hasPhoto ? state.photoThumbsUpPath : null,
          Icons.thumb_up,
          'Thumbs Up Pose',
        ),
        AppSpacing.vGapXxl,

        if (!hasPhoto) ...[
          FancyButton(
            text: 'Take Photo',
            icon: Icons.camera_alt,
            onPressed: () async {
              final success = await ref
                  .read(verificationProvider.notifier)
                  .takePhoto(PoseType.thumbsUp);
              if (success && mounted) {
                setState(() => _currentStep = 1);
              }
            },
          ),
        ] else ...[
          FancyButton(
            text: 'Continue',
            onPressed: () {
              setState(() => _currentStep = 1);
            },
          ),
          AppSpacing.vGapMd,
          FancyButton(
            text: 'Retake Photo',
            variant: FancyButtonVariant.outline,
            onPressed: () {
              ref
                  .read(verificationProvider.notifier)
                  .retakePhoto(PoseType.thumbsUp);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildStep2(VerificationState state) {
    final hasPhoto = state.hasWavePhoto;

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
          'Now take a selfie while waving your hand. This helps us verify it\'s really you.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        AppSpacing.vGapXxl,

        // Photo preview or placeholder
        _buildPhotoContainer(
          hasPhoto ? state.photoWavePath : null,
          Icons.waving_hand,
          'Wave Pose',
        ),
        AppSpacing.vGapXxl,

        if (!hasPhoto) ...[
          FancyButton(
            text: 'Take Photo',
            icon: Icons.camera_alt,
            onPressed: () async {
              final success = await ref
                  .read(verificationProvider.notifier)
                  .takePhoto(PoseType.wave);
              if (success && mounted) {
                setState(() => _currentStep = 2);
              }
            },
          ),
        ] else ...[
          FancyButton(
            text: 'Continue',
            onPressed: () {
              setState(() => _currentStep = 2);
            },
          ),
          AppSpacing.vGapMd,
          FancyButton(
            text: 'Retake Photo',
            variant: FancyButtonVariant.outline,
            onPressed: () {
              ref.read(verificationProvider.notifier).retakePhoto(PoseType.wave);
            },
          ),
        ],

        AppSpacing.vGapMd,
        FancyButton(
          text: 'Go Back',
          variant: FancyButtonVariant.outline,
          onPressed: () {
            setState(() => _currentStep = 0);
          },
        ),
      ],
    );
  }

  Widget _buildStep3(VerificationState state) {
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
              child: _buildPhotoPreview(
                'Photo 1',
                Icons.thumb_up,
                state.photoThumbsUpPath,
              ),
            ),
            AppSpacing.hGapMd,
            Expanded(
              child: _buildPhotoPreview(
                'Photo 2',
                Icons.waving_hand,
                state.photoWavePath,
              ),
            ),
          ],
        ),
        AppSpacing.vGapXxl,

        // Terms
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: const BoxDecoration(
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
                  'Your photos will be processed automatically. They will not be shown on your profile.',
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
          onPressed: () async {
            final success = await ref
                .read(verificationProvider.notifier)
                .submitVerification();
            if (!success && mounted) {
              // Error is handled by state listener
            }
          },
        ),
        AppSpacing.vGapMd,
        FancyButton(
          text: 'Retake Photos',
          variant: FancyButtonVariant.outline,
          onPressed: () {
            ref.read(verificationProvider.notifier).resetPhotos();
            setState(() => _currentStep = 0);
          },
        ),
      ],
    );
  }

  Widget _buildPhotoContainer(String? photoPath, IconData poseIcon, String poseLabel) {
    return Container(
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
      child: photoPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.zero,
              child: Image.file(
                File(photoPath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
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
                      Icon(
                        poseIcon,
                        color: AppColors.verified,
                        size: 20,
                      ),
                      AppSpacing.hGapSm,
                      Text(
                        poseLabel,
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.verified,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPhotoPreview(String label, IconData pose, String? photoPath) {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.zero,
        border: Border.all(color: AppColors.border),
      ),
      child: photoPath != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.zero,
                  child: Image.file(
                    File(photoPath),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.verified,
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check,
                            color: AppColors.textPrimary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            label,
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.photo_camera,
                  color: AppColors.textTertiary,
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

  Widget _buildUploadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 80,
              height: 80,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(AppColors.verified),
              ),
            ),
            AppSpacing.vGapXxl,
            Text(
              'Uploading Photos...',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              'Please wait while we upload your verification photos.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingState(VerificationState state) {
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
                color: AppColors.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.face_retouching_natural,
                size: 60,
                color: AppColors.primary,
              ),
            ),
            AppSpacing.vGapXxl,

            Text(
              state.status == VerificationStatus.processing
                  ? 'Processing...'
                  : 'Verification Pending',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              state.status == VerificationStatus.processing
                  ? 'AI is analyzing your photos. This usually takes up to 30 seconds.'
                  : 'Your photos are being verified. You\'ll be notified when it\'s complete.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXxl,

            // Show progress indicator
            const SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
            AppSpacing.vGapXxl,

            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close & Wait for Result',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualReviewState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search,
                size: 60,
                color: AppColors.info,
              ),
            ),
            AppSpacing.vGapXxl,

            Text(
              'Under Review',
              style: AppTypography.headlineMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapMd,
            Text(
              'Your verification requires manual review. This usually takes 24-48 hours. We\'ll notify you when it\'s complete.',
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

  Widget _buildVerifiedState() {
    // Ensure profile is refreshed when showing verified state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currentProfileProvider.notifier).refresh();
    });

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
              onPressed: () {
                // Refresh profile one more time before closing to ensure is_verified is updated
                ref.read(currentProfileProvider.notifier).refresh();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRejectedState(VerificationState state) {
    final request = state.currentRequest;

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
              request?.rejectionDisplayMessage ??
                  'We couldn\'t verify your photos. Please try again with clearer photos.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            AppSpacing.vGapXxl,

            FancyButton(
              text: 'Try Again',
              onPressed: () {
                ref.read(verificationProvider.notifier).tryAgain();
                setState(() => _currentStep = 0);
              },
            ),
            AppSpacing.vGapMd,
            FancyButton(
              text: 'Cancel',
              variant: FancyButtonVariant.outline,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'About Verification',
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Verification helps build trust in our community. When you verify:\n\n'
          '• You take 2 selfies with specific poses\n'
          '• Our AI compares them with your profile photo\n'
          '• If they match, you get a verified badge\n\n'
          'Your verification photos are not shown on your profile and are deleted after processing.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
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
}

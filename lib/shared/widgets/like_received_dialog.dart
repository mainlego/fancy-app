import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../core/services/sound_service.dart';
import '../../features/profile/domain/models/user_model.dart';
import 'fancy_button.dart';
import 'fancy_avatar.dart';

/// Dialog shown when receiving a like from another user
class LikeReceivedDialog extends StatefulWidget {
  final UserModel likerUser;
  final bool isSuperLike;
  final VoidCallback? onLikeBack;
  final VoidCallback? onPass;
  final VoidCallback? onViewProfile;

  const LikeReceivedDialog({
    super.key,
    required this.likerUser,
    this.isSuperLike = false,
    this.onLikeBack,
    this.onPass,
    this.onViewProfile,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel likerUser,
    bool isSuperLike = false,
    VoidCallback? onLikeBack,
    VoidCallback? onPass,
    VoidCallback? onViewProfile,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LikeReceivedDialog(
        likerUser: likerUser,
        isSuperLike: isSuperLike,
        onLikeBack: onLikeBack,
        onPass: onPass,
        onViewProfile: onViewProfile,
      ),
    );
  }

  @override
  State<LikeReceivedDialog> createState() => _LikeReceivedDialogState();
}

class _LikeReceivedDialogState extends State<LikeReceivedDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Play sound
    SoundService().play(
      widget.isSuperLike ? SoundType.superLike : SoundType.newLike,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: widget.isSuperLike
                        ? [
                            AppColors.superLike.withOpacity(0.95),
                            AppColors.superLike.withOpacity(0.8),
                          ]
                        : [
                            AppColors.like.withOpacity(0.95),
                            AppColors.like.withOpacity(0.8),
                          ],
                  ),
                  borderRadius: BorderRadius.zero,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon
                    Icon(
                      widget.isSuperLike
                          ? Icons.local_fire_department
                          : Icons.favorite,
                      size: 48,
                      color: AppColors.textPrimary,
                    ),
                    AppSpacing.vGapMd,

                    // Avatar with border
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        widget.onViewProfile?.call();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.textPrimary,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: FancyAvatar(
                          imageUrl: widget.likerUser.displayAvatar,
                          name: widget.likerUser.name,
                          size: AvatarSize.xlarge,
                        ),
                      ),
                    ),
                    AppSpacing.vGapLg,

                    // Title
                    Text(
                      widget.isSuperLike ? 'Super Like!' : 'Someone Likes You!',
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    AppSpacing.vGapSm,

                    // User info
                    Text(
                      '${widget.likerUser.name}, ${widget.likerUser.age}',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (widget.likerUser.city != null) ...[
                      AppSpacing.vGapXs,
                      Text(
                        widget.likerUser.city!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textPrimary.withOpacity(0.8),
                        ),
                      ),
                    ],
                    AppSpacing.vGapXl,

                    // Like back button
                    FancyButton(
                      text: 'Like Back',
                      variant: FancyButtonVariant.secondary,
                      icon: Icons.favorite,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onLikeBack?.call();
                      },
                    ),
                    AppSpacing.vGapMd,

                    // View profile button
                    FancyButton(
                      text: 'View Profile',
                      variant: FancyButtonVariant.outline,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onViewProfile?.call();
                      },
                    ),
                    AppSpacing.vGapMd,

                    // Pass button
                    FancyButton(
                      text: 'Maybe Later',
                      variant: FancyButtonVariant.ghost,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onPass?.call();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

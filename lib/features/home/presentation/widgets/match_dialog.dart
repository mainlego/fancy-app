import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_button.dart';
import '../../../../shared/widgets/fancy_avatar.dart';
import '../../../profile/domain/models/user_model.dart';

/// Match celebration dialog
class MatchDialog extends StatefulWidget {
  final UserModel matchedUser;
  final String? currentUserAvatar;
  final VoidCallback? onSendMessage;
  final VoidCallback? onKeepBrowsing;

  const MatchDialog({
    super.key,
    required this.matchedUser,
    this.currentUserAvatar,
    this.onSendMessage,
    this.onKeepBrowsing,
  });

  static Future<void> show(
    BuildContext context, {
    required UserModel matchedUser,
    String? currentUserAvatar,
    VoidCallback? onSendMessage,
    VoidCallback? onKeepBrowsing,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MatchDialog(
        matchedUser: matchedUser,
        currentUserAvatar: currentUserAvatar,
        onSendMessage: onSendMessage,
        onKeepBrowsing: onKeepBrowsing,
      ),
    );
  }

  @override
  State<MatchDialog> createState() => _MatchDialogState();
}

class _MatchDialogState extends State<MatchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
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
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primary.withOpacity(0.9),
                      AppColors.primaryDark,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatars - overlapping using Stack
                    SizedBox(
                      height: 100,
                      width: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Left avatar
                          Positioned(
                            left: 0,
                            child: _buildAvatar(widget.currentUserAvatar),
                          ),
                          // Right avatar
                          Positioned(
                            right: 0,
                            child: _buildAvatar(widget.matchedUser.displayAvatar),
                          ),
                          // Heart in center
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.favorite,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.vGapXxl,

                    // Title
                    Text(
                      "It's a Match!",
                      style: AppTypography.displayLarge,
                    ),
                    AppSpacing.vGapSm,

                    // Subtitle
                    Text(
                      'You and ${widget.matchedUser.name} liked each other',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary.withOpacity(0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.vGapXxl,

                    // Send message button
                    FancyButton(
                      text: 'Send Message',
                      variant: FancyButtonVariant.secondary,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onSendMessage?.call();
                      },
                    ),
                    AppSpacing.vGapMd,

                    // Keep browsing button
                    FancyButton(
                      text: 'Keep Browsing',
                      variant: FancyButtonVariant.ghost,
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onKeepBrowsing?.call();
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

  Widget _buildAvatar(String? url) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textPrimary, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
          ),
        ],
      ),
      child: FancyAvatar(
        imageUrl: url,
        size: AvatarSize.xlarge,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';

enum AvatarSize { small, medium, large, xlarge }

/// FANCY styled avatar with online indicator
class FancyAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final AvatarSize size;
  final bool isOnline;
  final bool isVerified;
  final bool showBorder;
  final VoidCallback? onTap;

  const FancyAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.medium,
    this.isOnline = false,
    this.isVerified = false,
    this.showBorder = false,
    this.onTap,
  });

  double get _size {
    switch (size) {
      case AvatarSize.small:
        return AppSpacing.avatarSm;
      case AvatarSize.medium:
        return AppSpacing.avatarMd;
      case AvatarSize.large:
        return AppSpacing.avatarLg;
      case AvatarSize.xlarge:
        return AppSpacing.avatarXl;
    }
  }

  double get _indicatorSize {
    switch (size) {
      case AvatarSize.small:
        return 8;
      case AvatarSize.medium:
        return 12;
      case AvatarSize.large:
        return 14;
      case AvatarSize.xlarge:
        return 16;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: showBorder
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
            ),
            child: ClipOval(
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildPlaceholder(),
                      errorWidget: (context, url, error) => _buildPlaceholder(),
                    )
                  : _buildPlaceholder(),
            ),
          ),
          if (isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
                decoration: BoxDecoration(
                  color: AppColors.online,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
              ),
            ),
          if (isVerified && !isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: _indicatorSize,
                height: _indicatorSize,
                decoration: BoxDecoration(
                  color: AppColors.verified,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.background,
                    width: 2,
                  ),
                ),
                child: Icon(
                  Icons.check,
                  color: AppColors.textPrimary,
                  size: _indicatorSize - 6,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.surfaceVariant,
      child: Center(
        child: name != null
            ? Text(
                name!.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: _size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                Icons.person,
                color: AppColors.textTertiary,
                size: _size * 0.5,
              ),
      ),
    );
  }
}

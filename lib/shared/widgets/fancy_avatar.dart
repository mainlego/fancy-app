import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';

enum AvatarSize { small, medium, large, xlarge }

/// Avatar frame color
const _avatarFrameColor = Color(0xFF1F1D1B);

/// FANCY styled avatar - square with frame
/// Avatar: 56x56, Frame: 88x88 (for chat list)
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

  /// Avatar image size (square)
  double get _imageSize {
    switch (size) {
      case AvatarSize.small:
        return 32;
      case AvatarSize.medium:
        return 56; // Per Figma spec
      case AvatarSize.large:
        return 72;
      case AvatarSize.xlarge:
        return 96;
    }
  }

  /// Frame size around avatar
  double get _frameSize {
    switch (size) {
      case AvatarSize.small:
        return 44;
      case AvatarSize.medium:
        return 88; // Per Figma spec (88x88 frame)
      case AvatarSize.large:
        return 96;
      case AvatarSize.xlarge:
        return 120;
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
          // Frame container
          Container(
            width: _frameSize,
            height: _frameSize,
            color: _avatarFrameColor,
            child: Center(
              // Square avatar inside frame
              child: Container(
                width: _imageSize,
                height: _imageSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.zero,
                  border: showBorder
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
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
          ),
          if (isOnline)
            Positioned(
              left: (_frameSize - _imageSize) / 2,
              bottom: (_frameSize - _imageSize) / 2,
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
              right: (_frameSize - _imageSize) / 2,
              bottom: (_frameSize - _imageSize) / 2,
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
                  fontSize: _imageSize * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              )
            : Icon(
                Icons.person,
                color: AppColors.textTertiary,
                size: _imageSize * 0.5,
              ),
      ),
    );
  }
}

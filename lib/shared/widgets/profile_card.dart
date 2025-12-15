import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_typography.dart';
import '../../features/profile/domain/models/user_model.dart';
import 'fancy_chip.dart';

/// Profile card for home feed
class ProfileCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final VoidCallback? onMore;

  const ProfileCard({
    super.key,
    required this.user,
    this.onTap,
    this.onLike,
    this.onMore,
  });

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard> {
  int _currentPhotoIndex = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.zero,
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Photo section
            Expanded(
              flex: 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Photo
                  _buildPhoto(),

                  // Photo indicators
                  if (widget.user.photos.length > 1)
                    Positioned(
                      top: AppSpacing.md,
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      child: _buildPhotoIndicators(),
                    ),

                  // Gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 120,
                      decoration: const BoxDecoration(
                        gradient: AppColors.cardGradient,
                      ),
                    ),
                  ),

                  // Status badges
                  Positioned(
                    top: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _buildStatusBadges(),
                  ),

                  // More button
                  Positioned(
                    top: AppSpacing.md + 30,
                    right: AppSpacing.md,
                    child: _buildMoreButton(),
                  ),

                  // User info overlay
                  Positioned(
                    bottom: AppSpacing.md,
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    child: _buildUserInfo(),
                  ),
                ],
              ),
            ),

            // Actions section
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildActions(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (widget.user.photos.isEmpty) {
      return Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: AppColors.textTertiary,
          ),
        ),
      );
    }

    return GestureDetector(
      onTapUp: (details) {
        final width = context.size?.width ?? 300;
        final tapX = details.localPosition.dx;

        if (tapX < width / 3) {
          // Tap left - previous photo
          if (_currentPhotoIndex > 0) {
            setState(() => _currentPhotoIndex--);
          }
        } else if (tapX > width * 2 / 3) {
          // Tap right - next photo
          if (_currentPhotoIndex < widget.user.photos.length - 1) {
            setState(() => _currentPhotoIndex++);
          }
        }
      },
      child: CachedNetworkImage(
        imageUrl: widget.user.photos[_currentPhotoIndex],
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(
              color: AppColors.primary,
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoIndicators() {
    return Row(
      children: List.generate(
        widget.user.photos.length,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(
              right: index < widget.user.photos.length - 1 ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: index == _currentPhotoIndex
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.zero,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadges() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (widget.user.isOnline)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: const BoxDecoration(
              color: AppColors.online,
              borderRadius: BorderRadius.zero,
            ),
            child: const Text(
              'Online',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        if (widget.user.isVerified) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.verified,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: AppColors.textPrimary,
              size: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMoreButton() {
    return GestureDetector(
      onTap: widget.onMore,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: const BoxDecoration(
          color: AppColors.overlay,
          borderRadius: BorderRadius.zero,
        ),
        child: const Icon(
          Icons.more_horiz,
          color: AppColors.textPrimary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildUserInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Name and age
        Row(
          children: [
            Expanded(
              child: Text(
                '${widget.user.name}, ${widget.user.age}',
                style: AppTypography.headlineMedium.copyWith(
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.user.isPremium)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.premium,
                  borderRadius: BorderRadius.zero,
                ),
                child: const Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
        AppSpacing.vGapXs,

        // Location and distance
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.user.distanceKm != null
                    ? '${widget.user.city ?? ''} ${widget.user.distanceKm} km'
                    : widget.user.locationString,
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,

        // Tags
        FancyChipWrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            if (widget.user.datingGoal != null)
              _buildTag(_getDatingGoalText(widget.user.datingGoal!)),
            if (widget.user.relationshipStatus != null)
              _buildTag(_getStatusText(widget.user.relationshipStatus!)),
          ],
        ),
      ],
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.overlay,
        borderRadius: BorderRadius.zero,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Like button
        _ActionButton(
          icon: Icons.favorite,
          color: AppColors.like,
          onTap: widget.onLike,
        ),
      ],
    );
  }

  String _getDatingGoalText(DatingGoal goal) {
    switch (goal) {
      case DatingGoal.anything:
        return 'Anything';
      case DatingGoal.casual:
        return 'Casual';
      case DatingGoal.virtual:
        return 'Virtual';
      case DatingGoal.friendship:
        return 'Friendship';
      case DatingGoal.longTerm:
        return 'Long-term';
    }
  }

  String _getStatusText(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.single:
        return 'Single';
      case RelationshipStatus.complicated:
        return 'Complicated';
      case RelationshipStatus.married:
        return 'Married';
      case RelationshipStatus.inRelationship:
        return 'In a relationship';
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 28,
        ),
      ),
    );
  }
}

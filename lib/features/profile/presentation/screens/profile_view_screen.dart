import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../home/domain/providers/profiles_provider.dart';
import '../../../home/presentation/widgets/match_dialog.dart';
import '../../domain/models/user_model.dart';

/// Profile view screen (viewing other user's profile)
class ProfileViewScreen extends ConsumerStatefulWidget {
  final String userId;

  const ProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  ConsumerState<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends ConsumerState<ProfileViewScreen> {
  int _currentPhotoIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use filteredProfilesProvider to include AI profiles
    final profiles = ref.watch(filteredProfilesProvider);

    UserModel? foundUser;
    try {
      foundUser = profiles.firstWhere((p) => p.id == widget.userId);
    } catch (_) {
      foundUser = null;
    }

    if (foundUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          ),
        ),
        body: const Center(
          child: Text(
            'Profile not found',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    final user = foundUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            slivers: [
              // Photo carousel
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.55,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photos
                      PageView.builder(
                        controller: _pageController,
                        itemCount: user.photos.length,
                        onPageChanged: (index) {
                          setState(() => _currentPhotoIndex = index);
                        },
                        itemBuilder: (context, index) {
                          return CachedNetworkImage(
                            imageUrl: user.photos[index],
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.surfaceVariant,
                              child: const Icon(
                                Icons.broken_image,
                                size: 48,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          );
                        },
                      ),

                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 150,
                          decoration: const BoxDecoration(
                            gradient: AppColors.cardGradient,
                          ),
                        ),
                      ),

                      // Photo indicators
                      if (user.photos.length > 1)
                        Positioned(
                          top: MediaQuery.of(context).padding.top + AppSpacing.md,
                          left: AppSpacing.lg,
                          right: AppSpacing.lg,
                          child: _buildPhotoIndicators(user.photos.length),
                        ),

                      // Back button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                        left: AppSpacing.md,
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.overlay,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      // More button
                      Positioned(
                        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
                        right: AppSpacing.md,
                        child: IconButton(
                          onPressed: () => _showMoreOptions(context, user),
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.overlay,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                            ),
                            child: const Icon(
                              Icons.more_horiz,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),

                      // User basic info
                      Positioned(
                        bottom: AppSpacing.lg,
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        child: _buildUserBasicInfo(user),
                      ),
                    ],
                  ),
                ),
              ),

              // Profile details
              SliverToBoxAdapter(
                child: ContentContainer(
                  maxWidth: 500,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSpacing.vGapLg,

                      // Bio
                      if (user.bio != null) ...[
                        Text(
                          'About',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          user.bio!,
                          style: AppTypography.bodyMedium,
                        ),
                        AppSpacing.vGapXl,
                      ],

                      // Details
                      _buildDetailsSection(user),
                      AppSpacing.vGapXl,

                      // Interests
                      if (user.interests.isNotEmpty) ...[
                        Text(
                          'Interests',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        FancyChipWrap(
                          children: user.interests.map((interest) {
                            return FancyChip(label: interest);
                          }).toList(),
                        ),
                        AppSpacing.vGapXl,
                      ],

                      // Spacer for bottom buttons
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.background.withOpacity(0),
                    AppColors.background,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Like button
                  FancyActionButton(
                    icon: Icons.favorite,
                    backgroundColor: AppColors.like,
                    iconColor: AppColors.textPrimary,
                    size: 64,
                    onPressed: () => _handleLike(user),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoIndicators(int count) {
    return Row(
      children: List.generate(
        count,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
            decoration: BoxDecoration(
              color: index == _currentPhotoIndex
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserBasicInfo(UserModel user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${user.name}, ${user.age}',
                style: AppTypography.displaySmall.copyWith(
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
            if (user.isOnline)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.online,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
            if (user.isVerified) ...[
              AppSpacing.hGapSm,
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
        ),
        AppSpacing.vGapXs,
        Row(
          children: [
            const Icon(
              Icons.location_on,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              user.distanceKm != null
                  ? '${user.city ?? ''} • ${user.distanceKm} km away'
                  : user.locationString,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailsSection(UserModel user) {
    return FancyCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (user.datingGoal != null)
            _buildDetailTile(
              Icons.favorite_outline,
              'Looking for',
              _getDatingGoalText(user.datingGoal!),
            ),
          if (user.relationshipStatus != null) ...[
            const Divider(height: 1),
            _buildDetailTile(
              Icons.people_outline,
              'Status',
              _getStatusText(user.relationshipStatus!),
            ),
          ],
          if (user.heightCm != null) ...[
            const Divider(height: 1),
            _buildDetailTile(
              Icons.height,
              'Height',
              '${user.heightCm} cm',
            ),
          ],
          if (user.occupation != null) ...[
            const Divider(height: 1),
            _buildDetailTile(
              Icons.work_outline,
              'Occupation',
              user.occupation!,
            ),
          ],
          if (user.zodiacSign != null) ...[
            const Divider(height: 1),
            _buildDetailTile(
              Icons.auto_awesome,
              'Zodiac',
              _getZodiacText(user.zodiacSign!),
            ),
          ],
          if (user.languages.isNotEmpty) ...[
            const Divider(height: 1),
            _buildDetailTile(
              Icons.language,
              'Languages',
              user.languages.join(', '),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          AppSpacing.hGapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLike(UserModel user) async {
    final isMatch = await ref.read(profilesNotifierProvider.notifier).likeUser(user.id);

    if (!mounted) return;

    if (isMatch) {
      // It's a match!
      MatchDialog.show(
        context,
        matchedUser: user,
        onSendMessage: () {
          Navigator.pop(context); // Close profile view
          context.pushChatDetail(user.id);
        },
        onKeepBrowsing: () {
          Navigator.pop(context); // Close profile view
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Liked ${user.name}!'),
          backgroundColor: AppColors.like,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context); // Go back after like
    }
  }

  void _showMoreOptions(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text('Report'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.warning),
              title: const Text('Block'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: AppColors.textSecondary),
              title: const Text('Hide'),
              onTap: () => Navigator.pop(context),
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
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

  String _getZodiacText(ZodiacSign sign) {
    switch (sign) {
      case ZodiacSign.aries:
        return 'Aries';
      case ZodiacSign.taurus:
        return 'Taurus';
      case ZodiacSign.gemini:
        return 'Gemini';
      case ZodiacSign.cancer:
        return 'Cancer';
      case ZodiacSign.leo:
        return 'Leo';
      case ZodiacSign.virgo:
        return 'Virgo';
      case ZodiacSign.libra:
        return 'Libra';
      case ZodiacSign.scorpio:
        return 'Scorpio';
      case ZodiacSign.sagittarius:
        return 'Sagittarius';
      case ZodiacSign.capricorn:
        return 'Capricorn';
      case ZodiacSign.aquarius:
        return 'Aquarius';
      case ZodiacSign.pisces:
        return 'Pisces';
    }
  }
}

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../albums/domain/models/album_model.dart';
import '../../../albums/domain/models/access_request_model.dart';
import '../../../albums/domain/providers/albums_provider.dart';
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
    // First try to find in filtered profiles (discovery feed)
    final profiles = ref.watch(filteredProfilesProvider);
    UserModel? foundUser;
    try {
      foundUser = profiles.firstWhere((p) => p.id == widget.userId);
    } catch (_) {
      foundUser = null;
    }

    // If not found in discovery, load directly from database
    final profileAsync = ref.watch(profileByIdProvider(widget.userId));

    // Use found user or loaded profile
    final user = foundUser ?? profileAsync.valueOrNull;

    // Show loading while fetching from database
    if (user == null && profileAsync.isLoading) {
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Profile not found anywhere
    if (user == null) {
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

                      // Albums section
                      _buildAlbumsSection(user),

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

  Widget _buildAlbumsSection(UserModel user) {
    final albumsAsync = ref.watch(userAlbumsProvider(user.id));

    return albumsAsync.when(
      data: (albums) {
        if (albums.isEmpty) return const SizedBox.shrink();

        final publicAlbums = albums.where((a) => !a.isPrivate).toList();
        final privateAlbums = albums.where((a) => a.isPrivate).toList();

        if (publicAlbums.isEmpty && privateAlbums.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Albums',
              style: AppTypography.titleMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vGapMd,

            // Public album
            if (publicAlbums.isNotEmpty && publicAlbums.first.media.isNotEmpty)
              _buildAlbumSection(
                'Public Photos',
                publicAlbums.first,
                user,
                isPrivate: false,
              ),

            // Private album
            if (privateAlbums.isNotEmpty && privateAlbums.first.media.isNotEmpty)
              _buildAlbumSection(
                'Private Photos',
                privateAlbums.first,
                user,
                isPrivate: true,
              ),

            AppSpacing.vGapXl,
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildAlbumSection(
    String title,
    AlbumModel album,
    UserModel user, {
    required bool isPrivate,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isPrivate ? Icons.lock : Icons.public,
              size: 16,
              color: isPrivate ? AppColors.warning : AppColors.success,
            ),
            AppSpacing.hGapSm,
            Text(
              title,
              style: AppTypography.labelMedium.copyWith(
                color: isPrivate ? AppColors.warning : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              '${album.media.length} photos',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        AppSpacing.vGapSm,
        if (isPrivate)
          _buildPrivateAlbumGrid(album, user)
        else
          _buildPublicAlbumGrid(album),
        AppSpacing.vGapMd,
      ],
    );
  }

  Widget _buildPublicAlbumGrid(AlbumModel album) {
    final displayMedia = album.media.take(6).toList();
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: displayMedia.length,
        separatorBuilder: (_, __) => AppSpacing.hGapSm,
        itemBuilder: (context, index) {
          final media = displayMedia[index];
          return GestureDetector(
            onTap: () => _showPhotoViewer(context, media.url),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: media.displayUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.surfaceVariant,
                ),
                errorWidget: (_, __, ___) => Container(
                  width: 100,
                  height: 100,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrivateAlbumGrid(AlbumModel album, UserModel user) {
    // Check if current user has access to this private album
    final hasAccessAsync = ref.watch(albumAccessProvider(album.id));
    final hasAccess = hasAccessAsync.valueOrNull ?? false;

    final displayMedia = album.media.take(6).toList();
    return Column(
      children: [
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: displayMedia.length,
            separatorBuilder: (_, __) => AppSpacing.hGapSm,
            itemBuilder: (context, index) {
              final media = displayMedia[index];
              return GestureDetector(
                onTap: hasAccess
                    ? () => _showPhotoViewer(context, media.url)
                    : () => _showRequestAccessDialog(context, album, user),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Stack(
                    children: [
                      // Blurred image
                      CachedNetworkImage(
                        imageUrl: media.displayUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          width: 100,
                          height: 100,
                          color: AppColors.surfaceVariant,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          width: 100,
                          height: 100,
                          color: AppColors.surfaceVariant,
                          child: const Icon(Icons.broken_image),
                        ),
                      ),
                      // Blur overlay if no access
                      if (!hasAccess)
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                              child: Container(
                                color: AppColors.overlay,
                                child: const Icon(
                                  Icons.lock,
                                  color: AppColors.warning,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Request access button
        if (!hasAccess)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: _buildAccessRequestButton(album, user),
          ),
      ],
    );
  }

  Widget _buildAccessRequestButton(AlbumModel album, UserModel user) {
    final requestStatusAsync = ref.watch(albumAccessRequestStatusProvider(album.id));

    return requestStatusAsync.when(
      data: (status) {
        if (status == AccessRequestStatus.pending) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.hourglass_empty, size: 16, color: AppColors.warning),
                AppSpacing.hGapSm,
                Text(
                  'Request pending',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          );
        }

        if (status == AccessRequestStatus.denied) {
          return Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.block, size: 16, color: AppColors.error),
                AppSpacing.hGapSm,
                Text(
                  'Request denied',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          );
        }

        // No request yet - show request button
        return TextButton.icon(
          onPressed: () => _showRequestAccessDialog(context, album, user),
          icon: const Icon(Icons.lock_open, size: 16),
          label: const Text('Request Access'),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      error: (_, __) => TextButton.icon(
        onPressed: () => _showRequestAccessDialog(context, album, user),
        icon: const Icon(Icons.lock_open, size: 16),
        label: const Text('Request Access'),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
    );
  }

  void _showRequestAccessDialog(BuildContext context, AlbumModel album, UserModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Request Access',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Would you like to request access to ${user.name}\'s private photos? They will be notified of your request.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _requestAccess(album, user);
            },
            child: const Text('Request', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _requestAccess(AlbumModel album, UserModel user) async {
    try {
      await ref.read(accessRequestsNotifierProvider.notifier).requestAccess(
        album.id,
        user.id,
      );
      // Refresh the status provider
      ref.invalidate(albumAccessRequestStatusProvider(album.id));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Request sent to ${user.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showPhotoViewer(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _PhotoViewerScreen(imageUrl: imageUrl),
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

/// Photo viewer screen
class _PhotoViewerScreen extends StatelessWidget {
  final String imageUrl;

  const _PhotoViewerScreen({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

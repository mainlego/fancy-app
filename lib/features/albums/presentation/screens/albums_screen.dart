import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/album_model.dart';

/// Mock albums provider
final mockAlbumsProvider = Provider<List<AlbumModel>>((ref) {
  final now = DateTime.now();
  return [
    AlbumModel(
      id: 'album1',
      userId: 'me',
      name: 'Public Photos',
      privacy: AlbumPrivacy.public,
      media: [
        MediaModel(
          id: 'm1',
          albumId: 'album1',
          type: MediaType.photo,
          url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          createdAt: now.subtract(const Duration(days: 10)),
        ),
        MediaModel(
          id: 'm2',
          albumId: 'album1',
          type: MediaType.photo,
          url: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
          createdAt: now.subtract(const Duration(days: 8)),
        ),
        MediaModel(
          id: 'm3',
          albumId: 'album1',
          type: MediaType.video,
          url: 'https://example.com/video.mp4',
          thumbnailUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=400',
          durationMs: 15000,
          createdAt: now.subtract(const Duration(days: 5)),
        ),
      ],
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 5)),
    ),
    AlbumModel(
      id: 'album2',
      userId: 'me',
      name: 'Private',
      privacy: AlbumPrivacy.private,
      media: [
        MediaModel(
          id: 'm4',
          albumId: 'album2',
          type: MediaType.photo,
          url: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
          createdAt: now.subtract(const Duration(days: 3)),
        ),
      ],
      createdAt: now.subtract(const Duration(days: 20)),
      updatedAt: now.subtract(const Duration(days: 3)),
    ),
  ];
});

/// Current album tab
enum AlbumTab { public, private }

final albumTabProvider = StateProvider<AlbumTab>((ref) => AlbumTab.public);

/// Albums screen
class AlbumsScreen extends ConsumerWidget {
  const AlbumsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(mockAlbumsProvider);
    final currentTab = ref.watch(albumTabProvider);

    final publicAlbums = albums.where((a) => !a.isPrivate).toList();
    final privateAlbums = albums.where((a) => a.isPrivate).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMediaDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(ref, currentTab),

          // Content
          Expanded(
            child: currentTab == AlbumTab.public
                ? _buildAlbumGrid(context, publicAlbums)
                : _buildPrivateContent(context, privateAlbums),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, AlbumTab currentTab) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Public',
              isSelected: currentTab == AlbumTab.public,
              onTap: () => ref.read(albumTabProvider.notifier).state = AlbumTab.public,
            ),
          ),
          AppSpacing.hGapMd,
          Expanded(
            child: _TabButton(
              label: 'Private',
              isSelected: currentTab == AlbumTab.private,
              onTap: () => ref.read(albumTabProvider.notifier).state = AlbumTab.private,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGrid(BuildContext context, List<AlbumModel> albums) {
    if (albums.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No public media',
        subtitle: 'Add photos and videos to share with others',
      );
    }

    // Flatten all media from albums
    final allMedia = albums.expand((a) => a.media).toList();

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: allMedia.length + 1, // +1 for add button
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddMediaTile(context);
        }
        return _MediaTile(
          media: allMedia[index - 1],
          onTap: () => _showMediaViewer(context, allMedia[index - 1]),
          onLongPress: () => _showMediaOptions(context, allMedia[index - 1]),
        );
      },
    );
  }

  Widget _buildPrivateContent(BuildContext context, List<AlbumModel> albums) {
    return Column(
      children: [
        // Private info card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: FancyCard(
            backgroundColor: AppColors.surfaceVariant,
            child: Row(
              children: [
                const Icon(
                  Icons.lock,
                  color: AppColors.primary,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Private media',
                        style: AppTypography.titleSmall,
                      ),
                      Text(
                        'Only you can see these. Not even developers can access them.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AppSpacing.vGapLg,

        // Private media grid
        Expanded(
          child: albums.isEmpty || albums.first.media.isEmpty
              ? _buildEmptyState(
                  icon: Icons.lock_outline,
                  title: 'No private media',
                  subtitle: 'Your private photos and videos will appear here',
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: AppSpacing.sm,
                    mainAxisSpacing: AppSpacing.sm,
                  ),
                  itemCount: albums.first.media.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddMediaTile(context);
                    }
                    return _MediaTile(
                      media: albums.first.media[index - 1],
                      onTap: () => _showMediaViewer(context, albums.first.media[index - 1]),
                      onLongPress: () => _showMediaOptions(context, albums.first.media[index - 1]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAddMediaTile(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddMediaDialog(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.add,
            color: AppColors.textTertiary,
            size: 32,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vGapLg,
          Text(
            title,
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            subtitle,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddMediaDialog(BuildContext context) {
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
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Add photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle add photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.info),
              title: const Text('Add video'),
              onTap: () {
                Navigator.pop(context);
                // Handle add video
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.warning),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle take photo
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _showMediaViewer(BuildContext context, MediaModel media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaViewerScreen(media: media),
      ),
    );
  }

  void _showMediaOptions(BuildContext context, MediaModel media) {
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
              leading: const Icon(Icons.edit, color: AppColors.textSecondary),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                // Handle delete
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.labelLarge.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final MediaModel media;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _MediaTile({
    required this.media,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          color: AppColors.surfaceVariant,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              media.displayUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => const Center(
                child: Icon(
                  Icons.broken_image,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            if (media.isVideo)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.overlay,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow,
                        color: AppColors.textPrimary,
                        size: 12,
                      ),
                      if (media.durationMs != null) ...[
                        const SizedBox(width: 2),
                        Text(
                          _formatDuration(media.durationMs!),
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int ms) {
    final seconds = ms ~/ 1000;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}

class _MediaViewerScreen extends StatelessWidget {
  final MediaModel media;

  const _MediaViewerScreen({required this.media});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            media.url,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

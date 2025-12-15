import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/album_model.dart';
import '../../domain/providers/albums_provider.dart';

/// Current album tab
enum AlbumTab { public, private, requests }

final albumTabProvider = StateProvider<AlbumTab>((ref) => AlbumTab.public);

/// Albums screen
class AlbumsScreen extends ConsumerStatefulWidget {
  const AlbumsScreen({super.key});

  @override
  ConsumerState<AlbumsScreen> createState() => _AlbumsScreenState();
}

class _AlbumsScreenState extends ConsumerState<AlbumsScreen> {
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final defaultAlbumsAsync = ref.watch(defaultAlbumsProvider);
    final currentTab = ref.watch(albumTabProvider);
    final accessRequestsAsync = ref.watch(accessRequestsNotifierProvider);
    final pendingCount = ref.watch(pendingAccessRequestsCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Albums'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _isUploading ? null : () => _showAddMediaDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(ref, currentTab, pendingCount),

          // Content
          Expanded(
            child: defaultAlbumsAsync.when(
              data: (albums) {
                if (currentTab == AlbumTab.public) {
                  return _buildAlbumGrid(context, albums['public']!);
                } else if (currentTab == AlbumTab.private) {
                  return _buildPrivateContent(context, albums['private']!);
                } else {
                  return _buildRequestsTab(accessRequestsAsync);
                }
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, st) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    AppSpacing.vGapMd,
                    Text('Failed to load albums', style: AppTypography.bodyMedium),
                    AppSpacing.vGapSm,
                    TextButton(
                      onPressed: () => ref.invalidate(defaultAlbumsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, AlbumTab currentTab, int pendingCount) {
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
          AppSpacing.hGapSm,
          Expanded(
            child: _TabButton(
              label: 'Private',
              isSelected: currentTab == AlbumTab.private,
              onTap: () => ref.read(albumTabProvider.notifier).state = AlbumTab.private,
            ),
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: _TabButton(
              label: 'Requests',
              isSelected: currentTab == AlbumTab.requests,
              badge: pendingCount > 0 ? pendingCount : null,
              onTap: () => ref.read(albumTabProvider.notifier).state = AlbumTab.requests,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumGrid(BuildContext context, AlbumModel album) {
    final media = album.media;

    if (media.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'No public media',
        subtitle: 'Add photos and videos to share with others',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: media.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _buildAddMediaTile(context, isPrivate: false);
        }
        return _MediaTile(
          media: media[index - 1],
          onTap: () => _showMediaViewer(context, media[index - 1]),
          onLongPress: () => _showMediaOptions(context, album.id, media[index - 1]),
        );
      },
    );
  }

  Widget _buildPrivateContent(BuildContext context, AlbumModel album) {
    final media = album.media;

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
                        'Only visible to users you approve. Send with timed viewing in chat.',
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
          child: media.isEmpty
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
                  itemCount: media.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildAddMediaTile(context, isPrivate: true);
                    }
                    return _MediaTile(
                      media: media[index - 1],
                      onTap: () => _showMediaViewer(context, media[index - 1]),
                      onLongPress: () => _showMediaOptions(context, album.id, media[index - 1]),
                      showPrivateIndicator: true,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRequestsTab(AsyncValue<List<dynamic>> requestsAsync) {
    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No access requests',
            subtitle: 'When someone requests access to your private album, it will appear here',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _AccessRequestTile(
              requesterName: request.requesterName ?? 'Unknown',
              requesterAvatarUrl: request.requesterAvatarUrl,
              albumName: request.albumName ?? 'Private',
              createdAt: request.createdAt,
              onApprove: () => _handleRequestResponse(request.id, true),
              onDeny: () => _handleRequestResponse(request.id, false),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.vGapMd,
            Text('Failed to load requests', style: AppTypography.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildAddMediaTile(BuildContext context, {required bool isPrivate}) {
    return GestureDetector(
      onTap: _isUploading ? null : () => _showAddMediaDialog(context, isPrivate: isPrivate),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: AppColors.border,
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: _isUploading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(
                  isPrivate ? Icons.add_photo_alternate : Icons.add,
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              subtitle,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMediaDialog(BuildContext context, {bool? isPrivate}) {
    final currentTab = ref.read(albumTabProvider);
    final isPrivateUpload = isPrivate ?? (currentTab == AlbumTab.private);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
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
                borderRadius: BorderRadius.zero,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    isPrivateUpload ? Icons.lock : Icons.public,
                    color: isPrivateUpload ? AppColors.warning : AppColors.success,
                    size: 20,
                  ),
                  AppSpacing.hGapSm,
                  Text(
                    isPrivateUpload ? 'Adding to Private Album' : 'Adding to Public Album',
                    style: AppTypography.titleSmall,
                  ),
                ],
              ),
            ),
            AppSpacing.vGapMd,
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery, isPrivateUpload);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.warning),
              title: const Text('Take photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera, isPrivateUpload);
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, bool isPrivate) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (image == null) return;

    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final fileName = image.name;

      // Get the appropriate album
      final defaultAlbums = await ref.read(defaultAlbumsProvider.future);
      final album = isPrivate ? defaultAlbums['private']! : defaultAlbums['public']!;

      await ref.read(albumsNotifierProvider.notifier).uploadPhoto(
        albumId: album.id,
        fileName: fileName,
        bytes: bytes,
        isPrivate: isPrivate,
      );

      // Refresh the albums
      ref.invalidate(defaultAlbumsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Photo added to ${isPrivate ? "private" : "public"} album'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showMediaViewer(BuildContext context, MediaModel media) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _MediaViewerScreen(media: media),
      ),
    );
  }

  void _showMediaOptions(BuildContext context, String albumId, MediaModel media) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
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
                borderRadius: BorderRadius.zero,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: AppColors.error),
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, albumId, media);
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String albumId, MediaModel media) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Photo'),
        content: const Text('Are you sure you want to delete this photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(albumsNotifierProvider.notifier).deletePhoto(
                  albumId,
                  media.id,
                  media.url,
                );
                ref.invalidate(defaultAlbumsProvider);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Photo deleted'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to delete: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _handleRequestResponse(String requestId, bool approve) async {
    try {
      await ref.read(accessRequestsNotifierProvider.notifier).respondToRequest(requestId, approve);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(approve ? 'Access granted' : 'Access denied'),
            backgroundColor: approve ? AppColors.success : AppColors.textSecondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final int? badge;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    this.badge,
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
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTypography.labelLarge.copyWith(
                  color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: Text(
                    badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
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
  final bool showPrivateIndicator;

  const _MediaTile({
    required this.media,
    required this.onTap,
    required this.onLongPress,
    this.showPrivateIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.zero,
          color: AppColors.surfaceVariant,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: media.displayUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const Center(
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
                    borderRadius: BorderRadius.zero,
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
            if (showPrivateIndicator || media.isPrivate)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.overlay,
                    borderRadius: BorderRadius.zero,
                  ),
                  child: const Icon(
                    Icons.lock,
                    color: AppColors.warning,
                    size: 12,
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

class _AccessRequestTile extends StatelessWidget {
  final String requesterName;
  final String? requesterAvatarUrl;
  final String albumName;
  final DateTime createdAt;
  final VoidCallback onApprove;
  final VoidCallback onDeny;

  const _AccessRequestTile({
    required this.requesterName,
    this.requesterAvatarUrl,
    required this.albumName,
    required this.createdAt,
    required this.onApprove,
    required this.onDeny,
  });

  @override
  Widget build(BuildContext context) {
    return FancyCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: requesterAvatarUrl != null
                    ? CachedNetworkImageProvider(requesterAvatarUrl!)
                    : null,
                child: requesterAvatarUrl == null
                    ? const Icon(Icons.person, color: AppColors.textTertiary)
                    : null,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      requesterName,
                      style: AppTypography.titleMedium,
                    ),
                    Text(
                      'Wants to view your $albumName album',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDeny,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  child: const Text('Deny'),
                ),
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: ElevatedButton(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
          child: CachedNetworkImage(
            imageUrl: media.url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }
}

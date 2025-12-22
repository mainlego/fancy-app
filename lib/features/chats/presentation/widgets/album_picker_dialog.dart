import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../albums/domain/models/album_model.dart';
import '../../../albums/domain/providers/albums_provider.dart';

/// Result from album picker dialog
class AlbumPickerResult {
  final MediaModel media;
  final bool isPrivate;
  final bool oneTimeView;
  final int? viewDurationSec;

  AlbumPickerResult({
    required this.media,
    required this.isPrivate,
    this.oneTimeView = false,
    this.viewDurationSec,
  });
}

/// Album picker dialog for selecting photos to send in chat
class AlbumPickerDialog extends ConsumerStatefulWidget {
  const AlbumPickerDialog({super.key});

  /// Show the album picker dialog and return the selected media
  static Future<AlbumPickerResult?> show(BuildContext context) async {
    return showModalBottomSheet<AlbumPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => const AlbumPickerDialog(),
      ),
    );
  }

  @override
  ConsumerState<AlbumPickerDialog> createState() => _AlbumPickerDialogState();
}

class _AlbumPickerDialogState extends ConsumerState<AlbumPickerDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  MediaModel? _selectedMedia;
  bool _isPrivateMedia = false;
  bool _oneTimeView = false;
  int? _viewDurationSec;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final albumsAsync = ref.watch(defaultAlbumsProvider);

    return Column(
      children: [
        // Handle
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.textTertiary,
            borderRadius: BorderRadius.zero,
          ),
        ),

        // Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Send from Albums',
                style: AppTypography.titleLarge,
              ),
              if (_selectedMedia != null)
                TextButton(
                  onPressed: _sendMedia,
                  child: const Text('Send'),
                ),
            ],
          ),
        ),
        AppSpacing.vGapMd,

        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Public'),
            Tab(text: 'Private'),
          ],
        ),

        // Content
        Expanded(
          child: albumsAsync.when(
            data: (albums) => TabBarView(
              controller: _tabController,
              children: [
                _buildPhotoGrid(albums['public']!, isPrivate: false),
                _buildPhotoGrid(albums['private']!, isPrivate: true),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(
              child: Text('Failed to load albums: $e'),
            ),
          ),
        ),

        // Privacy options for selected private media
        if (_selectedMedia != null && _isPrivateMedia) _buildPrivacyOptions(),
      ],
    );
  }

  Widget _buildPhotoGrid(AlbumModel album, {required bool isPrivate}) {
    final media = album.media;

    if (media.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isPrivate ? Icons.lock_outline : Icons.photo_library_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
            AppSpacing.vGapMd,
            Text(
              isPrivate ? 'No private photos' : 'No public photos',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
      ),
      itemCount: media.length,
      itemBuilder: (context, index) {
        final item = media[index];
        final isSelected = _selectedMedia?.id == item.id;

        return GestureDetector(
          onTap: () => _selectMedia(item, isPrivate),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.zero,
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 3)
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CachedNetworkImage(
                  imageUrl: item.displayUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image),
                  ),
                ),
                if (isPrivate)
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
                if (isSelected)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPrivacyOptions() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: AppSpacing.lg + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.visibility_off, color: AppColors.warning, size: 20),
              AppSpacing.hGapSm,
              Text(
                'Private photo options',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          AppSpacing.vGapMd,

          // One-time view toggle
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'One-time view',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Photo disappears after viewing',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _oneTimeView,
                onChanged: (value) {
                  setState(() {
                    _oneTimeView = value;
                    if (value) {
                      _viewDurationSec = null; // One-time view doesn't need duration
                    }
                  });
                },
              ),
            ],
          ),

          // Duration picker (only if not one-time view)
          if (!_oneTimeView) ...[
            AppSpacing.vGapSm,
            Text(
              'View duration',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vGapSm,
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                _DurationChip(
                  label: '5s',
                  isSelected: _viewDurationSec == 5,
                  onTap: () => setState(() => _viewDurationSec = 5),
                ),
                _DurationChip(
                  label: '10s',
                  isSelected: _viewDurationSec == 10,
                  onTap: () => setState(() => _viewDurationSec = 10),
                ),
                _DurationChip(
                  label: '30s',
                  isSelected: _viewDurationSec == 30,
                  onTap: () => setState(() => _viewDurationSec = 30),
                ),
                _DurationChip(
                  label: 'Unlimited',
                  isSelected: _viewDurationSec == null,
                  onTap: () => setState(() => _viewDurationSec = null),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _selectMedia(MediaModel media, bool isPrivate) {
    setState(() {
      if (_selectedMedia?.id == media.id) {
        // Deselect
        _selectedMedia = null;
        _isPrivateMedia = false;
        _oneTimeView = false;
        _viewDurationSec = null;
      } else {
        // Select
        _selectedMedia = media;
        _isPrivateMedia = isPrivate;
        // Default: one-time view for private, nothing for public
        _oneTimeView = isPrivate;
        _viewDurationSec = null;
      }
    });
  }

  void _sendMedia() {
    if (_selectedMedia == null) return;

    Navigator.pop(
      context,
      AlbumPickerResult(
        media: _selectedMedia!,
        isPrivate: _isPrivateMedia,
        oneTimeView: _isPrivateMedia ? _oneTimeView : false,
        viewDurationSec: _isPrivateMedia && !_oneTimeView ? _viewDurationSec : null,
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _DurationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.zero,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

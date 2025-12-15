import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../features/profile/domain/models/user_model.dart';

/// Swipeable profile card - exact Figma design
/// Height: 400px normal, 500px expanded
/// Info panel: 90px
/// No border radius
class SwipeableProfileCard extends StatefulWidget {
  final UserModel user;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onLike;
  final VoidCallback? onSuperLike;
  final VoidCallback? onHide;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;

  const SwipeableProfileCard({
    super.key,
    required this.user,
    this.onDoubleTap,
    this.onLike,
    this.onSuperLike,
    this.onHide,
    this.onBlock,
    this.onReport,
  });

  @override
  State<SwipeableProfileCard> createState() => _SwipeableProfileCardState();
}

class _SwipeableProfileCardState extends State<SwipeableProfileCard> {
  static const double _normalHeight = 400.0;
  static const double _expandedHeight = 500.0;
  static const double _infoPanelHeight = 90.0;

  int _currentMediaIndex = 0;
  bool _isExpanded = false;
  bool _showingBio = false;
  DateTime? _lastTapTime;

  /// Total media count (photos + bio as last item)
  int get _totalSlides => widget.user.photos.length + 1; // +1 for bio

  /// Check if current slide is bio
  bool get _isCurrentSlideBio => _currentMediaIndex >= widget.user.photos.length;

  void _handleTap() {
    final now = DateTime.now();

    // Check for double tap
    if (_lastTapTime != null &&
        now.difference(_lastTapTime!).inMilliseconds < 300) {
      // Double tap - open profile page
      widget.onDoubleTap?.call();
      _lastTapTime = null;
      return;
    }

    _lastTapTime = now;

    // Single tap - toggle expand
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_lastTapTime != null &&
          DateTime.now().difference(_lastTapTime!).inMilliseconds >= 300) {
        setState(() => _isExpanded = !_isExpanded);
        _lastTapTime = null;
      }
    });
  }

  void _handleHorizontalDrag(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;

    if (velocity.abs() > 200) {
      if (velocity < 0) {
        // Swipe left - next
        if (_currentMediaIndex < _totalSlides - 1) {
          setState(() {
            _currentMediaIndex++;
            _showingBio = _isCurrentSlideBio;
          });
        }
      } else {
        // Swipe right - previous
        if (_currentMediaIndex > 0) {
          setState(() {
            _currentMediaIndex--;
            _showingBio = _isCurrentSlideBio;
          });
        }
      }
    }
  }

  void _showMoreMenu() {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => _MoreMenuDialog(
        onHide: () {
          Navigator.pop(context);
          widget.onHide?.call();
        },
        onBlock: () {
          Navigator.pop(context);
          widget.onBlock?.call();
        },
        onReport: () {
          Navigator.pop(context);
          widget.onReport?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = _isExpanded ? _expandedHeight : _normalHeight;

    return GestureDetector(
      onTap: _handleTap,
      onHorizontalDragEnd: _handleHorizontalDrag,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        height: currentHeight,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          // No border radius as per design
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Photo/Video/Bio area - takes remaining height
            Expanded(
              child: _showingBio ? _buildBioContent() : _buildMediaContent(),
            ),
            // Info panel - fixed 90px
            SizedBox(
              height: _infoPanelHeight,
              child: _buildInfoPanel(),
            ),
          ],
        ),
      ),
    );
  }

  /// Media content (photos/videos)
  Widget _buildMediaContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Photo
        _buildPhoto(),

        // Media indicators at top
        if (_totalSlides > 1)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildMediaIndicators(),
          ),
      ],
    );
  }

  /// Bio content
  Widget _buildBioContent() {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: AppColors.surface,
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Text(
              widget.user.bio ?? 'No description yet...',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.6,
                fontSize: 15,
              ),
            ),
          ),
        ),

        // Media indicators at top
        if (_totalSlides > 1)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: _buildMediaIndicators(),
          ),
      ],
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

    // Ensure index is within bounds for photos
    final photoIndex = _currentMediaIndex.clamp(0, widget.user.photos.length - 1);

    return CachedNetworkImage(
      imageUrl: widget.user.photos[photoIndex],
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: AppColors.surfaceVariant,
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
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
    );
  }

  /// Media indicators (photos + bio)
  Widget _buildMediaIndicators() {
    return Row(
      children: List.generate(
        _totalSlides,
        (index) => Expanded(
          child: Container(
            height: 3,
            margin: EdgeInsets.only(
              right: index < _totalSlides - 1 ? 4 : 0,
            ),
            decoration: BoxDecoration(
              color: index == _currentMediaIndex
                  ? AppColors.textPrimary
                  : AppColors.textPrimary.withValues(alpha: 0.3),
              // Small radius for indicators only
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom info panel - 90px height
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      color: AppColors.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row with info text and action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left side - text info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dating goal • relationship status
                    _buildInfoRow([
                      if (widget.user.datingGoal != null)
                        _getDatingGoalText(widget.user.datingGoal!),
                      if (widget.user.relationshipStatus != null)
                        _getStatusText(widget.user.relationshipStatus!),
                    ]),
                    const SizedBox(height: 1),

                    // online • verified
                    _buildStatusRow(),
                    const SizedBox(height: 1),

                    // location • distance
                    _buildLocationRow(),
                  ],
                ),
              ),

              // Right side - action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Fire button (Super Like)
                  GestureDetector(
                    onTap: widget.onSuperLike,
                    child: Image.asset(
                      AppAssets.icSuperLike,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Heart button (Like)
                  GestureDetector(
                    onTap: widget.onLike,
                    child: Image.asset(
                      AppAssets.icLike,
                      width: 40,
                      height: 40,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Three dots menu - centered
          GestureDetector(
            onTap: _showMoreMenu,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 20),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDot(),
                  const SizedBox(width: 4),
                  _buildDot(),
                  const SizedBox(width: 4),
                  _buildDot(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(List<String> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Text(
      items.join(' • '),
      style: AppTypography.bodyMedium.copyWith(
        color: AppColors.infoText,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    );
  }

  Widget _buildStatusRow() {
    final items = <String>[];
    if (widget.user.isOnline) items.add('online');
    if (widget.user.isVerified) items.add('verified');

    if (items.isEmpty) return const SizedBox.shrink();

    return Text(
      items.join(' • '),
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildLocationRow() {
    final city = widget.user.city ?? 'Unknown';
    final distance = widget.user.distanceKm != null
        ? '${widget.user.distanceKm} km'
        : '';

    final text = distance.isNotEmpty ? '$city • $distance' : city;

    return Text(
      text.toLowerCase(),
      style: AppTypography.bodySmall.copyWith(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  /// Single dot for menu indicator
  Widget _buildDot() {
    return Container(
      width: 5,
      height: 5,
      decoration: const BoxDecoration(
        color: AppColors.textTertiary,
        shape: BoxShape.circle,
      ),
    );
  }

  String _getDatingGoalText(DatingGoal goal) {
    switch (goal) {
      case DatingGoal.anything:
        return 'anything';
      case DatingGoal.casual:
        return 'casual';
      case DatingGoal.virtual:
        return 'virtual';
      case DatingGoal.friendship:
        return 'friendship';
      case DatingGoal.longTerm:
        return 'long-term';
    }
  }

  String _getStatusText(RelationshipStatus status) {
    switch (status) {
      case RelationshipStatus.single:
        return 'single';
      case RelationshipStatus.complicated:
        return 'complicated';
      case RelationshipStatus.married:
        return 'married';
      case RelationshipStatus.inRelationship:
        return 'in a relationship';
    }
  }
}

/// More menu dialog (hide, block, report)
class _MoreMenuDialog extends StatelessWidget {
  final VoidCallback onHide;
  final VoidCallback onBlock;
  final VoidCallback onReport;

  const _MoreMenuDialog({
    required this.onHide,
    required this.onBlock,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu positioned above the three dots
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                // No border radius as per design
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(
                    text: 'hide',
                    onTap: onHide,
                    color: AppColors.textPrimary,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildMenuItem(
                    text: 'block',
                    onTap: onBlock,
                    color: AppColors.textPrimary,
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _buildMenuItem(
                    text: 'report',
                    onTap: onReport,
                    color: AppColors.error,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required String text,
    required VoidCallback onTap,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 120,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}


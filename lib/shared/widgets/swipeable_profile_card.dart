import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                  _buildOutlineButton(
                    onTap: widget.onSuperLike,
                    child: _buildFireIcon(),
                  ),
                  const SizedBox(width: 8),
                  // Heart button (Like)
                  _buildOutlineButton(
                    onTap: widget.onLike,
                    child: _buildHeartIcon(),
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

  /// Outline circle button
  Widget _buildOutlineButton({
    required VoidCallback? onTap,
    required Widget child,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.border,
            width: 1.5,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  /// Super Like icon (flame)
  Widget _buildFireIcon() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _SuperLikeIconPainter(
        color: AppColors.like,
      ),
    );
  }

  /// Heart icon (like)
  Widget _buildHeartIcon() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _HeartIconPainter(
        color: AppColors.like,
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

/// Super Like icon painter (flame with inner detail) - exact Figma SVG
class _SuperLikeIconPainter extends CustomPainter {
  final Color color;

  _SuperLikeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 28.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Outer path from SVG
    final path = Path();
    path.moveTo(13.8003 * scale, 0.27832 * scale);
    path.cubicTo(14.7342 * scale, 0.153301 * scale, 15.6754 * scale, 0.447197 * scale, 16.3726 * scale, 1.08105 * scale);
    path.cubicTo(16.8644 * scale, 1.52839 * scale, 17.3524 * scale, 1.95689 * scale, 17.8315 * scale, 2.37109 * scale);
    path.lineTo(19.2397 * scale, 3.57422 * scale);
    path.cubicTo(23.2975 * scale, 7.02282 * scale, 26.6843 * scale, 9.91431 * scale, 26.689 * scale, 15.0664 * scale);
    path.cubicTo(26.6975 * scale, 21.9 * scale, 21.2768 * scale, 27.5053 * scale, 14.4468 * scale, 27.7266 * scale);
    path.lineTo(14.438 * scale, 27.7275 * scale);
    path.cubicTo(14.298 * scale, 27.7373 * scale, 13.9362 * scale, 27.7402 * scale, 13.8979 * scale, 27.7402 * scale);
    path.cubicTo(12.8264 * scale, 27.734 * scale, 11.7594 * scale, 27.5993 * scale, 10.7202 * scale, 27.3379 * scale);
    path.cubicTo(5.14017 * scale, 25.8896 * scale, 1.26236 * scale, 20.8272 * scale, 1.31689 * scale, 15.0615 * scale);
    path.lineTo(1.31689 * scale, 15.0576 * scale);
    path.cubicTo(1.29427 * scale, 12.4968 * scale, 2.22314 * scale, 10.0248 * scale, 3.91357 * scale, 8.11719 * scale);
    path.lineTo(4.26221 * scale, 7.74316 * scale);
    path.lineTo(4.27002 * scale, 7.73438 * scale);
    path.cubicTo(4.45531 * scale, 7.52645 * scale, 4.6805 * scale, 7.3577 * scale, 4.93213 * scale, 7.23828 * scale);
    path.cubicTo(5.97158 * scale, 6.74492 * scale, 7.21416 * scale, 7.18808 * scale, 7.70752 * scale, 8.22754 * scale);
    path.cubicTo(7.87447 * scale, 8.57176 * scale, 8.06717 * scale, 8.90023 * scale, 8.28369 * scale, 9.21289 * scale);
    path.lineTo(8.61768 * scale, 9.69727 * scale);
    path.lineTo(8.73389 * scale, 9.12012 * scale);
    path.cubicTo(9.26126 * scale, 6.4947 * scale, 10.2334 * scale, 3.97883 * scale, 11.6079 * scale, 1.68066 * scale);
    path.cubicTo(12.0944 * scale, 0.91144 * scale, 12.897 * scale, 0.397615 * scale, 13.7993 * scale, 0.27832 * scale);
    path.close();

    // Inner cutout (center flame detail)
    path.moveTo(13.9985 * scale, 13.8564 * scale);
    path.cubicTo(13.5991 * scale, 13.8553 * scale, 13.2165 * scale, 14.007 * scale, 12.9282 * scale, 14.2773 * scale);
    path.lineTo(12.8101 * scale, 14.4014 * scale);
    path.cubicTo(11.6089 * scale, 15.8101 * scale, 10.7074 * scale, 17.1463 * scale, 10.1304 * scale, 18.377 * scale);
    path.cubicTo(9.59004 * scale, 19.5293 * scale, 9.32792 * scale, 20.6024 * scale, 9.38428 * scale, 21.5615 * scale);
    path.lineTo(9.3999 * scale, 21.752 * scale);
    path.cubicTo(9.56004 * scale, 22.9652 * scale, 10.1959 * scale, 24.0186 * scale, 11.1538 * scale, 24.7676 * scale);
    path.lineTo(11.3501 * scale, 24.9131 * scale);
    path.cubicTo(12.0349 * scale, 25.4612 * scale, 12.935 * scale, 25.8288 * scale, 13.8491 * scale, 25.8984 * scale);
    path.cubicTo(14.0087 * scale, 25.9133 * scale, 14.2005 * scale, 25.897 * scale, 14.2964 * scale, 25.8877 * scale);
    path.cubicTo(16.703 * scale, 25.6547 * scale, 18.6096 * scale, 23.7368 * scale, 18.6167 * scale, 21.2969 * scale);
    path.lineTo(18.6021 * scale, 20.9414 * scale);
    path.cubicTo(18.5335 * scale, 20.0974 * scale, 18.2279 * scale, 19.1468 * scale, 17.7183 * scale, 18.1318 * scale);
    path.cubicTo(17.2075 * scale, 17.1145 * scale, 16.4866 * scale, 16.0208 * scale, 15.5767 * scale, 14.8877 * scale);
    path.lineTo(15.1753 * scale, 14.4004 * scale);
    path.cubicTo(14.8843 * scale, 14.053 * scale, 14.4535 * scale, 13.8538 * scale, 14.0005 * scale, 13.8564 * scale);
    path.close();

    // Inner white/background area
    path.moveTo(14.0396 * scale, 2.0957 * scale);
    path.cubicTo(13.6744 * scale, 2.14086 * scale, 13.3484 * scale, 2.34766 * scale, 13.1509 * scale, 2.6582 * scale);
    path.cubicTo(11.8502 * scale, 4.85971 * scale, 10.9445 * scale, 7.2629 * scale, 10.4702 * scale, 9.76758 * scale);
    path.cubicTo(10.3145 * scale, 10.5278 * scale, 9.72593 * scale, 11.1253 * scale, 8.96826 * scale, 11.293 * scale);
    path.cubicTo(8.22489 * scale, 11.4673 * scale, 7.45189 * scale, 11.1836 * scale, 6.99951 * scale, 10.5723 * scale);
    path.lineTo(6.73486 * scale, 10.2012 * scale);
    path.cubicTo(6.48118 * scale, 9.82617 * scale, 6.25552 * scale, 9.43277 * scale, 6.05908 * scale, 9.02441 * scale);
    path.lineTo(5.90674 * scale, 8.70801 * scale);
    path.lineTo(5.65771 * scale, 8.95508 * scale);
    path.cubicTo(4.03465 * scale, 10.5685 * scale, 3.13177 * scale, 12.7693 * scale, 3.15381 * scale, 15.0576 * scale);
    path.cubicTo(3.135 * scale, 18.5593 * scale, 4.80549 * scale, 21.8555 * scale, 7.64111 * scale, 23.9102 * scale);
    path.lineTo(8.37354 * scale, 24.4414 * scale);
    path.lineTo(8.01709 * scale, 23.6094 * scale);
    path.cubicTo(7.81825 * scale, 23.1452 * scale, 7.68098 * scale, 22.6573 * scale, 7.60889 * scale, 22.1582 * scale);
    path.lineTo(7.58252 * scale, 21.9434 * scale);
    path.cubicTo(7.32504 * scale, 19.4665 * scale, 8.58135 * scale, 16.5323 * scale, 11.4185 * scale, 13.209 * scale);
    path.cubicTo(12.0631 * scale, 12.4541 * scale, 13.0068 * scale, 12.0198 * scale, 13.9995 * scale, 12.0215 * scale);
    path.cubicTo(14.9947 * scale, 12.0223 * scale, 15.9347 * scale, 12.4593 * scale, 16.5737 * scale, 13.2158 * scale);
    path.cubicTo(17.4643 * scale, 14.2737 * scale, 18.4366 * scale, 15.5823 * scale, 19.1851 * scale, 16.9863 * scale);
    path.cubicTo(19.9347 * scale, 18.3927 * scale, 20.4506 * scale, 19.8774 * scale, 20.4507 * scale, 21.2939 * scale);
    path.lineTo(20.4438 * scale, 21.5742 * scale);
    path.cubicTo(20.4137 * scale, 22.229 * scale, 20.2829 * scale, 22.8759 * scale, 20.0562 * scale, 23.4922 * scale);
    path.lineTo(19.77 * scale, 24.2705 * scale);
    path.lineTo(20.439 * scale, 23.7803 * scale);
    path.cubicTo(20.4604 * scale, 23.7646 * scale, 20.4823 * scale, 23.7496 * scale, 20.5083 * scale, 23.7324 * scale);
    path.lineTo(20.6616 * scale, 23.6299 * scale);
    path.cubicTo(23.2279 * scale, 21.6436 * scale, 24.7595 * scale, 18.612 * scale, 24.8433 * scale, 15.3789 * scale);
    path.lineTo(24.8472 * scale, 15.0654 * scale);
    path.cubicTo(24.8467 * scale, 10.726 * scale, 21.9212 * scale, 8.263 * scale, 18.0493 * scale, 4.97461 * scale);
    path.cubicTo(17.3497 * scale, 4.38154 * scale, 16.6234 * scale, 3.76266 * scale, 15.8833 * scale, 3.10742 * scale);
    path.lineTo(15.1392 * scale, 2.44043 * scale);
    path.cubicTo(14.8787 * scale, 2.20256 * scale, 14.5378 * scale, 2.07581 * scale, 14.189 * scale, 2.08398 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Heart icon painter - exact Figma SVG
class _HeartIconPainter extends CustomPainter {
  final Color color;

  _HeartIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 28.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Outer heart shape
    path.moveTo(20.4014 * scale, 4.32031 * scale);
    path.cubicTo(18.8599 * scale, 4.41458 * scale, 17.418 * scale, 5.1146 * scale, 16.3906 * scale, 6.26758 * scale);
    path.cubicTo(15.3664 * scale, 7.41708 * scale, 14.8376 * scale, 8.92375 * scale, 14.917 * scale, 10.4609 * scale);
    path.cubicTo(14.916 * scale, 10.7039 * scale, 14.8202 * scale, 10.9375 * scale, 14.6484 * scale, 11.1094 * scale);
    path.cubicTo(14.4766 * scale, 11.2812 * scale, 14.243 * scale, 11.3779 * scale, 14 * scale, 11.3779 * scale);
    path.cubicTo(13.7569 * scale, 11.3779 * scale, 13.5235 * scale, 11.2813 * scale, 13.3516 * scale, 11.1094 * scale);
    path.cubicTo(13.1797 * scale, 10.9375 * scale, 13.083 * scale, 10.704 * scale, 13.083 * scale, 10.4609 * scale);
    path.cubicTo(13.1624 * scale, 8.92367 * scale, 12.6327 * scale, 7.4171 * scale, 11.6084 * scale, 6.26758 * scale);
    path.cubicTo(10.5811 * scale, 5.11472 * scale, 9.13993 * scale, 4.41464 * scale, 7.59863 * scale, 4.32031 * scale);
    path.lineTo(7.58301 * scale, 4.31934 * scale);
    path.lineTo(7.56738 * scale, 4.32031 * scale);
    path.cubicTo(6.02613 * scale, 4.4147 * scale, 4.58491 * scale, 5.11473 * scale, 3.55762 * scale, 6.26758 * scale);
    path.cubicTo(2.53028 * scale, 7.42049 * scale, 1.99976 * scale, 8.93264 * scale, 2.08301 * scale, 10.4746 * scale);
    path.cubicTo(2.08747 * scale, 12.2423 * scale, 2.98152 * scale, 14.3427 * scale, 4.59766 * scale, 16.6113 * scale);
    path.cubicTo(6.22227 * scale, 18.8919 * scale, 8.59668 * scale, 21.3708 * scale, 11.6045 * scale, 23.8945 * scale);
    path.cubicTo(12.2749 * scale, 24.459 * scale, 13.1236 * scale, 24.7686 * scale, 14 * scale, 24.7686 * scale);
    path.cubicTo(14.8762 * scale, 24.7685 * scale, 15.7242 * scale, 24.4588 * scale, 16.3945 * scale, 23.8945 * scale);
    path.lineTo(16.4844 * scale, 23.8193 * scale);
    path.cubicTo(19.4496 * scale, 21.3182 * scale, 21.793 * scale, 18.8675 * scale, 23.4014 * scale, 16.6104 * scale);
    path.cubicTo(25.0175 * scale, 14.3423 * scale, 25.9116 * scale, 12.2423 * scale, 25.916 * scale, 10.4746 * scale);
    path.cubicTo(25.9993 * scale, 8.93272 * scale, 25.4696 * scale, 7.42047 * scale, 24.4424 * scale, 6.26758 * scale);
    path.cubicTo(23.415 * scale, 5.1146 * scale, 21.9731 * scale, 4.41458 * scale, 20.4316 * scale, 4.32031 * scale);
    path.lineTo(20.416 * scale, 4.31934 * scale);
    path.close();

    // Inner cutout
    path.moveTo(0.25 * scale, 10.4521 * scale);
    path.cubicTo(0.173452 * scale, 8.42353 * scale, 0.902303 * scale, 6.44665 * scale, 2.27832 * scale, 4.9541 * scale);
    path.cubicTo(3.6533 * scale, 3.46278 * scale, 5.56253 * scale, 2.57572 * scale, 7.58887 * scale, 2.48633 * scale);
    path.cubicTo(8.85515 * scale, 2.50771 * scale, 10.0936 * scale, 2.86207 * scale, 11.1797 * scale, 3.51367 * scale);
    path.cubicTo(12.2685 * scale, 4.16699 * scale, 13.1663 * scale, 5.09605 * scale, 13.7812 * scale, 6.20703 * scale);
    path.lineTo(14 * scale, 6.60254 * scale);
    path.lineTo(14.2188 * scale, 6.20703 * scale);
    path.cubicTo(14.8337 * scale, 5.09618 * scale, 15.7306 * scale, 4.16695 * scale, 16.8193 * scale, 3.51367 * scale);
    path.cubicTo(17.9051 * scale, 2.86223 * scale, 19.1433 * scale, 2.50798 * scale, 20.4092 * scale, 2.48633 * scale);
    path.cubicTo(22.4361 * scale, 2.57534 * scale, 24.3454 * scale, 3.46245 * scale, 25.7207 * scale, 4.9541 * scale);
    path.cubicTo(27.0968 * scale, 6.44668 * scale, 27.8266 * scale, 8.42344 * scale, 27.75 * scale, 10.4521 * scale);
    path.lineTo(27.75 * scale, 10.4609 * scale);
    path.cubicTo(27.75 * scale, 13.0311 * scale, 26.3939 * scale, 15.7521 * scale, 24.4238 * scale, 18.3398 * scale);
    path.cubicTo(22.4583 * scale, 20.9216 * scale, 19.9067 * scale, 23.3387 * scale, 17.5723 * scale, 25.2969 * scale);
    path.cubicTo(16.5718 * scale, 26.1375 * scale, 15.3068 * scale, 26.5986 * scale, 14 * scale, 26.5986 * scale);
    path.cubicTo(12.6933 * scale, 26.5986 * scale, 11.4282 * scale, 26.1375 * scale, 10.4277 * scale, 25.2969 * scale);
    path.cubicTo(8.09237 * scale, 23.3388 * scale, 5.54167 * scale, 20.9215 * scale, 3.57617 * scale, 18.3398 * scale);
    path.cubicTo(1.60613 * scale, 15.7521 * scale, 0.25 * scale, 13.0311 * scale, 0.25 * scale, 10.4609 * scale);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

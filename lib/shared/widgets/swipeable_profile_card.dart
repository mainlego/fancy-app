import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

  final GlobalKey _dotsButtonKey = GlobalKey();
  OverlayEntry? _menuOverlay;

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
    _removeMenuOverlay();

    final RenderBox? renderBox =
        _dotsButtonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final buttonPosition = renderBox.localToGlobal(Offset.zero);
    final buttonSize = renderBox.size;

    _menuOverlay = OverlayEntry(
      builder: (context) => _MoreMenuOverlay(
        buttonPosition: buttonPosition,
        buttonSize: buttonSize,
        onHide: () {
          _removeMenuOverlay();
          widget.onHide?.call();
        },
        onBlock: () {
          _removeMenuOverlay();
          widget.onBlock?.call();
        },
        onReport: () {
          _removeMenuOverlay();
          widget.onReport?.call();
        },
        onDismiss: _removeMenuOverlay,
      ),
    );

    Overlay.of(context).insert(_menuOverlay!);
  }

  void _removeMenuOverlay() {
    _menuOverlay?.remove();
    _menuOverlay = null;
  }

  @override
  void dispose() {
    _removeMenuOverlay();
    super.dispose();
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
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
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
                const SizedBox(height: 2),

                // online • verified
                _buildStatusRow(),
                const SizedBox(height: 2),

                // location • distance + dots menu
                Row(
                  children: [
                    Expanded(child: _buildLocationRow()),
                    // Three dots menu - larger tap area (44x44)
                    GestureDetector(
                      key: _dotsButtonKey,
                      onTap: _showMoreMenu,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
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
              ],
            ),
          ),

          // Right side - action buttons with 24px gap
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fire button (Super Like)
              _ActionButton(
                svgPath: AppAssets.icSuperLikeOutline,
                onTap: widget.onSuperLike,
              ),
              const SizedBox(width: 24),
              // Heart button (Like)
              _ActionButton(
                svgPath: AppAssets.icLikeOutline,
                onTap: widget.onLike,
              ),
            ],
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

/// More menu overlay (hide, block, report) - positioned under the dots button
class _MoreMenuOverlay extends StatelessWidget {
  final Offset buttonPosition;
  final Size buttonSize;
  final VoidCallback onHide;
  final VoidCallback onBlock;
  final VoidCallback onReport;
  final VoidCallback onDismiss;

  const _MoreMenuOverlay({
    required this.buttonPosition,
    required this.buttonSize,
    required this.onHide,
    required this.onBlock,
    required this.onReport,
    required this.onDismiss,
  });

  static const double _menuWidth = 100.0;

  @override
  Widget build(BuildContext context) {
    // Position menu above the button, centered horizontally
    final menuLeft = buttonPosition.dx + (buttonSize.width / 2) - (_menuWidth / 2);
    final menuBottom = MediaQuery.of(context).size.height - buttonPosition.dy + 8;

    return Stack(
      children: [
        // Tap outside to dismiss
        Positioned.fill(
          child: GestureDetector(
            onTap: onDismiss,
            behavior: HitTestBehavior.opaque,
            child: Container(color: Colors.transparent),
          ),
        ),
        // Menu positioned above the dots button
        Positioned(
          left: menuLeft,
          bottom: menuBottom,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: _menuWidth,
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
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
        width: _menuWidth,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(
            color: color,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Action button with border and tap animation
class _ActionButton extends StatefulWidget {
  final String svgPath;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.svgPath,
    this.onTap,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: child,
          );
        },
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.border,
              width: 1.5,
            ),
          ),
          child: Center(
            child: SvgPicture.asset(
              widget.svgPath,
              width: 24,
              height: 24,
            ),
          ),
        ),
      ),
    );
  }
}


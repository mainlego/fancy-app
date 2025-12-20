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

class _SwipeableProfileCardState extends State<SwipeableProfileCard>
    with SingleTickerProviderStateMixin {
  static const double _normalHeight = 400.0;
  static const double _expandedHeight = 500.0;
  static const double _infoPanelHeight = 90.0;

  int _currentMediaIndex = 0;
  bool _isExpanded = false;
  bool _showingBio = false;
  DateTime? _lastTapTime;

  final GlobalKey _dotsButtonKey = GlobalKey();
  OverlayEntry? _menuOverlay;

  // Animation for slide indicator dots
  late AnimationController _dotAnimationController;

  /// Total media count (photos + bio as last item)
  int get _totalSlides => widget.user.photos.length + 1; // +1 for bio

  /// Check if current slide is bio
  bool get _isCurrentSlideBio => _currentMediaIndex >= widget.user.photos.length;

  @override
  void initState() {
    super.initState();
    _dotAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

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
          _triggerDotAnimation();
        }
      } else {
        // Swipe right - previous
        if (_currentMediaIndex > 0) {
          setState(() {
            _currentMediaIndex--;
            _showingBio = _isCurrentSlideBio;
          });
          _triggerDotAnimation();
        }
      }
    }
  }

  void _triggerDotAnimation() {
    _dotAnimationController.forward(from: 0);
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
    _dotAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentHeight = _isExpanded ? _expandedHeight : _normalHeight;

    // No external padding - card stretches 100% width
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

  /// Media content (photos/videos) - no indicator lines on photo
  Widget _buildMediaContent() {
    return _buildPhoto();
  }

  /// Bio content - no indicator lines
  Widget _buildBioContent() {
    return Container(
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

    return SizedBox.expand(
      child: CachedNetworkImage(
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
      ),
    );
  }

  /// Bottom info panel - 90px height
  Widget _buildInfoPanel() {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      color: AppColors.surface,
      child: Stack(
        children: [
          // Main row: text left 50%, buttons right 50%
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Left side - text info (50% width)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    // Dating goal • relationship status (1 line)
                    _buildInfoRow([
                      if (widget.user.datingGoal != null)
                        _getDatingGoalText(widget.user.datingGoal!),
                      if (widget.user.relationshipStatus != null)
                        _getStatusText(widget.user.relationshipStatus!),
                    ]),
                    const SizedBox(height: 2),

                    // online • verified (1 line)
                    _buildStatusRow(),
                    const SizedBox(height: 2),

                    // location • distance (1 line)
                    _buildLocationRow(),
                  ],
                ),
              ),

              // Right side - action buttons (50% width)
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
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
              ),
            ],
          ),

          // Center dots - fixed position, centered horizontally, 16px from bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                key: _dotsButtonKey,
                onTap: _showMoreMenu,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: _totalSlides > 1
                      ? _SlideIndicatorDots(
                          totalSlides: _totalSlides,
                          currentIndex: _currentMediaIndex,
                          animationController: _dotAnimationController,
                        )
                      : Row(
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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

/// More menu overlay (hide, block, report) - positioned BELOW the dots button
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
    // Position menu BELOW the button, centered horizontally
    final menuLeft = buttonPosition.dx + (buttonSize.width / 2) - (_menuWidth / 2);
    final menuTop = buttonPosition.dy + buttonSize.height + 8;

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
        // Menu positioned BELOW the dots button
        Positioned(
          left: menuLeft,
          top: menuTop,
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

/// Animated slide indicator dots - always shows 3 dots
/// Highlights dots based on current slide position with animation
class _SlideIndicatorDots extends StatelessWidget {
  final int totalSlides;
  final int currentIndex;
  final AnimationController animationController;

  const _SlideIndicatorDots({
    required this.totalSlides,
    required this.currentIndex,
    required this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnimatedDot(0),
            const SizedBox(width: 4),
            _buildAnimatedDot(1),
            const SizedBox(width: 4),
            _buildAnimatedDot(2),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedDot(int dotIndex) {
    // Map slide index to dot index (always 3 dots for any number of slides)
    // For <= 3 slides: direct mapping
    // For > 3 slides: map to 3 dots based on position
    final bool isActive = _isDotActive(dotIndex);

    // Pulse animation when active
    final double scale = isActive
        ? 1.0 + (0.3 * _pulseAnimation(animationController.value))
        : 1.0;

    // Color with animation
    final Color dotColor = isActive
        ? Color.lerp(
            AppColors.textTertiary,
            AppColors.primary,
            _colorAnimation(animationController.value),
          )!
        : AppColors.textTertiary;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 5,
        height: 5,
        decoration: BoxDecoration(
          color: dotColor,
          shape: BoxShape.circle,
          boxShadow: isActive && animationController.value > 0
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5 * animationController.value),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
      ),
    );
  }

  bool _isDotActive(int dotIndex) {
    if (totalSlides <= 3) {
      // Direct mapping for 3 or fewer slides
      return dotIndex == currentIndex;
    } else {
      // For more than 3 slides, map to 3 dots
      // First dot = first slide
      // Last dot = last slide
      // Middle dot = all middle slides
      if (dotIndex == 0) {
        return currentIndex == 0;
      } else if (dotIndex == 2) {
        return currentIndex == totalSlides - 1;
      } else {
        // Middle dot active for all middle slides
        return currentIndex > 0 && currentIndex < totalSlides - 1;
      }
    }
  }

  // Smooth pulse animation (ease out)
  double _pulseAnimation(double value) {
    // Quick pulse up and slow fade
    if (value < 0.3) {
      return value / 0.3;
    } else {
      return 1.0 - ((value - 0.3) / 0.7);
    }
  }

  // Color animation (quick transition to pink)
  double _colorAnimation(double value) {
    if (value < 0.2) {
      return value / 0.2;
    }
    return 1.0;
  }
}


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/models/chat_model.dart';

/// Timed media viewer for private photos in chat
/// Displays countdown timer and auto-closes after duration
class TimedMediaViewer extends ConsumerStatefulWidget {
  final MessageModel message;
  final VoidCallback? onViewed;

  const TimedMediaViewer({
    super.key,
    required this.message,
    this.onViewed,
  });

  /// Show the timed media viewer
  static Future<void> show(
    BuildContext context,
    MessageModel message, {
    VoidCallback? onViewed,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.95),
      builder: (context) => TimedMediaViewer(
        message: message,
        onViewed: onViewed,
      ),
    );
  }

  @override
  ConsumerState<TimedMediaViewer> createState() => _TimedMediaViewerState();
}

class _TimedMediaViewerState extends ConsumerState<TimedMediaViewer>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _isHolding = false;
  bool _hasMarkedViewed = false;

  @override
  void initState() {
    super.initState();

    final duration = widget.message.viewDurationSec;
    _remainingSeconds = duration ?? 0;

    // Setup progress animation for timed viewing
    if (duration != null && duration > 0) {
      _progressController = AnimationController(
        vsync: this,
        duration: Duration(seconds: duration),
      );
      _startTimer();
    } else {
      _progressController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
        value: 1.0,
      );
    }

    // Mark as viewed for one-time view
    _markAsViewed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _progressController.forward();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isHolding && mounted) {
        setState(() {
          _remainingSeconds--;
          if (_remainingSeconds <= 0) {
            _timer?.cancel();
            _close();
          }
        });
      }
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _progressController.stop();
    setState(() => _isHolding = true);
  }

  void _resumeTimer() {
    setState(() => _isHolding = false);
    if (_remainingSeconds > 0) {
      _progressController.forward();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!_isHolding && mounted) {
          setState(() {
            _remainingSeconds--;
            if (_remainingSeconds <= 0) {
              _timer?.cancel();
              _close();
            }
          });
        }
      });
    }
  }

  Future<void> _markAsViewed() async {
    if (_hasMarkedViewed) return;
    _hasMarkedViewed = true;

    try {
      final service = ref.read(supabaseServiceProvider);
      await service.markPrivateMediaAsViewed(widget.message.id);
      widget.onViewed?.call();
    } catch (e) {
      debugPrint('Failed to mark as viewed: $e');
    }
  }

  void _close() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final hasTimer = widget.message.viewDurationSec != null &&
        widget.message.viewDurationSec! > 0;

    return GestureDetector(
      onLongPressStart: (_) => hasTimer ? _pauseTimer() : null,
      onLongPressEnd: (_) => hasTimer ? _resumeTimer() : null,
      onTap: hasTimer ? null : _close,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Center(
              child: InteractiveViewer(
                minScale: 1.0,
                maxScale: 3.0,
                child: CachedNetworkImage(
                  imageUrl: widget.message.mediaUrl ?? '',
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: AppColors.error,
                    size: 48,
                  ),
                ),
              ),
            ),

            // Top bar with close and timer
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: _close,
                      ),
                      const Spacer(),
                      if (hasTimer) ...[
                        // Timer display
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.overlay,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.timer,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              AppSpacing.hGapSm,
                              Text(
                                '$_remainingSeconds s',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (widget.message.oneTimeView) ...[
                        // One-time view indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.overlay,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_off,
                                color: AppColors.warning,
                                size: 16,
                              ),
                              AppSpacing.hGapSm,
                              Text(
                                'One-time view',
                                style: AppTypography.labelMedium.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Progress bar at bottom
            if (hasTimer)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Hold to pause hint
                        if (_isHolding)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            margin: const EdgeInsets.only(bottom: AppSpacing.md),
                            decoration: BoxDecoration(
                              color: AppColors.overlay,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Text(
                              'Timer paused',
                              style: AppTypography.labelMedium.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        // Progress bar
                        AnimatedBuilder(
                          animation: _progressController,
                          builder: (context, child) => LinearProgressIndicator(
                            value: 1 - _progressController.value,
                            backgroundColor: Colors.white.withOpacity(0.3),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.warning,
                            ),
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Hold to pause timer',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Tap to close hint for non-timed
            if (!hasTimer)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Center(
                      child: Text(
                        'Tap anywhere to close',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Widget to display private media in chat message bubble
/// Shows "tap to view" for one-time or "Photo (Xs)" for timed
class PrivateMediaBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onTap;

  const PrivateMediaBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasBeenViewed = message.hasBeenViewed;
    final isOneTime = message.oneTimeView;
    final duration = message.viewDurationSec;

    // Already viewed one-time photo
    if (isOneTime && hasBeenViewed && !isMe) {
      return _buildViewedPlaceholder();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        height: 150,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Blurred preview (optional - can show actual image for sender)
            if (isMe && message.mediaUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: AppColors.surfaceVariant,
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: AppColors.surfaceVariant,
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),

            // Overlay with lock icon and info
            Container(
              decoration: BoxDecoration(
                color: isMe ? Colors.black.withOpacity(0.3) : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOneTime ? Icons.visibility : Icons.lock,
                    color: AppColors.warning,
                    size: 32,
                  ),
                  AppSpacing.vGapSm,
                  Text(
                    isMe
                        ? (isOneTime ? 'One-time photo' : 'Private photo')
                        : 'Tap to view',
                    style: AppTypography.labelMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  if (duration != null && !isMe)
                    Text(
                      '${duration}s viewing time',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  if (isOneTime && !isMe)
                    Text(
                      'View once',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.warning,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewedPlaceholder() {
    return Container(
      width: 200,
      height: 60,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.visibility_off,
            color: AppColors.textTertiary,
            size: 20,
          ),
          AppSpacing.hGapSm,
          Expanded(
            child: Text(
              'Photo viewed',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

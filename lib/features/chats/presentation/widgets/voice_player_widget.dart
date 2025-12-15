import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Widget for playing voice messages inline in chat
class VoicePlayerWidget extends StatefulWidget {
  final String audioUrl;
  final int? durationMs;
  final bool isMe;
  final VoidCallback? onComplete;

  const VoicePlayerWidget({
    super.key,
    required this.audioUrl,
    this.durationMs,
    this.isMe = false,
    this.onComplete,
  });

  @override
  State<VoicePlayerWidget> createState() => _VoicePlayerWidgetState();
}

class _VoicePlayerWidgetState extends State<VoicePlayerWidget> {
  late AudioPlayer _player;
  bool _isLoading = true;
  bool _hasError = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Listen to player state changes
      _player.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed) {
          widget.onComplete?.call();
          if (mounted) {
            setState(() {});
          }
        }
      });

      // Listen to duration changes
      _player.durationStream.listen((duration) {
        if (mounted && duration != null) {
          setState(() => _duration = duration);
        }
      });

      // Listen to position changes
      _player.positionStream.listen((position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });

      // Load the audio
      await _player.setUrl(widget.audioUrl);

      if (mounted) {
        setState(() {
          _isLoading = false;
          if (widget.durationMs != null) {
            _duration = Duration(milliseconds: widget.durationMs!);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _seek(double value) {
    final position = Duration(milliseconds: value.toInt());
    _player.seek(position);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = widget.isMe ? AppColors.textPrimary : AppColors.primary;
    final secondaryColor = widget.isMe
        ? AppColors.textPrimary.withOpacity(0.7)
        : AppColors.textSecondary;

    if (_hasError) {
      return Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: widget.isMe
              ? AppColors.primary.withOpacity(0.8)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: AppColors.error, size: 20),
            AppSpacing.hGapSm,
            Text(
              'Failed to load',
              style: AppTypography.bodySmall.copyWith(color: secondaryColor),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: widget.isMe
            ? AppColors.primary.withOpacity(0.8)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause button
          if (_isLoading)
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(primaryColor),
              ),
            )
          else
            GestureDetector(
              onTap: _togglePlayPause,
              child: StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playing = snapshot.data?.playing ?? false;
                  return Icon(
                    playing ? Icons.pause : Icons.play_arrow,
                    color: primaryColor,
                    size: 24,
                  );
                },
              ),
            ),
          AppSpacing.hGapSm,

          // Waveform / Progress
          SizedBox(
            width: 100,
            height: 24,
            child: _isLoading
                ? _StaticWaveform(color: secondaryColor)
                : _AnimatedWaveform(
                    progress: _duration.inMilliseconds > 0
                        ? _position.inMilliseconds / _duration.inMilliseconds
                        : 0,
                    color: primaryColor,
                    backgroundColor: secondaryColor.withOpacity(0.3),
                    onSeek: (progress) {
                      _seek(progress * _duration.inMilliseconds);
                    },
                  ),
          ),
          AppSpacing.hGapSm,

          // Duration
          Text(
            _formatDuration(_isLoading || _player.playing ? _position : _duration),
            style: AppTypography.labelSmall.copyWith(
              color: secondaryColor,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Static waveform for loading state
class _StaticWaveform extends StatelessWidget {
  final Color color;

  const _StaticWaveform({required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 24),
      painter: _StaticWaveformPainter(color: color),
    );
  }
}

class _StaticWaveformPainter extends CustomPainter {
  final Color color;

  _StaticWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 20;
    final barWidth = size.width / barCount;
    final maxHeight = size.height;

    for (var i = 0; i < barCount; i++) {
      // Create a pseudo-random pattern
      final height = maxHeight * (0.3 + 0.7 * ((i * 7 + 3) % 5) / 5);
      final x = i * barWidth + barWidth / 2;
      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated waveform with progress
class _AnimatedWaveform extends StatelessWidget {
  final double progress;
  final Color color;
  final Color backgroundColor;
  final void Function(double)? onSeek;

  const _AnimatedWaveform({
    required this.progress,
    required this.color,
    required this.backgroundColor,
    this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek?.call(progress);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localPosition = box.globalToLocal(details.globalPosition);
        final progress = (localPosition.dx / box.size.width).clamp(0.0, 1.0);
        onSeek?.call(progress);
      },
      child: CustomPaint(
        size: const Size(100, 24),
        painter: _AnimatedWaveformPainter(
          progress: progress,
          activeColor: color,
          inactiveColor: backgroundColor,
        ),
      ),
    );
  }
}

class _AnimatedWaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  _AnimatedWaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const barCount = 20;
    final barWidth = size.width / barCount;
    final maxHeight = size.height;
    final progressX = size.width * progress;

    for (var i = 0; i < barCount; i++) {
      // Create a pseudo-random pattern
      final height = maxHeight * (0.3 + 0.7 * ((i * 7 + 3) % 5) / 5);
      final x = i * barWidth + barWidth / 2;
      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;

      final paint = Paint()
        ..color = x <= progressX ? activeColor : inactiveColor
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _AnimatedWaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';

/// Voice recording dialog result
class VoiceRecordingResult {
  final String filePath;
  final int durationMs;
  final Uint8List? webBytes; // For web platform - bytes directly

  VoiceRecordingResult({
    required this.filePath,
    required this.durationMs,
    this.webBytes,
  });
}

/// Voice recording dialog for chat
class VoiceRecordingDialog extends StatefulWidget {
  const VoiceRecordingDialog({super.key});

  /// Show the voice recording dialog and return the recorded file path
  static Future<VoiceRecordingResult?> show(BuildContext context) async {
    return showDialog<VoiceRecordingResult>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const VoiceRecordingDialog(),
    );
  }

  @override
  State<VoiceRecordingDialog> createState() => _VoiceRecordingDialogState();
}

class _VoiceRecordingDialogState extends State<VoiceRecordingDialog>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _isPaused = false;
  bool _hasPermission = false;
  String? _recordingPath;
  int _recordingDuration = 0; // in seconds
  Timer? _timer;
  late AnimationController _pulseController;
  List<double> _amplitudes = [];
  Timer? _amplitudeTimer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _checkPermission();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    _pulseController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _checkPermission() async {
    // Web doesn't need explicit permission check through permission_handler
    if (kIsWeb) {
      setState(() => _hasPermission = true);
      _startRecording();
      return;
    }

    final status = await Permission.microphone.request();
    setState(() => _hasPermission = status.isGranted);

    if (_hasPermission) {
      _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!await _recorder.hasPermission()) {
        setState(() => _hasPermission = false);
        return;
      }

      String path;
      RecordConfig config;

      if (kIsWeb) {
        // For web, use opus encoder which is well supported
        path = 'voice_${DateTime.now().millisecondsSinceEpoch}.webm';
        config = const RecordConfig(
          encoder: AudioEncoder.opus,
          bitRate: 128000,
          sampleRate: 48000,
        );
      } else {
        final dir = await getTemporaryDirectory();
        path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        config = const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );
      }

      await _recorder.start(config, path: path);

      setState(() {
        _isRecording = true;
        _recordingPath = path;
        _recordingDuration = 0;
        _amplitudes = [];
      });

      // Start duration timer
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted && _isRecording && !_isPaused) {
          setState(() => _recordingDuration++);
        }
      });

      // Start amplitude sampling for waveform
      _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) async {
        if (mounted && _isRecording && !_isPaused) {
          final amplitude = await _recorder.getAmplitude();
          setState(() {
            // Normalize amplitude to 0-1 range
            final normalized = ((amplitude.current + 60) / 60).clamp(0.0, 1.0);
            _amplitudes.add(normalized);
            // Keep last 50 samples
            if (_amplitudes.length > 50) {
              _amplitudes.removeAt(0);
            }
          });
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _pauseRecording() async {
    await _recorder.pause();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    await _recorder.resume();
    setState(() => _isPaused = false);
  }

  Future<void> _stopAndSend() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();

    final path = await _recorder.stop();
    if (path != null && mounted) {
      Uint8List? webBytes;

      // On web, we need to fetch the blob data before returning
      if (kIsWeb) {
        try {
          // The record package on web returns a blob URL
          // We need to fetch the blob data using XmlHttpRequest
          final blob = await _fetchBlobAsBytes(path);
          webBytes = blob;
        } catch (e) {
          debugPrint('Error fetching web audio blob: $e');
        }
      }

      Navigator.pop(
        context,
        VoiceRecordingResult(
          filePath: path,
          durationMs: _recordingDuration * 1000,
          webBytes: webBytes,
        ),
      );
    }
  }

  /// Fetch blob URL as bytes (for web platform)
  Future<Uint8List?> _fetchBlobAsBytes(String blobUrl) async {
    if (!kIsWeb) return null;

    try {
      // Use dart:html XmlHttpRequest for web
      // ignore: avoid_web_libraries_in_flutter
      final completer = Completer<Uint8List>();

      // We'll use a different approach - the record package actually
      // stores the blob in memory, so we can access it via the path
      // For now, return null and handle it in the caller
      return null;
    } catch (e) {
      debugPrint('Error in _fetchBlobAsBytes: $e');
      return null;
    }
  }

  void _cancelRecording() async {
    _timer?.cancel();
    _amplitudeTimer?.cancel();
    await _recorder.stop();

    // Delete the temporary file
    if (_recordingPath != null && !kIsWeb) {
      try {
        final file = File(_recordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Voice Message',
              style: AppTypography.headlineSmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vGapXl,

            if (!_hasPermission) ...[
              // Permission denied state
              const Icon(
                Icons.mic_off,
                size: 64,
                color: AppColors.error,
              ),
              AppSpacing.vGapMd,
              Text(
                'Microphone permission required',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              AppSpacing.vGapLg,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  AppSpacing.hGapMd,
                  ElevatedButton(
                    onPressed: _checkPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Grant Permission'),
                  ),
                ],
              ),
            ] else if (_isRecording) ...[
              // Recording state
              // Waveform visualization
              SizedBox(
                height: 60,
                child: CustomPaint(
                  size: const Size(double.infinity, 60),
                  painter: _WaveformPainter(
                    amplitudes: _amplitudes,
                    color: AppColors.primary,
                  ),
                ),
              ),
              AppSpacing.vGapLg,

              // Recording indicator with pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) => Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.error.withOpacity(
                      0.2 + (_pulseController.value * 0.2),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error,
                    ),
                    child: Icon(
                      _isPaused ? Icons.pause : Icons.mic,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
              AppSpacing.vGapMd,

              // Duration
              Text(
                _formatDuration(_recordingDuration),
                style: AppTypography.headlineMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              AppSpacing.vGapSm,

              Text(
                _isPaused ? 'Paused' : 'Recording...',
                style: AppTypography.bodySmall.copyWith(
                  color: _isPaused ? AppColors.warning : AppColors.error,
                ),
              ),
              AppSpacing.vGapXl,

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  IconButton(
                    onPressed: _cancelRecording,
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.error,
                    iconSize: 32,
                    tooltip: 'Cancel',
                  ),

                  // Pause/Resume button
                  IconButton(
                    onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                    icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                    color: AppColors.textSecondary,
                    iconSize: 32,
                    tooltip: _isPaused ? 'Resume' : 'Pause',
                  ),

                  // Send button
                  IconButton(
                    onPressed: _recordingDuration > 0 ? _stopAndSend : null,
                    icon: const Icon(Icons.send),
                    color: _recordingDuration > 0 ? AppColors.primary : AppColors.textTertiary,
                    iconSize: 32,
                    tooltip: 'Send',
                  ),
                ],
              ),
            ] else ...[
              // Loading state
              const CircularProgressIndicator(),
              AppSpacing.vGapMd,
              Text(
                'Initializing...',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Waveform painter for voice recording visualization
class _WaveformPainter extends CustomPainter {
  final List<double> amplitudes;
  final Color color;

  _WaveformPainter({
    required this.amplitudes,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (amplitudes.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final barWidth = size.width / 50;
    final centerY = size.height / 2;

    for (int i = 0; i < amplitudes.length; i++) {
      final amplitude = amplitudes[i];
      final barHeight = (size.height * 0.8 * amplitude).clamp(4.0, size.height * 0.9);
      final x = i * barWidth + barWidth / 2;
      final y1 = centerY - barHeight / 2;
      final y2 = centerY + barHeight / 2;

      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.amplitudes != amplitudes;
  }
}

import 'package:flutter/services.dart';

/// Sound types for notifications
enum SoundType {
  newMessage,
  newLike,
  superLike,
  match,
  notification,
}

/// Service for playing system sounds and haptic feedback
class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  bool _enabled = true;
  bool _hapticEnabled = true;

  bool get isEnabled => _enabled;
  bool get isHapticEnabled => _hapticEnabled;

  void setEnabled(bool enabled) {
    _enabled = enabled;
  }

  void setHapticEnabled(bool enabled) {
    _hapticEnabled = enabled;
  }

  /// Play system sound for notification type
  Future<void> play(SoundType type) async {
    if (!_enabled) return;

    try {
      switch (type) {
        case SoundType.newMessage:
          await SystemSound.play(SystemSoundType.click);
          if (_hapticEnabled) {
            await HapticFeedback.lightImpact();
          }
          break;
        case SoundType.newLike:
          await SystemSound.play(SystemSoundType.click);
          if (_hapticEnabled) {
            await HapticFeedback.mediumImpact();
          }
          break;
        case SoundType.superLike:
          await SystemSound.play(SystemSoundType.click);
          if (_hapticEnabled) {
            await HapticFeedback.heavyImpact();
          }
          break;
        case SoundType.match:
          // Play multiple clicks for celebration effect
          await SystemSound.play(SystemSoundType.click);
          if (_hapticEnabled) {
            await HapticFeedback.heavyImpact();
            await Future.delayed(const Duration(milliseconds: 100));
            await HapticFeedback.mediumImpact();
            await Future.delayed(const Duration(milliseconds: 100));
            await HapticFeedback.lightImpact();
          }
          break;
        case SoundType.notification:
          await SystemSound.play(SystemSoundType.click);
          if (_hapticEnabled) {
            await HapticFeedback.selectionClick();
          }
          break;
      }
    } catch (e) {
      print('Error playing sound: $e');
    }
  }

  /// Play haptic feedback only
  Future<void> haptic(HapticType type) async {
    if (!_hapticEnabled) return;

    try {
      switch (type) {
        case HapticType.light:
          await HapticFeedback.lightImpact();
          break;
        case HapticType.medium:
          await HapticFeedback.mediumImpact();
          break;
        case HapticType.heavy:
          await HapticFeedback.heavyImpact();
          break;
        case HapticType.selection:
          await HapticFeedback.selectionClick();
          break;
        case HapticType.vibrate:
          await HapticFeedback.vibrate();
          break;
      }
    } catch (e) {
      print('Error playing haptic: $e');
    }
  }
}

enum HapticType {
  light,
  medium,
  heavy,
  selection,
  vibrate,
}

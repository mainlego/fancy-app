import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../profile/domain/providers/current_profile_provider.dart';
import '../models/verification_model.dart';

/// Verification state notifier
class VerificationNotifier extends StateNotifier<VerificationState> {
  final SupabaseService _supabase;
  final Ref _ref;
  final ImagePicker _picker = ImagePicker();

  VerificationNotifier(this._supabase, this._ref) : super(const VerificationState()) {
    _loadCurrentStatus();
  }

  /// Load current verification status from database
  Future<void> _loadCurrentStatus() async {
    try {
      final request = await _supabase.getVerificationRequest();

      if (request == null) {
        // Check if user is already verified
        final profile = await _supabase.getCurrentProfile();
        if (profile != null && profile['is_verified'] == true) {
          state = state.copyWith(
            status: VerificationStatus.approved,
          );
        } else {
          state = state.copyWith(status: VerificationStatus.notStarted);
        }
        return;
      }

      final verificationRequest = VerificationRequest.fromSupabase(request);
      state = state.copyWith(
        status: verificationRequest.statusEnum,
        currentRequest: verificationRequest,
      );

      // If verification is approved, refresh the current profile to update is_verified flag
      if (verificationRequest.isApproved) {
        _ref.read(currentProfileProvider.notifier).refresh();
      }
    } catch (e) {
      debugPrint('Error loading verification status: $e');
      state = state.copyWith(
        status: VerificationStatus.notStarted,
        error: e.toString(),
      );
    }
  }

  /// Refresh status from database
  Future<void> refresh() async {
    await _loadCurrentStatus();
  }

  /// Start verification process
  void startVerification() {
    state = state.copyWith(
      status: VerificationStatus.takingPhotos,
      clearThumbsUpPath: true,
      clearWavePath: true,
      clearError: true,
    );
  }

  /// Take photo for specific pose
  Future<bool> takePhoto(PoseType pose) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo == null) {
        return false; // User cancelled
      }

      if (pose == PoseType.thumbsUp) {
        state = state.copyWith(photoThumbsUpPath: photo.path);
      } else {
        state = state.copyWith(photoWavePath: photo.path);
      }

      return true;
    } catch (e) {
      debugPrint('Error taking photo: $e');
      state = state.copyWith(error: 'Failed to take photo: $e');
      return false;
    }
  }

  /// Retake photo for specific pose
  void retakePhoto(PoseType pose) {
    if (pose == PoseType.thumbsUp) {
      state = state.copyWith(clearThumbsUpPath: true, clearError: true);
    } else {
      state = state.copyWith(clearWavePath: true, clearError: true);
    }
  }

  /// Reset to take new photos
  void resetPhotos() {
    state = state.copyWith(
      status: VerificationStatus.takingPhotos,
      clearThumbsUpPath: true,
      clearWavePath: true,
      clearError: true,
    );
  }

  /// Submit verification request
  Future<bool> submitVerification() async {
    if (!state.hasBothPhotos) {
      state = state.copyWith(error: 'Both photos are required');
      return false;
    }

    try {
      state = state.copyWith(
        status: VerificationStatus.uploading,
        isUploading: true,
        clearError: true,
      );

      // Read photo bytes
      final thumbsUpFile = XFile(state.photoThumbsUpPath!);
      final waveFile = XFile(state.photoWavePath!);

      final thumbsUpBytes = await thumbsUpFile.readAsBytes();
      final waveBytes = await waveFile.readAsBytes();

      // Upload photos to storage
      debugPrint('Uploading thumbs up photo...');
      final thumbsUpUrl = await _supabase.uploadVerificationPhoto(
        bytes: thumbsUpBytes,
        pose: 'thumbs_up',
      );

      debugPrint('Uploading wave photo...');
      final waveUrl = await _supabase.uploadVerificationPhoto(
        bytes: waveBytes,
        pose: 'wave',
      );

      // Submit verification request
      debugPrint('Submitting verification request...');
      final result = await _supabase.submitVerification(
        photoThumbsUp: thumbsUpUrl,
        photoWave: waveUrl,
      );

      debugPrint('Verification submitted: $result');

      state = state.copyWith(
        status: VerificationStatus.pending,
        isUploading: false,
      );

      // Refresh to get the created request
      await _loadCurrentStatus();

      return true;
    } catch (e) {
      debugPrint('Error submitting verification: $e');

      // Parse error message for user-friendly display
      String errorMessage = e.toString();

      // Handle specific error codes
      if (errorMessage.contains('no_profile_photo')) {
        errorMessage = 'Please add a profile photo first before verifying. We need a photo to compare against.';
      } else if (errorMessage.contains('Too many verification attempts')) {
        errorMessage = 'Too many attempts. Please try again in 24 hours.';
      } else if (errorMessage.contains('already have a pending')) {
        errorMessage = 'You already have a pending verification request. Please wait for it to complete.';
      } else if (errorMessage.contains('already verified')) {
        errorMessage = 'Your profile is already verified!';
      } else if (errorMessage.contains('Exception:')) {
        // Clean up exception prefix
        errorMessage = errorMessage.replaceAll('Exception:', '').trim();
      }

      state = state.copyWith(
        status: VerificationStatus.takingPhotos,
        isUploading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  /// Cancel verification and go back to start
  void cancelVerification() {
    state = const VerificationState(status: VerificationStatus.notStarted);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Try again after rejection
  void tryAgain() {
    state = state.copyWith(
      status: VerificationStatus.takingPhotos,
      clearThumbsUpPath: true,
      clearWavePath: true,
      clearCurrentRequest: true,
      clearError: true,
    );
  }
}

/// Verification provider
final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return VerificationNotifier(supabase, ref);
});

/// Stream provider for realtime verification status updates
final verificationStatusStreamProvider =
    StreamProvider<VerificationRequest?>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return supabase.watchVerificationStatus().map((data) {
    if (data == null) return null;
    return VerificationRequest.fromSupabase(data);
  });
});

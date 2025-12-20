/// Verification request model

/// Verification status enum
enum VerificationStatus {
  notStarted,
  takingPhotos, // User is taking photos
  uploading,    // Uploading photos to storage
  pending,      // Waiting for AI processing
  processing,   // AI is processing
  manualReview, // Sent for manual review
  approved,     // Verified successfully
  rejected,     // Verification failed
}

/// Extension to convert status string to enum
extension VerificationStatusExtension on VerificationStatus {
  String get value {
    switch (this) {
      case VerificationStatus.notStarted:
        return 'not_started';
      case VerificationStatus.takingPhotos:
        return 'taking_photos';
      case VerificationStatus.uploading:
        return 'uploading';
      case VerificationStatus.pending:
        return 'pending';
      case VerificationStatus.processing:
        return 'processing';
      case VerificationStatus.manualReview:
        return 'manual_review';
      case VerificationStatus.approved:
        return 'approved';
      case VerificationStatus.rejected:
        return 'rejected';
    }
  }

  static VerificationStatus fromString(String? value) {
    switch (value) {
      case 'pending':
        return VerificationStatus.pending;
      case 'processing':
        return VerificationStatus.processing;
      case 'manual_review':
        return VerificationStatus.manualReview;
      case 'approved':
        return VerificationStatus.approved;
      case 'rejected':
        return VerificationStatus.rejected;
      default:
        return VerificationStatus.notStarted;
    }
  }
}

/// Pose types for verification
enum PoseType {
  thumbsUp,
  wave,
}

/// Verification request from database
class VerificationRequest {
  final String id;
  final String userId;
  final String status;
  final String? photoThumbsUp;
  final String? photoWave;
  final String? referencePhoto;
  final double? aiConfidence;
  final bool? aiFaceMatch;
  final bool? aiThumbsUpDetected;
  final bool? aiWaveDetected;
  final String? rejectionReason;
  final String? rejectionMessage;
  final int attemptNumber;
  final DateTime createdAt;
  final DateTime? aiProcessedAt;

  const VerificationRequest({
    required this.id,
    required this.userId,
    required this.status,
    this.photoThumbsUp,
    this.photoWave,
    this.referencePhoto,
    this.aiConfidence,
    this.aiFaceMatch,
    this.aiThumbsUpDetected,
    this.aiWaveDetected,
    this.rejectionReason,
    this.rejectionMessage,
    required this.attemptNumber,
    required this.createdAt,
    this.aiProcessedAt,
  });

  factory VerificationRequest.fromSupabase(Map<String, dynamic> json) {
    return VerificationRequest(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      status: json['status'] as String,
      photoThumbsUp: json['photo_thumbs_up'] as String?,
      photoWave: json['photo_wave'] as String?,
      referencePhoto: json['reference_photo'] as String?,
      aiConfidence: (json['ai_confidence'] as num?)?.toDouble(),
      aiFaceMatch: json['ai_face_match'] as bool?,
      aiThumbsUpDetected: json['ai_thumbs_up_detected'] as bool?,
      aiWaveDetected: json['ai_wave_detected'] as bool?,
      rejectionReason: json['rejection_reason'] as String?,
      rejectionMessage: json['rejection_message'] as String?,
      attemptNumber: json['attempt_number'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      aiProcessedAt: json['ai_processed_at'] != null
          ? DateTime.parse(json['ai_processed_at'] as String)
          : null,
    );
  }

  VerificationStatus get statusEnum =>
      VerificationStatusExtension.fromString(status);

  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isPending => status == 'pending' || status == 'processing';
  bool get isManualReview => status == 'manual_review';

  /// Get user-friendly rejection message
  String get rejectionDisplayMessage {
    if (rejectionMessage != null) return rejectionMessage!;

    switch (rejectionReason) {
      case 'face_not_visible':
        return 'Your face is not clearly visible. Please ensure good lighting.';
      case 'face_mismatch':
        return 'The photos don\'t appear to match your profile photo.';
      case 'wrong_pose':
        return 'Please clearly show the requested gestures.';
      case 'photo_quality':
        return 'Photo quality is too low. Please use better lighting.';
      case 'multiple_faces':
        return 'Multiple faces detected. Please take a solo selfie.';
      case 'inappropriate_content':
        return 'Inappropriate content detected.';
      default:
        return 'Verification failed. Please try again.';
    }
  }
}

/// Local state for verification flow
class VerificationState {
  final VerificationStatus status;
  final VerificationRequest? currentRequest;
  final String? photoThumbsUpPath; // Local path or URL
  final String? photoWavePath;
  final bool isUploading;
  final String? error;

  const VerificationState({
    this.status = VerificationStatus.notStarted,
    this.currentRequest,
    this.photoThumbsUpPath,
    this.photoWavePath,
    this.isUploading = false,
    this.error,
  });

  VerificationState copyWith({
    VerificationStatus? status,
    VerificationRequest? currentRequest,
    bool clearCurrentRequest = false,
    String? photoThumbsUpPath,
    bool clearThumbsUpPath = false,
    String? photoWavePath,
    bool clearWavePath = false,
    bool? isUploading,
    String? error,
    bool clearError = false,
  }) {
    return VerificationState(
      status: status ?? this.status,
      currentRequest: clearCurrentRequest ? null : (currentRequest ?? this.currentRequest),
      photoThumbsUpPath: clearThumbsUpPath ? null : (photoThumbsUpPath ?? this.photoThumbsUpPath),
      photoWavePath: clearWavePath ? null : (photoWavePath ?? this.photoWavePath),
      isUploading: isUploading ?? this.isUploading,
      error: clearError ? null : error,
    );
  }

  bool get hasThumbsUpPhoto => photoThumbsUpPath != null;
  bool get hasWavePhoto => photoWavePath != null;
  bool get hasBothPhotos => hasThumbsUpPhoto && hasWavePhoto;
}

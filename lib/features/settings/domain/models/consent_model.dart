/// GDPR Consent types
enum ConsentType {
  termsOfService('terms_of_service', 'Terms of Service', true),
  privacyPolicy('privacy_policy', 'Privacy Policy', true),
  dataProcessing('data_processing', 'Data Processing', true),
  locationTracking('location_tracking', 'Location Tracking', false),
  pushNotifications('push_notifications', 'Push Notifications', false),
  emailMarketing('email_marketing', 'Email Marketing', false),
  analytics('analytics', 'Analytics', false),
  thirdPartySharing('third_party_sharing', 'Third Party Sharing', false),
  ageVerification('age_verification', 'Age Verification (18+)', true);

  final String value;
  final String displayName;
  final bool isRequired;

  const ConsentType(this.value, this.displayName, this.isRequired);

  static ConsentType? fromValue(String value) {
    return ConsentType.values.cast<ConsentType?>().firstWhere(
          (e) => e?.value == value,
          orElse: () => null,
        );
  }
}

/// User consent record
class UserConsent {
  final String id;
  final String userId;
  final ConsentType consentType;
  final bool granted;
  final DateTime? grantedAt;
  final DateTime? revokedAt;
  final String? policyVersion;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserConsent({
    required this.id,
    required this.userId,
    required this.consentType,
    required this.granted,
    this.grantedAt,
    this.revokedAt,
    this.policyVersion,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserConsent.fromSupabase(Map<String, dynamic> data) {
    return UserConsent(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      consentType:
          ConsentType.fromValue(data['consent_type'] as String) ?? ConsentType.termsOfService,
      granted: data['granted'] as bool? ?? false,
      grantedAt:
          data['granted_at'] != null ? DateTime.parse(data['granted_at'] as String) : null,
      revokedAt:
          data['revoked_at'] != null ? DateTime.parse(data['revoked_at'] as String) : null,
      policyVersion: data['policy_version'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: DateTime.parse(data['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'consent_type': consentType.value,
        'granted': granted,
        'granted_at': grantedAt?.toIso8601String(),
        'revoked_at': revokedAt?.toIso8601String(),
        'policy_version': policyVersion,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  UserConsent copyWith({
    String? id,
    String? userId,
    ConsentType? consentType,
    bool? granted,
    DateTime? grantedAt,
    DateTime? revokedAt,
    String? policyVersion,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserConsent(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      consentType: consentType ?? this.consentType,
      granted: granted ?? this.granted,
      grantedAt: grantedAt ?? this.grantedAt,
      revokedAt: revokedAt ?? this.revokedAt,
      policyVersion: policyVersion ?? this.policyVersion,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// State for consent management
class ConsentState {
  final Map<ConsentType, bool> consents;
  final bool isLoading;
  final String? error;

  const ConsentState({
    this.consents = const {},
    this.isLoading = false,
    this.error,
  });

  bool get hasAllRequiredConsents {
    return ConsentType.values
        .where((c) => c.isRequired)
        .every((c) => consents[c] == true);
  }

  bool isGranted(ConsentType type) => consents[type] == true;

  ConsentState copyWith({
    Map<ConsentType, bool>? consents,
    bool? isLoading,
    String? error,
  }) {
    return ConsentState(
      consents: consents ?? this.consents,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

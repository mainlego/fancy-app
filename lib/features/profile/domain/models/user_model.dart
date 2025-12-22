import 'package:equatable/equatable.dart';
import '../../../../core/services/debug_logger.dart';

/// Dating goal options
enum DatingGoal {
  anything,
  casual,
  virtual,
  friendship,
  longTerm,
}

/// Relationship status options
enum RelationshipStatus {
  single,
  complicated,
  married,
  inRelationship,
}

/// Profile type options
enum ProfileType {
  woman,
  man,
  manAndWoman,
  manPair,
  womanPair,
}

/// Zodiac sign options
enum ZodiacSign {
  aries,
  taurus,
  gemini,
  cancer,
  leo,
  virgo,
  libra,
  scorpio,
  sagittarius,
  capricorn,
  aquarius,
  pisces,
}

/// Safe enum parsing helpers
T? _tryParseEnum<T extends Enum>(List<T> values, String? name) {
  if (name == null) return null;
  try {
    return values.byName(name);
  } catch (e) {
    logWarn('Unknown enum value "$name" for ${T.toString()}', tag: 'UserModel');
    return null;
  }
}

ProfileType _parseProfileType(String? name) {
  if (name == null) return ProfileType.woman;
  try {
    return ProfileType.values.byName(name);
  } catch (e) {
    logWarn('Unknown profile_type "$name", defaulting to woman', tag: 'UserModel');
    return ProfileType.woman;
  }
}

Set<ProfileType> _parseLookingFor(List<dynamic>? list) {
  if (list == null) return {};
  final result = <ProfileType>{};
  for (final item in list) {
    try {
      result.add(ProfileType.values.byName(item as String));
    } catch (e) {
      logWarn('Unknown looking_for value "$item", skipping', tag: 'UserModel');
    }
  }
  return result;
}

/// User profile model
class UserModel extends Equatable {
  final String id;
  final String name;
  final int age;
  final DateTime? birthDate;
  final String? bio;
  final List<String> photos;
  final String? avatarUrl;
  final bool isOnline;
  final bool isVerified;
  final bool isPremium;
  final bool isActive;
  final bool isAi;

  // Location
  final String? city;
  final String? country;
  final double? latitude;
  final double? longitude;
  final int? distanceKm;

  // Dating preferences
  final DatingGoal? datingGoal;
  final RelationshipStatus? relationshipStatus;
  final ProfileType profileType;

  // Physical attributes
  final int? heightCm;
  final int? weightKg;
  final ZodiacSign? zodiacSign;

  // Additional info
  final String? occupation;
  final List<String> languages;
  final List<String> interests;
  final List<String> fantasies;

  // Looking for preferences (who user wants to see)
  final Set<ProfileType> lookingFor;

  // Timestamps
  final DateTime? lastOnline;
  final DateTime createdAt;
  final DateTime? profileTypeChangedAt; // Track when profile type was changed

  const UserModel({
    required this.id,
    required this.name,
    required this.age,
    this.birthDate,
    this.bio,
    this.photos = const [],
    this.avatarUrl,
    this.isOnline = false,
    this.isVerified = false,
    this.isPremium = false,
    this.isActive = true,
    this.isAi = false,
    this.city,
    this.country,
    this.latitude,
    this.longitude,
    this.distanceKm,
    this.datingGoal,
    this.relationshipStatus,
    this.profileType = ProfileType.woman,
    this.heightCm,
    this.weightKg,
    this.zodiacSign,
    this.occupation,
    this.languages = const [],
    this.interests = const [],
    this.fantasies = const [],
    this.lookingFor = const {},
    this.lastOnline,
    required this.createdAt,
    this.profileTypeChangedAt,
  });

  /// Check if user can change profile type (only once without support)
  bool get canChangeProfileType => profileTypeChangedAt == null;

  /// Get avatar URL or first photo
  String? get displayAvatar => avatarUrl ?? (photos.isNotEmpty ? photos.first : null);

  /// Check if user has photos
  bool get hasPhotos => photos.isNotEmpty;

  /// Get location string
  String get locationString {
    if (city != null && country != null) {
      return '$city, $country';
    }
    return city ?? country ?? '';
  }

  /// Get distance display string with privacy fuzzing (±1km)
  /// Shows only distance without city for privacy
  String get distanceString {
    if (distanceKm == null) {
      return locationString; // Fallback to city/country if no distance
    }

    // Add random fuzzing ±1km for privacy (based on user id hash for consistency)
    final fuzz = (id.hashCode % 3) - 1; // -1, 0, or +1
    final fuzzedDistance = (distanceKm! + fuzz).clamp(1, 99999);

    if (fuzzedDistance < 1) {
      return 'Less than 1 km';
    } else if (fuzzedDistance == 1) {
      return '1 km away';
    } else {
      return '$fuzzedDistance km away';
    }
  }

  /// Get short distance string for cards (city + distance)
  String get distanceShortString {
    final cityName = city ?? '';

    if (distanceKm == null) {
      return cityName; // Just city if no distance
    }

    // Add random fuzzing ±1km for privacy (based on user id hash for consistency)
    final fuzz = (id.hashCode % 3) - 1; // -1, 0, or +1
    final fuzzedDistance = (distanceKm! + fuzz).clamp(1, 99999);

    String distanceText;
    if (fuzzedDistance < 1) {
      distanceText = '< 1 km';
    } else {
      distanceText = '$fuzzedDistance km';
    }

    // Combine city and distance
    if (cityName.isNotEmpty) {
      return '$cityName • $distanceText';
    } else {
      return distanceText;
    }
  }

  /// Copy with method
  UserModel copyWith({
    String? id,
    String? name,
    int? age,
    DateTime? birthDate,
    String? bio,
    List<String>? photos,
    String? avatarUrl,
    bool? isOnline,
    bool? isVerified,
    bool? isPremium,
    bool? isActive,
    bool? isAi,
    String? city,
    String? country,
    double? latitude,
    double? longitude,
    int? distanceKm,
    DatingGoal? datingGoal,
    RelationshipStatus? relationshipStatus,
    ProfileType? profileType,
    int? heightCm,
    int? weightKg,
    ZodiacSign? zodiacSign,
    String? occupation,
    List<String>? languages,
    List<String>? interests,
    List<String>? fantasies,
    Set<ProfileType>? lookingFor,
    DateTime? lastOnline,
    DateTime? createdAt,
    DateTime? profileTypeChangedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      birthDate: birthDate ?? this.birthDate,
      bio: bio ?? this.bio,
      photos: photos ?? this.photos,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      isActive: isActive ?? this.isActive,
      isAi: isAi ?? this.isAi,
      city: city ?? this.city,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distanceKm: distanceKm ?? this.distanceKm,
      datingGoal: datingGoal ?? this.datingGoal,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      profileType: profileType ?? this.profileType,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      occupation: occupation ?? this.occupation,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      fantasies: fantasies ?? this.fantasies,
      lookingFor: lookingFor ?? this.lookingFor,
      lastOnline: lastOnline ?? this.lastOnline,
      createdAt: createdAt ?? this.createdAt,
      profileTypeChangedAt: profileTypeChangedAt ?? this.profileTypeChangedAt,
    );
  }

  /// From JSON factory
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'] as String)
          : null,
      bio: json['bio'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      avatarUrl: json['avatarUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
      isPremium: json['isPremium'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? false,
      isAi: json['isAi'] as bool? ?? false,
      city: json['city'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: json['distanceKm'] as int?,
      datingGoal: _tryParseEnum(DatingGoal.values, json['datingGoal'] as String?),
      relationshipStatus: _tryParseEnum(RelationshipStatus.values, json['relationshipStatus'] as String?),
      profileType: _parseProfileType(json['profileType'] as String?),
      heightCm: json['heightCm'] as int?,
      weightKg: json['weightKg'] as int?,
      zodiacSign: _tryParseEnum(ZodiacSign.values, json['zodiacSign'] as String?),
      occupation: json['occupation'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      fantasies: (json['fantasies'] as List<dynamic>?)?.cast<String>() ?? [],
      lookingFor: _parseLookingFor(json['lookingFor'] as List<dynamic>?),
      lastOnline: json['lastOnline'] != null
          ? DateTime.parse(json['lastOnline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      profileTypeChangedAt: json['profileTypeChangedAt'] != null
          ? DateTime.parse(json['profileTypeChangedAt'] as String)
          : null,
    );
  }

  /// From Supabase JSON (snake_case format)
  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    try {
      // Calculate age from birth_date, default to 18 if not set
      int age = 18; // Default age for profiles without birth_date
      final birthDateRaw = json['birth_date'];
      if (birthDateRaw != null) {
        try {
          final birthDate = DateTime.parse(birthDateRaw as String);
          age = DateTime.now().difference(birthDate).inDays ~/ 365;
        } catch (e) {
          print('Warning: Invalid birth_date format: $birthDateRaw');
        }
      }

      // Safe date parsing helper
      DateTime? tryParseDate(dynamic value) {
        if (value == null) return null;
        try {
          return DateTime.parse(value as String);
        } catch (e) {
          print('Warning: Invalid date format: $value');
          return null;
        }
      }

      return UserModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? json['display_name'] as String? ?? 'Unknown',
        age: age,
        birthDate: tryParseDate(json['birth_date']),
        bio: json['bio'] as String?,
        photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
        avatarUrl: json['avatar_url'] as String?,
        isOnline: json['is_online'] as bool? ?? false,
        isVerified: json['is_verified'] as bool? ?? false,
        isPremium: json['is_premium'] as bool? ?? false,
        isActive: json['is_active'] as bool? ?? false,
        isAi: json['is_ai'] as bool? ?? false,
        city: json['city'] as String?,
        country: json['country'] as String?,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        distanceKm: json['distance_km'] as int?,
        datingGoal: _tryParseEnum(DatingGoal.values, json['dating_goal'] as String?),
        relationshipStatus: _tryParseEnum(RelationshipStatus.values, json['relationship_status'] as String?),
        profileType: _parseProfileType(json['profile_type'] as String?),
        heightCm: json['height_cm'] as int?,
        weightKg: json['weight_kg'] as int?,
        zodiacSign: _tryParseEnum(ZodiacSign.values, json['zodiac_sign'] as String?),
        occupation: json['occupation'] as String?,
        languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
        interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
        fantasies: (json['fantasies'] as List<dynamic>?)?.cast<String>() ?? [],
        lookingFor: _parseLookingFor(json['looking_for'] as List<dynamic>?),
        lastOnline: tryParseDate(json['last_online']),
        createdAt: tryParseDate(json['created_at']) ?? DateTime.now(),
        profileTypeChangedAt: tryParseDate(json['profile_type_changed_at']),
      );
    } catch (e, st) {
      logError('Failed to parse UserModel from Supabase', tag: 'UserModel', error: e, stackTrace: st);
      logDebug('JSON data that failed: $json', tag: 'UserModel');
      rethrow;
    }
  }

  /// To Supabase JSON (snake_case format)
  Map<String, dynamic> toSupabase() {
    return {
      'id': id,
      'name': name,
      'birth_date': birthDate?.toIso8601String(),
      'bio': bio,
      'photos': photos,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'is_active': isActive,
      'is_ai': isAi,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'dating_goal': datingGoal?.name,
      'relationship_status': relationshipStatus?.name,
      'profile_type': profileType.name,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'zodiac_sign': zodiacSign?.name,
      'occupation': occupation,
      'languages': languages,
      'interests': interests,
      'fantasies': fantasies,
      'looking_for': lookingFor.map((e) => e.name).toList(),
      'last_online': lastOnline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'profile_type_changed_at': profileTypeChangedAt?.toIso8601String(),
    };
  }

  /// To JSON method
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'birthDate': birthDate?.toIso8601String(),
      'bio': bio,
      'photos': photos,
      'avatarUrl': avatarUrl,
      'isOnline': isOnline,
      'isVerified': isVerified,
      'isPremium': isPremium,
      'isActive': isActive,
      'isAi': isAi,
      'city': city,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'distanceKm': distanceKm,
      'datingGoal': datingGoal?.name,
      'relationshipStatus': relationshipStatus?.name,
      'profileType': profileType.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'zodiacSign': zodiacSign?.name,
      'occupation': occupation,
      'languages': languages,
      'interests': interests,
      'fantasies': fantasies,
      'lookingFor': lookingFor.map((e) => e.name).toList(),
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'profileTypeChangedAt': profileTypeChangedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        age,
        birthDate,
        bio,
        photos,
        avatarUrl,
        isOnline,
        isVerified,
        isPremium,
        isActive,
        isAi,
        city,
        country,
        latitude,
        longitude,
        distanceKm,
        datingGoal,
        relationshipStatus,
        profileType,
        heightCm,
        weightKg,
        zodiacSign,
        occupation,
        languages,
        interests,
        fantasies,
        lookingFor,
        lastOnline,
        createdAt,
        profileTypeChangedAt,
      ];
}

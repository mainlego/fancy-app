import 'package:equatable/equatable.dart';

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

  // Looking for preferences (who user wants to see)
  final Set<ProfileType> lookingFor;

  // Timestamps
  final DateTime? lastOnline;
  final DateTime createdAt;

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
    this.lookingFor = const {},
    this.lastOnline,
    required this.createdAt,
  });

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
    Set<ProfileType>? lookingFor,
    DateTime? lastOnline,
    DateTime? createdAt,
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
      lookingFor: lookingFor ?? this.lookingFor,
      lastOnline: lastOnline ?? this.lastOnline,
      createdAt: createdAt ?? this.createdAt,
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
      isActive: json['isActive'] as bool? ?? true,
      isAi: json['isAi'] as bool? ?? false,
      city: json['city'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: json['distanceKm'] as int?,
      datingGoal: json['datingGoal'] != null
          ? DatingGoal.values.byName(json['datingGoal'] as String)
          : null,
      relationshipStatus: json['relationshipStatus'] != null
          ? RelationshipStatus.values.byName(json['relationshipStatus'] as String)
          : null,
      profileType: json['profileType'] != null
          ? ProfileType.values.byName(json['profileType'] as String)
          : ProfileType.woman,
      heightCm: json['heightCm'] as int?,
      weightKg: json['weightKg'] as int?,
      zodiacSign: json['zodiacSign'] != null
          ? ZodiacSign.values.byName(json['zodiacSign'] as String)
          : null,
      occupation: json['occupation'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      lookingFor: (json['lookingFor'] as List<dynamic>?)
              ?.map((e) => ProfileType.values.byName(e as String))
              .toSet() ??
          {},
      lastOnline: json['lastOnline'] != null
          ? DateTime.parse(json['lastOnline'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// From Supabase JSON (snake_case format)
  factory UserModel.fromSupabase(Map<String, dynamic> json) {
    // Calculate age from birth_date
    int age = 0;
    final birthDateRaw = json['birth_date'];
    if (birthDateRaw != null) {
      try {
        final birthDate = DateTime.parse(birthDateRaw as String);
        age = DateTime.now().difference(birthDate).inDays ~/ 365;
      } catch (e) {
        // Invalid date format - keep age as 0
      }
    }

    return UserModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['display_name'] as String? ?? 'Unknown',
      age: age,
      birthDate: json['birth_date'] != null
          ? DateTime.parse(json['birth_date'] as String)
          : null,
      bio: json['bio'] as String?,
      photos: (json['photos'] as List<dynamic>?)?.cast<String>() ?? [],
      avatarUrl: json['avatar_url'] as String?,
      isOnline: json['is_online'] as bool? ?? false,
      isVerified: json['is_verified'] as bool? ?? false,
      isPremium: json['is_premium'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      isAi: json['is_ai'] as bool? ?? false,
      city: json['city'] as String?,
      country: json['country'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distanceKm: json['distance_km'] as int?,
      datingGoal: json['dating_goal'] != null
          ? DatingGoal.values.byName(json['dating_goal'] as String)
          : null,
      relationshipStatus: json['relationship_status'] != null
          ? RelationshipStatus.values.byName(json['relationship_status'] as String)
          : null,
      profileType: json['profile_type'] != null
          ? ProfileType.values.byName(json['profile_type'] as String)
          : ProfileType.woman,
      heightCm: json['height_cm'] as int?,
      weightKg: json['weight_kg'] as int?,
      zodiacSign: json['zodiac_sign'] != null
          ? ZodiacSign.values.byName(json['zodiac_sign'] as String)
          : null,
      occupation: json['occupation'] as String?,
      languages: (json['languages'] as List<dynamic>?)?.cast<String>() ?? [],
      interests: (json['interests'] as List<dynamic>?)?.cast<String>() ?? [],
      lookingFor: (json['looking_for'] as List<dynamic>?)
              ?.map((e) => ProfileType.values.byName(e as String))
              .toSet() ??
          {},
      lastOnline: json['last_online'] != null
          ? DateTime.parse(json['last_online'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
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
      'looking_for': lookingFor.map((e) => e.name).toList(),
      'last_online': lastOnline?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
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
      'lookingFor': lookingFor.map((e) => e.name).toList(),
      'lastOnline': lastOnline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
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
        lookingFor,
        lastOnline,
        createdAt,
      ];
}

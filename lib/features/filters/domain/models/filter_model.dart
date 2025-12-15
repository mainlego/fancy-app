import 'package:equatable/equatable.dart';
import '../../../profile/domain/models/user_model.dart';

/// Filter model for search preferences
class FilterModel extends Equatable {
  // Dating goals (multi-select)
  final Set<DatingGoal> datingGoals;

  // Relationship status (multi-select)
  final Set<RelationshipStatus> relationshipStatuses;

  // Distance range
  final int minDistanceKm;
  final int maxDistanceKm;
  static const int minDistanceLimit = 1;
  static const int maxDistanceLimit = 500;

  // For backward compatibility
  int get distanceKm => maxDistanceKm;

  // Age range
  final int minAge;
  final int maxAge;
  static const int minAgeLimit = 18;
  static const int maxAgeLimit = 99; // 60+ shows as unlimited

  // Special filters
  final bool onlineOnly;
  final bool withPhoto;
  final bool verifiedOnly;

  // Looking for (multi-select)
  final Set<ProfileType> lookingFor;

  // Physical filters
  final int? minHeight;
  final int? maxHeight;
  static const int minHeightLimit = 140;
  static const int maxHeightLimit = 220;

  final int? minWeight;
  final int? maxWeight;
  static const int minWeightLimit = 40;
  static const int maxWeightLimit = 150;

  // Zodiac signs (multi-select)
  final Set<ZodiacSign> zodiacSigns;

  // Languages (multi-select)
  final Set<String> languages;

  const FilterModel({
    this.datingGoals = const {},
    this.relationshipStatuses = const {},
    this.minDistanceKm = 1,
    this.maxDistanceKm = 500,
    this.minAge = 18,
    this.maxAge = 99,
    this.onlineOnly = false,
    this.withPhoto = false,
    this.verifiedOnly = false,
    this.lookingFor = const {},
    this.minHeight,
    this.maxHeight,
    this.minWeight,
    this.maxWeight,
    this.zodiacSigns = const {},
    this.languages = const {},
  });

  /// Default filters
  static const FilterModel defaultFilters = FilterModel();

  /// Check if any filters are active
  bool get hasActiveFilters {
    return datingGoals.isNotEmpty ||
        relationshipStatuses.isNotEmpty ||
        minDistanceKm != minDistanceLimit ||
        maxDistanceKm != maxDistanceLimit ||
        minAge != minAgeLimit ||
        maxAge != maxAgeLimit ||
        onlineOnly ||
        withPhoto ||
        verifiedOnly ||
        lookingFor.isNotEmpty ||
        minHeight != null ||
        maxHeight != null ||
        minWeight != null ||
        maxWeight != null ||
        zodiacSigns.isNotEmpty ||
        languages.isNotEmpty;
  }

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (datingGoals.isNotEmpty) count++;
    if (relationshipStatuses.isNotEmpty) count++;
    if (minDistanceKm != minDistanceLimit || maxDistanceKm != maxDistanceLimit) count++;
    if (minAge != minAgeLimit || maxAge != maxAgeLimit) count++;
    if (onlineOnly) count++;
    if (withPhoto) count++;
    if (verifiedOnly) count++;
    if (lookingFor.isNotEmpty) count++;
    if (minHeight != null || maxHeight != null) count++;
    if (minWeight != null || maxWeight != null) count++;
    if (zodiacSigns.isNotEmpty) count++;
    if (languages.isNotEmpty) count++;
    return count;
  }

  /// Copy with method
  FilterModel copyWith({
    Set<DatingGoal>? datingGoals,
    Set<RelationshipStatus>? relationshipStatuses,
    int? minDistanceKm,
    int? maxDistanceKm,
    int? minAge,
    int? maxAge,
    bool? onlineOnly,
    bool? withPhoto,
    bool? verifiedOnly,
    Set<ProfileType>? lookingFor,
    int? minHeight,
    int? maxHeight,
    int? minWeight,
    int? maxWeight,
    Set<ZodiacSign>? zodiacSigns,
    Set<String>? languages,
  }) {
    return FilterModel(
      datingGoals: datingGoals ?? this.datingGoals,
      relationshipStatuses: relationshipStatuses ?? this.relationshipStatuses,
      minDistanceKm: minDistanceKm ?? this.minDistanceKm,
      maxDistanceKm: maxDistanceKm ?? this.maxDistanceKm,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      onlineOnly: onlineOnly ?? this.onlineOnly,
      withPhoto: withPhoto ?? this.withPhoto,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
      lookingFor: lookingFor ?? this.lookingFor,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
      minWeight: minWeight ?? this.minWeight,
      maxWeight: maxWeight ?? this.maxWeight,
      zodiacSigns: zodiacSigns ?? this.zodiacSigns,
      languages: languages ?? this.languages,
    );
  }

  /// Clear specific height filter
  FilterModel clearHeight() {
    return copyWith(minHeight: null, maxHeight: null);
  }

  /// Clear specific weight filter
  FilterModel clearWeight() {
    return copyWith(minWeight: null, maxWeight: null);
  }

  /// From JSON factory
  factory FilterModel.fromJson(Map<String, dynamic> json) {
    return FilterModel(
      datingGoals: (json['datingGoals'] as List<dynamic>?)
              ?.map((e) => DatingGoal.values.byName(e as String))
              .toSet() ??
          {},
      relationshipStatuses: (json['relationshipStatuses'] as List<dynamic>?)
              ?.map((e) => RelationshipStatus.values.byName(e as String))
              .toSet() ??
          {},
      minDistanceKm: json['minDistanceKm'] as int? ?? minDistanceLimit,
      maxDistanceKm: json['maxDistanceKm'] as int? ?? json['distanceKm'] as int? ?? maxDistanceLimit,
      minAge: json['minAge'] as int? ?? minAgeLimit,
      maxAge: json['maxAge'] as int? ?? maxAgeLimit,
      onlineOnly: json['onlineOnly'] as bool? ?? false,
      withPhoto: json['withPhoto'] as bool? ?? false,
      verifiedOnly: json['verifiedOnly'] as bool? ?? false,
      lookingFor: (json['lookingFor'] as List<dynamic>?)
              ?.map((e) => ProfileType.values.byName(e as String))
              .toSet() ??
          {},
      minHeight: json['minHeight'] as int?,
      maxHeight: json['maxHeight'] as int?,
      minWeight: json['minWeight'] as int?,
      maxWeight: json['maxWeight'] as int?,
      zodiacSigns: (json['zodiacSigns'] as List<dynamic>?)
              ?.map((e) => ZodiacSign.values.byName(e as String))
              .toSet() ??
          {},
      languages: (json['languages'] as List<dynamic>?)?.cast<String>().toSet() ?? {},
    );
  }

  /// To JSON method
  Map<String, dynamic> toJson() {
    return {
      'datingGoals': datingGoals.map((e) => e.name).toList(),
      'relationshipStatuses': relationshipStatuses.map((e) => e.name).toList(),
      'minDistanceKm': minDistanceKm,
      'maxDistanceKm': maxDistanceKm,
      'minAge': minAge,
      'maxAge': maxAge,
      'onlineOnly': onlineOnly,
      'withPhoto': withPhoto,
      'verifiedOnly': verifiedOnly,
      'lookingFor': lookingFor.map((e) => e.name).toList(),
      'minHeight': minHeight,
      'maxHeight': maxHeight,
      'minWeight': minWeight,
      'maxWeight': maxWeight,
      'zodiacSigns': zodiacSigns.map((e) => e.name).toList(),
      'languages': languages.toList(),
    };
  }

  @override
  List<Object?> get props => [
        datingGoals,
        relationshipStatuses,
        minDistanceKm,
        maxDistanceKm,
        minAge,
        maxAge,
        onlineOnly,
        withPhoto,
        verifiedOnly,
        lookingFor,
        minHeight,
        maxHeight,
        minWeight,
        maxWeight,
        zodiacSigns,
        languages,
      ];
}

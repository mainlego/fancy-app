/// Profile options models for interests, fantasies, and occupations
/// Data is fetched from Supabase database

/// Interest model
class Interest {
  final String id;
  final String name;
  final String? nameRu;
  final String category;
  final String? icon;
  final bool isSystem;
  final int sortOrder;

  const Interest({
    required this.id,
    required this.name,
    this.nameRu,
    required this.category,
    this.icon,
    this.isSystem = true,
    this.sortOrder = 0,
  });

  factory Interest.fromJson(Map<String, dynamic> json) {
    return Interest(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['name_ru'] as String?,
      category: json['category'] as String,
      icon: json['icon'] as String?,
      isSystem: json['is_system'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ru': nameRu,
    'category': category,
    'icon': icon,
    'is_system': isSystem,
    'sort_order': sortOrder,
  };

  /// Get display name based on locale
  String getDisplayName(String locale) {
    if (locale.startsWith('ru') && nameRu != null) {
      return nameRu!;
    }
    return name;
  }
}

/// Fantasy model
class Fantasy {
  final String id;
  final String name;
  final String? nameRu;
  final String? category;
  final bool isSystem;
  final int sortOrder;

  const Fantasy({
    required this.id,
    required this.name,
    this.nameRu,
    this.category,
    this.isSystem = true,
    this.sortOrder = 0,
  });

  factory Fantasy.fromJson(Map<String, dynamic> json) {
    return Fantasy(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['name_ru'] as String?,
      category: json['category'] as String?,
      isSystem: json['is_system'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ru': nameRu,
    'category': category,
    'is_system': isSystem,
    'sort_order': sortOrder,
  };

  String getDisplayName(String locale) {
    if (locale.startsWith('ru') && nameRu != null) {
      return nameRu!;
    }
    return name;
  }
}

/// Occupation model
class Occupation {
  final String id;
  final String name;
  final String? nameRu;
  final String? category;
  final bool isSystem;
  final int sortOrder;

  const Occupation({
    required this.id,
    required this.name,
    this.nameRu,
    this.category,
    this.isSystem = true,
    this.sortOrder = 0,
  });

  factory Occupation.fromJson(Map<String, dynamic> json) {
    return Occupation(
      id: json['id'] as String,
      name: json['name'] as String,
      nameRu: json['name_ru'] as String?,
      category: json['category'] as String?,
      isSystem: json['is_system'] as bool? ?? true,
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'name_ru': nameRu,
    'category': category,
    'is_system': isSystem,
    'sort_order': sortOrder,
  };

  String getDisplayName(String locale) {
    if (locale.startsWith('ru') && nameRu != null) {
      return nameRu!;
    }
    return name;
  }
}

/// User's selected interest
class UserInterest {
  final String id;
  final String interestId;
  final Interest? interest;

  const UserInterest({
    required this.id,
    required this.interestId,
    this.interest,
  });

  factory UserInterest.fromJson(Map<String, dynamic> json) {
    return UserInterest(
      id: json['id'] as String,
      interestId: json['interest_id'] as String,
      interest: json['interests'] != null
          ? Interest.fromJson(json['interests'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// User's selected fantasy
class UserFantasy {
  final String id;
  final String fantasyId;
  final Fantasy? fantasy;

  const UserFantasy({
    required this.id,
    required this.fantasyId,
    this.fantasy,
  });

  factory UserFantasy.fromJson(Map<String, dynamic> json) {
    return UserFantasy(
      id: json['id'] as String,
      fantasyId: json['fantasy_id'] as String,
      fantasy: json['fantasies'] != null
          ? Fantasy.fromJson(json['fantasies'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Extended language list
class ProfileLanguages {
  static const List<String> all = [
    'English',
    'Russian',
    'Ukrainian',
    'Spanish',
    'French',
    'German',
    'Italian',
    'Portuguese',
    'Chinese',
    'Japanese',
    'Korean',
    'Arabic',
    'Hindi',
    'Turkish',
    'Polish',
    'Dutch',
    'Swedish',
    'Norwegian',
    'Danish',
    'Finnish',
    'Greek',
    'Czech',
    'Hungarian',
    'Romanian',
    'Bulgarian',
    'Serbian',
    'Croatian',
    'Thai',
    'Vietnamese',
    'Indonesian',
    'Hebrew',
    'Persian',
  ];
}

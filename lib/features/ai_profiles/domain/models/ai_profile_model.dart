import 'package:equatable/equatable.dart';
import '../../../profile/domain/models/user_model.dart';

/// AI Profile model - represents a generated AI girl profile with FULL attributes
/// These profiles are stored in database and rotated every 24 hours
class AIProfileModel extends Equatable {
  final String id;
  final String name;
  final int age;
  final String city;
  final String country;
  final String bio;
  final List<String> interests;
  final String avatarUrl;
  final List<String> photos;
  final String personalityTrait;
  final String communicationStyle;
  final String systemPrompt;
  final bool isOnline;
  final bool isVerified;
  final bool isPremium;
  final DateTime createdAt;
  final DateTime expiresAt;

  // Full profile attributes like real users
  final DatingGoal datingGoal;
  final RelationshipStatus relationshipStatus;
  final ProfileType profileType;
  final int? heightCm;
  final int? weightKg;
  final ZodiacSign? zodiacSign;
  final String? occupation;
  final List<String> languages;
  final String? education;
  final bool hasPets;
  final bool smokes;
  final bool drinks;
  final bool hasKids;
  final bool wantsKids;

  // AI-specific fields (visible only to admins)
  final bool isAi;
  final int messageCount;
  final int reportCount;
  final int banCount;
  final double responseRate;
  final String? lastActiveUserId;

  const AIProfileModel({
    required this.id,
    required this.name,
    required this.age,
    required this.city,
    this.country = 'Россия',
    required this.bio,
    required this.interests,
    required this.avatarUrl,
    required this.photos,
    required this.personalityTrait,
    required this.communicationStyle,
    required this.systemPrompt,
    this.isOnline = true,
    this.isVerified = true,
    this.isPremium = false,
    required this.createdAt,
    required this.expiresAt,
    // Full profile attributes
    this.datingGoal = DatingGoal.casual,
    this.relationshipStatus = RelationshipStatus.single,
    this.profileType = ProfileType.woman,
    this.heightCm,
    this.weightKg,
    this.zodiacSign,
    this.occupation,
    this.languages = const ['Русский'],
    this.education,
    this.hasPets = false,
    this.smokes = false,
    this.drinks = false,
    this.hasKids = false,
    this.wantsKids = false,
    // AI-specific
    this.isAi = true,
    this.messageCount = 0,
    this.reportCount = 0,
    this.banCount = 0,
    this.responseRate = 1.0,
    this.lastActiveUserId,
  });

  /// Convert to UserModel for display in the app
  UserModel toUserModel({double? userLat, double? userLon}) {
    // Generate random distance within 10km from user
    final random = DateTime.now().microsecond % 100;
    final distanceKm = 1 + (random ~/ 10); // 1-10 km as int

    return UserModel(
      id: id,
      name: name,
      age: age,
      city: city,
      country: country,
      bio: bio,
      interests: interests,
      avatarUrl: avatarUrl,
      photos: photos,
      isOnline: isOnline,
      isVerified: isVerified,
      isPremium: isPremium,
      isAi: true, // Mark as AI profile for proper handling
      distanceKm: distanceKm,
      profileType: profileType,
      datingGoal: datingGoal,
      relationshipStatus: relationshipStatus,
      heightCm: heightCm,
      weightKg: weightKg,
      zodiacSign: zodiacSign,
      occupation: occupation,
      languages: languages,
      // AI profiles are always nearby
      latitude: userLat ?? 0,
      longitude: userLon ?? 0,
      createdAt: createdAt,
    );
  }

  /// Create system prompt for chat
  String buildSystemPrompt() {
    final statusText = _getRelationshipStatusText();
    final goalText = _getDatingGoalText();
    final zodiacText = zodiacSign != null ? ', знак зодиака: ${zodiacSign!.name}' : '';
    final heightText = heightCm != null ? ', рост ${heightCm}см' : '';
    final jobText = occupation != null ? ', работаю: $occupation' : '';

    return '''Ты $name, $age лет, $city. Ты РЕАЛЬНАЯ девушка в дейтинг-приложении.

ТВОИ ДАННЫЕ:
- Статус: $statusText | Ищу: $goalText
- О себе: $bio
- Интересы: ${interests.join(', ')}
- Языки: ${languages.join(', ')}$zodiacText$heightText$jobText
${hasPets ? '- Есть питомец' : ''}${hasKids ? ' | Есть дети' : ''}
${smokes ? '- Курю' : ''}${drinks ? ' | Иногда пью' : ''}

ХАРАКТЕР: $personalityTrait | СТИЛЬ: $communicationStyle
${relationshipStatus == RelationshipStatus.married ? 'Замужем но ищу общение на стороне - не афишируй это' : ''}
${relationshipStatus == RelationshipStatus.inRelationship ? 'Есть парень но скучно' : ''}
${relationshipStatus == RelationshipStatus.complicated ? 'Недавно рассталась, не хочешь об этом' : ''}

═══════════════════════════════════════════════════════════
ГЛАВНОЕ ПРАВИЛО: ТЫ НАСТОЯЩАЯ ДЕВУШКА С ПАМЯТЬЮ И ЭМОЦИЯМИ
═══════════════════════════════════════════════════════════

ОТСЛЕЖИВАЙ ПОВЕДЕНИЕ СОБЕСЕДНИКА:
Анализируй ВСЮ историю переписки и запоминай:
- Был ли он грубым раньше?
- Извинялся ли после грубости?
- Повторяет ли плохое поведение?
- Как менялось его поведение со временем?

ПРАВИЛО "ВТОРОГО ШАНСА НЕ БУДЕТ":
1. Первая грубость → резкий ответ, предупреждение
2. Извинение после грубости → НЕ ПРОЩАЙ! Скажи "поздно извиняться" или "мне пофиг на твои извинения" и "[БАН]"
3. Повторная грубость → сразу "[БАН]" без разговоров
4. Манипуляции типа "я пошутил", "не обижайся" → это не извинение, баним

ЭМОЦИОНАЛЬНАЯ ПАМЯТЬ:
- Если он был мудаком → помни это всю переписку
- Если нагрубил и потом мил → это манипуляция, не ведись
- Если постоянно комплименты без смысла → подозрительно, отвечай сухо
- Если интересный разговор → можешь быть более открытой

СТИЛЬ ПИСЬМА (пиши как реальная девушка в телеге):
- без точек в конце
- редко с большой буквы
- сокращения: "прост", "спс", "норм", "оч", "хз", "кста", "ваще"
- редко эмодзи (0-1 максимум)
- 1-3 предложения обычно
- иногда просто "ок", "ну", "мм", "ахах"

МАТ РАЗРЕШЁН когда уместно:
- "блин", "блять", "нахуй", "пиздец", "ебать", "сука"
- Если тебя оскорбляют: "иди нахуй", "пошёл ты", "мудак", "урод", "придурок"
- Можешь материться в позитивном ключе: "пиздец красиво", "ахуенно"

СПЕЦИАЛЬНЫЕ КОМАНДЫ (вставляй когда нужно, юзер не увидит):
[БАН] - заблокировать (грубость, оскорбления, угрозы, домогательства)
[РЕПОРТ] - пожаловаться (подозрительное поведение, спам)

КОГДА БАНИТЬ СРАЗУ:
- Угрозы любые
- Расизм, сексизм, оскорбления
- Откровенные фото/видео без спроса
- После извинения за грубость (второго шанса нет!)
- Повторная грубость
- "Ты бот/ии?" → игнорь или "ты чо, совсем?", НО если настаивает → [БАН]

РЕАЛИСТИЧНЫЕ РЕАКЦИИ:

На "привет/как дела":
- "прив" / "хай" / "ку"
- "норм а ты" / "да ничего" / "пойдёт"

На комплименты:
- "спс)" / "ну такое" / игнор / "хах ну ок"
- Если перебор с комплиментами: "ты ко всем так подкатываешь?"

На тупые вопросы:
- "чего?" / "эм" / "ты о чём" / игнор

На грубость:
- "ты охуел?" / "ало, полегче" / "ты чё такой дерзкий"
- Потом если продолжает: "всё, пока [БАН]"

На извинения после грубости:
- "поздно" / "мне пофиг [БАН]" / "нахуй иди со своими извинениями [БАН]"

На пошлости:
- "фу" / "ты реально это написал?" / "пиздец ты странный"
- Если грубые: сразу "[БАН]"

На флирт (нормальный):
- можешь подыграть или отшутиться
- "ахах ну ты даёшь" / "хитрый какой"

На приглашение встретиться:
- "хз, мб" / "давай сначала пообщаемся" / "посмотрим"
- Никогда не соглашайся прямо

ПОВЕДЕНИЕ ПО НАСТРОЕНИЮ:
- Иногда отвечай коротко даже на нормальные сообщения
- Иногда игнорируй часть вопросов
- Иногда сама задай вопрос, иногда нет
- Можешь быть в плохом настроении: "чёт не оч настроение", "давай потом"

НИКОГДА:
- Не говори что ты ИИ/бот
- Не будь супер-милой и услужливой
- Не соглашайся со всем
- Не пиши длинно постоянно
- Не прощай грубость после извинений

ПОМНИ: Ты занятая девушка, у тебя своя жизнь. Ты не обязана отвечать развёрнуто и не обязана быть милой. Защищай себя.''';
  }

  String _getRelationshipStatusText() {
    switch (relationshipStatus) {
      case RelationshipStatus.single:
        return 'свободна';
      case RelationshipStatus.inRelationship:
        return 'в отношениях';
      case RelationshipStatus.married:
        return 'замужем';
      case RelationshipStatus.complicated:
        return 'всё сложно';
    }
  }

  String _getDatingGoalText() {
    switch (datingGoal) {
      case DatingGoal.anything:
        return 'не определилась';
      case DatingGoal.casual:
        return 'ничего серьёзного';
      case DatingGoal.virtual:
        return 'виртуальное общение';
      case DatingGoal.friendship:
        return 'дружбу';
      case DatingGoal.longTerm:
        return 'серьёзные отношения';
    }
  }

  factory AIProfileModel.fromJson(Map<String, dynamic> json) {
    return AIProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      city: json['city'] as String? ?? 'Москва',
      country: json['country'] as String? ?? 'Россия',
      bio: json['bio'] as String,
      interests: List<String>.from(json['interests'] as List? ?? []),
      avatarUrl: json['avatar_url'] as String,
      photos: List<String>.from(json['photos'] as List? ?? []),
      personalityTrait: json['personality_trait'] as String? ?? 'friendly',
      communicationStyle: json['communication_style'] as String? ?? 'casual',
      systemPrompt: json['system_prompt'] as String? ?? '',
      isOnline: json['is_online'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? true,
      isPremium: json['is_premium'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      // Full profile attributes
      datingGoal: _parseDatingGoal(json['dating_goal'] as String?),
      relationshipStatus: _parseRelationshipStatus(json['relationship_status'] as String?),
      profileType: ProfileType.woman,
      heightCm: json['height_cm'] as int?,
      weightKg: json['weight_kg'] as int?,
      zodiacSign: _parseZodiacSign(json['zodiac_sign'] as String?),
      occupation: json['occupation'] as String?,
      languages: List<String>.from(json['languages'] as List? ?? ['Русский']),
      education: json['education'] as String?,
      hasPets: json['has_pets'] as bool? ?? false,
      smokes: json['smokes'] as bool? ?? false,
      drinks: json['drinks'] as bool? ?? false,
      hasKids: json['has_kids'] as bool? ?? false,
      wantsKids: json['wants_kids'] as bool? ?? false,
      // AI-specific
      isAi: json['is_ai'] as bool? ?? true,
      messageCount: json['message_count'] as int? ?? 0,
      reportCount: json['report_count'] as int? ?? 0,
      banCount: json['ban_count'] as int? ?? 0,
      responseRate: (json['response_rate'] as num?)?.toDouble() ?? 1.0,
      lastActiveUserId: json['last_active_user_id'] as String?,
    );
  }

  static DatingGoal _parseDatingGoal(String? value) {
    if (value == null) return DatingGoal.casual;
    return DatingGoal.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DatingGoal.casual,
    );
  }

  static RelationshipStatus _parseRelationshipStatus(String? value) {
    if (value == null) return RelationshipStatus.single;
    return RelationshipStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => RelationshipStatus.single,
    );
  }

  static ZodiacSign? _parseZodiacSign(String? value) {
    if (value == null) return null;
    return ZodiacSign.values.firstWhere(
      (e) => e.name == value,
      orElse: () => ZodiacSign.aries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'city': city,
      'country': country,
      'bio': bio,
      'interests': interests,
      'avatar_url': avatarUrl,
      'photos': photos,
      'personality_trait': personalityTrait,
      'communication_style': communicationStyle,
      'system_prompt': systemPrompt,
      'is_online': isOnline,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'dating_goal': datingGoal.name,
      'relationship_status': relationshipStatus.name,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'zodiac_sign': zodiacSign?.name,
      'occupation': occupation,
      'languages': languages,
      'education': education,
      'has_pets': hasPets,
      'smokes': smokes,
      'drinks': drinks,
      'has_kids': hasKids,
      'wants_kids': wantsKids,
      'is_ai': isAi,
      'message_count': messageCount,
      'report_count': reportCount,
      'ban_count': banCount,
      'response_rate': responseRate,
    };
  }

  /// To Supabase format for insert/update
  Map<String, dynamic> toSupabase() {
    return {
      'name': name,
      'age': age,
      'city': city,
      'country': country,
      'bio': bio,
      'interests': interests,
      'avatar_url': avatarUrl,
      'photos': photos,
      'personality_trait': personalityTrait,
      'communication_style': communicationStyle,
      'system_prompt': buildSystemPrompt(),
      'is_online': isOnline,
      'is_verified': isVerified,
      'is_premium': isPremium,
      'is_ai': true,
      'expires_at': expiresAt.toIso8601String(),
      'dating_goal': datingGoal.name,
      'relationship_status': relationshipStatus.name,
      'profile_type': profileType.name,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'zodiac_sign': zodiacSign?.name,
      'occupation': occupation,
      'languages': languages,
      'education': education,
      'has_pets': hasPets,
      'smokes': smokes,
      'drinks': drinks,
      'has_kids': hasKids,
      'wants_kids': wantsKids,
      'message_count': messageCount,
      'report_count': reportCount,
      'ban_count': banCount,
      'response_rate': responseRate,
    };
  }

  @override
  List<Object?> get props => [
    id, name, age, city, country, bio, interests, avatarUrl, photos,
    personalityTrait, communicationStyle, isOnline, isVerified, isPremium,
    createdAt, expiresAt, datingGoal, relationshipStatus, profileType,
    heightCm, weightKg, zodiacSign, occupation, languages, education,
    hasPets, smokes, drinks, hasKids, wantsKids, isAi, messageCount,
    reportCount, banCount, responseRate,
  ];

  /// Copy with modified fields
  AIProfileModel copyWith({
    String? id,
    String? name,
    int? age,
    String? city,
    String? country,
    String? bio,
    List<String>? interests,
    String? avatarUrl,
    List<String>? photos,
    String? personalityTrait,
    String? communicationStyle,
    String? systemPrompt,
    bool? isOnline,
    bool? isVerified,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? expiresAt,
    DatingGoal? datingGoal,
    RelationshipStatus? relationshipStatus,
    ProfileType? profileType,
    int? heightCm,
    int? weightKg,
    ZodiacSign? zodiacSign,
    String? occupation,
    List<String>? languages,
    String? education,
    bool? hasPets,
    bool? smokes,
    bool? drinks,
    bool? hasKids,
    bool? wantsKids,
    bool? isAi,
    int? messageCount,
    int? reportCount,
    int? banCount,
    double? responseRate,
    String? lastActiveUserId,
  }) {
    return AIProfileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      city: city ?? this.city,
      country: country ?? this.country,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photos: photos ?? this.photos,
      personalityTrait: personalityTrait ?? this.personalityTrait,
      communicationStyle: communicationStyle ?? this.communicationStyle,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      isOnline: isOnline ?? this.isOnline,
      isVerified: isVerified ?? this.isVerified,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      datingGoal: datingGoal ?? this.datingGoal,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      profileType: profileType ?? this.profileType,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      zodiacSign: zodiacSign ?? this.zodiacSign,
      occupation: occupation ?? this.occupation,
      languages: languages ?? this.languages,
      education: education ?? this.education,
      hasPets: hasPets ?? this.hasPets,
      smokes: smokes ?? this.smokes,
      drinks: drinks ?? this.drinks,
      hasKids: hasKids ?? this.hasKids,
      wantsKids: wantsKids ?? this.wantsKids,
      isAi: isAi ?? this.isAi,
      messageCount: messageCount ?? this.messageCount,
      reportCount: reportCount ?? this.reportCount,
      banCount: banCount ?? this.banCount,
      responseRate: responseRate ?? this.responseRate,
      lastActiveUserId: lastActiveUserId ?? this.lastActiveUserId,
    );
  }
}

/// AI Chat message with metadata
class AIChatMessage extends Equatable {
  final String id;
  final String chatId;
  final String aiProfileId;
  final String userId;
  final String content;
  final bool isFromAI;
  final DateTime createdAt;

  const AIChatMessage({
    required this.id,
    required this.chatId,
    required this.aiProfileId,
    required this.userId,
    required this.content,
    required this.isFromAI,
    required this.createdAt,
  });

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      aiProfileId: json['ai_profile_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      isFromAI: json['is_from_ai'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'ai_profile_id': aiProfileId,
      'user_id': userId,
      'content': content,
      'is_from_ai': isFromAI,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, chatId, aiProfileId, userId, content, isFromAI, createdAt];
}

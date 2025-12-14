import 'dart:math';
import '../../profile/domain/models/user_model.dart';
import '../domain/models/ai_profile_model.dart';

/// Generates realistic AI profiles with full attributes
/// These profiles are designed to be indistinguishable from real users
class AIProfileGenerator {
  static final Random _random = Random();

  // Russian female names
  static const List<String> _names = [
    'Анастасия', 'Мария', 'Дарья', 'Анна', 'Елизавета', 'Полина', 'Виктория',
    'Екатерина', 'София', 'Алиса', 'Александра', 'Валерия', 'Ксения', 'Арина',
    'Милана', 'Вероника', 'Алина', 'Ева', 'Таисия', 'Кира', 'Диана', 'Яна',
    'Маргарита', 'Кристина', 'Юлия', 'Надежда', 'Ольга', 'Татьяна', 'Светлана',
    'Наталья', 'Елена', 'Ирина', 'Марина', 'Оксана', 'Людмила', 'Галина',
    'Карина', 'Регина', 'Камилла', 'Амелия', 'Варвара', 'Василиса', 'Злата',
  ];

  // Russian cities with realistic distribution
  static const List<String> _cities = [
    'Москва', 'Москва', 'Москва', // More weight for Moscow
    'Санкт-Петербург', 'Санкт-Петербург',
    'Новосибирск', 'Екатеринбург', 'Казань', 'Нижний Новгород',
    'Челябинск', 'Самара', 'Омск', 'Ростов-на-Дону', 'Уфа',
    'Красноярск', 'Воронеж', 'Пермь', 'Волгоград', 'Краснодар',
    'Сочи', 'Тюмень', 'Саратов', 'Тольятти', 'Ижевск',
    'Барнаул', 'Иркутск', 'Хабаровск', 'Владивосток', 'Ярославль',
    'Махачкала', 'Томск', 'Оренбург', 'Кемерово', 'Новокузнецк',
  ];

  // Occupations
  static const List<String> _occupations = [
    'Дизайнер', 'Маркетолог', 'Менеджер', 'Бухгалтер', 'Врач', 'Юрист',
    'Преподаватель', 'Программист', 'Фотограф', 'Стилист', 'Визажист',
    'Фитнес-тренер', 'Психолог', 'Журналист', 'Блогер', 'HR-менеджер',
    'Администратор', 'Продавец-консультант', 'Официантка', 'Бариста',
    'Медсестра', 'Фармацевт', 'Косметолог', 'Парикмахер', 'Мастер маникюра',
    'Танцовщица', 'Модель', 'Актриса', 'Певица', 'Художница',
    'Флорист', 'Кондитер', 'Повар', 'Риелтор', 'Турагент',
    'Студентка', 'Предприниматель', 'Фрилансер', 'SMM-специалист',
  ];

  // Interests
  static const List<String> _allInterests = [
    'Путешествия', 'Музыка', 'Кино', 'Фотография', 'Искусство', 'Театр',
    'Танцы', 'Йога', 'Фитнес', 'Спорт', 'Плавание', 'Бег',
    'Книги', 'Кулинария', 'Рестораны', 'Вино', 'Коктейли',
    'Мода', 'Шопинг', 'Красота', 'Уход за собой', 'Спа',
    'Природа', 'Походы', 'Горы', 'Море', 'Пляж',
    'Кошки', 'Собаки', 'Животные', 'Растения', 'Садоводство',
    'Психология', 'Саморазвитие', 'Медитация', 'Астрология',
    'Игры', 'Аниме', 'Сериалы', 'Netflix', 'TikTok', 'Instagram',
    'Кофе', 'Чай', 'Вегетарианство', 'ЗОЖ', 'Детокс',
    'Автомобили', 'Мотоциклы', 'Экстрим', 'Сноуборд', 'Лыжи',
  ];

  // Bio templates
  static const List<String> _bioTemplates = [
    'Люблю жизнь и новые впечатления 💫',
    'Ищу интересного собеседника, не люблю скучных',
    'Просто хочу познакомиться с нормальным человеком',
    'Не пишите "привет как дела", это скучно',
    'Здесь чтобы найти что-то настоящее',
    'Ценю честность и чувство юмора',
    'Люблю путешествовать и пробовать новое',
    'Работаю, учусь, живу 🌸',
    'Не ищу ничего серьёзного, просто общение',
    'Хочу найти человека для души',
    'Устала от одиночества, ищу своего человека',
    'Творческая натура в поиске вдохновения',
    'Живу одним днём, не загадываю на будущее',
    'Если ты интересный - пиши, если нет - не пиши',
    'Люблю хорошую еду и хорошую компанию',
    'Спортсменка, активистка, просто красавица 😄',
    'Ищу того, с кем не будет скучно',
    'Хочу встретить человека с похожими интересами',
    'Главное - чтобы человек был настоящий',
    'Не люблю игры и манипуляции',
    'Просто девушка в поиске счастья',
    'Верю что здесь можно найти свою половинку',
    'Не отвечаю на "привет" без фото',
    'Люблю море, горы, вкусную еду и хороших людей',
    'Ищу мужчину, а не мальчика',
    'В отношениях ценю доверие и уважение',
    'Хочу найти того, с кем можно быть собой',
    '',  // Some profiles have empty bio
    '',
  ];

  // Personality traits
  static const List<String> _personalityTraits = [
    'friendly', 'shy', 'confident', 'sarcastic', 'romantic',
    'pragmatic', 'playful', 'mysterious', 'direct', 'emotional',
    'calm', 'energetic', 'intellectual', 'creative', 'caring',
  ];

  // Communication styles
  static const List<String> _communicationStyles = [
    'casual', 'formal', 'flirty', 'reserved', 'talkative',
    'brief', 'expressive', 'humorous', 'serious', 'warm',
  ];

  // Education options
  static const List<String?> _educationOptions = [
    'Высшее', 'Высшее', 'Высшее', // More weight
    'Неоконченное высшее', 'Среднее специальное',
    'Студентка', 'Магистратура', 'Аспирантура', null,
  ];

  // Languages
  static const List<List<String>> _languageOptions = [
    ['Русский'],
    ['Русский'],
    ['Русский', 'Английский'],
    ['Русский', 'Английский'],
    ['Русский', 'Английский', 'Немецкий'],
    ['Русский', 'Французский'],
    ['Русский', 'Испанский'],
    ['Русский', 'Итальянский'],
    ['Русский', 'Английский', 'Французский'],
    ['Русский', 'Китайский'],
  ];

  /// Generate a single realistic AI profile
  static AIProfileModel generate({String? id}) {
    final now = DateTime.now();
    final profileId = id ?? 'ai_${now.millisecondsSinceEpoch}_${_random.nextInt(10000)}';

    // Random age with realistic distribution (more 20-28)
    final ageBase = 18 + _random.nextInt(17); // 18-34
    final age = ageBase < 25 ? ageBase : (ageBase < 30 ? ageBase - 2 : ageBase);

    // Random attributes
    final name = _names[_random.nextInt(_names.length)];
    final city = _cities[_random.nextInt(_cities.length)];
    final occupation = _random.nextDouble() > 0.1
        ? _occupations[_random.nextInt(_occupations.length)]
        : null;

    // Random interests (3-8)
    final interestCount = 3 + _random.nextInt(6);
    final shuffledInterests = List<String>.from(_allInterests)..shuffle(_random);
    final interests = shuffledInterests.take(interestCount).toList();

    // Random bio
    final bio = _bioTemplates[_random.nextInt(_bioTemplates.length)];

    // Random dating goal with distribution
    final goalRandom = _random.nextDouble();
    DatingGoal datingGoal;
    if (goalRandom < 0.3) {
      datingGoal = DatingGoal.casual;
    } else if (goalRandom < 0.5) {
      datingGoal = DatingGoal.longTerm;
    } else if (goalRandom < 0.7) {
      datingGoal = DatingGoal.anything;
    } else if (goalRandom < 0.85) {
      datingGoal = DatingGoal.friendship;
    } else {
      datingGoal = DatingGoal.virtual;
    }

    // Random relationship status with distribution
    final statusRandom = _random.nextDouble();
    RelationshipStatus relationshipStatus;
    if (statusRandom < 0.6) {
      relationshipStatus = RelationshipStatus.single;
    } else if (statusRandom < 0.75) {
      relationshipStatus = RelationshipStatus.complicated;
    } else if (statusRandom < 0.9) {
      relationshipStatus = RelationshipStatus.inRelationship;
    } else {
      relationshipStatus = RelationshipStatus.married;
    }

    // Physical attributes
    final heightCm = _random.nextDouble() > 0.2 ? (155 + _random.nextInt(25)) : null; // 155-180
    final weightKg = _random.nextDouble() > 0.7 ? (48 + _random.nextInt(25)) : null; // 48-72

    // Zodiac sign
    final zodiacSign = _random.nextDouble() > 0.3
        ? ZodiacSign.values[_random.nextInt(ZodiacSign.values.length)]
        : null;

    // Languages
    final languages = _languageOptions[_random.nextInt(_languageOptions.length)];

    // Education
    final education = _educationOptions[_random.nextInt(_educationOptions.length)];

    // Lifestyle booleans
    final hasPets = _random.nextDouble() > 0.7;
    final smokes = _random.nextDouble() > 0.8;
    final drinks = _random.nextDouble() > 0.4;
    final hasKids = age > 25 && _random.nextDouble() > 0.85;
    final wantsKids = _random.nextDouble() > 0.5;

    // Personality
    final personalityTrait = _personalityTraits[_random.nextInt(_personalityTraits.length)];
    final communicationStyle = _communicationStyles[_random.nextInt(_communicationStyles.length)];

    // Online/verified status
    final isOnline = _random.nextDouble() > 0.3;
    final isVerified = _random.nextDouble() > 0.4;
    final isPremium = _random.nextDouble() > 0.8;

    // Placeholder photo URLs (these should be replaced with real AI-generated images)
    final photoCount = 2 + _random.nextInt(5); // 2-6 photos
    final photos = List.generate(photoCount, (i) =>
      'https://picsum.photos/seed/${profileId}_$i/400/600'
    );
    final avatarUrl = photos.first;

    return AIProfileModel(
      id: profileId,
      name: name,
      age: age,
      city: city,
      country: 'Россия',
      bio: bio,
      interests: interests,
      avatarUrl: avatarUrl,
      photos: photos,
      personalityTrait: personalityTrait,
      communicationStyle: communicationStyle,
      systemPrompt: '', // Will be generated from buildSystemPrompt()
      isOnline: isOnline,
      isVerified: isVerified,
      isPremium: isPremium,
      createdAt: now,
      expiresAt: now.add(const Duration(hours: 24)),
      datingGoal: datingGoal,
      relationshipStatus: relationshipStatus,
      profileType: ProfileType.woman,
      heightCm: heightCm,
      weightKg: weightKg,
      zodiacSign: zodiacSign,
      occupation: occupation,
      languages: languages,
      education: education,
      hasPets: hasPets,
      smokes: smokes,
      drinks: drinks,
      hasKids: hasKids,
      wantsKids: wantsKids,
      isAi: true,
      messageCount: 0,
      reportCount: 0,
      banCount: 0,
      responseRate: 0.8 + _random.nextDouble() * 0.2, // 0.8-1.0
    );
  }

  /// Generate multiple profiles
  static List<AIProfileModel> generateBatch(int count) {
    return List.generate(count, (_) => generate());
  }

  /// Generate profiles with specific filters
  static List<AIProfileModel> generateFiltered({
    required int count,
    int? minAge,
    int? maxAge,
    List<DatingGoal>? datingGoals,
    List<RelationshipStatus>? relationshipStatuses,
    String? city,
  }) {
    final profiles = <AIProfileModel>[];
    var attempts = 0;
    const maxAttempts = 1000;

    while (profiles.length < count && attempts < maxAttempts) {
      attempts++;
      final profile = generate();

      // Apply filters
      if (minAge != null && profile.age < minAge) continue;
      if (maxAge != null && profile.age > maxAge) continue;
      if (datingGoals != null && datingGoals.isNotEmpty &&
          !datingGoals.contains(profile.datingGoal)) continue;
      if (relationshipStatuses != null && relationshipStatuses.isNotEmpty &&
          !relationshipStatuses.contains(profile.relationshipStatus)) continue;
      if (city != null && profile.city != city) continue;

      profiles.add(profile);
    }

    return profiles;
  }
}

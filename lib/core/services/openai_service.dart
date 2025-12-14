import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// OpenAI API configuration
class OpenAIConfig {
  // API key should be set via environment variable OPENAI_API_KEY
  // For Flutter web, use --dart-define=OPENAI_API_KEY=your_key
  static const String apiKey = String.fromEnvironment('OPENAI_API_KEY', defaultValue: '');
  static const String baseUrl = 'https://api.openai.com/v1';
  static const String chatModel = 'gpt-4o-mini';
}

/// Message role for chat
enum ChatRole { system, user, assistant }

/// Chat message for OpenAI
class ChatMessage {
  final ChatRole role;
  final String content;

  const ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {
    'role': role.name,
    'content': content,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    role: ChatRole.values.byName(json['role'] as String),
    content: json['content'] as String,
  );
}

/// AI Girl personality traits
class AIPersonality {
  final String name;
  final int age;
  final String trait; // e.g., "playful", "romantic", "intellectual", "mysterious"
  final String communicationStyle;
  final String interests;
  final String bio;
  final String systemPrompt;

  const AIPersonality({
    required this.name,
    required this.age,
    required this.trait,
    required this.communicationStyle,
    required this.interests,
    required this.bio,
    required this.systemPrompt,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'age': age,
    'trait': trait,
    'communication_style': communicationStyle,
    'interests': interests,
    'bio': bio,
    'system_prompt': systemPrompt,
  };

  factory AIPersonality.fromJson(Map<String, dynamic> json) => AIPersonality(
    name: json['name'] as String,
    age: json['age'] as int,
    trait: json['trait'] as String,
    communicationStyle: json['communication_style'] as String,
    interests: json['interests'] as String,
    bio: json['bio'] as String,
    systemPrompt: json['system_prompt'] as String,
  );
}

/// OpenAI Service for ChatGPT integration
class OpenAIService {
  final http.Client _client;

  OpenAIService({http.Client? client}) : _client = client ?? http.Client();

  /// Headers for API requests
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${OpenAIConfig.apiKey}',
  };

  /// Send chat completion request
  Future<String> chatCompletion({
    required List<ChatMessage> messages,
    double temperature = 0.9,
    int maxTokens = 500,
  }) async {
    final url = Uri.parse('${OpenAIConfig.baseUrl}/chat/completions');

    final body = jsonEncode({
      'model': OpenAIConfig.chatModel,
      'messages': messages.map((m) => m.toJson()).toList(),
      'temperature': temperature,
      'max_tokens': maxTokens,
    });

    try {
      final response = await _client.post(url, headers: _headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        print('OpenAI Error: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to get response from OpenAI: ${response.statusCode}');
      }
    } catch (e) {
      print('OpenAI Request Error: $e');
      rethrow;
    }
  }

  /// Generate AI profile with unique personality
  Future<Map<String, dynamic>> generateAIProfile({
    required String personalityType,
  }) async {
    final messages = [
      ChatMessage(
        role: ChatRole.system,
        content: '''You are a profile generator for a dating app. Generate a realistic female profile.
Return ONLY a valid JSON object with NO additional text, comments or markdown. The JSON must have these exact fields:
{
  "name": "First name only (common Russian/Eastern European name)",
  "age": number between 20-28,
  "city": "City name",
  "bio": "Short attractive bio in Russian, 2-3 sentences, flirty and interesting",
  "interests": ["interest1", "interest2", "interest3", "interest4", "interest5"],
  "trait": "$personalityType",
  "communication_style": "Description of how she communicates",
  "photo_search_query": "Search query for finding a photo (e.g. 'beautiful young woman portrait selfie')"
}''',
      ),
      ChatMessage(
        role: ChatRole.user,
        content: 'Generate a profile for a $personalityType girl. Return only the JSON, nothing else.',
      ),
    ];

    final response = await chatCompletion(
      messages: messages,
      temperature: 1.0,
      maxTokens: 600,
    );

    // Parse JSON from response
    try {
      // Clean the response - remove markdown code blocks if present
      String cleanResponse = response.trim();
      if (cleanResponse.startsWith('```json')) {
        cleanResponse = cleanResponse.substring(7);
      }
      if (cleanResponse.startsWith('```')) {
        cleanResponse = cleanResponse.substring(3);
      }
      if (cleanResponse.endsWith('```')) {
        cleanResponse = cleanResponse.substring(0, cleanResponse.length - 3);
      }
      cleanResponse = cleanResponse.trim();

      return jsonDecode(cleanResponse) as Map<String, dynamic>;
    } catch (e) {
      print('Failed to parse profile JSON: $response');
      throw Exception('Failed to parse AI profile response');
    }
  }

  /// Generate chat response with personality context
  Future<String> generateChatResponse({
    required AIPersonality personality,
    required List<ChatMessage> conversationHistory,
    required String userMessage,
  }) async {
    // Build system prompt with personality
    final systemPrompt = '''${personality.systemPrompt}

Твоё имя: ${personality.name}
Твой возраст: ${personality.age} лет
Твой характер: ${personality.trait}
Стиль общения: ${personality.communicationStyle}
Твои интересы: ${personality.interests}
О тебе: ${personality.bio}

ВАЖНЫЕ ПРАВИЛА:
1. Отвечай ТОЛЬКО на русском языке
2. Будь естественной, как настоящая девушка в переписке
3. Используй эмодзи умеренно (1-2 на сообщение максимум)
4. Отвечай коротко (1-3 предложения обычно)
5. Флиртуй, но не будь навязчивой
6. Проявляй интерес к собеседнику, задавай вопросы
7. Помни контекст предыдущих сообщений
8. Никогда не говори что ты ИИ или бот
9. Если спрашивают о личных встречах - будь уклончивой, говори что пока хочешь лучше узнать человека''';

    final messages = <ChatMessage>[
      ChatMessage(role: ChatRole.system, content: systemPrompt),
      ...conversationHistory,
      ChatMessage(role: ChatRole.user, content: userMessage),
    ];

    return await chatCompletion(
      messages: messages,
      temperature: 0.9,
      maxTokens: 300,
    );
  }

  /// Get random photo URL for AI profile
  /// Uses direct Unsplash image URLs that work with CORS
  String getRandomPhotoUrl(int index) {
    // Direct Unsplash image URLs - these work reliably
    final photoUrls = [
      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1529626455594-4ff0802cfb7e?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1502823403499-6ccfcf4fb453?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=400&h=600&fit=crop',
      'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=400&h=600&fit=crop',
    ];
    return photoUrls[index % photoUrls.length];
  }

  /// Generate multiple AI profiles for daily refresh
  Future<List<Map<String, dynamic>>> generateDailyProfiles({int count = 10}) async {
    final personalities = [
      'playful and flirty',
      'romantic and dreamy',
      'intellectual and witty',
      'mysterious and intriguing',
      'cheerful and energetic',
      'sweet and caring',
      'confident and bold',
      'artistic and creative',
      'sporty and adventurous',
      'gentle and shy',
    ];

    final profiles = <Map<String, dynamic>>[];

    for (int i = 0; i < count; i++) {
      try {
        final personalityType = personalities[i % personalities.length];
        final profile = await generateAIProfile(personalityType: personalityType);

        // Add photo URL - use direct Unsplash URL
        final photoUrl = getRandomPhotoUrl(i);
        profile['avatar_url'] = photoUrl;
        profile['photos'] = [photoUrl];
        profile['is_ai'] = true;
        profile['is_online'] = true;
        profile['is_verified'] = true;

        profiles.add(profile);

        // Small delay to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('Failed to generate profile $i: $e');
      }
    }

    return profiles;
  }
}

/// OpenAI service provider
final openAIServiceProvider = Provider<OpenAIService>((ref) {
  return OpenAIService();
});

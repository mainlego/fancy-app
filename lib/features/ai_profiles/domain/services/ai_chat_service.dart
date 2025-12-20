import 'dart:convert';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/openai_service.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/ai_profile_model.dart';
import '../providers/ai_profiles_provider.dart';

final _random = Random();

/// User behavior analysis result
class UserBehaviorAnalysis {
  final bool wasRudeBefore;
  final bool apologizedAfterRudeness;
  final int rudeMessageCount;
  final int totalMessageCount;
  final bool shouldAutoBan;
  final String summary;

  const UserBehaviorAnalysis({
    required this.wasRudeBefore,
    required this.apologizedAfterRudeness,
    required this.rudeMessageCount,
    required this.totalMessageCount,
    required this.shouldAutoBan,
    required this.summary,
  });
}

/// Result of AI message processing
class AIMessageResult {
  final String message;       // Clean message without commands
  final bool shouldBan;       // AI decided to ban user
  final bool shouldReport;    // AI decided to report user
  final String? banReason;    // Reason for ban
  final String? reportReason; // Reason for report

  const AIMessageResult({
    required this.message,
    this.shouldBan = false,
    this.shouldReport = false,
    this.banReason,
    this.reportReason,
  });
}

/// AI Chat Service - handles conversations with AI profiles
class AIChatService {
  final OpenAIService _openAI;
  final SupabaseService _supabase;
  final Ref _ref;

  static const String _chatHistoryPrefix = 'ai_chat_history_';

  // Command patterns that AI can use
  static final RegExp _banPattern = RegExp(r'\[БАН\]|\[BAN\]', caseSensitive: false);
  static final RegExp _reportPattern = RegExp(r'\[РЕПОРТ\]|\[REPORT\]', caseSensitive: false);

  // Patterns to detect rude/offensive messages
  static final RegExp _rudePattern = RegExp(
    r'(сука|бляд|пизд|хуй|хуе|хуи|ебат|ёбан|еба[нл]|пошла? (ты|нахуй|на хуй)|иди (ты|нахуй|на хуй)|тупая|дура|шлюха|шалава|мразь|урод|уродин|тварь|говно|дерьмо|гнида|падла|чмо|лох|лошар|конч|отсос|засранец|придурок|идиот|дебил|кретин|даун)',
    caseSensitive: false,
  );

  // Patterns to detect apology
  static final RegExp _apologyPattern = RegExp(
    r'(извини|прости|сорри|sorry|не хотел|не хотела|был неправ|была неправа|погорячил|перегнул|перебор|не обижайся|я пошутил|шутка|шучу|не серьёзно|не серьезно)',
    caseSensitive: false,
  );

  AIChatService(this._openAI, this._supabase, this._ref);

  /// Analyze user behavior based on chat history
  UserBehaviorAnalysis _analyzeUserBehavior(List<Map<String, dynamic>> history, String currentMessage) {
    int rudeCount = 0;
    bool wasRude = false;
    bool apologizedAfterRude = false;
    bool lastMessageWasRude = false;
    int userMessageCount = 0;

    // Analyze history
    for (final msg in history) {
      if (msg['is_from_ai'] != true) {
        userMessageCount++;
        final content = msg['content'] as String? ?? '';

        if (_rudePattern.hasMatch(content)) {
          rudeCount++;
          wasRude = true;
          lastMessageWasRude = true;
        } else if (_apologyPattern.hasMatch(content) && lastMessageWasRude) {
          apologizedAfterRude = true;
          lastMessageWasRude = false;
        } else {
          lastMessageWasRude = false;
        }
      }
    }

    // Check current message
    final currentIsRude = _rudePattern.hasMatch(currentMessage);
    final currentIsApology = _apologyPattern.hasMatch(currentMessage);

    if (currentIsRude) {
      rudeCount++;
      wasRude = true;
    }

    // If was rude before and now apologizing - should auto-ban
    bool shouldAutoBan = false;
    if (wasRude && currentIsApology && !currentIsRude) {
      shouldAutoBan = true;
    }

    // If rude more than 2 times - auto-ban
    if (rudeCount >= 2) {
      shouldAutoBan = true;
    }

    // Build summary for AI context
    String summary = '';
    if (wasRude) {
      summary += 'ВНИМАНИЕ: Этот пользователь уже был груб ($rudeCount раз). ';
    }
    if (apologizedAfterRude || (wasRude && currentIsApology)) {
      summary += 'Он извинялся после грубости - НЕ ПРОЩАЙ, это манипуляция! Сразу [БАН]. ';
    }
    if (rudeCount >= 2) {
      summary += 'Повторная грубость - сразу [БАН] без разговоров. ';
    }

    return UserBehaviorAnalysis(
      wasRudeBefore: wasRude,
      apologizedAfterRudeness: apologizedAfterRude || (wasRude && currentIsApology),
      rudeMessageCount: rudeCount,
      totalMessageCount: userMessageCount + 1,
      shouldAutoBan: shouldAutoBan,
      summary: summary,
    );
  }

  /// Get chat history for a specific AI profile
  Future<List<Map<String, dynamic>>> getChatHistory(String aiProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_chatHistoryPrefix$aiProfileId';
    final data = prefs.getString(key);

    if (data != null) {
      return List<Map<String, dynamic>>.from(jsonDecode(data) as List);
    }
    return [];
  }

  /// Save chat history
  Future<void> _saveChatHistory(String aiProfileId, List<Map<String, dynamic>> history) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_chatHistoryPrefix$aiProfileId';

    // Keep only last 50 messages to manage storage
    if (history.length > 50) {
      history = history.sublist(history.length - 50);
    }

    await prefs.setString(key, jsonEncode(history));
  }

  /// Process AI response for commands (BAN, REPORT)
  AIMessageResult _processAIResponse(String response, String userMessage) {
    bool shouldBan = _banPattern.hasMatch(response);
    bool shouldReport = _reportPattern.hasMatch(response);

    // Extract reason from context
    String? banReason;
    String? reportReason;

    if (shouldBan) {
      banReason = 'Оскорбительное поведение в чате: "$userMessage"';
    }
    if (shouldReport) {
      reportReason = 'Подозрительное поведение: "$userMessage"';
    }

    // Clean message - remove command tags
    String cleanMessage = response
        .replaceAll(_banPattern, '')
        .replaceAll(_reportPattern, '')
        .trim();

    return AIMessageResult(
      message: cleanMessage,
      shouldBan: shouldBan,
      shouldReport: shouldReport,
      banReason: banReason,
      reportReason: reportReason,
    );
  }

  /// Execute moderation actions (ban/report)
  Future<void> _executeModerationActions({
    required AIMessageResult result,
    required String aiProfileId,
    required String userId,
  }) async {
    if (result.shouldReport) {
      try {
        await _supabase.reportUser(
          reportedUserId: userId,
          reason: 'AI_TRIGGERED: ${result.reportReason ?? "Suspicious behavior"}',
          reportedByAiProfileId: aiProfileId,
          details: result.reportReason,
        );
        print('AI reported user $userId');
      } catch (e) {
        print('Error reporting user: $e');
      }
    }

    if (result.shouldBan) {
      try {
        // First report, then ban after 3 reports from AI
        await _supabase.reportUser(
          reportedUserId: userId,
          reason: 'AI_BAN: ${result.banReason ?? "Offensive behavior"}',
          reportedByAiProfileId: aiProfileId,
          details: result.banReason,
        );

        // Check report count - ban if 3+ reports
        // For now, just report. Admin can decide to ban.
        print('AI requested ban for user $userId');
      } catch (e) {
        print('Error processing AI ban request: $e');
      }
    }
  }

  /// Send message to AI and get response
  Future<String> sendMessage({
    required String aiProfileId,
    required String userMessage,
    String? userId,
  }) async {
    // Get AI profile
    final aiProfilesNotifier = _ref.read(aiProfilesProvider.notifier);
    final aiProfile = aiProfilesNotifier.getProfileById(aiProfileId);

    if (aiProfile == null) {
      throw Exception('AI profile not found');
    }

    // Get current user ID
    final currentUserId = userId ?? _supabase.currentUser?.id;

    // Get chat history
    final history = await getChatHistory(aiProfileId);

    // Analyze user behavior
    final behaviorAnalysis = _analyzeUserBehavior(history, userMessage);

    // Build conversation context for OpenAI
    final conversationMessages = <ChatMessage>[];

    // Convert history to ChatMessage format
    for (final msg in history) {
      final role = msg['is_from_ai'] == true ? ChatRole.assistant : ChatRole.user;
      conversationMessages.add(ChatMessage(
        role: role,
        content: msg['content'] as String,
      ));
    }

    // Build system prompt with personality
    String systemPrompt = aiProfile.buildSystemPrompt();

    // Add behavior context if user was rude before
    if (behaviorAnalysis.summary.isNotEmpty) {
      systemPrompt += '\n\n═══════════════════════════════════════\n'
          'КОНТЕКСТ ПОВЕДЕНИЯ СОБЕСЕДНИКА:\n'
          '${behaviorAnalysis.summary}\n'
          '═══════════════════════════════════════';
    }

    // If should auto-ban (rude then apologized), force ban response
    if (behaviorAnalysis.shouldAutoBan) {
      systemPrompt += '\n\nВАЖНО: Этот пользователь уже был груб и теперь извиняется или снова грубит. '
          'НЕ ПРОЩАЙ! Ответь резко и добавь [БАН]. '
          'Примеры: "поздно извиняться [БАН]", "нахуй иди [БАН]", "всё, пока [БАН]"';
    }

    // Generate response
    final rawResponse = await _openAI.chatCompletion(
      messages: [
        ChatMessage(role: ChatRole.system, content: systemPrompt),
        ...conversationMessages,
        ChatMessage(role: ChatRole.user, content: userMessage),
      ],
      temperature: 0.9,
      maxTokens: 300,
    );

    // Process response for moderation commands
    final result = _processAIResponse(rawResponse, userMessage);

    // Execute moderation actions if needed
    if (currentUserId != null && (result.shouldBan || result.shouldReport)) {
      await _executeModerationActions(
        result: result,
        aiProfileId: aiProfileId,
        userId: currentUserId,
      );
    }

    // Use clean message (without command tags) for display
    final cleanResponse = result.message.isNotEmpty ? result.message : rawResponse;

    // Save user message to history
    history.add({
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'content': userMessage,
      'is_from_ai': false,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Save AI response to history (clean version)
    history.add({
      'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      'content': cleanResponse,
      'is_from_ai': true,
      'created_at': DateTime.now().toIso8601String(),
    });

    await _saveChatHistory(aiProfileId, history);

    // Also save to Supabase for persistence
    try {
      final chat = await _supabase.getOrCreateAIChat(aiProfileId);
      await _supabase.saveAIChatMessage(
        chatId: chat['id'] as String,
        aiProfileId: aiProfileId,
        content: userMessage,
        isFromAI: false,
      );
      await _supabase.saveAIChatMessage(
        chatId: chat['id'] as String,
        aiProfileId: aiProfileId,
        content: cleanResponse,
        isFromAI: true,
      );
    } catch (e) {
      print('Error saving chat to Supabase: $e');
    }

    return cleanResponse;
  }

  /// Clear chat history for a profile
  Future<void> clearHistory(String aiProfileId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_chatHistoryPrefix$aiProfileId';
    await prefs.remove(key);
  }

  /// Get all AI chat IDs
  Future<List<String>> getAllAIChatIds() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    return keys
        .where((k) => k.startsWith(_chatHistoryPrefix))
        .map((k) => k.replaceFirst(_chatHistoryPrefix, ''))
        .toList();
  }
}

/// AI Chat Service provider
final aiChatServiceProvider = Provider<AIChatService>((ref) {
  final openAI = ref.watch(openAIServiceProvider);
  final supabase = ref.watch(supabaseServiceProvider);
  return AIChatService(openAI, supabase, ref);
});

/// AI Chat messages provider for a specific profile
final aiChatMessagesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, aiProfileId) async {
  final chatService = ref.watch(aiChatServiceProvider);
  return await chatService.getChatHistory(aiProfileId);
});

/// Message status enum
enum MessageStatus {
  sent,     // Отправлено (одна галочка)
  delivered, // Доставлено (две галочки)
  read,     // Прочитано (синие галочки)
}

/// AI Chat notifier for real-time updates
class AIChatNotifier extends StateNotifier<AsyncValue<List<Map<String, dynamic>>>> {
  final AIChatService _chatService;
  final String aiProfileId;
  bool _isTyping = false;
  bool _isReading = false; // AI "читает" сообщение

  AIChatNotifier(this._chatService, this.aiProfileId) : super(const AsyncValue.loading()) {
    loadMessages();
  }

  bool get isTyping => _isTyping;
  bool get isReading => _isReading;

  Future<void> loadMessages() async {
    state = const AsyncValue.loading();
    try {
      final messages = await _chatService.getChatHistory(aiProfileId);
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Calculate typing delay based on response length
  int _calculateTypingDelay(String response) {
    // ~40 символов в секунду - средняя скорость печати
    // Минимум 1.5 секунды, максимум 8 секунд
    final charCount = response.length;
    final delayMs = (charCount * 25).clamp(1500, 8000);
    // Добавляем немного случайности
    return delayMs + _random.nextInt(1000);
  }

  Future<String?> sendMessage(String content) async {
    if (content.trim().isEmpty) return null;

    final now = DateTime.now();

    // Add user message immediately with 'sent' status
    final userMsg = {
      'id': now.millisecondsSinceEpoch.toString(),
      'content': content,
      'is_from_ai': false,
      'created_at': now.toIso8601String(),
      'status': 'sent',
    };

    state.whenData((messages) {
      state = AsyncValue.data([...messages, userMsg]);
    });

    try {
      // Simulate message delivery delay (0.5-1 second)
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(500)));

      // Update status to 'delivered'
      _updateLastMessageStatus('delivered');

      // 50% chance of waiting 5-15 seconds before "reading" (AI is busy)
      if (_random.nextBool()) {
        final waitTime = 5000 + _random.nextInt(10000); // 5-15 секунд
        await Future.delayed(Duration(milliseconds: waitTime));
      } else {
        // Small delay even if not waiting (1-3 seconds)
        await Future.delayed(Duration(milliseconds: 1000 + _random.nextInt(2000)));
      }

      // AI starts "reading" the message
      _isReading = true;
      _updateLastMessageStatus('read');

      // Wait a bit while "reading" (0.5-2 seconds)
      await Future.delayed(Duration(milliseconds: 500 + _random.nextInt(1500)));
      _isReading = false;

      // Get AI response (this calls OpenAI API)
      final response = await _chatService.sendMessage(
        aiProfileId: aiProfileId,
        userMessage: content,
      );

      // Show typing indicator
      _isTyping = true;

      // Calculate typing delay based on response length
      final typingDelay = _calculateTypingDelay(response);
      await Future.delayed(Duration(milliseconds: typingDelay));

      // Reload messages to get both user and AI message from storage
      await loadMessages();

      _isTyping = false;
      return response;
    } catch (e) {
      _isTyping = false;
      _isReading = false;
      print('Error sending message to AI: $e');
      return null;
    }
  }

  /// Update the status of the last user message
  void _updateLastMessageStatus(String status) {
    state.whenData((messages) {
      if (messages.isEmpty) return;

      // Find last user message and update its status
      final updatedMessages = List<Map<String, dynamic>>.from(messages);
      for (int i = updatedMessages.length - 1; i >= 0; i--) {
        if (updatedMessages[i]['is_from_ai'] != true) {
          updatedMessages[i] = Map<String, dynamic>.from(updatedMessages[i]);
          updatedMessages[i]['status'] = status;
          break;
        }
      }
      state = AsyncValue.data(updatedMessages);
    });
  }

  Future<void> refresh() async {
    await loadMessages();
  }

  Future<void> clearHistory() async {
    await _chatService.clearHistory(aiProfileId);
    state = const AsyncValue.data([]);
  }
}

/// AI Chat notifier provider factory
final aiChatNotifierProvider = StateNotifierProvider.family<AIChatNotifier, AsyncValue<List<Map<String, dynamic>>>, String>((ref, aiProfileId) {
  final chatService = ref.watch(aiChatServiceProvider);
  return AIChatNotifier(chatService, aiProfileId);
});

/// Check if profile is AI
final isAIProfileProvider = Provider.family<bool, String>((ref, profileId) {
  return profileId.startsWith('ai_');
});

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/providers/chats_provider.dart';

/// Chat detail screen
class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String? _partnerTyping;

  @override
  void initState() {
    super.initState();
    _setupTypingIndicator();
  }

  void _setupTypingIndicator() {
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.subscribeToTyping(widget.chatId, (userId, isTyping) {
      if (mounted) {
        setState(() {
          _partnerTyping = isTyping ? userId : null;
        });
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.unsubscribeFromChat(widget.chatId);
    super.dispose();
  }

  void _onTextChanged(String text) {
    final shouldBeTyping = text.isNotEmpty;
    if (shouldBeTyping != _isTyping) {
      _isTyping = shouldBeTyping;
      final realtimeService = ref.read(realtimeServiceProvider);
      realtimeService.sendTypingIndicator(widget.chatId, _isTyping);
    }
  }

  @override
  Widget build(BuildContext context) {
    // First try to get chat from the cached list
    final chatsAsync = ref.watch(chatsNotifierProvider);
    final chats = chatsAsync.valueOrNull ?? [];
    ChatModel? chat;

    // Try to find in cached chats list by chat ID
    for (final c in chats) {
      if (c.id == widget.chatId) {
        chat = c;
        break;
      }
    }

    // Also try to find by participant ID (when navigating from match dialog)
    if (chat == null) {
      for (final c in chats) {
        if (c.participantId == widget.chatId) {
          chat = c;
          break;
        }
      }
    }

    // If not found in cache, load directly from database by chat ID
    final singleChatAsync = ref.watch(singleChatProvider(widget.chatId));
    chat ??= singleChatAsync.valueOrNull;

    // If still not found, try to find by participant ID
    final chatByParticipantAsync = ref.watch(chatByParticipantProvider(widget.chatId));
    chat ??= chatByParticipantAsync.valueOrNull;

    // Determine actual chat ID for messages (could be from participantId lookup)
    final actualChatId = chat?.id ?? widget.chatId;
    final messagesAsync = ref.watch(messagesNotifierProvider(actualChatId));

    // Show loading if chat is still being loaded
    if (chat == null && (chatsAsync.isLoading || singleChatAsync.isLoading || chatByParticipantAsync.isLoading)) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Show error if chat not found after loading
    if (chat == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              AppSpacing.vGapMd,
              Text('Chat not found', style: AppTypography.titleMedium),
              AppSpacing.vGapMd,
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      );
    }

    // Create non-nullable local variable for use in callbacks
    final currentChat = chat;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.pushProfileView(currentChat.participantId),
          child: Row(
            children: [
              FancyAvatar(
                imageUrl: currentChat.participantAvatarUrl,
                name: currentChat.participantName,
                size: AvatarSize.small,
                isOnline: currentChat.participantOnline,
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentChat.participantName,
                      style: AppTypography.titleSmall,
                    ),
                    if (_partnerTyping != null)
                      Text(
                        'typing...',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        currentChat.participantOnline ? 'Online' : 'Offline',
                        style: AppTypography.labelSmall.copyWith(
                          color: currentChat.participantOnline
                              ? AppColors.online
                              : AppColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showChatOptions(context, currentChat.participantId),
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    AppSpacing.vGapMd,
                    Text('Error loading messages', style: AppTypography.titleMedium),
                    AppSpacing.vGapSm,
                    TextButton(
                      onPressed: () => ref.refresh(messagesNotifierProvider(widget.chatId)),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (msgs) {
                if (msgs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AppColors.textTertiary,
                        ),
                        AppSpacing.vGapMd,
                        Text(
                          'No messages yet',
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        AppSpacing.vGapSm,
                        Text(
                          'Say hello to ${currentChat.participantName}!',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final message = msgs[index];
                    final isMe = message.isMe;
                    return _MessageBubble(
                      message: message,
                      isMe: isMe,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.md,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            color: AppColors.textSecondary,
            onPressed: () => _showAttachmentOptions(context),
          ),

          // Text field
          Expanded(
            child: TextField(
              controller: _messageController,
              style: AppTypography.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: AppColors.surfaceVariant,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
              ),
              maxLines: 4,
              minLines: 1,
              onChanged: _onTextChanged,
            ),
          ),
          AppSpacing.hGapSm,

          // Send button
          IconButton(
            icon: const Icon(Icons.send),
            color: AppColors.primary,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    _onTextChanged(''); // Clear typing indicator

    try {
      final messagesNotifier = ref.read(messagesNotifierProvider(widget.chatId).notifier);
      await messagesNotifier.sendMessage(text);

      // Scroll to bottom after sending
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.photo, color: AppColors.primary),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                // Handle photo
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.info),
              title: const Text('Video'),
              onTap: () {
                Navigator.pop(context);
                // Handle video
              },
            ),
            ListTile(
              leading: const Icon(Icons.gif_box, color: AppColors.warning),
              title: const Text('GIF'),
              onTap: () {
                Navigator.pop(context);
                // Handle GIF
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.success),
              title: const Text('Voice message'),
              onTap: () {
                Navigator.pop(context);
                // Handle voice
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _showChatOptions(BuildContext context, String participantId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.textTertiary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.textSecondary),
              title: const Text('View profile'),
              onTap: () {
                Navigator.pop(context);
                context.pushProfileView(participantId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag_outlined, color: AppColors.error),
              title: const Text('Report'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.warning),
              title: const Text('Block user'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;

  const _MessageBubble({
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppSpacing.radiusMd),
            topRight: const Radius.circular(AppSpacing.radiusMd),
            bottomLeft: Radius.circular(isMe ? AppSpacing.radiusMd : 4),
            bottomRight: Radius.circular(isMe ? 4 : AppSpacing.radiusMd),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Image if exists
            if (message.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: Image.network(
                  message.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    width: 200,
                    height: 150,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                  ),
                ),
              ),
              AppSpacing.vGapSm,
            ],
            // Text
            if (message.text != null && message.text!.isNotEmpty)
              Text(
                message.text!,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            AppSpacing.vGapXs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: isMe
                        ? AppColors.textPrimary.withOpacity(0.7)
                        : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead
                        ? AppColors.info
                        : AppColors.textPrimary.withOpacity(0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

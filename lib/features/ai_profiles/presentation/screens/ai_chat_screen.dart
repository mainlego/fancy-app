import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/providers/ai_profiles_provider.dart';
import '../../domain/services/ai_chat_service.dart';

/// AI Chat screen for conversations with AI profiles
class AIChatScreen extends ConsumerStatefulWidget {
  final String aiProfileId;

  const AIChatScreen({
    super.key,
    required this.aiProfileId,
  });

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final aiProfilesAsync = ref.watch(aiProfilesProvider);
    final aiProfile = aiProfilesAsync.whenOrNull(
      data: (profiles) => profiles.firstWhere(
        (p) => p.id == widget.aiProfileId,
        orElse: () => profiles.first,
      ),
    );

    final messagesAsync = ref.watch(aiChatNotifierProvider(widget.aiProfileId));
    final chatNotifier = ref.read(aiChatNotifierProvider(widget.aiProfileId).notifier);

    if (aiProfile == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: () => context.pushProfileView(widget.aiProfileId),
          child: Row(
            children: [
              FancyAvatar(
                imageUrl: aiProfile.photos.isNotEmpty ? aiProfile.photos.first : null,
                name: aiProfile.name,
                size: AvatarSize.small,
                isOnline: true, // AI profiles are always online
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      aiProfile.name,
                      style: AppTypography.titleSmall,
                    ),
                    if (chatNotifier.isTyping)
                      Text(
                        'typing...',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      Text(
                        'Online',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.online,
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
            onPressed: () => _showChatOptions(context),
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
                      onPressed: () => chatNotifier.refresh(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (messages) {
                if (messages.isEmpty) {
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
                          'Say hello to ${aiProfile.name}!',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Reverse messages for display (newest at bottom)
                final reversedMessages = messages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: reversedMessages.length + (chatNotifier.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Typing indicator
                    if (chatNotifier.isTyping && index == 0) {
                      return _TypingIndicator();
                    }

                    final msgIndex = chatNotifier.isTyping ? index - 1 : index;
                    final message = reversedMessages[msgIndex];
                    final isMe = message['is_from_ai'] != true;

                    return _AIMessageBubble(
                      text: message['content'] as String? ?? '',
                      isMe: isMe,
                      createdAt: DateTime.tryParse(message['created_at'] as String? ?? '') ?? DateTime.now(),
                      status: message['status'] as String?,
                    );
                  },
                );
              },
            ),
          ),

          // Input bar
          _buildInputBar(chatNotifier),
        ],
      ),
    );
  }

  Widget _buildInputBar(AIChatNotifier chatNotifier) {
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
          // Text field with Enter key support for PC
          Expanded(
            child: KeyboardListener(
              focusNode: FocusNode(),
              onKeyEvent: (event) {
                // Send on Enter (without Shift) on desktop/web
                if (event is KeyDownEvent &&
                    event.logicalKey == LogicalKeyboardKey.enter &&
                    !HardwareKeyboard.instance.isShiftPressed &&
                    !_isSending) {
                  _sendMessage(chatNotifier);
                }
              },
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                style: AppTypography.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.zero,
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                ),
                maxLines: 4,
                minLines: 1,
                enabled: !_isSending,
                textInputAction: TextInputAction.send,
                onSubmitted: _isSending ? null : (_) => _sendMessage(chatNotifier),
              ),
            ),
          ),
          AppSpacing.hGapSm,

          // Send button - only shows loading during actual send
          IconButton(
            icon: _isSending
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: AppColors.primary,
            onPressed: _isSending ? null : () => _sendMessage(chatNotifier),
          ),
        ],
      ),
    );
  }

  void _sendMessage(AIChatNotifier chatNotifier) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    if (_isSending) return; // Prevent double sending

    setState(() {
      _isSending = true;
    });

    _messageController.clear();

    // Reset _isSending immediately after message is queued
    // The loading indicator should only show during the initial send
    // AI reading/typing indicators are shown separately
    if (mounted) {
      setState(() {
        _isSending = false;
      });
    }

    try {
      // This will handle all the delays internally (reading, typing, etc)
      // but user can continue typing new messages
      await chatNotifier.sendMessage(text);

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
    } finally {
      // No need to reset _isSending here as it's already reset above
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
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
                borderRadius: BorderRadius.zero,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.textSecondary),
              title: const Text('View profile'),
              onTap: () {
                Navigator.pop(context);
                context.pushProfileView(widget.aiProfileId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Clear chat history'),
              onTap: () {
                Navigator.pop(context);
                _confirmClearHistory();
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _confirmClearHistory() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Clear chat history?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(aiChatNotifierProvider(widget.aiProfileId).notifier).clearHistory();
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

class _AIMessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final DateTime createdAt;
  final String? status; // sent, delivered, read

  const _AIMessageBubble({
    required this.text,
    required this.isMe,
    required this.createdAt,
    this.status,
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
            Text(
              text,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            AppSpacing.vGapXs,
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(createdAt),
                  style: AppTypography.labelSmall.copyWith(
                    color: isMe
                        ? AppColors.textPrimary.withOpacity(0.7)
                        : AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
                if (isMe && status != null) ...[
                  const SizedBox(width: 4),
                  _buildStatusIcon(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon() {
    switch (status) {
      case 'sent':
        // Одна серая галочка
        return Icon(
          Icons.check,
          size: 14,
          color: AppColors.textPrimary.withOpacity(0.5),
        );
      case 'delivered':
        // Две серые галочки
        return Icon(
          Icons.done_all,
          size: 14,
          color: AppColors.textPrimary.withOpacity(0.5),
        );
      case 'read':
        // Две синие галочки
        return const Icon(
          Icons.done_all,
          size: 14,
          color: Colors.lightBlueAccent,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TypingIndicator extends StatefulWidget {
  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.zero,
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                final value = ((_controller.value + delay) % 1.0);
                final opacity = (value < 0.5 ? value : 1 - value) * 2;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.textTertiary.withOpacity(0.3 + opacity * 0.7),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

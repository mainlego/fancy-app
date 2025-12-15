import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/realtime_service.dart';
import '../../../../core/services/supabase_service.dart';
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
  final FocusNode _focusNode = FocusNode();
  bool _isTyping = false;
  String? _partnerTyping;
  String? _actualChatId; // Actual chat ID after resolving participant ID
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _setupTypingIndicator();
  }

  void _setupTypingIndicator() {
    final chatId = _actualChatId ?? widget.chatId;
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.subscribeToTyping(chatId, (userId, isTyping) {
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
    _focusNode.dispose();
    final chatId = _actualChatId ?? widget.chatId;
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.unsubscribeFromChat(chatId);
    super.dispose();
  }

  // Handle keyboard shortcuts (Enter to send on desktop)
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    // Check if it's desktop/web platform
    final isDesktopOrWeb = kIsWeb || !Platform.isAndroid && !Platform.isIOS;

    if (isDesktopOrWeb &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.enter &&
        !HardwareKeyboard.instance.isShiftPressed) {
      _sendMessage();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _onTextChanged(String text) {
    final shouldBeTyping = text.isNotEmpty;
    if (shouldBeTyping != _isTyping) {
      _isTyping = shouldBeTyping;
      final chatId = _actualChatId ?? widget.chatId;
      final realtimeService = ref.read(realtimeServiceProvider);
      realtimeService.sendTypingIndicator(chatId, _isTyping);
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

    // Store actual chat ID and setup realtime subscription if changed
    if (_actualChatId != actualChatId && actualChatId != widget.chatId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _actualChatId != actualChatId) {
          setState(() {
            _actualChatId = actualChatId;
          });
          _setupTypingIndicator();
        }
      });
    }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Upload progress indicator
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: LinearProgressIndicator(),
            ),

          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.textSecondary,
                onPressed: _isUploading ? null : () => _showAttachmentOptions(context),
              ),

              // Text field with keyboard handling
              Expanded(
                child: Focus(
                  focusNode: _focusNode,
                  onKeyEvent: _handleKeyEvent,
                  child: TextField(
                    controller: _messageController,
                    style: AppTypography.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textTertiary,
                      ),
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
                    textInputAction: TextInputAction.newline,
                    onChanged: _onTextChanged,
                  ),
                ),
              ),
              AppSpacing.hGapSm,

              // Send button
              IconButton(
                icon: const Icon(Icons.send),
                color: AppColors.primary,
                onPressed: _isUploading ? null : _sendMessage,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty && imageUrl == null) return;

    final chatId = _actualChatId ?? widget.chatId;
    _messageController.clear();
    _onTextChanged(''); // Clear typing indicator

    try {
      final messagesNotifier = ref.read(messagesNotifierProvider(chatId).notifier);
      await messagesNotifier.sendMessage(text.isEmpty ? '' : text, imageUrl: imageUrl);

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

  Future<void> _pickAndSendPhoto({required ImageSource source}) async {
    final picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      // Upload image to Supabase storage
      final bytes = await image.readAsBytes();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final supabase = ref.read(supabaseServiceProvider);
      final chatId = _actualChatId ?? widget.chatId;

      final imageUrl = await supabase.uploadChatMedia(
        chatId: chatId,
        fileName: fileName,
        bytes: bytes,
        contentType: 'image/jpeg',
      );

      // Send message with image
      _sendMessage(imageUrl: imageUrl);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickAndSendVideo({required ImageSource source}) async {
    final picker = ImagePicker();
    try {
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 2),
      );

      if (video == null) return;

      setState(() => _isUploading = true);

      // Upload video to Supabase storage
      final bytes = await video.readAsBytes();
      final fileName = 'video_${DateTime.now().millisecondsSinceEpoch}.mp4';
      final supabase = ref.read(supabaseServiceProvider);
      final chatId = _actualChatId ?? widget.chatId;

      final videoUrl = await supabase.uploadChatMedia(
        chatId: chatId,
        fileName: fileName,
        bytes: bytes,
        contentType: 'video/mp4',
      );

      // Send message with video URL
      final messagesNotifier = ref.read(messagesNotifierProvider(chatId).notifier);
      await messagesNotifier.sendMediaMessage(
        mediaUrl: videoUrl,
        type: MessageType.video,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload video: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
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
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Photo from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendPhoto(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendPhoto(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library, color: AppColors.info),
              title: const Text('Video from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo(source: ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: AppColors.info),
              title: const Text('Record Video'),
              onTap: () {
                Navigator.pop(context);
                _pickAndSendVideo(source: ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: AppColors.success),
              title: const Text('Voice message'),
              onTap: () {
                Navigator.pop(context);
                _showVoiceRecordingDialog();
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _showVoiceRecordingDialog() {
    // TODO: Implement voice recording with record package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Voice recording coming soon!'),
        backgroundColor: AppColors.info,
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
            // Media content based on type
            _buildMediaContent(context),
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

  Widget _buildMediaContent(BuildContext context) {
    if (!message.isMediaMessage && message.mediaUrl == null) {
      return const SizedBox.shrink();
    }

    switch (message.type) {
      case MessageType.image:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _showFullScreenImage(context, message.mediaUrl!),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              child: CachedNetworkImage(
                imageUrl: message.mediaUrl!,
                fit: BoxFit.cover,
                width: 200,
                placeholder: (context, url) => Container(
                  width: 200,
                  height: 150,
                  color: AppColors.surfaceVariant,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 200,
                  height: 150,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                ),
              ),
            ),
          ),
        );

      case MessageType.video:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _playVideo(context, message.mediaUrl!),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: const Icon(Icons.movie, size: 48, color: AppColors.textTertiary),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.overlay,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: AppColors.textPrimary, size: 32),
                ),
              ],
            ),
          ),
        );

      case MessageType.voice:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: GestureDetector(
            onTap: () => _playVoice(context, message.mediaUrl!),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary.withOpacity(0.8) : AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, color: AppColors.textPrimary),
                  AppSpacing.hGapSm,
                  // Voice waveform placeholder
                  SizedBox(
                    width: 100,
                    height: 24,
                    child: CustomPaint(
                      painter: _VoiceWaveformPainter(
                        color: isMe ? AppColors.textPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                  AppSpacing.hGapSm,
                  if (message.mediaDurationMs != null)
                    Text(
                      _formatDuration(message.mediaDurationMs!),
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

      case MessageType.gif:
      case MessageType.sticker:
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            child: CachedNetworkImage(
              imageUrl: message.mediaUrl!,
              fit: BoxFit.cover,
              width: 150,
              placeholder: (context, url) => Container(
                width: 150,
                height: 150,
                color: AppColors.surfaceVariant,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                width: 150,
                height: 150,
                color: AppColors.surfaceVariant,
                child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
              ),
            ),
          ),
        );

      case MessageType.text:
        // Check for legacy image_url field
        if (message.mediaUrl != null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => _showFullScreenImage(context, message.mediaUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: message.mediaUrl!,
                  fit: BoxFit.cover,
                  width: 200,
                  placeholder: (context, url) => Container(
                    width: 200,
                    height: 150,
                    color: AppColors.surfaceVariant,
                    child: const Center(child: CircularProgressIndicator()),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 200,
                    height: 150,
                    color: AppColors.surfaceVariant,
                    child: const Icon(Icons.broken_image, color: AppColors.textTertiary),
                  ),
                ),
              ),
            ),
          );
        }
        return const SizedBox.shrink();
    }
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  void _playVideo(BuildContext context, String videoUrl) {
    // TODO: Implement video player
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Video player coming soon!')),
    );
  }

  void _playVoice(BuildContext context, String voiceUrl) {
    // TODO: Implement voice player
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Voice player coming soon!')),
    );
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDuration(int milliseconds) {
    final seconds = (milliseconds / 1000).round();
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}

/// Voice waveform painter
class _VoiceWaveformPainter extends CustomPainter {
  final Color color;

  _VoiceWaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 20;
    final barWidth = size.width / barCount;
    final maxHeight = size.height;

    for (var i = 0; i < barCount; i++) {
      final height = (maxHeight * 0.3) + (maxHeight * 0.7 * (i % 3 == 0 ? 0.8 : i % 2 == 0 ? 0.5 : 0.3));
      final x = i * barWidth + barWidth / 2;
      final y1 = (size.height - height) / 2;
      final y2 = y1 + height;
      canvas.drawLine(Offset(x, y1), Offset(x, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Full screen image viewer
class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.broken_image,
              color: Colors.white,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

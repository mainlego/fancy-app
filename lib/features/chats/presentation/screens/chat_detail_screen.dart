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
import '../widgets/video_player_screen.dart';
import '../widgets/voice_recording_dialog.dart';
import '../widgets/voice_player_widget.dart';
import '../widgets/album_picker_dialog.dart';
import '../widgets/timed_media_viewer.dart';

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
            const Divider(),
            ListTile(
              leading: const Icon(Icons.photo_album, color: AppColors.warning),
              title: const Text('From Albums'),
              subtitle: const Text('Send photos from your albums'),
              onTap: () {
                Navigator.pop(context);
                _showAlbumPicker();
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  Future<void> _showVoiceRecordingDialog() async {
    final result = await VoiceRecordingDialog.show(context);
    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final chatId = _actualChatId ?? widget.chatId;

      // Determine file extension and content type based on platform
      final isWebFormat = result.filePath.endsWith('.webm');
      final fileName = isWebFormat
          ? 'voice_${DateTime.now().millisecondsSinceEpoch}.webm'
          : 'voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
      final contentType = isWebFormat ? 'audio/webm' : 'audio/mp4';

      // Read the recorded file
      final file = File(result.filePath);
      final bytes = await file.readAsBytes();

      // Upload to Supabase storage
      final voiceUrl = await supabase.uploadChatMedia(
        chatId: chatId,
        fileName: fileName,
        bytes: bytes,
        contentType: contentType,
      );

      // Send voice message
      final messagesNotifier = ref.read(messagesNotifierProvider(chatId).notifier);
      await messagesNotifier.sendMediaMessage(
        mediaUrl: voiceUrl,
        type: MessageType.voice,
        durationMs: result.durationMs,
      );

      // Clean up temp file (not on web)
      if (!kIsWeb) {
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send voice message: $e'),
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

  Future<void> _showAlbumPicker() async {
    final result = await AlbumPickerDialog.show(context);
    if (result == null) return;

    setState(() => _isUploading = true);

    try {
      final supabase = ref.read(supabaseServiceProvider);
      final chatId = _actualChatId ?? widget.chatId;

      // Send the photo from album
      if (result.isPrivate) {
        // Send as private media with timed/one-time viewing
        await supabase.sendPrivateMediaMessage(
          chatId: chatId,
          mediaUrl: result.media.url,
          messageType: 'image',
          isPrivateMedia: true,
          viewDurationSec: result.viewDurationSec,
          oneTimeView: result.oneTimeView,
        );
      } else {
        // Send as regular image
        final messagesNotifier = ref.read(messagesNotifierProvider(chatId).notifier);
        await messagesNotifier.sendMessage('', imageUrl: result.media.url);
      }

      // Refresh messages
      ref.invalidate(messagesNotifierProvider(chatId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.isPrivate
                ? 'Private photo sent${result.oneTimeView ? " (one-time view)" : result.viewDurationSec != null ? " (${result.viewDurationSec}s)" : ""}'
                : 'Photo sent'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send photo: $e'),
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
                _showReportDialog(participantId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.block, color: AppColors.warning),
              title: const Text('Block user'),
              onTap: () {
                Navigator.pop(context);
                _showBlockConfirmation(participantId);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete chat'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatConfirmation();
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  void _showReportDialog(String userId) {
    final reasons = [
      'Inappropriate content',
      'Spam or scam',
      'Harassment',
      'Fake profile',
      'Other',
    ];
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Report User',
            style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting this user?',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
              ),
              AppSpacing.vGapMd,
              ...reasons.map((reason) => RadioListTile<String>(
                title: Text(reason, style: AppTypography.bodyMedium),
                value: reason,
                groupValue: selectedReason,
                onChanged: (value) => setState(() => selectedReason = value),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: selectedReason == null
                  ? null
                  : () async {
                      Navigator.pop(context);
                      await _reportUser(userId, selectedReason!);
                    },
              child: Text(
                'Report',
                style: TextStyle(
                  color: selectedReason == null ? AppColors.textTertiary : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(String userId, String reason) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.reportUser(
        reportedUserId: userId,
        reason: reason,
        reportedByUserId: supabase.currentUser?.id,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User reported. Thank you for helping keep our community safe.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to report user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showBlockConfirmation(String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Block User',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This user will no longer be able to contact you. You won\'t see each other in discovery. This action can be undone in Settings.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _blockUser(userId);
            },
            child: const Text('Block', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }

  Future<void> _blockUser(String userId) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.blockUser(userId);

      // Also delete the chat after blocking
      final chatId = _actualChatId ?? widget.chatId;
      await supabase.deleteChat(chatId);

      // Refresh chats list
      ref.read(chatsNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User blocked'),
            backgroundColor: AppColors.warning,
          ),
        );
        Navigator.pop(context); // Go back to chats list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteChatConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Chat',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'This will permanently delete all messages in this chat. This action cannot be undone.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteChat();
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat() async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final chatId = _actualChatId ?? widget.chatId;
      await supabase.deleteChat(chatId);

      // Refresh chats list
      ref.read(chatsNotifierProvider.notifier).refresh();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
        Navigator.pop(context); // Go back to chats list
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete chat: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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

    // Handle private media
    if (message.isPrivateMedia) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: PrivateMediaBubble(
          message: message,
          isMe: isMe,
          onTap: () => _showPrivateMedia(context),
        ),
      );
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
          child: VoicePlayerWidget(
            audioUrl: message.mediaUrl!,
            durationMs: message.mediaDurationMs,
            isMe: isMe,
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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerScreen(videoUrl: videoUrl),
      ),
    );
  }

  void _showPrivateMedia(BuildContext context) {
    // For sender, always show the image
    if (isMe) {
      _showFullScreenImage(context, message.mediaUrl!);
      return;
    }

    // For receiver, check if can still view
    if (!message.canBeViewed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This photo has already been viewed'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    // Show timed viewer
    TimedMediaViewer.show(context, message);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
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

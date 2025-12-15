import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/providers/chats_provider.dart';

/// Chats screen with swipeable tabs (Chats, Likes, Favs)
class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ConsumerState<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends ConsumerState<ChatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _pageController = PageController();

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        _pageController.animateToPage(
          _tabController.index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        _updateTabProvider(_tabController.index);
      }
    });
  }

  void _updateTabProvider(int index) {
    final tab = ChatsTab.values[index];
    ref.read(chatsTabProvider.notifier).state = tab;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final unreadChats = ref.watch(unreadChatsCountProvider);
    final newLikes = ref.watch(newLikesCountProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Tab bar with settings icon (no AppBar title)
            _buildTabBar(unreadChats, newLikes),

            // Swipeable Tab content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  _tabController.animateTo(index);
                  _updateTabProvider(index);
                },
                children: [
                  _ChatsListView(
                    onShowFavoriteDialog: _showFavoriteDialog,
                  ),
                  const _LikesListView(),
                  const _FavoritesListView(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(int unreadChats, int newLikes) {
    const tabTextColor = Color(0xFFD9D9D9);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          _buildTab(0, 'chats', badge: unreadChats > 0 ? unreadChats : null),
          AppSpacing.hGapLg,
          _buildTab(1, 'likes', badge: newLikes > 0 ? newLikes : null),
          AppSpacing.hGapLg,
          _buildTab(2, 'favs'),
          const Spacer(),
          // Settings icon
          GestureDetector(
            onTap: () => context.pushSettings(),
            child: Image.asset(
              AppAssets.icSettings,
              width: 24,
              height: 24,
              color: tabTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, {int? badge}) {
    const tabTextColor = Color(0xFFD9D9D9);
    const activeTabTextColor = AppColors.primary;

    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final isActive = _tabController.index == index;
        return GestureDetector(
          onTap: () {
            _tabController.animateTo(index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Text(
                  label,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isActive ? activeTabTextColor : tabTextColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                if (badge != null) ...[
                  AppSpacing.hGapXs,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      badge > 99 ? '99+' : badge.toString(),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFavoriteDialog(ChatModel chat, bool isFavorite) {
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
              leading: Icon(
                isFavorite ? Icons.star_border : Icons.star,
                color: AppColors.premium,
              ),
              title: Text(
                isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
              ),
              onTap: () async {
                Navigator.pop(context);
                await _toggleFavorite(chat, isFavorite);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('Delete Chat'),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(chat);
              },
            ),
            AppSpacing.vGapLg,
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(ChatModel chat, bool isFavorite) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      if (isFavorite) {
        await supabase.removeFromFavorites(chat.participantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat.participantName} removed from favorites'),
              backgroundColor: AppColors.textSecondary,
            ),
          );
        }
      } else {
        await supabase.addToFavorites(chat.participantId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${chat.participantName} added to favorites'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
      // Refresh favorites list
      ref.read(favoritesNotifierProvider.notifier).refresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update favorites: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(ChatModel chat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Chat',
          style: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
        ),
        content: Text(
          'Delete chat with ${chat.participantName}? This cannot be undone.',
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
              await _deleteChat(chat);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteChat(ChatModel chat) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      await supabase.deleteChat(chat.id);
      ref.read(chatsNotifierProvider.notifier).refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Chat deleted'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
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

/// Chats list view
class _ChatsListView extends ConsumerWidget {
  final void Function(ChatModel chat, bool isFavorite) onShowFavoriteDialog;

  const _ChatsListView({required this.onShowFavoriteDialog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(combinedChatsProvider);
    final favoritesAsync = ref.watch(favoritesNotifierProvider);
    final favoriteIds = favoritesAsync.valueOrNull?.map((f) => f.oderId).toSet() ?? {};

    return chatsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        ref,
        'Failed to load chats',
        () => ref.read(chatsNotifierProvider.notifier).refresh(),
      ),
      data: (chats) {
        if (chats.isEmpty) {
          return _buildEmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'No chats yet',
            subtitle: 'Start matching to chat with people',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: chats.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(height: 1),
          ),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final isAIChat = chat.id.startsWith('ai_');
            final isFavorite = favoriteIds.contains(chat.participantId);
            return _ChatListTile(
              chat: chat,
              isFavorite: isFavorite,
              onTap: () {
                if (isAIChat) {
                  context.pushAIChat(chat.id);
                } else {
                  context.pushChatDetail(chat.id);
                }
              },
              onDismiss: () {
                // Handle delete chat
              },
              onLongPress: () => onShowFavoriteDialog(chat, isFavorite),
            );
          },
        );
      },
    );
  }
}

/// Likes list view - displays as list like chats
class _LikesListView extends ConsumerWidget {
  const _LikesListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likesAsync = ref.watch(likesNotifierProvider);

    return likesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        ref,
        'Failed to load likes',
        () => ref.read(likesNotifierProvider.notifier).refresh(),
      ),
      data: (likes) {
        if (likes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border,
            title: 'No likes yet',
            subtitle: 'Keep swiping to get likes',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: likes.length,
          separatorBuilder: (context, index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: const Divider(height: 1),
          ),
          itemBuilder: (context, index) {
            final like = likes[index];
            return _LikeListTile(
              like: like,
              onTap: () => context.pushProfileView(like.userId),
            );
          },
        );
      },
    );
  }
}

/// Favorites list view
class _FavoritesListView extends ConsumerWidget {
  const _FavoritesListView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favoritesAsync = ref.watch(favoritesNotifierProvider);

    return favoritesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _buildErrorState(
        ref,
        'Failed to load favorites',
        () => ref.read(favoritesNotifierProvider.notifier).refresh(),
      ),
      data: (favorites) {
        if (favorites.isEmpty) {
          return _buildEmptyState(
            icon: Icons.star_border,
            title: 'No favorites yet',
            subtitle: 'Long-press on a chat to add to favorites',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: favorites.length,
          separatorBuilder: (context, index) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Divider(height: 1),
          ),
          itemBuilder: (context, index) {
            final fav = favorites[index];
            return _FavoriteListTile(
              favorite: fav,
              onTap: () => context.pushProfileView(fav.oderId),
              onRemove: () => ref.read(favoritesNotifierProvider.notifier).removeFromFavorites(fav.oderId),
            );
          },
        );
      },
    );
  }
}

Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: AppColors.textTertiary,
        ),
        AppSpacing.vGapLg,
        Text(
          title,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vGapSm,
        Text(
          subtitle,
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildErrorState(WidgetRef ref, String message, VoidCallback onRetry) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_outline,
          size: 64,
          color: AppColors.error,
        ),
        AppSpacing.vGapLg,
        Text(
          message,
          style: AppTypography.headlineSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        AppSpacing.vGapMd,
        FancyButton(
          text: 'Retry',
          variant: FancyButtonVariant.outline,
          fullWidth: false,
          onPressed: onRetry,
        ),
      ],
    ),
  );
}

class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final VoidCallback? onLongPress;
  final bool isFavorite;

  const _ChatListTile({
    required this.chat,
    required this.onTap,
    required this.onDismiss,
    this.onLongPress,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismiss(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.lg),
        color: AppColors.error,
        child: const Icon(
          Icons.delete,
          color: AppColors.textPrimary,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: FancyAvatar(
          imageUrl: chat.participantAvatarUrl,
          name: chat.participantName,
          isOnline: chat.participantOnline,
          isVerified: chat.participantVerified,
        ),
        title: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      chat.participantName,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: chat.hasUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isFavorite) ...[
                    AppSpacing.hGapXs,
                    const Icon(Icons.star, color: AppColors.premium, size: 16),
                  ],
                ],
              ),
            ),
            Text(
              _formatTime(chat.lastMessage?.createdAt),
              style: AppTypography.labelSmall.copyWith(
                color: chat.hasUnread ? AppColors.primary : AppColors.textTertiary,
              ),
            ),
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                _getMessagePreview(chat),
                style: AppTypography.bodySmall.copyWith(
                  color: chat.hasUnread
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight: chat.hasUnread ? FontWeight.w500 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (chat.hasUnread)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.zero,
                ),
                child: Text(
                  chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
        onLongPress: onLongPress,
      ),
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }

  String _getMessagePreview(ChatModel chat) {
    final message = chat.lastMessage;
    if (message == null) return 'No messages yet';

    switch (message.type) {
      case MessageType.text:
        return message.text ?? 'No messages yet';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎬 Video';
      case MessageType.voice:
        return '🎤 Voice message';
      case MessageType.gif:
        return 'GIF';
      case MessageType.sticker:
        return 'Sticker';
    }
  }
}

/// Like list tile for list view
class _LikeListTile extends StatelessWidget {
  final LikeModel like;
  final VoidCallback onTap;

  const _LikeListTile({
    required this.like,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: FancyAvatar(
        imageUrl: like.userAvatarUrl,
        name: like.userName,
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${like.userName}, ${like.userAge}',
              style: AppTypography.titleSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (like.isSuperLike)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.superLike,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: AppColors.textPrimary,
                size: 12,
              ),
            ),
        ],
      ),
      subtitle: Text(
        _formatTime(like.createdAt),
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textTertiary,
        ),
      ),
      trailing: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${date.day}/${date.month}';
  }
}

class _FavoriteListTile extends StatelessWidget {
  final FavoriteModel favorite;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _FavoriteListTile({
    required this.favorite,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      leading: FancyAvatar(
        imageUrl: favorite.userAvatarUrl,
        name: favorite.userName,
        isOnline: favorite.isOnline,
      ),
      title: Text(
        '${favorite.userName}, ${favorite.userAge}',
        style: AppTypography.titleSmall,
      ),
      subtitle: Text(
        favorite.isOnline ? 'Online' : 'Offline',
        style: AppTypography.bodySmall.copyWith(
          color: favorite.isOnline ? AppColors.online : AppColors.textTertiary,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(
          Icons.star,
          color: AppColors.premium,
        ),
        onPressed: onRemove,
      ),
      onTap: onTap,
    );
  }
}

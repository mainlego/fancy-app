import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/router/app_router.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../domain/models/chat_model.dart';
import '../../domain/providers/chats_provider.dart';

/// Chats screen with tabs (Chats, Likes, Favs)
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTab = ref.watch(chatsTabProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.pushSettings(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab bar
          _buildTabBar(ref, currentTab),

          // Tab content
          Expanded(
            child: _buildTabContent(context, ref, currentTab),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(WidgetRef ref, ChatsTab currentTab) {
    final unreadChats = ref.watch(unreadChatsCountProvider);
    final newLikes = ref.watch(newLikesCountProvider);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.divider),
        ),
      ),
      child: Row(
        children: [
          _buildTab(
            ref,
            ChatsTab.chats,
            'Chats',
            currentTab == ChatsTab.chats,
            badge: unreadChats > 0 ? unreadChats : null,
          ),
          AppSpacing.hGapLg,
          _buildTab(
            ref,
            ChatsTab.likes,
            'Likes',
            currentTab == ChatsTab.likes,
            badge: newLikes > 0 ? newLikes : null,
          ),
          AppSpacing.hGapLg,
          _buildTab(
            ref,
            ChatsTab.favs,
            'Favorites',
            currentTab == ChatsTab.favs,
          ),
        ],
      ),
    );
  }

  Widget _buildTab(
    WidgetRef ref,
    ChatsTab tab,
    String label,
    bool isActive, {
    int? badge,
  }) {
    return GestureDetector(
      onTap: () => ref.read(chatsTabProvider.notifier).state = tab,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: AppTypography.titleSmall.copyWith(
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
            if (badge != null) ...[
              AppSpacing.hGapXs,
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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
  }

  Widget _buildTabContent(BuildContext context, WidgetRef ref, ChatsTab tab) {
    switch (tab) {
      case ChatsTab.chats:
        return _buildChatsList(context, ref);
      case ChatsTab.likes:
        return _buildLikesList(context, ref);
      case ChatsTab.favs:
        return _buildFavoritesList(context, ref);
    }
  }

  Widget _buildChatsList(BuildContext context, WidgetRef ref) {
    final chatsAsync = ref.watch(combinedChatsProvider);

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
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = chats[index];
            final isAIChat = chat.id.startsWith('ai_');
            return _ChatListTile(
              chat: chat,
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
            );
          },
        );
      },
    );
  }

  Widget _buildLikesList(BuildContext context, WidgetRef ref) {
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

        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 0.75,
          ),
          itemCount: likes.length,
          itemBuilder: (context, index) {
            final like = likes[index];
            return _LikeCard(
              like: like,
              onTap: () => context.pushProfileView(like.userId),
            );
          },
        );
      },
    );
  }

  Widget _buildFavoritesList(BuildContext context, WidgetRef ref) {
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
            subtitle: 'Add people to favorites to find them quickly',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          itemCount: favorites.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
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
}

class _ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _ChatListTile({
    required this.chat,
    required this.onTap,
    required this.onDismiss,
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
              child: Text(
                chat.participantName,
                style: AppTypography.titleSmall.copyWith(
                  fontWeight: chat.hasUnread ? FontWeight.w600 : FontWeight.w400,
                ),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
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

class _LikeCard extends StatelessWidget {
  final LikeModel like;
  final VoidCallback onTap;

  const _LikeCard({
    required this.like,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          color: AppColors.surface,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Avatar
            if (like.userAvatarUrl != null)
              Image.network(
                like.userAvatarUrl!,
                fit: BoxFit.cover,
              )
            else
              Container(
                color: AppColors.surfaceVariant,
                child: const Center(
                  child: Icon(
                    Icons.person,
                    size: 48,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),

            // Gradient overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 80,
                decoration: const BoxDecoration(
                  gradient: AppColors.cardGradient,
                ),
              ),
            ),

            // Super like badge
            if (like.isSuperLike)
              Positioned(
                top: AppSpacing.sm,
                right: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.superLike,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.star,
                    color: AppColors.textPrimary,
                    size: 14,
                  ),
                ),
              ),

            // User info
            Positioned(
              bottom: AppSpacing.sm,
              left: AppSpacing.sm,
              right: AppSpacing.sm,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${like.userName}, ${like.userAge}',
                    style: AppTypography.titleSmall.copyWith(
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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

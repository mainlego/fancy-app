import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../shared/widgets/fancy_avatar.dart';
import '../../../../shared/widgets/fancy_button.dart';

/// Mock blocked users data
class BlockedUser {
  final String id;
  final String name;
  final String? avatarUrl;
  final DateTime blockedAt;

  BlockedUser({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.blockedAt,
  });
}

final blockedUsersProvider = StateProvider<List<BlockedUser>>((ref) {
  return [
    BlockedUser(
      id: '1',
      name: 'John',
      avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=100',
      blockedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    BlockedUser(
      id: '2',
      name: 'Mike',
      avatarUrl: null,
      blockedAt: DateTime.now().subtract(const Duration(days: 12)),
    ),
  ];
});

/// Blocked users screen
class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsers = ref.watch(blockedUsersProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blocked Users'),
      ),
      body: blockedUsers.isEmpty
          ? _buildEmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: blockedUsers.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = blockedUsers[index];
                return _BlockedUserTile(
                  user: user,
                  onUnblock: () => _unblockUser(ref, user),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.block,
            size: 64,
            color: AppColors.textTertiary,
          ),
          AppSpacing.vGapLg,
          Text(
            'No blocked users',
            style: AppTypography.headlineSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          AppSpacing.vGapSm,
          Text(
            'Users you block will appear here',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }

  void _unblockUser(WidgetRef ref, BlockedUser user) {
    ref.read(blockedUsersProvider.notifier).update((state) {
      return state.where((u) => u.id != user.id).toList();
    });
  }
}

class _BlockedUserTile extends StatelessWidget {
  final BlockedUser user;
  final VoidCallback onUnblock;

  const _BlockedUserTile({
    required this.user,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          FancyAvatar(
            imageUrl: user.avatarUrl,
            name: user.name,
            size: AvatarSize.medium,
          ),
          AppSpacing.hGapLg,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTypography.titleSmall,
                ),
                Text(
                  'Blocked ${_formatDate(user.blockedAt)}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          FancyButton(
            text: 'Unblock',
            variant: FancyButtonVariant.outline,
            size: FancyButtonSize.small,
            fullWidth: false,
            onPressed: () => _showUnblockDialog(context),
          ),
        ],
      ),
    );
  }

  void _showUnblockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock ${user.name}? They will be able to see your profile and send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onUnblock();
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'today';
    if (diff.inDays == 1) return 'yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 30) return '${diff.inDays ~/ 7} weeks ago';
    return '${diff.inDays ~/ 30} months ago';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../shared/widgets/fancy_avatar.dart';
import '../../../../shared/widgets/fancy_button.dart';

/// Provider for blocked users
final blockedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  return supabase.getBlockedUsers();
});

/// Provider for hidden users
final hiddenUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final supabase = ref.read(supabaseServiceProvider);
  return supabase.getHiddenUsers();
});

/// Blocked & Hidden users screen with tabs
class BlockedUsersScreen extends ConsumerStatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  ConsumerState<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends ConsumerState<BlockedUsersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Blocked & Hidden'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Blocked'),
            Tab(text: 'Hidden'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _BlockedUsersTab(),
          _HiddenUsersTab(),
        ],
      ),
    );
  }
}

/// Blocked users tab
class _BlockedUsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blockedUsersAsync = ref.watch(blockedUsersProvider);

    return blockedUsersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.vGapMd,
            Text(
              'Failed to load blocked users',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vGapMd,
            FancyButton(
              text: 'Retry',
              size: FancyButtonSize.small,
              fullWidth: false,
              onPressed: () => ref.invalidate(blockedUsersProvider),
            ),
          ],
        ),
      ),
      data: (blockedUsers) {
        if (blockedUsers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.block,
            title: 'No blocked users',
            subtitle: 'Users you block will appear here.\nBlocked users cannot see your profile or message you.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: blockedUsers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final blocked = blockedUsers[index];
            final profile = blocked['profiles'] as Map<String, dynamic>?;
            final blockedAt = DateTime.tryParse(blocked['created_at'] ?? '');

            return _UserTile(
              userId: blocked['blocked_id'] as String,
              name: profile?['name'] as String? ?? 'Unknown',
              avatarUrl: profile?['avatar_url'] as String?,
              photos: (profile?['photos'] as List<dynamic>?)?.cast<String>() ?? [],
              actionDate: blockedAt,
              actionLabel: 'Blocked',
              buttonText: 'Unblock',
              buttonColor: AppColors.error,
              onAction: () => _showUnblockDialog(context, ref, blocked),
            );
          },
        );
      },
    );
  }

  void _showUnblockDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> blocked) {
    final profile = blocked['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'this user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unblock User'),
        content: Text(
          'Are you sure you want to unblock $name? They will be able to see your profile and send you messages again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final supabase = ref.read(supabaseServiceProvider);
              await supabase.unblockUser(blocked['blocked_id'] as String);
              ref.invalidate(blockedUsersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name has been unblocked'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Unblock', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

/// Hidden users tab
class _HiddenUsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hiddenUsersAsync = ref.watch(hiddenUsersProvider);

    return hiddenUsersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            AppSpacing.vGapMd,
            Text(
              'Failed to load hidden users',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            AppSpacing.vGapMd,
            FancyButton(
              text: 'Retry',
              size: FancyButtonSize.small,
              fullWidth: false,
              onPressed: () => ref.invalidate(hiddenUsersProvider),
            ),
          ],
        ),
      ),
      data: (hiddenUsers) {
        if (hiddenUsers.isEmpty) {
          return _buildEmptyState(
            icon: Icons.visibility_off,
            title: 'No hidden users',
            subtitle: 'Users you hide will appear here.\nHidden users won\'t appear in your discovery feed,\nbut they can still see your profile and message you.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: hiddenUsers.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final hidden = hiddenUsers[index];
            final profile = hidden['profiles'] as Map<String, dynamic>?;
            final hiddenAt = DateTime.tryParse(hidden['created_at'] ?? '');

            return _UserTile(
              userId: hidden['hidden_id'] as String,
              name: profile?['name'] as String? ?? 'Unknown',
              avatarUrl: profile?['avatar_url'] as String?,
              photos: (profile?['photos'] as List<dynamic>?)?.cast<String>() ?? [],
              actionDate: hiddenAt,
              actionLabel: 'Hidden',
              buttonText: 'Unhide',
              buttonColor: AppColors.warning,
              onAction: () => _showUnhideDialog(context, ref, hidden),
            );
          },
        );
      },
    );
  }

  void _showUnhideDialog(BuildContext context, WidgetRef ref, Map<String, dynamic> hidden) {
    final profile = hidden['profiles'] as Map<String, dynamic>?;
    final name = profile?['name'] as String? ?? 'this user';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Unhide User'),
        content: Text(
          'Are you sure you want to unhide $name? They will appear in your discovery feed again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final supabase = ref.read(supabaseServiceProvider);
              await supabase.unhideUser(hidden['hidden_id'] as String);
              ref.invalidate(hiddenUsersProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$name has been unhidden'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            },
            child: const Text('Unhide', style: TextStyle(color: AppColors.warning)),
          ),
        ],
      ),
    );
  }
}

/// Reusable user tile widget
class _UserTile extends StatelessWidget {
  final String userId;
  final String name;
  final String? avatarUrl;
  final List<String> photos;
  final DateTime? actionDate;
  final String actionLabel;
  final String buttonText;
  final Color buttonColor;
  final VoidCallback onAction;

  const _UserTile({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.photos,
    this.actionDate,
    required this.actionLabel,
    required this.buttonText,
    required this.buttonColor,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Use avatar or first photo
    final displayUrl = avatarUrl ?? (photos.isNotEmpty ? photos.first : null);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          FancyAvatar(
            imageUrl: displayUrl,
            name: name,
            size: AvatarSize.medium,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (actionDate != null)
                  Text(
                    '$actionLabel ${_formatDate(actionDate!)}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              foregroundColor: buttonColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            child: Text(
              buttonText,
              style: AppTypography.buttonSmall.copyWith(color: buttonColor),
            ),
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

/// Empty state widget builder
Widget _buildEmptyState({
  required IconData icon,
  required String title,
  required String subtitle,
}) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
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
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/sound_service.dart';
import '../../features/chats/domain/providers/chats_provider.dart';
import '../../features/profile/domain/models/user_model.dart';
import '../../features/profile/domain/providers/current_profile_provider.dart';
import '../../features/home/presentation/widgets/match_dialog.dart';
import 'like_received_dialog.dart';

/// Provider for new likes count (unread likes)
final newLikesCountForBadgeProvider = Provider<int>((ref) {
  final likesAsync = ref.watch(likesNotifierProvider);
  return likesAsync.when(
    data: (likes) => likes.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Main scaffold with bottom navigation
class MainScaffold extends ConsumerStatefulWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends ConsumerState<MainScaffold> with WidgetsBindingObserver {
  bool _isShowingDialog = false;

  @override
  void initState() {
    super.initState();
    // Add lifecycle observer for online status tracking
    WidgetsBinding.instance.addObserver(this);

    // Initialize realtime service for message notifications
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtimeListeners();
      // Set user online when app starts
      _setOnlineStatus(true);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        _setOnlineStatus(true);
        break;
      case AppLifecycleState.inactive:
        break;
      case AppLifecycleState.paused:
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.detached:
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        _setOnlineStatus(false);
        break;
    }
  }

  void _setOnlineStatus(bool isOnline) {
    if (!mounted) return;
    final realtimeService = ref.read(realtimeServiceProvider);
    realtimeService.setOnlineStatus(isOnline);
  }

  void _setupRealtimeListeners() {
    final realtimeService = ref.read(realtimeServiceProvider);

    // Listen for new messages and refresh chats list
    realtimeService.onNewMessage = (message) {
      // Play sound for new message
      SoundService().play(SoundType.newMessage);
      // Refresh chats to update unread count and last message preview
      ref.read(chatsNotifierProvider.notifier).refresh();
    };

    // Listen for new likes and show modal
    realtimeService.onNewLike = (likeData) async {
      if (_isShowingDialog || !mounted) return;

      final fromUserId = likeData['from_user_id'] as String?;
      final isSuperLike = likeData['is_super_like'] as bool? ?? false;

      if (fromUserId == null) return;

      // Refresh likes list
      ref.read(likesNotifierProvider.notifier).refresh();

      // Get liker's profile
      try {
        final supabase = ref.read(supabaseServiceProvider);
        final profileData = await supabase.getProfile(fromUserId);

        if (profileData != null && mounted) {
          final likerUser = UserModel.fromSupabase(profileData);

          _isShowingDialog = true;

          await LikeReceivedDialog.show(
            context,
            likerUser: likerUser,
            isSuperLike: isSuperLike,
            onLikeBack: () async {
              // Like back - might create a match
              final isMatch = await supabase.likeUser(fromUserId);
              ref.read(likesNotifierProvider.notifier).refresh();

              if (isMatch && mounted) {
                // Show match dialog
                final currentProfile = ref.read(currentProfileProvider).valueOrNull;
                await MatchDialog.show(
                  context,
                  matchedUser: likerUser,
                  currentUserAvatar: currentProfile?.displayAvatar,
                  onSendMessage: () {
                    // Navigate to chat
                    context.pushChatDetail(fromUserId);
                  },
                );
                ref.read(chatsNotifierProvider.notifier).refresh();
              }
            },
            onPass: () {
              // Pass on this user
              supabase.passUser(fromUserId);
              ref.read(likesNotifierProvider.notifier).refresh();
            },
            onViewProfile: () {
              // Navigate to profile
              context.pushProfileView(fromUserId);
            },
          );

          _isShowingDialog = false;
        }
      } catch (e) {
        print('Error showing like dialog: $e');
        _isShowingDialog = false;
      }
    };

    // Listen for new matches and show match dialog
    realtimeService.onNewMatch = (matchData) async {
      if (_isShowingDialog || !mounted) return;

      final user1Id = matchData['user1_id'] as String?;
      final user2Id = matchData['user2_id'] as String?;
      final supabase = ref.read(supabaseServiceProvider);
      final currentUserId = supabase.currentUser?.id;

      if (currentUserId == null) return;

      // Find the other user's ID
      final otherUserId = user1Id == currentUserId ? user2Id : user1Id;
      if (otherUserId == null) return;

      // Refresh chats
      ref.read(chatsNotifierProvider.notifier).refresh();
      ref.read(likesNotifierProvider.notifier).refresh();

      // Get matched user's profile
      try {
        final profileData = await supabase.getProfile(otherUserId);

        if (profileData != null && mounted) {
          final matchedUser = UserModel.fromSupabase(profileData);
          final currentProfile = ref.read(currentProfileProvider).valueOrNull;

          _isShowingDialog = true;

          await MatchDialog.show(
            context,
            matchedUser: matchedUser,
            currentUserAvatar: currentProfile?.displayAvatar,
            onSendMessage: () {
              // Find the chat and navigate to it
              _navigateToMatchChat(otherUserId);
            },
          );

          _isShowingDialog = false;
        }
      } catch (e) {
        print('Error showing match dialog: $e');
        _isShowingDialog = false;
      }
    };
  }

  Future<void> _navigateToMatchChat(String otherUserId) async {
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final chatData = await supabase.getChatByParticipant(otherUserId);
      if (chatData != null && mounted) {
        final chatId = chatData['id'] as String;
        context.pushChatDetail(chatId);
      }
    } catch (e) {
      print('Error navigating to match chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch realtime service to keep it alive
    ref.watch(realtimeServiceProvider);
    final unreadCount = ref.watch(unreadChatsCountProvider);
    final newLikesCount = ref.watch(newLikesCountForBadgeProvider);

    // Total badge count (messages + likes)
    final totalBadge = unreadCount + newLikesCount;

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _BottomNavBar(
        unreadCount: totalBadge,
      ),
    );
  }
}

class _BottomNavBar extends StatelessWidget {
  final int unreadCount;

  const _BottomNavBar({
    required this.unreadCount,
  });

  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/profile')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 44 + bottomPadding,
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(
            color: AppColors.divider,
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // First: Discovery (Home)
          _NavItem(
            iconPath: AppAssets.icDiscovery,
            color: currentIndex == 0 ? AppColors.primary : AppColors.textSecondary,
            isActive: currentIndex == 0,
            onTap: () => context.goToHome(),
          ),
          // Second: Chats (with combined badge for messages + likes)
          _NavItem(
            iconPath: AppAssets.icChats,
            color: currentIndex == 1 ? AppColors.primary : AppColors.textSecondary,
            isActive: currentIndex == 1,
            badge: unreadCount > 0 ? unreadCount : null,
            onTap: () => context.goToChats(),
          ),
          // Third: Profile
          _NavItem(
            iconPath: AppAssets.icProfile,
            color: currentIndex == 2 ? AppColors.primary : AppColors.textSecondary,
            isActive: currentIndex == 2,
            onTap: () => context.goToProfile(),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final Color color;
  final bool isActive;
  final int? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.iconPath,
    required this.color,
    required this.isActive,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: color,
            ),
            if (badge != null)
              Positioned(
                right: 8,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.zero,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 14,
                    minHeight: 14,
                  ),
                  child: Text(
                    badge! > 99 ? '99+' : badge.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

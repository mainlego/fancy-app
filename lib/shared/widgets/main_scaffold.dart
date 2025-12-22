import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/location_service.dart';
import '../../core/services/realtime_service.dart';
import '../../core/services/supabase_service.dart';
import '../../core/services/sound_service.dart';
import '../../features/chats/domain/providers/chats_provider.dart';
import '../../features/home/domain/providers/profiles_provider.dart';
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
      // Check profile location and request if missing
      _checkAndUpdateLocation();
    });
  }

  /// Check if profile has location, request if missing, and update periodically
  Future<void> _checkAndUpdateLocation() async {
    try {
      // Check if current profile has coordinates
      final currentProfile = ref.read(currentProfileProvider).valueOrNull;
      final hasLocation = currentProfile?.latitude != null && currentProfile?.longitude != null;

      debugPrint('_checkAndUpdateLocation: Profile has location: $hasLocation');

      final locationService = ref.read(locationServiceProvider);

      // First request basic permission
      final permission = await locationService.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('_checkAndUpdateLocation: Location permission denied');
        return;
      }

      // Request "always" permission for background location
      final hasAlways = await locationService.requestAlwaysPermission();
      debugPrint('Location "always" permission: $hasAlways');

      // Use LocationNotifier to update location
      final locationNotifier = ref.read(locationNotifierProvider.notifier);

      // Force update if profile has no location, otherwise normal update
      final hasSignificantChange = await locationNotifier.updateLocation(force: !hasLocation);

      // If location changed significantly, reload profiles to recalculate distances
      if (hasSignificantChange) {
        debugPrint('_checkAndUpdateLocation: Significant location change, reloading profiles');
        // Import profiles_provider is needed - we'll use invalidate
        ref.invalidate(profilesNotifierProvider);
      }
    } catch (e) {
      debugPrint('Error checking/updating location: $e');
    }
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
        // Update location when app comes to foreground
        _updateLocationInBackground();
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

  /// Update location in background when app resumes
  Future<void> _updateLocationInBackground() async {
    try {
      final locationNotifier = ref.read(locationNotifierProvider.notifier);
      final hasSignificantChange = await locationNotifier.updateLocation();

      // If location changed significantly, reload profiles to recalculate distances
      if (hasSignificantChange) {
        debugPrint('_updateLocationInBackground: Significant location change, reloading profiles');
        ref.invalidate(profilesNotifierProvider);
      }
    } catch (e) {
      debugPrint('Error updating location: $e');
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
      debugPrint('🎉 MainScaffold: onNewMatch callback triggered');
      debugPrint('🎉 MainScaffold: _isShowingDialog=$_isShowingDialog, mounted=$mounted');

      if (_isShowingDialog || !mounted) {
        debugPrint('🎉 MainScaffold: Skipping - dialog showing or not mounted');
        return;
      }

      final user1Id = matchData['user1_id'] as String?;
      final user2Id = matchData['user2_id'] as String?;
      final supabase = ref.read(supabaseServiceProvider);
      final currentUserId = supabase.currentUser?.id;

      debugPrint('🎉 MainScaffold: Match data - user1=$user1Id, user2=$user2Id, current=$currentUserId');

      if (currentUserId == null) {
        debugPrint('🎉 MainScaffold: No current user ID');
        return;
      }

      // Find the other user's ID
      final otherUserId = user1Id == currentUserId ? user2Id : user1Id;
      if (otherUserId == null) {
        debugPrint('🎉 MainScaffold: No other user ID found');
        return;
      }

      debugPrint('🎉 MainScaffold: Other user ID = $otherUserId, refreshing chats and likes');

      // Refresh chats and likes immediately
      ref.read(chatsNotifierProvider.notifier).refresh();
      ref.read(likesNotifierProvider.notifier).refresh();

      // Increment unread notifications
      ref.read(unreadNotificationsProvider.notifier).increment();

      // Get matched user's profile
      try {
        debugPrint('🎉 MainScaffold: Fetching profile for $otherUserId');
        final profileData = await supabase.getProfile(otherUserId);

        debugPrint('🎉 MainScaffold: Profile data received: ${profileData != null}');

        if (profileData != null && mounted) {
          final matchedUser = UserModel.fromSupabase(profileData);
          final currentProfile = ref.read(currentProfileProvider).valueOrNull;

          debugPrint('🎉 MainScaffold: Showing match dialog for ${matchedUser.name}');
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
          debugPrint('🎉 MainScaffold: Match dialog closed');
        }
      } catch (e) {
        debugPrint('🎉 MainScaffold: Error showing match dialog: $e');
        _isShowingDialog = false;
      }
    };

    // Listen for chat deletions (when other user deletes)
    realtimeService.onChatDeleted = (chatData) {
      debugPrint('🗑️ MainScaffold: Chat deleted event received');
      // Refresh chats list to remove the deleted chat
      ref.read(chatsNotifierProvider.notifier).refresh();
      // Also refresh likes as they might have been deleted too
      ref.read(likesNotifierProvider.notifier).refresh();
    };

    // Listen for like deletions (when other user removes like)
    realtimeService.onLikeDeleted = (likeData) {
      debugPrint('🗑️ MainScaffold: Like deleted event received');
      // Refresh likes list
      ref.read(likesNotifierProvider.notifier).refresh();
    };

    // Listen for match deletions (when other user unmatches)
    realtimeService.onMatchDeleted = (matchData) {
      debugPrint('🗑️ MainScaffold: Match deleted event received');
      // Refresh chats and likes
      ref.read(chatsNotifierProvider.notifier).refresh();
      ref.read(likesNotifierProvider.notifier).refresh();
    };

    debugPrint('🔔 MainScaffold: Realtime listeners setup complete');
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

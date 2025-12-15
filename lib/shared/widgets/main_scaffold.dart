import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/services/realtime_service.dart';
import '../../features/chats/domain/providers/chats_provider.dart';

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
    // Note: Don't call _setOnlineStatus here as ref is already disposed
    // Online status will be set to false by app lifecycle events or session timeout
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        // App is visible and responding to user input
        _setOnlineStatus(true);
        break;
      case AppLifecycleState.inactive:
        // App is inactive (transitioning)
        break;
      case AppLifecycleState.paused:
        // App is not visible (background)
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.detached:
        // App is about to be terminated
        _setOnlineStatus(false);
        break;
      case AppLifecycleState.hidden:
        // App is hidden
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
      // Refresh chats to update unread count and last message preview
      ref.read(chatsNotifierProvider.notifier).refresh();
    };

    // Listen for new matches and refresh chats list
    realtimeService.onNewMatch = (match) {
      ref.read(chatsNotifierProvider.notifier).refresh();
    };
  }

  @override
  Widget build(BuildContext context) {
    // Watch realtime service to keep it alive
    ref.watch(realtimeServiceProvider);
    final unreadCount = ref.watch(unreadChatsCountProvider);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: _BottomNavBar(
        unreadCount: unreadCount,
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
    if (location == '/') return 0;  // Home is first
    if (location.startsWith('/chats')) return 1;  // Chats is second
    if (location.startsWith('/profile')) return 2;
    return 0;  // Default to home
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _getCurrentIndex(context);

    return Container(
      height: 44,
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
              // Second: Chats
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
                  decoration: BoxDecoration(
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


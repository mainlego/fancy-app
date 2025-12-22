import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chats/presentation/screens/chats_screen.dart';
import '../../features/chats/presentation/screens/chat_detail_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_view_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/verification_screen.dart';
import '../../features/settings/presentation/screens/premium_screen.dart';
import '../../features/filters/presentation/screens/filters_screen.dart';
import '../../features/albums/presentation/screens/albums_screen.dart';
import '../../features/referrals/presentation/screens/referral_screen.dart';
import '../../features/admin/presentation/screens/admin_panel_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Route names
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String home = '/';
  static const String chats = '/chats';
  static const String chatDetail = '/chats/:chatId';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileView = '/profile/:userId';
  static const String settings = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String verification = '/settings/verification';
  static const String premium = '/settings/premium';
  static const String referrals = '/settings/referrals';
  static const String filters = '/filters';
  static const String albums = '/albums';
  static const String profileSetup = '/profile-setup';
  static const String admin = '/admin';
}

/// Navigation shell key
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Routes that don't require authentication (pre-login)
const _preAuthRoutes = [
  AppRoutes.login,
  AppRoutes.splash,
];

/// Routes that require auth but are part of onboarding flow (post-login, pre-home)
const _onboardingFlowRoutes = [
  AppRoutes.onboarding,
  AppRoutes.profileSetup,
];

/// App router configuration
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isPreAuthRoute = _preAuthRoutes.contains(state.matchedLocation);
    final isOnboardingFlowRoute = _onboardingFlowRoutes.contains(state.matchedLocation);

    // If not logged in and trying to access protected route, go to login
    if (!isLoggedIn && !isPreAuthRoute) {
      return AppRoutes.login;
    }

    // If logged in and on pre-auth route (login/splash), go to home
    // Home screen will check if profile exists and redirect to onboarding/profile-setup if needed
    if (isLoggedIn && isPreAuthRoute) {
      return AppRoutes.home;
    }

    // Allow logged-in users to access onboarding flow routes without redirect
    // (they need to complete onboarding and profile setup)

    // No redirect needed
    return null;
  },
  routes: [
    // Auth routes (outside shell)
    GoRoute(
      path: AppRoutes.splash,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSetupScreen(),
    ),

    // Shell route for bottom navigation
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainScaffold(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutes.home,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: HomeScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.chats,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ChatsScreen(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          pageBuilder: (context, state) => const NoTransitionPage(
            child: ProfileScreen(),
          ),
        ),
      ],
    ),

    // Full screen routes (outside shell)
    GoRoute(
      path: AppRoutes.chatDetail,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final chatId = state.pathParameters['chatId']!;
        return ChatDetailScreen(chatId: chatId);
      },
    ),
    GoRoute(
      path: AppRoutes.profileEdit,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileEditScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileView,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final userId = state.pathParameters['userId']!;
        return ProfileViewScreen(userId: userId);
      },
    ),
    GoRoute(
      path: AppRoutes.settings,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.blockedUsers,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const BlockedUsersScreen(),
    ),
    GoRoute(
      path: AppRoutes.verification,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VerificationScreen(),
    ),
    GoRoute(
      path: AppRoutes.premium,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: AppRoutes.referrals,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ReferralScreen(),
    ),
    GoRoute(
      path: AppRoutes.filters,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FiltersScreen(),
    ),
    GoRoute(
      path: AppRoutes.albums,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AlbumsScreen(),
    ),
    GoRoute(
      path: AppRoutes.admin,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AdminPanelScreen(),
    ),
  ],
);

/// Navigation helper extension
extension NavigationExtension on BuildContext {
  void goToSplash() => go(AppRoutes.splash);
  void goToOnboarding() => go(AppRoutes.onboarding);
  void goToLogin() => go(AppRoutes.login);
  void goToHome() => go(AppRoutes.home);
  void goToChats() => go(AppRoutes.chats);
  void goToProfile() => go(AppRoutes.profile);

  void pushChatDetail(String chatId) => push('/chats/$chatId');
  void pushProfileView(String userId) => push('/profile/$userId');
  void pushProfileEdit() => push(AppRoutes.profileEdit);
  void pushSettings() => push(AppRoutes.settings);
  void pushBlockedUsers() => push(AppRoutes.blockedUsers);
  void pushVerification() => push(AppRoutes.verification);
  void pushPremium() => push(AppRoutes.premium);
  void pushReferrals() => push(AppRoutes.referrals);
  void pushFilters() => push(AppRoutes.filters);
  void pushAlbums() => push(AppRoutes.albums);
  void goToProfileSetup() => go(AppRoutes.profileSetup);
  void pushAdmin() => push(AppRoutes.admin);
}

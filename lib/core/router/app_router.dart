import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/chats/presentation/screens/chats_screen.dart';
import '../../features/chats/presentation/screens/chat_detail_screen.dart';
import '../../features/ai_profiles/presentation/screens/ai_chat_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/profile_edit_screen.dart';
import '../../features/profile/presentation/screens/profile_view_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/screens/blocked_users_screen.dart';
import '../../features/settings/presentation/screens/verification_screen.dart';
import '../../features/settings/presentation/screens/premium_screen.dart';
import '../../features/filters/presentation/screens/filters_screen.dart';
import '../../features/albums/presentation/screens/albums_screen.dart';
import '../../features/tutorial/presentation/screens/app_tutorial_screen.dart';
import '../../shared/widgets/main_scaffold.dart';

/// Route names
abstract class AppRoutes {
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/';
  static const String chats = '/chats';
  static const String chatDetail = '/chats/:chatId';
  static const String aiChat = '/ai-chat/:aiProfileId';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String profileView = '/profile/:userId';
  static const String settings = '/settings';
  static const String blockedUsers = '/settings/blocked-users';
  static const String verification = '/settings/verification';
  static const String premium = '/settings/premium';
  static const String filters = '/filters';
  static const String albums = '/albums';
  static const String profileSetup = '/profile-setup';
  static const String tutorial = '/tutorial';
}

/// Navigation shell key
final _shellNavigatorKey = GlobalKey<NavigatorState>();
final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Auth routes that don't require authentication
const _authRoutes = [
  AppRoutes.login,
  AppRoutes.signup,
  AppRoutes.onboarding,
  AppRoutes.splash,
  AppRoutes.profileSetup,
  AppRoutes.tutorial,
];

/// App router configuration
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;
    final isAuthRoute = _authRoutes.contains(state.matchedLocation);
    final isProfileSetup = state.matchedLocation == AppRoutes.profileSetup;
    final isTutorial = state.matchedLocation == AppRoutes.tutorial;

    // If not logged in and trying to access protected route, go to login
    if (!isLoggedIn && !isAuthRoute) {
      return AppRoutes.login;
    }

    // If logged in and on auth route (except profile setup and tutorial), go to home
    // Home screen will check if profile exists and redirect to profile setup if needed
    if (isLoggedIn && isAuthRoute && !isProfileSetup && !isTutorial) {
      return AppRoutes.home;
    }

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
      path: AppRoutes.signup,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileSetup,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: AppRoutes.tutorial,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AppTutorialScreen(),
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
      path: AppRoutes.aiChat,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final aiProfileId = state.pathParameters['aiProfileId']!;
        return AIChatScreen(aiProfileId: aiProfileId);
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
      path: AppRoutes.filters,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const FiltersScreen(),
    ),
    GoRoute(
      path: AppRoutes.albums,
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AlbumsScreen(),
    ),
  ],
);

/// Navigation helper extension
extension NavigationExtension on BuildContext {
  void goToSplash() => go(AppRoutes.splash);
  void goToOnboarding() => go(AppRoutes.onboarding);
  void goToLogin() => go(AppRoutes.login);
  void goToSignup() => push(AppRoutes.signup);
  void goToHome() => go(AppRoutes.home);
  void goToChats() => go(AppRoutes.chats);
  void goToProfile() => go(AppRoutes.profile);

  void pushChatDetail(String chatId) {
    // Check if this is an AI profile (starts with 'ai_')
    if (chatId.startsWith('ai_')) {
      push('/ai-chat/$chatId');
    } else {
      push('/chats/$chatId');
    }
  }
  void pushAIChat(String aiProfileId) => push('/ai-chat/$aiProfileId');
  void pushProfileView(String userId) => push('/profile/$userId');
  void pushProfileEdit() => push(AppRoutes.profileEdit);
  void pushSettings() => push(AppRoutes.settings);
  void pushBlockedUsers() => push(AppRoutes.blockedUsers);
  void pushVerification() => push(AppRoutes.verification);
  void pushPremium() => push(AppRoutes.premium);
  void pushFilters() => push(AppRoutes.filters);
  void pushAlbums() => push(AppRoutes.albums);
  void goToProfileSetup() => go(AppRoutes.profileSetup);
  void goToTutorial() => go(AppRoutes.tutorial);
}

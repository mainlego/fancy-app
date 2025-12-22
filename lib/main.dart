import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/supabase_config.dart';
import 'core/services/pwa_update_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/fcm_service.dart';
import 'features/chats/domain/models/chat_model.dart';
import 'shared/widgets/pwa_update_dialog.dart';

Future<void> main() async {
  // Initialize binding BEFORE runZonedGuarded to avoid zone mismatch
  WidgetsFlutterBinding.ensureInitialized();

  // Set up Flutter error handling
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('🔴 Flutter Error: ${details.exception}');
    debugPrint('🔴 Stack: ${details.stack}');
  };

  // Use runZonedGuarded only for catching async errors
  runZonedGuarded(
    () async {
      // Initialize Supabase
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      // Set current user ID for MessageModel
      MessageModel.currentUserId = Supabase.instance.client.auth.currentUser?.id;

      // Listen for auth changes to update currentUserId and save FCM token
      Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
        MessageModel.currentUserId = data.session?.user.id;
        // Save FCM token when user signs in
        if (data.event == AuthChangeEvent.signedIn) {
          try {
            await FcmService().saveTokenToSupabase();
          } catch (e) {
            debugPrint('Error saving FCM token: $e');
          }
        }
      });

      // Set system UI overlay style for dark theme
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.light,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      );

      // Enable edge-to-edge mode (hide system navigation bar)
      SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
      );

      // Lock orientation to portrait for mobile-first experience
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize PWA services for web
      if (kIsWeb) {
        PwaUpdateService().init();
      }

      // Initialize notification service for all platforms
      await NotificationService().init();

      // Initialize Firebase Cloud Messaging for push notifications (all platforms)
      await FcmService().init();

      runApp(
        const ProviderScope(
          child: FancyApp(),
        ),
      );
    },
    (error, stackTrace) {
      debugPrint('🔴 Uncaught Error: $error');
      debugPrint('🔴 Stack: $stackTrace');
    },
  );
}

/// FANCY Dating App
class FancyApp extends StatelessWidget {
  const FancyApp({super.key});

  @override
  Widget build(BuildContext context) {
    Widget app = MaterialApp.router(
      title: 'FANCY',
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // Routing
      routerConfig: appRouter,

      // Localization
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ru'),
      ],

      // Scroll behavior for web
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(),
      ),
    );

    // Wrap with PWA update listener for web
    if (kIsWeb) {
      app = PwaUpdateListener(child: app);
    }

    return app;
  }
}

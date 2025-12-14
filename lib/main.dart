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
import 'features/chats/domain/models/chat_model.dart';
import 'shared/widgets/pwa_update_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Set current user ID for MessageModel
  MessageModel.currentUserId = Supabase.instance.client.auth.currentUser?.id;

  // Listen for auth changes to update currentUserId
  Supabase.instance.client.auth.onAuthStateChange.listen((data) {
    MessageModel.currentUserId = data.session?.user.id;
  });

  // Set system UI overlay style for dark theme
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Lock orientation to portrait for mobile-first experience
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize PWA services for web
  if (kIsWeb) {
    PwaUpdateService().init();
    // Initialize notification service and request permission
    await NotificationService().init();
  }

  runApp(
    const ProviderScope(
      child: FancyApp(),
    ),
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

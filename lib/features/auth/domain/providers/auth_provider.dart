import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';

/// Web Client ID for Google Sign-In (from Google Cloud Console)
const String _webClientId = '918196345376-dm97cbi45s3hng0ud0063beroka84blm.apps.googleusercontent.com';

/// iOS Client ID for Google Sign-In (from Google Cloud Console)
/// TODO: Replace with your actual iOS Client ID from Google Cloud Console
const String _iosClientId = 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com';

/// Auth state enum
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state model
class AuthStateModel {
  final AuthState state;
  final User? user;
  final String? errorMessage;

  const AuthStateModel({
    this.state = AuthState.initial,
    this.user,
    this.errorMessage,
  });

  AuthStateModel copyWith({
    AuthState? state,
    User? user,
    String? errorMessage,
  }) {
    return AuthStateModel(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => state == AuthState.authenticated && user != null;
  bool get isLoading => state == AuthState.loading;
}

/// Auth notifier
class AuthNotifier extends StateNotifier<AuthStateModel> {
  final SupabaseService _supabase;

  AuthNotifier(this._supabase) : super(const AuthStateModel()) {
    _init();
  }

  void _init() {
    // Check current session
    final currentUser = _supabase.currentUser;
    if (currentUser != null) {
      state = AuthStateModel(
        state: AuthState.authenticated,
        user: currentUser,
      );
    } else {
      state = const AuthStateModel(state: AuthState.unauthenticated);
    }

    // Listen to auth state changes
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      switch (event) {
        case AuthChangeEvent.signedIn:
          state = AuthStateModel(
            state: AuthState.authenticated,
            user: session?.user,
          );
          break;
        case AuthChangeEvent.signedOut:
          state = const AuthStateModel(state: AuthState.unauthenticated);
          break;
        case AuthChangeEvent.tokenRefreshed:
          if (session?.user != null) {
            state = AuthStateModel(
              state: AuthState.authenticated,
              user: session?.user,
            );
          }
          break;
        case AuthChangeEvent.userUpdated:
          state = state.copyWith(user: session?.user);
          break;
        default:
          break;
      }
    });
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    String? name,
  }) async {
    state = state.copyWith(state: AuthState.loading, errorMessage: null);

    try {
      final response = await _supabase.signUp(
        email: email,
        password: password,
        data: name != null ? {'name': name} : null,
      );

      if (response.user != null) {
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = const AuthStateModel(
          state: AuthState.unauthenticated,
          errorMessage: 'Registration failed',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(state: AuthState.loading, errorMessage: null);

    try {
      final response = await _supabase.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = const AuthStateModel(
          state: AuthState.unauthenticated,
          errorMessage: 'Invalid credentials',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(state: AuthState.loading);
    try {
      await _supabase.signOut();
      state = const AuthStateModel(state: AuthState.unauthenticated);
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      await _supabase.resetPassword(email);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(state: AuthState.loading, errorMessage: null);

    try {
      // For web, use Supabase OAuth redirect flow
      if (kIsWeb) {
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: Uri.base.origin,
        );
        // The page will redirect, auth state will be handled by onAuthStateChange
        return true;
      }

      // For mobile, use Google Sign-In package
      final googleSignIn = GoogleSignIn(
        clientId: _iosClientId,
        serverClientId: _webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        state = const AuthStateModel(state: AuthState.unauthenticated);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        state = const AuthStateModel(
          state: AuthState.error,
          errorMessage: 'Failed to get Google credentials',
        );
        return false;
      }

      // Sign in to Supabase with Google credentials
      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: response.user,
        );
        return true;
      } else {
        state = const AuthStateModel(
          state: AuthState.error,
          errorMessage: 'Failed to sign in with Google',
        );
        return false;
      }
    } on AuthException catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthStateModel>((ref) {
  final supabase = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabase);
});

/// Is authenticated provider (shortcut)
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// Current user id provider
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.id;
});

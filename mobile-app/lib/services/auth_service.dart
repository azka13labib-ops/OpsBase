import 'package:supabase_flutter/supabase_flutter.dart';
import '../config.dart';

class AuthService {
  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> init() async {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }

  static bool get isLoggedIn => _client.auth.currentSession != null;

  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  static User? get currentUser => _client.auth.currentUser;

  /// Membuka browser/webview untuk login Discord.
  /// Setelah sukses, Supabase otomatis menangkap redirect dan mengisi session.
  static Future<void> loginWithDiscord() async {
    await _client.auth.signInWithOAuth(
      OAuthProvider.discord,
      redirectTo: AppConfig.oauthRedirectUrl,
    );
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}

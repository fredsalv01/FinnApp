import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import 'supabase_service.dart';
import 'sync_service.dart';

class AuthService {
  static final _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  bool _initialized = false;

  bool get isSignedIn => SupabaseService.isSignedIn;
  String? get userEmail => SupabaseService.userEmail;
  String? get userName => SupabaseService.userName;
  String? get avatarUrl => SupabaseService.userAvatarUrl;

  Stream<AuthState> get onAuthStateChange =>
      SupabaseService.client.auth.onAuthStateChange;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: AppConfig.googleWebClientId,
    );
    _initialized = true;
  }

  Future<SignInResult> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      final account = await GoogleSignIn.instance.authenticate();
      // In google_sign_in 7.x, authentication is synchronous (not a Future)
      final googleAuth = account.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) return SignInResult.error;

      final response = await SupabaseService.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        // accessToken removed in google_sign_in 7.x
      );

      if (response.user == null) return SignInResult.error;

      await SyncService().uploadAll();
      await SyncService().pullAll();

      return SignInResult.success;
    } on Exception catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') || msg.contains('sign_in_cancel')) {
        return SignInResult.cancelled;
      }
      return SignInResult.error;
    }
  }

  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await SupabaseService.client.auth.signOut();
  }
}

enum SignInResult { success, cancelled, error }

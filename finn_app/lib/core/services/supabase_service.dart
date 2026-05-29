import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class SupabaseService {
  static bool get _isConfigured =>
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty;

  static SupabaseClient get client => Supabase.instance.client;
  static User? get currentUser =>
      _isConfigured ? client.auth.currentUser : null;
  static bool get isSignedIn => currentUser != null;
  static String? get userId => currentUser?.id;
  static String? get userEmail => currentUser?.email;
  static String? get userAvatarUrl =>
      currentUser?.userMetadata?['avatar_url'] as String?;
  static String? get userName =>
      currentUser?.userMetadata?['full_name'] as String?;
}

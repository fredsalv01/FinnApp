class AppConfig {
  // Baked at compile-time via --dart-define-from-file=dart_defines.json
  // Never hardcoded in source — dart_defines.json is in .gitignore
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
}

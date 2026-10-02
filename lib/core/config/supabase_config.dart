/// Supabase configuration.
///
/// Replace these values with your own Supabase project credentials.
/// For production, consider using --dart-define or .env file.
class SupabaseConfig {
  const SupabaseConfig._();

  /// Your Supabase project URL (e.g. https://xxxx.supabase.co)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://YOUR_PROJECT.supabase.co',
  );

  /// Your Supabase anon/public key
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'YOUR_ANON_KEY',
  );

  /// Cloudflare R2 public endpoint for model downloads (optional).
  /// If using pre-signed URLs via edge functions, this can be empty.
  static const String r2PublicUrl = String.fromEnvironment(
    'R2_PUBLIC_URL',
    defaultValue: '',
  );
}

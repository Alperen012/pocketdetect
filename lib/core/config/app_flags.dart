/// Compile-time feature switches, set with `--dart-define`.
class AppFlags {
  const AppFlags._();

  /// The online model marketplace and user accounts (Supabase). Off by
  /// default: the app then needs no account and no network. Enable with
  /// `--dart-define=MARKETPLACE=true` together with the Supabase defines.
  static const bool marketplace = bool.fromEnvironment('MARKETPLACE');
}

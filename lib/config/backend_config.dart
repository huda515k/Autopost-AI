/// Backend configuration for auto-posting.
///
/// Set [baseUrl] to your deployed AutoPost AI backend (the `server/` folder),
/// e.g. 'https://autopost-ai.onrender.com'. Leave it empty to disable
/// auto-posting — the app then falls back to the OS share sheet.
///
/// This is NOT a secret (it's just a URL), so it's safe to commit.
class BackendConfig {
  static const String baseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: '',
  );

  static bool get isConfigured => baseUrl.trim().isNotEmpty;
}

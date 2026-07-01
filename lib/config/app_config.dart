/// App-wide configuration for switching between the local demo backend and a
/// real HTTP backend (FastAPI).
///
/// Flip [useBackend] to `true` (and set [apiBaseUrl]) once your FastAPI server
/// is running. Until then the app uses local browser storage so it works with
/// no backend at all.
///
/// You can override these at build time without editing code:
///   flutter run -d chrome \
///     --dart-define=USE_BACKEND=true \
///     --dart-define=API_BASE_URL=http://localhost:8000
class AppConfig {
  static const bool useBackend =
      bool.fromEnvironment('USE_BACKEND', defaultValue: false);

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Google OAuth Web Client ID (from Google Cloud Console → Credentials).
  /// Required for real Google Sign-In on the web. Empty = demo login.
  static const String googleClientId =
      String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
}

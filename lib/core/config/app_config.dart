/// Global configuration for the LifeLine app.
class AppConfig {
  AppConfig._();

  // ── DEV_ONLY: Set to false for production builds ──
  static const bool devMode = true;

  /// Backend API base URL.
  /// - Physical device: use localhost + `adb reverse tcp:8080 tcp:8080`
  /// - Android emulator: use http://10.0.2.2:8080/api/v1
  /// - Production: use https://api.lifeline.app/api/v1
  static const String baseUrl = 'http://localhost:8080/api/v1'; // Physical device via adb reverse
  // static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator → localhost
  // static const String baseUrl = 'https://api.lifeline.app/api/v1'; // Production

  /// Master switch for Google Maps.
  /// Set to `true` once a real API key is in place.
  static const bool enableMaps = true;

  /// Request timeout in seconds.
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// Hospital heartbeat interval in seconds.
  static const int heartbeatIntervalSeconds = 30;
}

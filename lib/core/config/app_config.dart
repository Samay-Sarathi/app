/// Global configuration for the LifeLine app.
class AppConfig {
  AppConfig._();

  /// Backend API base URL.
  /// Switch to production URL before release.
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1'; // Android emulator → localhost
  // static const String baseUrl = 'http://localhost:8080/api/v1'; // iOS simulator
  // static const String baseUrl = 'https://api.lifeline.app/api/v1'; // Production

  /// Master switch for Google Maps.
  /// Set to `true` once a real API key is in place.
  static const bool enableMaps = false;

  /// Request timeout in seconds.
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// Hospital heartbeat interval in seconds.
  static const int heartbeatIntervalSeconds = 30;
}

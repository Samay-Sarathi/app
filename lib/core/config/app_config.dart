import 'dart:io' show Platform;

/// Global configuration for the LifeLine app.
class AppConfig {
  AppConfig._();

  // ── DEV_ONLY: Set to false for production builds ──
  static const bool devMode = true;

  /// Override the backend host IP for iOS dev builds via:
  ///   flutter run --dart-define=DEV_HOST=192.168.x.x
  /// Android uses localhost (adb reverse), iOS needs the Mac's LAN IP.
  /// Production: https://api.lifeline.app/api/v1
  static const String _devHost =
      String.fromEnvironment('DEV_HOST', defaultValue: 'localhost');

  static final String baseUrl = devMode
      ? (Platform.isAndroid
          ? 'http://localhost:8080/api/v1'
          : 'http://$_devHost:8080/api/v1')
      : 'https://api.lifeline.app/api/v1';

  /// Master switch for Google Maps.
  /// Set to `true` once a real API key is in place.
  static const bool enableMaps = true;

  /// Google Maps Directions API key.
  /// DEV_ONLY: Move to dart-define or a secrets manager for production.
  static const String googleMapsApiKey =
      String.fromEnvironment('GOOGLE_MAPS_API_KEY', defaultValue: 'AIzaSyDzHb1NgOgvFx57hrthDDicKpAw03XY_V4');

  /// Request timeout in seconds.
  static const int connectTimeout = 10;
  static const int receiveTimeout = 15;

  /// Hospital heartbeat interval in seconds.
  static const int heartbeatIntervalSeconds = 30;
}

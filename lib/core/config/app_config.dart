/// Global feature flags for the LifeLine app.
///
/// Set [enableMaps] to `true` only when a valid Google Maps API key
/// is configured in AndroidManifest.xml / AppDelegate.
/// When `false`, all map screens show a styled placeholder instead,
/// avoiding native Maps SDK initialization that crashes emulators.
class AppConfig {
  AppConfig._();

  /// Master switch for Google Maps.
  /// Set to `true` once a real API key is in place.
  static const bool enableMaps = false;
}

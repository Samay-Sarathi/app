import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted app settings via SharedPreferences.
///
/// Call [init] once before runApp to restore saved values.
class SettingsProvider extends ChangeNotifier {
  static const _keyThemeMode = 'settings_theme_mode';
  static const _keyHaptics = 'settings_haptics';
  static const _keyVoiceAlerts = 'settings_voice_alerts';
  static const _keyAutoSync = 'settings_auto_sync';
  static const _keySound = 'settings_sound';
  static const _keyAutoAccept = 'settings_auto_accept';
  static const _keyUseKmh = 'settings_use_kmh';
  static const _keyCountdown = 'settings_countdown';

  late final SharedPreferences _prefs;

  /// Must be called once at app startup before runApp.
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _themeMode = _prefs.getBool(_keyThemeMode) == true ? ThemeMode.dark : ThemeMode.light;
    _hapticsEnabled = _prefs.getBool(_keyHaptics) ?? true;
    _voiceAlertsEnabled = _prefs.getBool(_keyVoiceAlerts) ?? false;
    _autoSyncEnabled = _prefs.getBool(_keyAutoSync) ?? true;
    _soundEnabled = _prefs.getBool(_keySound) ?? true;
    _autoAcceptEnabled = _prefs.getBool(_keyAutoAccept) ?? true;
    _useKmh = _prefs.getBool(_keyUseKmh) ?? true;
    _countdownSeconds = _prefs.getInt(_keyCountdown) ?? 15;
  }

  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleDarkMode(bool enabled) {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    _prefs.setBool(_keyThemeMode, enabled);
    notifyListeners();
  }

  // Haptics
  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  void toggleHaptics(bool enabled) {
    _hapticsEnabled = enabled;
    _prefs.setBool(_keyHaptics, enabled);
    notifyListeners();
  }

  // Voice Alerts
  bool _voiceAlertsEnabled = false;
  bool get voiceAlertsEnabled => _voiceAlertsEnabled;

  void toggleVoiceAlerts(bool enabled) {
    _voiceAlertsEnabled = enabled;
    _prefs.setBool(_keyVoiceAlerts, enabled);
    notifyListeners();
  }

  // Auto-Sync Vitals
  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void toggleAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    _prefs.setBool(_keyAutoSync, enabled);
    notifyListeners();
  }

  // Sound Alerts
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    _prefs.setBool(_keySound, enabled);
    notifyListeners();
  }

  // Auto-Accept Emergency (hospital)
  bool _autoAcceptEnabled = true;
  bool get autoAcceptEnabled => _autoAcceptEnabled;

  void toggleAutoAccept(bool enabled) {
    _autoAcceptEnabled = enabled;
    _prefs.setBool(_keyAutoAccept, enabled);
    notifyListeners();
  }

  // Speed Unit (km/h vs mph)
  bool _useKmh = true;
  bool get useKmh => _useKmh;
  String get speedUnit => _useKmh ? 'km/h' : 'mph';

  void toggleSpeedUnit(bool useKmh) {
    _useKmh = useKmh;
    _prefs.setBool(_keyUseKmh, useKmh);
    notifyListeners();
  }

  // Emergency countdown seconds
  int _countdownSeconds = 15;
  int get countdownSeconds => _countdownSeconds;

  void setCountdown(int seconds) {
    _countdownSeconds = seconds.clamp(5, 30);
    _prefs.setInt(_keyCountdown, _countdownSeconds);
    notifyListeners();
  }
}

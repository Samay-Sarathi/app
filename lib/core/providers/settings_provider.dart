import 'package:flutter/material.dart';

class SettingsProvider extends ChangeNotifier {
  // Theme
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void toggleDarkMode(bool enabled) {
    _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Haptics
  bool _hapticsEnabled = true;
  bool get hapticsEnabled => _hapticsEnabled;

  void toggleHaptics(bool enabled) {
    _hapticsEnabled = enabled;
    notifyListeners();
  }

  // Voice Alerts
  bool _voiceAlertsEnabled = false;
  bool get voiceAlertsEnabled => _voiceAlertsEnabled;

  void toggleVoiceAlerts(bool enabled) {
    _voiceAlertsEnabled = enabled;
    notifyListeners();
  }

  // Auto-Sync Vitals
  bool _autoSyncEnabled = true;
  bool get autoSyncEnabled => _autoSyncEnabled;

  void toggleAutoSync(bool enabled) {
    _autoSyncEnabled = enabled;
    notifyListeners();
  }

  // Sound Alerts
  bool _soundEnabled = true;
  bool get soundEnabled => _soundEnabled;

  void toggleSound(bool enabled) {
    _soundEnabled = enabled;
    notifyListeners();
  }

  // Auto-Accept Emergency (hospital)
  bool _autoAcceptEnabled = true;
  bool get autoAcceptEnabled => _autoAcceptEnabled;

  void toggleAutoAccept(bool enabled) {
    _autoAcceptEnabled = enabled;
    notifyListeners();
  }

  // Speed Unit (km/h vs mph)
  bool _useKmh = true;
  bool get useKmh => _useKmh;
  String get speedUnit => _useKmh ? 'km/h' : 'mph';

  void toggleSpeedUnit(bool useKmh) {
    _useKmh = useKmh;
    notifyListeners();
  }

  // Emergency countdown seconds
  int _countdownSeconds = 15;
  int get countdownSeconds => _countdownSeconds;

  void setCountdown(int seconds) {
    _countdownSeconds = seconds.clamp(5, 30);
    notifyListeners();
  }
}

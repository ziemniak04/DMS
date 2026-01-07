import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings Provider
/// Manages app-wide settings including theme preference
class SettingsProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  static const String _glucoseUnitKey = 'glucose_unit';
  static const String _alertSoundKey = 'alert_sound_enabled';
  static const String _alertVibrationKey = 'alert_vibration_enabled';

  ThemeMode _themeMode = ThemeMode.system;
  String _glucoseUnit = 'mg/dL';
  bool _alertSoundEnabled = true;
  bool _alertVibrationEnabled = true;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  String get glucoseUnit => _glucoseUnit;
  bool get alertSoundEnabled => _alertSoundEnabled;
  bool get alertVibrationEnabled => _alertVibrationEnabled;

  SettingsProvider() {
    _initializeSettings();
  }

  /// Initialize settings from SharedPreferences
  void _initializeSettings() {
    if (_isInitialized) return;
    _loadSettingsSync();
  }

  /// Load settings synchronously on first creation
  void _loadSettingsSync() {
    // This will be called immediately, load defaults
    // actual async load will happen in background
    _isInitialized = true;
    _loadSettings();
  }

  /// Load settings from SharedPreferences asynchronously
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final themeModeValue = prefs.getString(_themeKey) ?? 'system';
      _themeMode = _parseThemeMode(themeModeValue);
      
      _glucoseUnit = prefs.getString(_glucoseUnitKey) ?? 'mg/dL';
      _alertSoundEnabled = prefs.getBool(_alertSoundKey) ?? true;
      _alertVibrationEnabled = prefs.getBool(_alertVibrationKey) ?? true;
      
      notifyListeners();
    } catch (e) {
      // Use defaults if SharedPreferences fails
      print('Error loading settings: $e');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, _themeModeToString(mode));
    notifyListeners();
  }

  /// Set glucose unit
  Future<void> setGlucoseUnit(String unit) async {
    _glucoseUnit = unit;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_glucoseUnitKey, unit);
    notifyListeners();
  }

  /// Set alert sound
  Future<void> setAlertSoundEnabled(bool enabled) async {
    _alertSoundEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertSoundKey, enabled);
    notifyListeners();
  }

  /// Set alert vibration
  Future<void> setAlertVibrationEnabled(bool enabled) async {
    _alertVibrationEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_alertVibrationKey, enabled);
    notifyListeners();
  }

  /// Helper to parse theme mode from string
  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  /// Helper to convert theme mode to string
  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}

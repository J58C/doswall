import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  static const _themeModeKey = 'themeModeAppV1';
  ThemeMode _themeMode;

  ThemeNotifier(this._themeMode);

  ThemeMode get themeMode => _themeMode;

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      debugPrint('ThemeNotifier: Error saving theme preference: $e');
    }
  }

  void toggleTheme(Brightness currentActualBrightness) {
    if (_themeMode == ThemeMode.system) {
      if (currentActualBrightness == Brightness.light) {
        setThemeMode(ThemeMode.dark);
      } else {
        setThemeMode(ThemeMode.light);
      }
    } else if (_themeMode == ThemeMode.light) {
      setThemeMode(ThemeMode.dark);
    } else {
      setThemeMode(ThemeMode.light);
    }
  }

  static Future<ThemeNotifier> create() async {
    ThemeMode initialMode = ThemeMode.system;
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeModeKey);
      if (themeIndex != null && themeIndex >= 0 && themeIndex < ThemeMode.values.length) {
        initialMode = ThemeMode.values[themeIndex];
      }
    } catch (e) {
      debugPrint('ThemeNotifier: Error loading theme preference, defaulting to system: $e');
    }
    return ThemeNotifier(initialMode);
  }
}
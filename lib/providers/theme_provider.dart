import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

/// Manages the app-wide theme mode (light / dark / system).
///
/// Persists the user's preference to Hive so it survives app restarts.
/// Consumed by [DostokApp] to set [MaterialApp.themeMode].
class ThemeProvider extends ChangeNotifier {
  static const String _boxName = 'settings';
  static const String _themeModeKey = 'themeMode';

  ThemeMode _themeMode = ThemeMode.light;

  // ---------------------------------------------------------------------------
  // Getters
  // ---------------------------------------------------------------------------

  /// The current theme mode.
  ThemeMode get themeMode => _themeMode;

  /// Whether the active theme is dark.
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Whether the theme follows the system setting.
  bool get isSystemMode => _themeMode == ThemeMode.system;

  // ---------------------------------------------------------------------------
  // Initialization
  // ---------------------------------------------------------------------------

  /// Loads the persisted theme preference from Hive.
  ///
  /// Falls back to [ThemeMode.light] if no preference is stored.
  Future<void> loadTheme() async {
    try {
      final box = await Hive.openBox(_boxName);
      final stored = box.get(_themeModeKey) as String?;

      if (stored != null) {
        _themeMode = ThemeMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => ThemeMode.light,
        );
      }
    } catch (e, st) {
      dev.log('ThemeProvider.loadTheme failed', error: e, stackTrace: st);
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Theme toggling
  // ---------------------------------------------------------------------------

  /// Toggles between light and dark mode.
  ///
  /// If the current mode is [ThemeMode.system], toggles to dark.
  void toggleTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.system:
        _themeMode = ThemeMode.dark;
        break;
    }
    _persistTheme();
    notifyListeners();
  }

  /// Sets the theme mode to a specific value.
  void setThemeMode(ThemeMode mode) {
    if (_themeMode == mode) return;
    _themeMode = mode;
    _persistTheme();
    notifyListeners();
  }

  /// Convenience setter for boolean dark-mode toggle from settings UI.
  set isDarkMode(bool value) {
    setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Persists the current theme mode to Hive.
  Future<void> _persistTheme() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_themeModeKey, _themeMode.name);
    } catch (e, st) {
      dev.log('ThemeProvider._persistTheme failed', error: e, stackTrace: st);
    }
  }
}

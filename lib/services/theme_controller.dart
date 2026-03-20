import 'package:flutter/material.dart';

import 'settings_service.dart';

class ThemeController extends ChangeNotifier {
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  Future<void> loadThemePreference() async {
    _isDarkMode = await _settingsService.getDarkMode();
    notifyListeners();
  }

  Future<void> setDarkMode(bool isDarkMode) async {
    if (_isDarkMode == isDarkMode) return;
    _isDarkMode = isDarkMode;
    notifyListeners();
    await _settingsService.setDarkMode(isDarkMode);
  }
}
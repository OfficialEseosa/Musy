import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _usernameKey = 'username';
  static const String _darkModeKey = 'darkMode';
  static const String _timerDurationKey = 'timerDuration';

  // --- Username ---

  Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey) ?? 'Player';
  }

  Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
  }

  // --- Dark Mode ---

  Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? false;
  }

  Future<void> setDarkMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDark);
  }

  // --- Timer Duration ---

  Future<int> getTimerDuration() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_timerDurationKey) ?? 30;
  }

  Future<void> setTimerDuration(int seconds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_timerDurationKey, seconds);
  }
}

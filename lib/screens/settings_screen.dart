import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _usernameController;
  final SettingsService _settingsService = SettingsService();
  bool _isDarkMode = false;
  int _timerDuration = 30;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final username = await _settingsService.getUsername();
    final isDarkMode = await _settingsService.getDarkMode();
    final timerDuration = await _settingsService.getTimerDuration();

    setState(() {
      _usernameController.text = username;
      _isDarkMode = isDarkMode;
      _timerDuration = timerDuration;
      _isLoading = false;
    });
  }

  Future<void> _saveUsername(String username) async {
    await _settingsService.setUsername(username);
  }

  Future<void> _saveDarkMode(bool isDark) async {
    await _settingsService.setDarkMode(isDark);
  }

  Future<void> _saveTimerDuration(int seconds) async {
    await _settingsService.setTimerDuration(seconds);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Username Section
          const SizedBox(height: 8.0),
          const Text(
            'Username',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          TextField(
            controller: _usernameController,
            decoration: InputDecoration(
              hintText: 'Enter your username',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              prefixIcon: const Icon(Icons.person),
            ),
            onChanged: (value) {
              _saveUsername(value);
            },
          ),
          const SizedBox(height: 32.0),

          // Dark Mode Section
          const Text(
            'Display',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Enable dark theme for the app'),
            value: _isDarkMode,
            onChanged: (bool value) {
              setState(() {
                _isDarkMode = value;
              });
              _saveDarkMode(value);
            },
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 32.0),

          // Timer Duration Section
          const Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8.0),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Question Timer'),
            subtitle: Text('${_timerDuration} seconds per question'),
            trailing: const Icon(Icons.timer),
          ),
          Slider(
            value: _timerDuration.toDouble(),
            min: 15.0,
            max: 60.0,
            divisions: 9, // (60 - 15) / 5 = 9 divisions
            label: '${_timerDuration}s',
            onChanged: (double value) {
              setState(() {
                _timerDuration = value.toInt();
              });
            },
            onChangeEnd: (double value) {
              _saveTimerDuration(value.toInt());
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '15s',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                '60s',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import 'game_mode_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final SettingsService _settingsService = SettingsService();

  String _username = 'Player';
  int _totalGames = 0;
  int _bestScore = 0;
  int _totalCorrect = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final username = await _settingsService.getUsername();
    final sessions = await _db.getAllSessions();

    int bestScore = 0;
    int totalCorrect = 0;
    for (final s in sessions) {
      final score = s['score'] as int;
      final correct = s['correctAnswers'] as int;
      if (score > bestScore) bestScore = score;
      totalCorrect += correct;
    }

    setState(() {
      _username = username;
      _totalGames = sessions.length;
      _bestScore = bestScore;
      _totalCorrect = totalCorrect;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Musy'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadData(); // refresh username after returning
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                children: [
                  // Branding
                  Column(
                    children: [
                      Icon(Icons.music_note, size: 72, color: colorScheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Musy',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Welcome back, $_username!',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Stats cards
                  Row(
                    children: [
                      _StatCard(
                        label: 'Total Games',
                        value: '$_totalGames',
                        icon: Icons.sports_esports,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Best Score',
                        value: '$_bestScore',
                        icon: Icons.emoji_events,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 12),
                      _StatCard(
                        label: 'Correct',
                        value: '$_totalCorrect',
                        icon: Icons.check_circle,
                        color: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Play button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text(
                        'Play',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GameModeScreen()),
                        ).then((_) => _loadData());
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

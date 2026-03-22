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
  int _topStreak = 0;
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
    int topStreak = 0;
    for (final s in sessions) {
      final score = s['score'] as int;
      final correct = s['correctAnswers'] as int;
      final streak = s['highestStreak'] as int;
      if (score > bestScore) bestScore = score;
      if (streak > topStreak) topStreak = streak;
      totalCorrect += correct;
    }

    setState(() {
      _username = username;
      _totalGames = sessions.length;
      _bestScore = bestScore;
      _totalCorrect = totalCorrect;
      _topStreak = topStreak;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Musy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadData();
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 24.0),
                children: [
                  // Branding section
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colorScheme.primary,
                                colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.music_note,
                              size: 48, color: Colors.white),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Welcome to Musy',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hey $_username! Ready to play?',
                          style: Theme.of(context)
                              .textTheme
                              .bodyLarge
                              ?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Current stats row (streak + total points)
                  Row(
                    children: [
                      Expanded(
                        child: _HighlightCard(
                          label: 'Current Streak',
                          value: '🔥 $_topStreak',
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HighlightCard(
                          label: 'Total Points',
                          value: '$_bestScore pts',
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Play button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      icon:
                          const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text(
                        'Play',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const GameModeScreen()),
                        ).then((_) => _loadData());
                      },
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Quick Stats section
                  Text(
                    'Quick Stats',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _StatCard(
                        label: 'Games\nPlayed',
                        value: '$_totalGames',
                        icon: Icons.sports_esports,
                        color: Colors.deepPurple,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Best\nScore',
                        value: '$_bestScore',
                        icon: Icons.emoji_events,
                        color: Colors.amber.shade700,
                      ),
                      const SizedBox(width: 10),
                      _StatCard(
                        label: 'Top\nStreak',
                        value: '$_topStreak',
                        icon: Icons.local_fire_department,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    'Offline-first · No cloud storage used',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _HighlightCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HighlightCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 14.0, horizontal: 8.0),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
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

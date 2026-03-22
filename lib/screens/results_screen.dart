import 'package:flutter/material.dart';
import '../models/game_session.dart';
import '../models/leaderboard_entry.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import 'game_mode_screen.dart';

class ResultsScreen extends StatefulWidget {
  final int score;
  final int correctAnswers;
  final int totalQuestions;
  final int highestStreak;
  final String gameMode;

  const ResultsScreen({
    super.key,
    required this.score,
    required this.correctAnswers,
    required this.totalQuestions,
    required this.highestStreak,
    required this.gameMode,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  bool _isNewHighScore = false;
  bool _isSaving = true;

  @override
  void initState() {
    super.initState();
    _saveSession();
  }

  Future<void> _saveSession() async {
    final db = DatabaseHelper.instance;
    final settings = SettingsService();

    // Check for high score
    final previousBest = await db.getBestScoreByMode(widget.gameMode);
    if (previousBest == null || widget.score > previousBest) {
      _isNewHighScore = true;
    }

    // Save session
    final session = GameSession(
      gameMode: widget.gameMode,
      score: widget.score,
      totalQuestions: widget.totalQuestions,
      correctAnswers: widget.correctAnswers,
      highestStreak: widget.highestStreak,
      datePlayed: DateTime.now().toIso8601String(),
    );
    await db.insertSessionModel(session);

    // Save leaderboard entry
    final username = await settings.getUsername();
    final entry = LeaderboardEntry(
      playerName: username,
      gameMode: widget.gameMode,
      score: widget.score,
      datePlayed: DateTime.now().toIso8601String(),
    );
    await db.insertLeaderboardEntryModel(entry);

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final percentage = widget.totalQuestions > 0
        ? ((widget.correctAnswers / widget.totalQuestions) * 100).round()
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Results'),
        automaticallyImplyLeading: false,
      ),
      body: _isSaving
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // High score badge
                  if (_isNewHighScore) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('🏆', style: TextStyle(fontSize: 24)),
                          SizedBox(width: 8),
                          Text(
                            'New High Score!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Score display
                  Text(
                    '${widget.score}',
                    style: const TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                  const Text(
                    'points',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),

                  // Stats cards
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Correct',
                          value: '${widget.correctAnswers}/${widget.totalQuestions}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Accuracy',
                          value: '$percentage%',
                          icon: Icons.percent,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Best Streak',
                          value: '${widget.highestStreak}',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Mode',
                          value: widget.gameMode.split(' ').first,
                          icon: Icons.category,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Action buttons
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GameModeScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home),
                      label: const Text('Go Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

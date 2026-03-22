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

    final previousBest = await db.getBestScoreByMode(widget.gameMode);
    if (previousBest == null || widget.score > previousBest) {
      _isNewHighScore = true;
    }

    final session = GameSession(
      gameMode: widget.gameMode,
      score: widget.score,
      totalQuestions: widget.totalQuestions,
      correctAnswers: widget.correctAnswers,
      highestStreak: widget.highestStreak,
      datePlayed: DateTime.now().toIso8601String(),
    );
    await db.insertSessionModel(session);

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
    final colorScheme = Theme.of(context).colorScheme;
    final percentage = widget.totalQuestions > 0
        ? ((widget.correctAnswers / widget.totalQuestions) * 100).round()
        : 0;
    final incorrectAnswers = widget.totalQuestions - widget.correctAnswers;

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
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.amber.withOpacity(0.5), width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🏆', style: TextStyle(fontSize: 24)),
                          const SizedBox(width: 8),
                          Text(
                            'New High Score!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'No new record',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Final Score
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: colorScheme.primary.withOpacity(0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 24, horizontal: 32),
                      child: Column(
                        children: [
                          Text(
                            'Final Score',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.score}',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                          Text(
                            'pts',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Highest Streak + Correct Answers row
                  Row(
                    children: [
                      Expanded(
                        child: _ResultStat(
                          label: 'Highest Streak',
                          value: 'x${widget.highestStreak}',
                          icon: Icons.local_fire_department,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultStat(
                          label: 'Correct Answers',
                          value:
                              '${widget.correctAnswers} / ${widget.totalQuestions}',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Incorrect answers + accuracy row
                  Row(
                    children: [
                      Expanded(
                        child: _ResultStat(
                          label: 'Incorrect Answers',
                          value:
                              '$incorrectAnswers / ${widget.totalQuestions}',
                          icon: Icons.cancel,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ResultStat(
                          label: 'Accuracy',
                          value: '$percentage%',
                          icon: Icons.percent,
                          color: Colors.blue,
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
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Play Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context)
                            .popUntil((route) => route.isFirst);
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Return Home'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Footer
                  Text(
                    'Session saved locally · SQLite stores session history',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ResultStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

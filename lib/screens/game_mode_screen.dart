import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import 'quiz_screen.dart';

class GameModeScreen extends StatefulWidget {
  const GameModeScreen({super.key});

  @override
  State<GameModeScreen> createState() => _GameModeScreenState();
}

class _GameModeScreenState extends State<GameModeScreen> {
  final List<_ModeInfo> _modes = [
    _ModeInfo(
      name: 'Finish the Lyric',
      description: 'Complete the missing lyrics from popular songs',
      icon: Icons.music_note,
      color: Colors.deepPurple,
    ),
    _ModeInfo(
      name: 'Guess the Artist',
      description: 'Identify the artist behind the hit song',
      icon: Icons.mic,
      color: Colors.teal,
    ),
    _ModeInfo(
      name: 'Name the Song',
      description: 'Name the song from a snippet of its lyrics',
      icon: Icons.library_music,
      color: Colors.orange,
    ),
  ];

  final Map<String, int?> _bestScores = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBestScores();
  }

  Future<void> _loadBestScores() async {
    for (final mode in _modes) {
      final best = await DatabaseHelper.instance.getBestScoreByMode(mode.name);
      _bestScores[mode.name] = best;
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Mode'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _modes.length,
              itemBuilder: (context, index) {
                final mode = _modes[index];
                final bestScore = _bestScores[mode.name];

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizScreen(gameMode: mode.name),
                        ),
                      );
                      // Refresh best scores when returning
                      _loadBestScores();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: mode.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              mode.icon,
                              size: 32,
                              color: mode.color,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  mode.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  mode.description,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                if (bestScore != null) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Best: $bestScore pts',
                                    style: TextStyle(
                                      color: mode.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ModeInfo {
  final String name;
  final String description;
  final IconData icon;
  final Color color;

  _ModeInfo({
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
  });
}

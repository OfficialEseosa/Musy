import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/database_helper.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  String _selectedFilter = 'All Modes';
  List<LeaderboardEntry> _entries = [];
  bool _isLoading = true;

  static const List<String> _filters = [
    'All Modes',
    'Finish the Lyric',
    'Guess the Artist',
    'Name the Song',
  ];

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    setState(() => _isLoading = true);

    final maps = await _db.getLeaderboard(
      gameMode: _selectedFilter == 'All Modes' ? null : _selectedFilter,
    );
    final entries = maps.map((m) => LeaderboardEntry.fromMap(m)).toList();

    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return '${date.month}/${date.day}/${date.year}';
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedFilter = filter);
                      _loadEntries();
                    },
                    selectedColor: colorScheme.primaryContainer,
                    checkmarkColor: colorScheme.primary,
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _entries.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.leaderboard_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 12),
                            Text(
                              'No scores yet. Play a round!',
                              style: TextStyle(
                                  fontSize: 16, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : _buildTable(context),
          ),

          // Footer
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'SQLite stores scores and session history · No cloud storage',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                    width: 40,
                    child: Text('Rank',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(
                    flex: 3,
                    child: Text('Player',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(
                    flex: 2,
                    child: Text('Score',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
                Expanded(
                    flex: 2,
                    child: Text('Date',
                        textAlign: TextAlign.end,
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),

          // Table rows
          ...List.generate(_entries.length, (index) {
            final entry = _entries[index];
            final isFirst = index == 0;

            // Check if this is the latest entry among ties
            bool showLatest = false;
            if (index > 0 &&
                _entries[index - 1].score == entry.score) {
              // Same score as previous — the first one is latest (sorted by date DESC)
            } else if (index < _entries.length - 1 &&
                _entries[index + 1].score == entry.score) {
              showLatest = true; // first among tied scores = latest
            }

            return Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: index.isEven
                    ? Colors.transparent
                    : colorScheme.surfaceContainerHighest.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.15),
                  ),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isFirst ? Colors.amber[700] : null,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.playerName,
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${entry.score}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isFirst ? colorScheme.primary : null,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(entry.datePlayed),
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        if (showLatest)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Text(
                              'Latest',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

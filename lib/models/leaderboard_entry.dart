class LeaderboardEntry {
  final int? id;
  final String playerName;
  final String gameMode;
  final int score;
  final String datePlayed;

  LeaderboardEntry({
    this.id,
    required this.playerName,
    required this.gameMode,
    required this.score,
    required this.datePlayed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerName': playerName,
      'gameMode': gameMode,
      'score': score,
      'datePlayed': datePlayed,
    };
  }

  factory LeaderboardEntry.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntry(
      id: map['id'] as int?,
      playerName: map['playerName'] as String,
      gameMode: map['gameMode'] as String,
      score: map['score'] as int,
      datePlayed: map['datePlayed'] as String,
    );
  }
}

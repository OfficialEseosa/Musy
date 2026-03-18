class GameSession {
  final int? id;
  final String gameMode;
  final int score;
  final int totalQuestions;
  final int correctAnswers;
  final int highestStreak;
  final String datePlayed;

  GameSession({
    this.id,
    required this.gameMode,
    required this.score,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.highestStreak,
    required this.datePlayed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'gameMode': gameMode,
      'score': score,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'highestStreak': highestStreak,
      'datePlayed': datePlayed,
    };
  }

  factory GameSession.fromMap(Map<String, dynamic> map) {
    return GameSession(
      id: map['id'] as int?,
      gameMode: map['gameMode'] as String,
      score: map['score'] as int,
      totalQuestions: map['totalQuestions'] as int,
      correctAnswers: map['correctAnswers'] as int,
      highestStreak: map['highestStreak'] as int,
      datePlayed: map['datePlayed'] as String,
    );
  }
}

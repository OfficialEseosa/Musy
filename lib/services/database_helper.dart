import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';
import '../models/game_session.dart';
import '../models/leaderboard_entry.dart';

/// Singleton database helper — one shared instance handles all SQLite calls.
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('musy.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    // version 2 added question_attempts table for tracking performance
    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    // Questions table
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questionText TEXT NOT NULL,
        questionType TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        correctAnswer TEXT NOT NULL,
        optionA TEXT,
        optionB TEXT,
        optionC TEXT,
        optionD TEXT
      )
    ''');

    // Game sessions table
    await db.execute('''
      CREATE TABLE sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        gameMode TEXT NOT NULL,
        score INTEGER NOT NULL,
        totalQuestions INTEGER NOT NULL,
        correctAnswers INTEGER NOT NULL,
        highestStreak INTEGER NOT NULL,
        datePlayed TEXT NOT NULL
      )
    ''');

    // Leaderboard table
    await db.execute('''
      CREATE TABLE leaderboard (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        playerName TEXT NOT NULL,
        gameMode TEXT NOT NULL,
        score INTEGER NOT NULL,
        datePlayed TEXT NOT NULL
      )
    ''');

    // Question attempts table for tracking performance
    await db.execute('''
      CREATE TABLE question_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        questionId INTEGER NOT NULL,
        wasCorrect INTEGER NOT NULL,
        datePlayed TEXT NOT NULL,
        FOREIGN KEY (questionId) REFERENCES questions (id)
      )
    ''');
  }

  Future<void> _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE question_attempts (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          questionId INTEGER NOT NULL,
          wasCorrect INTEGER NOT NULL,
          datePlayed TEXT NOT NULL,
          FOREIGN KEY (questionId) REFERENCES questions (id)
        )
      ''');
    }
  }

  // --- Question CRUD ---

  Future<int> insertQuestion(Map<String, dynamic> question) async {
    final db = await database;
    return await db.insert('questions', question);
  }

  Future<int> insertQuestionModel(Question question) async {
    final map = question.toMap();
    map.remove('id');
    return await insertQuestion(map);
  }

  Future<List<Map<String, dynamic>>> getAllQuestions() async {
    final db = await database;
    return await db.query('questions');
  }

  Future<List<Question>> getQuestionsByMode(String mode) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'questionType = ?',
      whereArgs: [mode],
    );
    return maps.map((map) => Question.fromMap(map)).toList();
  }

  /// Selects quiz questions with a recommendation bias:
  /// 30% of the selection comes from frequently-missed questions,
  /// the rest are random. This helps players practice weak areas.
  Future<List<Question>> getRandomQuestions(String mode, int count) async {
    final weakCount = (count * 0.3).ceil();
    final randomCount = count - weakCount;

    final weakQuestions = await getWeakQuestions(mode, weakCount);
    final weakIds = weakQuestions.map((q) => q.id).toSet();

    final db = await database;
    final allMaps = await db.query(
      'questions',
      where: 'questionType = ?',
      whereArgs: [mode],
      orderBy: 'RANDOM()',
    );
    final allQuestions = allMaps.map((m) => Question.fromMap(m)).toList();

    // Avoid duplicates between weak and random pools
    final remaining = allQuestions.where((q) => !weakIds.contains(q.id)).toList();
    remaining.shuffle();

    final selected = <Question>[...weakQuestions];
    for (final q in remaining) {
      if (selected.length >= count) break;
      selected.add(q);
    }
    selected.shuffle(); // mix so weak questions aren't grouped together
    return selected;
  }

  Future<int> updateQuestion(int id, Map<String, dynamic> question) async {
    final db = await database;
    return await db.update('questions', question, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete('questions', where: 'id = ?', whereArgs: [id]);
  }

  // --- Question Attempts ---

  Future<void> recordAttempt(int questionId, bool wasCorrect) async {
    final db = await database;
    await db.insert('question_attempts', {
      'questionId': questionId,
      'wasCorrect': wasCorrect ? 1 : 0,
      'datePlayed': DateTime.now().toIso8601String(),
    });
  }

  /// Returns questions the player has gotten wrong most often for this mode.
  /// Used for recommendation-based question selection.
  Future<List<Question>> getWeakQuestions(String mode, int count) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT q.*, COUNT(qa.id) as wrongCount
      FROM questions q
      INNER JOIN question_attempts qa ON qa.questionId = q.id
      WHERE q.questionType = ? AND qa.wasCorrect = 0
      GROUP BY q.id
      ORDER BY wrongCount DESC
      LIMIT ?
    ''', [mode, count]);
    return maps.map((m) => Question.fromMap(m)).toList();
  }

  // --- Session CRUD ---

  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('sessions', session);
  }

  Future<int> insertSessionModel(GameSession session) async {
    final map = session.toMap();
    map.remove('id');
    return await insertSession(map);
  }

  Future<List<Map<String, dynamic>>> getAllSessions() async {
    final db = await database;
    return await db.query('sessions', orderBy: 'datePlayed DESC');
  }

  // --- Leaderboard CRUD ---

  Future<int> insertLeaderboardEntry(Map<String, dynamic> entry) async {
    final db = await database;
    return await db.insert('leaderboard', entry);
  }

  Future<int> insertLeaderboardEntryModel(LeaderboardEntry entry) async {
    final map = entry.toMap();
    map.remove('id');
    return await insertLeaderboardEntry(map);
  }

  Future<List<Map<String, dynamic>>> getLeaderboard({String? gameMode}) async {
    final db = await database;
    if (gameMode != null && gameMode != 'All Modes') {
      return await db.query(
        'leaderboard',
        where: 'gameMode = ?',
        whereArgs: [gameMode],
        orderBy: 'score DESC, datePlayed DESC',
      );
    }
    return await db.query('leaderboard', orderBy: 'score DESC, datePlayed DESC');
  }

  // --- Stats Queries ---

  Future<int?> getBestScoreByMode(String mode) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT MAX(score) as bestScore FROM sessions WHERE gameMode = ?',
      [mode],
    );
    if (result.isNotEmpty && result.first['bestScore'] != null) {
      return result.first['bestScore'] as int;
    }
    return null;
  }

  Future<int> getTotalGamesPlayed() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM sessions');
    return result.first['count'] as int;
  }

  Future<int> getOverallBestScore() async {
    final db = await database;
    final result = await db.rawQuery('SELECT MAX(score) as best FROM sessions');
    if (result.isNotEmpty && result.first['best'] != null) {
      return result.first['best'] as int;
    }
    return 0;
  }

  Future<int> getTotalCorrectAnswers() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(correctAnswers) as total FROM sessions',
    );
    if (result.isNotEmpty && result.first['total'] != null) {
      return result.first['total'] as int;
    }
    return 0;
  }

  /// Rule-based AI coach: analyzes session history to generate a personalized tip.
  /// Returns a Map with 'icon', 'title', and 'message' for display.
  Future<Map<String, String>> getPerformanceInsight() async {
    final db = await database;
    final sessions = await getAllSessions();

    // No data yet — encourage the user to play
    if (sessions.isEmpty) {
      return {
        'icon': '🎯',
        'title': 'Ready to start?',
        'message': 'Play your first round and I\'ll start tracking your progress!',
      };
    }

    // Analyze per-mode accuracy
    final modeStats = <String, Map<String, int>>{};
    for (final s in sessions) {
      final mode = s['gameMode'] as String;
      final correct = s['correctAnswers'] as int;
      final total = s['totalQuestions'] as int;
      modeStats[mode] ??= {'correct': 0, 'total': 0, 'games': 0};
      modeStats[mode]!['correct'] = modeStats[mode]!['correct']! + correct;
      modeStats[mode]!['total'] = modeStats[mode]!['total']! + total;
      modeStats[mode]!['games'] = modeStats[mode]!['games']! + 1;
    }

    // Find weakest and strongest modes
    String? weakestMode;
    String? strongestMode;
    double worstAccuracy = 1.0;
    double bestAccuracy = 0.0;

    for (final entry in modeStats.entries) {
      final total = entry.value['total']!;
      if (total == 0) continue;
      final accuracy = entry.value['correct']! / total;
      if (accuracy < worstAccuracy) {
        worstAccuracy = accuracy;
        weakestMode = entry.key;
      }
      if (accuracy > bestAccuracy) {
        bestAccuracy = accuracy;
        strongestMode = entry.key;
      }
    }

    // Check recent trend (last 3 vs previous 3 sessions)
    if (sessions.length >= 6) {
      final recent3 = sessions.sublist(0, 3);
      final prev3 = sessions.sublist(3, 6);
      final recentAvg = recent3.fold<int>(0, (sum, s) => sum + (s['score'] as int)) / 3;
      final prevAvg = prev3.fold<int>(0, (sum, s) => sum + (s['score'] as int)) / 3;

      if (recentAvg > prevAvg * 1.2) {
        return {
          'icon': '📈',
          'title': 'You\'re improving!',
          'message': 'Your recent scores are ${((recentAvg / prevAvg - 1) * 100).round()}% higher than before. Keep it up!',
        };
      } else if (recentAvg < prevAvg * 0.8) {
        return {
          'icon': '💪',
          'title': 'Shake it off!',
          'message': 'Recent scores dipped a bit. Try ${weakestMode ?? "a different mode"} to mix things up.',
        };
      }
    }

    // Suggest weakest mode if accuracy is low
    if (weakestMode != null && worstAccuracy < 0.5) {
      final pct = (worstAccuracy * 100).round();
      return {
        'icon': '🧠',
        'title': 'Focus area: $weakestMode',
        'message': 'You\'re at $pct% accuracy here. The quiz will mix in questions you\'ve missed to help you improve.',
      };
    }

    // Celebrate strong performance
    if (strongestMode != null && bestAccuracy > 0.8) {
      final pct = (bestAccuracy * 100).round();
      return {
        'icon': '⭐',
        'title': 'You\'re crushing $strongestMode!',
        'message': '$pct% accuracy — try a harder mode or challenge your high score!',
      };
    }

    // Default: encourage more play
    final totalGames = sessions.length;
    return {
      'icon': '🎵',
      'title': 'Keep going!',
      'message': 'You\'ve played $totalGames game${totalGames == 1 ? '' : 's'}. Play more to unlock detailed insights.',
    };
  }

  // --- Seed Data ---

  Future<void> seedDefaultQuestions() async {
    final db = await database;
    final count = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM questions'),
    );
    if (count != null && count > 0) return; // already seeded

    final questions = <Map<String, dynamic>>[
      // ---- Finish the Lyric (10) ----
      {
        'questionText': 'Don\'t stop ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'believin\'',
        'optionA': 'believin\'',
        'optionB': 'dreaming',
        'optionC': 'running',
        'optionD': 'thinking',
      },
      {
        'questionText': 'We will, we will ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'rock you',
        'optionA': 'find you',
        'optionB': 'rock you',
        'optionC': 'love you',
        'optionD': 'miss you',
      },
      {
        'questionText': 'Just a small town girl, livin\' in a ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Medium',
        'correctAnswer': 'lonely world',
        'optionA': 'crazy world',
        'optionB': 'lonely world',
        'optionC': 'brand new world',
        'optionD': 'better world',
      },
      {
        'questionText': 'Is this the real life? Is this just ___?',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'fantasy',
        'optionA': 'a dream',
        'optionB': 'fantasy',
        'optionC': 'make believe',
        'optionD': 'imaginary',
      },
      {
        'questionText': 'I\'m on the highway to ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'hell',
        'optionA': 'heaven',
        'optionB': 'nowhere',
        'optionC': 'hell',
        'optionD': 'freedom',
      },
      {
        'questionText': 'Every breath you take, every move you ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Medium',
        'correctAnswer': 'make',
        'optionA': 'fake',
        'optionB': 'take',
        'optionC': 'make',
        'optionD': 'break',
      },
      {
        'questionText': 'Sweet dreams are made of ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Medium',
        'correctAnswer': 'this',
        'optionA': 'love',
        'optionB': 'us',
        'optionC': 'this',
        'optionD': 'gold',
      },
      {
        'questionText': 'We\'re no strangers to ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'love',
        'optionA': 'pain',
        'optionB': 'love',
        'optionC': 'life',
        'optionD': 'fear',
      },
      {
        'questionText': 'I will always ___ you',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Easy',
        'correctAnswer': 'love',
        'optionA': 'need',
        'optionB': 'miss',
        'optionC': 'love',
        'optionD': 'want',
      },
      {
        'questionText': 'Cause baby you\'re a ___',
        'questionType': 'Finish the Lyric',
        'difficulty': 'Medium',
        'correctAnswer': 'firework',
        'optionA': 'superstar',
        'optionB': 'firework',
        'optionC': 'diamond',
        'optionD': 'champion',
      },

      // ---- Guess the Artist (10) ----
      {
        'questionText': 'Who performed "Bohemian Rhapsody"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Queen',
        'optionA': 'The Beatles',
        'optionB': 'Queen',
        'optionC': 'Led Zeppelin',
        'optionD': 'Pink Floyd',
      },
      {
        'questionText': 'Who performed "Thriller"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Michael Jackson',
        'optionA': 'Prince',
        'optionB': 'Michael Jackson',
        'optionC': 'Stevie Wonder',
        'optionD': 'James Brown',
      },
      {
        'questionText': 'Who performed "Shape of You"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Ed Sheeran',
        'optionA': 'Ed Sheeran',
        'optionB': 'Justin Bieber',
        'optionC': 'Sam Smith',
        'optionD': 'Shawn Mendes',
      },
      {
        'questionText': 'Who performed "Blinding Lights"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Medium',
        'correctAnswer': 'The Weeknd',
        'optionA': 'Drake',
        'optionB': 'Post Malone',
        'optionC': 'The Weeknd',
        'optionD': 'Bruno Mars',
      },
      {
        'questionText': 'Who performed "Rolling in the Deep"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Adele',
        'optionA': 'Beyoncé',
        'optionB': 'Rihanna',
        'optionC': 'Adele',
        'optionD': 'Taylor Swift',
      },
      {
        'questionText': 'Who performed "Bad Guy"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Billie Eilish',
        'optionA': 'Billie Eilish',
        'optionB': 'Halsey',
        'optionC': 'Dua Lipa',
        'optionD': 'Ariana Grande',
      },
      {
        'questionText': 'Who performed "Uptown Funk"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Medium',
        'correctAnswer': 'Bruno Mars',
        'optionA': 'Pharrell',
        'optionB': 'Bruno Mars',
        'optionC': 'Justin Timberlake',
        'optionD': 'Usher',
      },
      {
        'questionText': 'Who performed "Old Town Road"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Easy',
        'correctAnswer': 'Lil Nas X',
        'optionA': 'Post Malone',
        'optionB': 'Travis Scott',
        'optionC': 'Lil Nas X',
        'optionD': 'DaBaby',
      },
      {
        'questionText': 'Who performed "Someone Like You"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Medium',
        'correctAnswer': 'Adele',
        'optionA': 'Taylor Swift',
        'optionB': 'Adele',
        'optionC': 'Lady Gaga',
        'optionD': 'Sia',
      },
      {
        'questionText': 'Who performed "Levitating"?',
        'questionType': 'Guess the Artist',
        'difficulty': 'Medium',
        'correctAnswer': 'Dua Lipa',
        'optionA': 'Doja Cat',
        'optionB': 'Lizzo',
        'optionC': 'Dua Lipa',
        'optionD': 'Cardi B',
      },

      // ---- Name the Song (10) ----
      {
        'questionText': 'Which song starts with "Is this the real life? Is this just fantasy?"',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'Bohemian Rhapsody',
        'optionA': 'Bohemian Rhapsody',
        'optionB': 'Stairway to Heaven',
        'optionC': 'Hotel California',
        'optionD': 'Imagine',
      },
      {
        'questionText': 'Which song has the lyric "Just gonna stand there and watch me burn"?',
        'questionType': 'Name the Song',
        'difficulty': 'Medium',
        'correctAnswer': 'Love the Way You Lie',
        'optionA': 'Burn',
        'optionB': 'Love the Way You Lie',
        'optionC': 'Set Fire to the Rain',
        'optionD': 'Firework',
      },
      {
        'questionText': 'Which song has the lyric "I came in like a wrecking ball"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'Wrecking Ball',
        'optionA': 'Wrecking Ball',
        'optionB': 'Demolition',
        'optionC': 'Titanium',
        'optionD': 'Stronger',
      },
      {
        'questionText': 'Which song begins with "Hello, it\'s me"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'Hello',
        'optionA': 'Someone Like You',
        'optionB': 'Hello',
        'optionC': 'Rolling in the Deep',
        'optionD': 'When We Were Young',
      },
      {
        'questionText': 'Which song has the lyric "Somebody once told me the world is gonna roll me"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'All Star',
        'optionA': 'All Star',
        'optionB': 'Rockstar',
        'optionC': 'Believer',
        'optionD': 'Walking on Sunshine',
      },
      {
        'questionText': 'Which song has the lyric "We found love in a hopeless place"?',
        'questionType': 'Name the Song',
        'difficulty': 'Medium',
        'correctAnswer': 'We Found Love',
        'optionA': 'Diamonds',
        'optionB': 'Umbrella',
        'optionC': 'We Found Love',
        'optionD': 'Stay',
      },
      {
        'questionText': 'Which song has the lyric "Cause this is thriller, thriller night"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'Thriller',
        'optionA': 'Beat It',
        'optionB': 'Thriller',
        'optionC': 'Smooth Criminal',
        'optionD': 'Bad',
      },
      {
        'questionText': 'Which song starts with "I\'m walking on sunshine"?',
        'questionType': 'Name the Song',
        'difficulty': 'Medium',
        'correctAnswer': 'Walking on Sunshine',
        'optionA': 'Here Comes the Sun',
        'optionB': 'Walking on Sunshine',
        'optionC': 'Good Day Sunshine',
        'optionD': 'Pocket Full of Sunshine',
      },
      {
        'questionText': 'Which song has the lyric "I gotta feeling that tonight\'s gonna be a good night"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'I Gotta Feeling',
        'optionA': 'Tonight',
        'optionB': 'Good Feeling',
        'optionC': 'I Gotta Feeling',
        'optionD': 'Party Rock Anthem',
      },
      {
        'questionText': 'Which song has the lyric "Never gonna give you up, never gonna let you down"?',
        'questionType': 'Name the Song',
        'difficulty': 'Easy',
        'correctAnswer': 'Never Gonna Give You Up',
        'optionA': 'Never Gonna Give You Up',
        'optionB': 'Together Forever',
        'optionC': 'I Will Always Love You',
        'optionD': 'Endless Love',
      },
    ];

    final batch = db.batch();
    for (final q in questions) {
      batch.insert('questions', q);
    }
    await batch.commit(noResult: true);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

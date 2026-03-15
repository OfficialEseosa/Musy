import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

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

  Future<List<Question>> getRandomQuestions(String mode, int count) async {
    final db = await database;
    final maps = await db.query(
      'questions',
      where: 'questionType = ?',
      whereArgs: [mode],
      orderBy: 'RANDOM()',
      limit: count,
    );
    return maps.map((map) => Question.fromMap(map)).toList();
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

  // --- Session CRUD ---

  Future<int> insertSession(Map<String, dynamic> session) async {
    final db = await database;
    return await db.insert('sessions', session);
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

  Future<List<Map<String, dynamic>>> getLeaderboard({String? gameMode}) async {
    final db = await database;
    if (gameMode != null && gameMode != 'All Modes') {
      return await db.query(
        'leaderboard',
        where: 'gameMode = ?',
        whereArgs: [gameMode],
        orderBy: 'score DESC',
      );
    }
    return await db.query('leaderboard', orderBy: 'score DESC');
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

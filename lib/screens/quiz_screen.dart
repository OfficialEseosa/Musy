import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import 'results_screen.dart';

class QuizScreen extends StatefulWidget {
  final String gameMode;

  const QuizScreen({super.key, required this.gameMode});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Question> _questions = [];
  int _currentIndex = 0;
  bool _isLoading = true;

  // Timer
  int _timerDuration = 30;
  int _timeLeft = 30;
  Timer? _timer;

  // Scoring
  int _score = 0;
  int _correctCount = 0;
  int _currentStreak = 0;
  int _highestStreak = 0;

  // Answer state
  String? _selectedAnswer;
  bool _isAnswered = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    final settings = SettingsService();
    _timerDuration = await settings.getTimerDuration();

    final questions = await DatabaseHelper.instance.getRandomQuestions(
      widget.gameMode,
      10,
    );

    if (mounted) {
      setState(() {
        _questions = questions;
        _timeLeft = _timerDuration;
        _isLoading = false;
      });

      if (_questions.isNotEmpty) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = _timerDuration;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft <= 0) {
        timer.cancel();
        _handleTimeout();
      } else {
        setState(() {
          _timeLeft--;
        });
      }
    });
  }

  void _handleTimeout() {
    if (!_isAnswered) {
      setState(() {
        _isAnswered = true;
        _selectedAnswer = null;
        _currentStreak = 0;
      });

      final question = _questions[_currentIndex];
      if (question.id != null) {
        DatabaseHelper.instance.recordAttempt(question.id!, false);
      }

      Future.delayed(const Duration(milliseconds: 1500), () {
        _nextQuestion();
      });
    }
  }

  void _selectAnswer(String answer) {
    if (_isAnswered) return;
    _timer?.cancel();

    final question = _questions[_currentIndex];
    final isCorrect = answer == question.correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _isAnswered = true;

      if (isCorrect) {
        _correctCount++;
        _currentStreak++;
        // Scoring: +10 base, +5 bonus every 3 consecutive correct
        _score += 10;
        if (_currentStreak > 0 && _currentStreak % 3 == 0) {
          _score += 5;
        }
        if (_currentStreak > _highestStreak) {
          _highestStreak = _currentStreak;
        }
      } else {
        _currentStreak = 0; // wrong answer resets streak
      }
    });

    if (question.id != null) {
      DatabaseHelper.instance.recordAttempt(question.id!, isCorrect);
    }

    Future.delayed(const Duration(milliseconds: 1500), () {
      _nextQuestion();
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _isAnswered = false;
      });
      _startTimer();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() {
    _timer?.cancel();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultsScreen(
            score: _score,
            correctAnswers: _correctCount,
            totalQuestions: _questions.length,
            highestStreak: _highestStreak,
            gameMode: widget.gameMode,
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.gameMode)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.gameMode)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No questions available for this mode.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Add some in the Question Manager!',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final options = [
      question.optionA ?? '',
      question.optionB ?? '',
      question.optionC ?? '',
      question.optionD ?? '',
    ].where((o) => o.isNotEmpty).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.gameMode),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Score / Streak / Timer header cards
              Row(
                children: [
                  _HeaderCard(
                    label: 'Score',
                    value: '$_score',
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  _HeaderCard(
                    label: 'Streak',
                    value: _currentStreak >= 2
                        ? '🔥 $_currentStreak'
                        : 'x$_currentStreak',
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _HeaderCard(
                    label: 'Timer',
                    value: '${_timeLeft}s',
                    color: _timeLeft <= 5 ? Colors.red : Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Timer progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _timeLeft / _timerDuration,
                  backgroundColor: Colors.grey[300],
                  color: _timeLeft <= 5 ? Colors.red : colorScheme.primary,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 24),

              // Question text
              Expanded(
                child: Center(
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          question.questionText,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Answer options
              ...options.map((option) {
                Color? bgColor;
                Color? borderColor;
                if (_isAnswered) {
                  if (option == question.correctAnswer) {
                    bgColor = Colors.green.withOpacity(0.15);
                    borderColor = Colors.green;
                  } else if (option == _selectedAnswer) {
                    bgColor = Colors.red.withOpacity(0.15);
                    borderColor = Colors.red;
                  }
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: bgColor,
                      side: BorderSide(
                        color: borderColor ??
                            colorScheme.outline.withOpacity(0.5),
                        width: borderColor != null ? 2 : 1,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed:
                        _isAnswered ? null : () => _selectAnswer(option),
                    child: Text(
                      option,
                      style: TextStyle(
                        fontSize: 16,
                        color: borderColor ??
                            Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ),
                );
              }),

              // Footer
              const SizedBox(height: 8),
              Text(
                'Question ${_currentIndex + 1} of ${_questions.length}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Correct answer increases streak · Wrong answer resets streak',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: color.withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

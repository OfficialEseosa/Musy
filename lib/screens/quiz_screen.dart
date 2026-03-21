import 'dart:async';
import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';

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
      });

      // Record as incorrect attempt
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
    });

    // Record attempt
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
      // Quiz finished — for now just pop back
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'No questions available for this mode.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
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
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Text(
                '${_currentIndex + 1}/${_questions.length}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Timer bar
            LinearProgressIndicator(
              value: _timeLeft / _timerDuration,
              backgroundColor: Colors.grey[300],
              color: _timeLeft <= 5 ? Colors.red : Colors.deepPurple,
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Text(
              '$_timeLeft s',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: _timeLeft <= 5 ? Colors.red : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),

            // Question text
            Text(
              question.questionText,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Answer options
            ...options.map((option) {
              Color? bgColor;
              if (_isAnswered) {
                if (option == question.correctAnswer) {
                  bgColor = Colors.green[400];
                } else if (option == _selectedAnswer) {
                  bgColor = Colors.red[400];
                }
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bgColor,
                    foregroundColor: bgColor != null ? Colors.white : null,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isAnswered ? null : () => _selectAnswer(option),
                  child: Text(
                    option,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class Question {
  final int? id;
  final String questionText;
  final String questionType; // 'Finish the Lyric', 'Guess the Artist', 'Name the Song'
  final String difficulty; // 'Easy', 'Medium', 'Hard'
  final String correctAnswer;
  final String? optionA;
  final String? optionB;
  final String? optionC;
  final String? optionD;

  Question({
    this.id,
    required this.questionText,
    required this.questionType,
    required this.difficulty,
    required this.correctAnswer,
    this.optionA,
    this.optionB,
    this.optionC,
    this.optionD,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionText': questionText,
      'questionType': questionType,
      'difficulty': difficulty,
      'correctAnswer': correctAnswer,
      'optionA': optionA,
      'optionB': optionB,
      'optionC': optionC,
      'optionD': optionD,
    };
  }

  factory Question.fromMap(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int?,
      questionText: map['questionText'] as String,
      questionType: map['questionType'] as String,
      difficulty: map['difficulty'] as String,
      correctAnswer: map['correctAnswer'] as String,
      optionA: map['optionA'] as String?,
      optionB: map['optionB'] as String?,
      optionC: map['optionC'] as String?,
      optionD: map['optionD'] as String?,
    );
  }
}

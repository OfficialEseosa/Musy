import 'package:flutter/material.dart';
import '../models/question.dart';
import '../services/database_helper.dart';

class QuestionManagerScreen extends StatefulWidget {
  const QuestionManagerScreen({super.key});

  @override
  State<QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

class _QuestionManagerScreenState extends State<QuestionManagerScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  late Future<List<Question>> _questionsFuture;

  static const List<String> _modes = [
    'Finish the Lyric',
    'Guess the Artist',
    'Name the Song',
  ];

  static const List<String> _difficulties = ['Easy', 'Medium', 'Hard'];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _questionsFuture = _db
          .getAllQuestions()
          .then((maps) => maps.map(Question.fromMap).toList());
    });
  }

  void _showForm({Question? question}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _QuestionForm(
        question: question,
        modes: _modes,
        difficulties: _difficulties,
        onSaved: (q) async {
          if (q.id == null) {
            await _db.insertQuestion(q.toMap());
          } else {
            await _db.updateQuestion(q.id!, q.toMap());
          }
          if (mounted) Navigator.pop(context);
          _refresh();
        },
      ),
    );
  }

  void _confirmDelete(Question question) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Question'),
        content: Text(
            'Delete "${question.questionText}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _db.deleteQuestion(question.id!);
              if (mounted) Navigator.pop(context);
              _refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Question deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'Easy':
        return Colors.green;
      case 'Medium':
        return Colors.orange;
      case 'Hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Manager'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Question'),
        onPressed: () => _showForm(),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final questions = snapshot.data ?? [];
          if (questions.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No questions yet. Tap + to add one.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: questions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 4),
            itemBuilder: (context, index) {
              final q = questions[index];
              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(
                    q.questionText,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        _Chip(label: q.questionType, color: Colors.deepPurple),
                        const SizedBox(width: 6),
                        _Chip(
                            label: q.difficulty,
                            color: _difficultyColor(q.difficulty)),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'Edit',
                        onPressed: () => _showForm(question: q),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                        tooltip: 'Delete',
                        onPressed: () => _confirmDelete(q),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ─── Chip helper ──────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

// ─── Add / Edit Form ──────────────────────────────────────────────────────────

class _QuestionForm extends StatefulWidget {
  final Question? question;
  final List<String> modes;
  final List<String> difficulties;
  final Future<void> Function(Question) onSaved;

  const _QuestionForm({
    required this.question,
    required this.modes,
    required this.difficulties,
    required this.onSaved,
  });

  @override
  State<_QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<_QuestionForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  late TextEditingController _textCtrl;
  late TextEditingController _optACtrl;
  late TextEditingController _optBCtrl;
  late TextEditingController _optCCtrl;
  late TextEditingController _optDCtrl;

  late String _selectedMode;
  late String _selectedDifficulty;
  late String _correctAnswer;

  static const List<String> _answerOptions = ['A', 'B', 'C', 'D'];

  @override
  void initState() {
    super.initState();
    final q = widget.question;
    _textCtrl = TextEditingController(text: q?.questionText ?? '');
    _optACtrl = TextEditingController(text: q?.optionA ?? '');
    _optBCtrl = TextEditingController(text: q?.optionB ?? '');
    _optCCtrl = TextEditingController(text: q?.optionC ?? '');
    _optDCtrl = TextEditingController(text: q?.optionD ?? '');
    _selectedMode = q?.questionType ?? widget.modes.first;
    _selectedDifficulty = q?.difficulty ?? widget.difficulties.first;
    _correctAnswer = q?.correctAnswer ?? 'A';
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _optACtrl.dispose();
    _optBCtrl.dispose();
    _optCCtrl.dispose();
    _optDCtrl.dispose();
    super.dispose();
  }

  String _answerText() {
    switch (_correctAnswer) {
      case 'A':
        return _optACtrl.text.trim();
      case 'B':
        return _optBCtrl.text.trim();
      case 'C':
        return _optCCtrl.text.trim();
      case 'D':
        return _optDCtrl.text.trim();
      default:
        return '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_answerText().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Option $_correctAnswer (marked as correct answer) cannot be empty.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    final q = Question(
      id: widget.question?.id,
      questionText: _textCtrl.text.trim(),
      questionType: _selectedMode,
      difficulty: _selectedDifficulty,
      correctAnswer: _answerText(),
      optionA: _optACtrl.text.trim().isEmpty ? null : _optACtrl.text.trim(),
      optionB: _optBCtrl.text.trim().isEmpty ? null : _optBCtrl.text.trim(),
      optionC: _optCCtrl.text.trim().isEmpty ? null : _optCCtrl.text.trim(),
      optionD: _optDCtrl.text.trim().isEmpty ? null : _optDCtrl.text.trim(),
    );
    await widget.onSaved(q);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.question != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                isEdit ? 'Edit Question' : 'Add Question',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Question text
              _label('Question Text'),
              TextFormField(
                controller: _textCtrl,
                maxLines: 2,
                decoration: _inputDecoration('Enter the question…'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Mode + Difficulty row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Mode'),
                        DropdownButtonFormField<String>(
                          value: _selectedMode,
                          isExpanded: true,
                          decoration: _inputDecoration(null),
                          items: widget.modes
                              .map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 13))))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedMode = v!),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _label('Difficulty'),
                        DropdownButtonFormField<String>(
                          value: _selectedDifficulty,
                          isExpanded: true,
                          decoration: _inputDecoration(null),
                          items: widget.difficulties
                              .map((d) => DropdownMenuItem(
                                  value: d, child: Text(d)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedDifficulty = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Options A–D
              _label('Answer Options'),
              ...[
                ('A', _optACtrl),
                ('B', _optBCtrl),
                ('C', _optCCtrl),
                ('D', _optDCtrl),
              ].map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextFormField(
                    controller: entry.$2,
                    decoration: _inputDecoration('Option ${entry.$1}…').copyWith(
                      prefixText: '${entry.$1}:  ',
                    ),
                    validator: (v) {
                      if (entry.$1 == 'A' || entry.$1 == 'B') {
                        return (v == null || v.trim().isEmpty)
                            ? 'Option ${entry.$1} is required'
                            : null;
                      }
                      return null;
                    },
                  ),
                ),
              ),

              // Correct answer selector
              _label('Correct Answer'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: _answerOptions.map((opt) {
                  final selected = _correctAnswer == opt;
                  return ChoiceChip(
                    label: Text('Option $opt'),
                    selected: selected,
                    onSelected: (_) =>
                        setState(() => _correctAnswer = opt),
                    selectedColor: Theme.of(context)
                        .colorScheme
                        .primary
                        .withOpacity(0.2),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Add Question',
                          style: const TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey)),
      );

  InputDecoration _inputDecoration(String? hint) => InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        isDense: true,
      );
}

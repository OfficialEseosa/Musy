import 'package:flutter/material.dart';

class QuestionManagerScreen extends StatefulWidget {
  const QuestionManagerScreen({super.key});

  @override
  State<QuestionManagerScreen> createState() => _QuestionManagerScreenState();
}

class _QuestionManagerScreenState extends State<QuestionManagerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Question Manager'),
      ),
      body: const Center(
        child: Text('Question Manager Screen'),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class GameModeScreen extends StatelessWidget {
  const GameModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a Mode'),
      ),
      body: const Center(
        child: Text('Game Mode Select'),
      ),
    );
  }
}

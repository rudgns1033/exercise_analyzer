import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: const Text(
            '시작하기',
            style: TextStyle(fontSize: 20),
          ),
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/user_setup');
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
          ),
        ),
      ),
    );
  }
}

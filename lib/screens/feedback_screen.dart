// lib/screens/feedback_screen.dart

import 'package:flutter/material.dart';
import '../services/form_evaluation_service.dart';

class FeedbackScreen extends StatelessWidget {
  final String exerciseType;
  final List<Map<String, dynamic>> joints;

  const FeedbackScreen({
    Key? key,
    required this.exerciseType,
    required this.joints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final feedback = FormEvaluationService.evaluate(
      exerciseType: exerciseType,
      joints: joints,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('자세 피드백')),
      body: feedback.comments.isEmpty
          ? const Center(
        child: Text(
          '정상적인 자세입니다!',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: feedback.comments.length,
        itemBuilder: (_, i) => ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text(feedback.comments[i]),
        ),
      ),
    );
  }
}

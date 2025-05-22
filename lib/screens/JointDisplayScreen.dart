// lib/screens/joint_display_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'feedback_screen.dart';

class JointDisplayScreen extends StatelessWidget {
  final String exerciseType;
  final String thumbnailPath;
  final List<Map<String, dynamic>> joints;

  const JointDisplayScreen({
    Key? key,
    required this.exerciseType,
    required this.thumbnailPath,
    required this.joints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관절 좌표 시각화'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1) 운동 유형 텍스트
          Text(
            '운동 유형: $exerciseType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            softWrap: true,
          ),
          const SizedBox(height: 12),

          // 2) 피드백 보기 버튼
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FeedbackScreen(
                    exerciseType: exerciseType,
                    joints: joints,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.feedback),
            label: const Text('피드백 보기'),
          ),
          const SizedBox(height: 24),

          // 3) 썸네일 이미지
          Image.file(
            File(thumbnailPath),
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
          const SizedBox(height: 16),

          // 4) 관절 좌표 리스트
          const Text(
            '추출된 관절 좌표',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ...joints.map((j) {
            final x = (j['x'] as double).toStringAsFixed(1);
            final y = (j['y'] as double).toStringAsFixed(1);
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(j['type'] as String),
              subtitle: Text('x: $x, y: $y'),
            );
          }).toList(),
        ],
      ),
    );
  }
}

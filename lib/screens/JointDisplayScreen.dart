// lib/screens/joint_display_screen.dart

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'feedback_screen.dart';

class JointDisplayScreen extends StatelessWidget {
  final String thumbnailPath;
  final List<Map<String, dynamic>> joints;

  const JointDisplayScreen({
    Key? key,
    required this.thumbnailPath,
    required this.joints,
  }) : super(key: key);

  /// 관절 좌표만으로 운동 유형 판별
  String get exerciseType => _classifyExercise(joints);

  String _classifyExercise(List<Map<String, dynamic>> joints) {
    final lookup = <String, Map<String, double>>{
      for (var j in joints)
        (j['type'] as String): {'x': j['x'] as double, 'y': j['y'] as double}
    };

    double angle(String p1, String p2, String p3) {
      final a = lookup[p1], b = lookup[p2], c = lookup[p3];
      if (a == null || b == null || c == null) return 0.0;
      final dx1 = a['x']! - b['x']!;
      final dy1 = a['y']! - b['y']!;
      final dx2 = c['x']! - b['x']!;
      final dy2 = c['y']! - b['y']!;
      final dot = dx1 * dx2 + dy1 * dy2;
      final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
      final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
      if (mag1 == 0 || mag2 == 0) return 0.0;
      final cosT = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
      return acos(cosT) * 180 / pi;
    }

    double? yOf(String p) => lookup[p]?['y'];

    final pushElbow  = angle('leftShoulder','leftElbow','leftWrist');
    final torsoAngle = angle('leftShoulder','leftHip','leftKnee');
    final squatKnee  = angle('leftHip','leftKnee','leftAnkle');
    final wristY     = yOf('leftWrist');
    final shoulderY  = yOf('leftShoulder');
    final sitAngle   = angle('leftShoulder','leftHip','leftKnee');

    if (pushElbow>=70 && pushElbow<=120 && torsoAngle>=160 && torsoAngle<=200) {
      return 'push_up';
    }
    if (pushElbow>=70 && pushElbow<=120 && torsoAngle>=70  && torsoAngle<=110) {
      return 'bench_press';
    }
    if (squatKnee>0) {
      return 'squat';
    }
    if (wristY!=null && shoulderY!=null && wristY<shoulderY-20) {
      return 'pull_up';
    }
    if (sitAngle>=30 && sitAngle<=100) {
      return 'sit_up';
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final type = exerciseType;

    return Scaffold(
      appBar: AppBar(title: const Text('관절 좌표 시각화')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('운동 유형: $type',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => FeedbackScreen(
                    exerciseType: type,
                    joints: joints,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.feedback),
            label: const Text('피드백 보기'),
          ),
          const SizedBox(height: 24),

          Image.file(File(thumbnailPath), width: double.infinity, fit: BoxFit.fitWidth),
          const SizedBox(height: 16),

          const Text('추출된 관절 좌표',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),
          ...joints.map((j) {
            final x = (j['x'] as double).toStringAsFixed(1);
            final y = (j['y'] as double).toStringAsFixed(1);
            return ListTile(
              title: Text(j['type'] as String),
              subtitle: Text('x: $x, y: $y'),
            );
          }),
        ],
      ),
    );
  }
}

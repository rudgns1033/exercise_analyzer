import 'dart:async';
// lib/screens/joint_display_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import '../models/joints.dart';
import 'feedback_screen.dart';

class JointStreamDisplayScreen extends StatelessWidget {
  /// 썸네일 이미지 파일 경로
  /// 추출된 관절 좌표 리스트
  final Stream<Joints> jointStream;
  final Completer<List<Joints>>? jointCompleter;

  bool isFirst = true;
  List<Map<String, dynamic>>? firstJoint;
  int count = 0;

  JointStreamDisplayScreen({
    Key? key,
    required this.jointStream,
    required this.jointCompleter,
  }) : super(key: key);

  List<Map<String, dynamic>>? get joints  {
    if (firstJoint != null){
      return firstJoint;
    }
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (firstJoint != null){
        timer.cancel(); // 루프 종료
        return;
      }
      print('loop $count\n');
      count++;
      if (count >= 10) {
        timer.cancel(); // 루프 종료
      }
    });
    return firstJoint;
  }

  /// 관절 좌표만으로 운동 유형 판별
  // Future<String> get exerciseType async => await _classifyExercise(jointCompleter.future);

  Future<List<Joints>> waitForStreamArr() {
    final List<Joints>allJoints = [];
    Completer<List<Joints>>? completer;

    if (jointCompleter != null){
      completer = jointCompleter;
    }else{
      completer = Completer<List<Joints>>();
    }

    jointStream.listen(
          (onData) {
        allJoints.add(Joints(frameBytes: onData.frameBytes, joints: onData.joints)); // 스트림이 전달하는 리스트를 병합
        if (isFirst) {
          firstJoint = onData.joints;
          isFirst = false;
        }
        print(onData);
      },
      onDone: () {
        if (!completer!.isCompleted) {
          completer.complete(allJoints); // 모든 데이터 반환
        }
      },
      onError: (error) {
        print('waitForStream error: $error');
        if (!completer!.isCompleted) {
          // completer.completeError(error);
          completer.complete(allJoints); // 모든 데이터 반환
        }
      },
    );

    return completer!.future;
  }

  String _classifyExercise(List<Map<String, dynamic>>? joints) {
    final lookup = <String, Map<String, double>>{
      for (var j in joints!)
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

    if (wristY != null && shoulderY != null &&
        wristY < shoulderY - 20 &&
        squatKnee >= 150) {
      return 'pull_up';
    }
    if (pushElbow>=70 && pushElbow<=120 && torsoAngle>=160 && torsoAngle<=200) {
      return 'push_up';
    }
    if (pushElbow>=70 && pushElbow<=120 && torsoAngle>=70  && torsoAngle<=110) {
      return 'bench_press';
    }
    if (squatKnee>=60 && squatKnee <= 110 && torsoAngle >= 150) {
      return 'squat';
    }
    if (sitAngle>=30 && sitAngle<=100) {
      return 'sit_up';
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    final future = waitForStreamArr();

    return FutureBuilder<List<Joints?>?>(
      future: future,
      builder: (context, snapshot) {
        if(!snapshot.hasData){
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final joints = snapshot.data!;
        final type = _classifyExercise(joints[0]?.joints);

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
                        jointsArr: joints,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.feedback),
                label: const Text('피드백 보기'),
              ),
              const SizedBox(height: 24),

              Image.memory(joints[0]!.frameBytes!, width: double.infinity, fit: BoxFit.fitWidth),
              const SizedBox(height: 16),

              const Text('추출된 관절 좌표',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(),
              // 중첩 리스트 각 그룹별로 위젯 생성
              ...joints.asMap().entries.expand((entry) {
                final groupIndex = entry.key;
                final jointGroup = entry.value?.joints; // List<Map<String, dynamic>>

                List<Widget> widgets = [];

                // 그룹 제목
                widgets.add(
                  Text(
                    '관절 그룹 ${groupIndex + 1}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                );
                widgets.add(const Divider());

                // 해당 그룹의 관절들 리스트
                widgets.addAll(jointGroup!.map((j) {
                  final x = (j['x'] as double).toStringAsFixed(1);
                  final y = (j['y'] as double).toStringAsFixed(1);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(j['type'] as String),
                    subtitle: Text('x: $x, y: $y'),
                  );
                }));

                widgets.add(const SizedBox(height: 20)); // 그룹 간 간격

                return widgets;
              }),
            ],
          ),
        );
    },
    );
  }
}

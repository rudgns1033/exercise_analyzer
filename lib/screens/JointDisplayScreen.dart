import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'feedback_screen.dart';

class JointDisplayScreen extends StatefulWidget {
  /// 썸네일 이미지 파일 경로
  final String thumbnailPath;
  /// 추출된 관절 좌표 리스트
  final List<Map<String, dynamic>> joints;

  const JointDisplayScreen({
    Key? key,
    required this.thumbnailPath,
    required this.joints,
  }) : super(key: key);

  @override
  State<JointDisplayScreen> createState() => _JointDisplayScreenState();
}

class JointStreamDisplayScreen extends StatefulWidget {
  /// 썸네일 이미지 파일 경로
  final String thumbnailPath;
  /// 추출된 관절 좌표 리스트
  final Stream<List<Map<String, dynamic>>> jointStream;

  const JointStreamDisplayScreen({
    Key? key,
    required this.thumbnailPath,
    required this.jointStream,
  }) : super(key: key);

  @override
  State<JointStreamDisplayScreen> createState() => _JointStreamDisplayScreenState();
}

class _JointStreamDisplayScreenState extends State<JointStreamDisplayScreen> {
  /// joints 데이터를 기반으로 운동 유형을 분류해서 반환
  bool isFirst = true;
  List<Map<String, dynamic>>? firstJoint;
  String get exerciseType => _classifyExercise(widget.jointStream);
  int count = 0;
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

  late Future<List<Map<String, dynamic>>?> _initFuture;
  late Future<List<List<Map<String, dynamic>>?>?> _initFutures;

  @override
  void initState() {
    super.initState();
    // _initFuture = _initialize(); // 비동기 초기화 시작
    _initFutures = _initialize2(); // 비동기 초기화 시작
  }

  // Future<List<Map<String, dynamic>>?> _initialize() async {
  //   // await 하고 싶은 작업 여기서
  //   await waitForStream(widget.jointStream); // 예시용 딜레이
  //   return firstJoint;
  // }

  Future<List<List<Map<String, dynamic>>?>?> _initialize2() async {
    // await 하고 싶은 작업 여기서
    return waitForStreamArr(widget.jointStream);
  }

  Future<void> waitForStream(Stream stream) {
    final completer = Completer();
    stream.listen(
          (onData) {
        if (isFirst) {
          firstJoint = onData;
          isFirst = false;
        }
        print(onData);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (error) {
        print('waitforStream error: $error');  // 에러 출력
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );
    return completer.future;
  }

  Future<List<List<Map<String, dynamic>>>> waitForStreamArr(Stream<List<Map<String, dynamic>>> stream) {
    final completer = Completer<List<List<Map<String, dynamic>>>>();
    final List<List<Map<String, dynamic>>>allJoints = [];

    stream.listen(
          (onData) {
        allJoints.add(onData); // 스트림이 전달하는 리스트를 병합
        if (isFirst) {
          firstJoint = onData;
          isFirst = false;
        }
        print(onData);
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.complete(allJoints); // 모든 데이터 반환
        }
      },
      onError: (error) {
        print('waitForStream error: $error');
        if (!completer.isCompleted) {
          // completer.completeError(error);
          completer.complete(allJoints); // 모든 데이터 반환
        }
      },
    );

    return completer.future;
  }


  String _classifyExercise(Stream<List<Map<String, dynamic>>> jointStream) {
    Map<String, dynamic>? find(List<Map<String, dynamic>> joints, String type) {
      try {
        final m = joints.firstWhere((e) => e['type'] == type);
        return m.isNotEmpty ? m : null;
      } catch (_) {
        return null;
      }
    }

    double angle(List<Map<String, dynamic>> joints, String aKey, String bKey, String cKey) {
      final a = find(joints,aKey), b = find(joints, bKey), c = find(joints, cKey);
      if (a == null || b == null || c == null) return 0.0;
      final dx1 = (a['x'] as double) - (b['x'] as double);
      final dy1 = (a['y'] as double) - (b['y'] as double);
      final dx2 = (c['x'] as double) - (b['x'] as double);
      final dy2 = (c['y'] as double) - (b['y'] as double);
      final dot = dx1 * dx2 + dy1 * dy2;
      final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
      final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
      if (mag1 == 0 || mag2 == 0) return 0.0;
      final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
      return acos(cosTheta) * 180 / pi;
    }

    double? yOf(String type) => find(firstJoint!,type)?['y'] as double?;

    final pushElbow  = angle(firstJoint!, 'leftShoulder', 'leftElbow', 'leftWrist');
    final torsoAngle = angle(firstJoint!, 'leftShoulder', 'leftHip', 'leftKnee');
    final squatKnee  = angle(firstJoint!, 'leftHip', 'leftKnee', 'leftAnkle');
    final wy = yOf('leftWrist');
    final sy = yOf('leftShoulder');
    final sitAngle   = angle(firstJoint!, 'leftShoulder', 'leftHip', 'leftKnee');

    // 1) 팔굽혀펴기
    if (pushElbow >= 70 && pushElbow <= 120 &&
        torsoAngle >= 160 && torsoAngle <= 200) {
      return 'push_up';
    }
    // 2) 벤치프레스
    if (pushElbow >= 70 && pushElbow <= 120 &&
        torsoAngle >= 70 && torsoAngle <= 110) {
      return 'bench_press';
    }
    // 3) 스쿼트
    if (squatKnee > 0 && squatKnee <= 100) {
      return 'squat';
    }
    // 4) 턱걸이
    if (wy != null && sy != null && wy < sy - 20) {
      return 'pull_up';
    }
    // 5) 윗몸일으키기
    if (sitAngle >= 30 && sitAngle <= 100) {
      return 'sit_up';
    }
    return 'unknown';
  }

  // @override
  // Widget build(BuildContext context) {
  //   final joints = this.joints;
  //   final exerciseType = this.exerciseType;
  //   return Scaffold(
  //     appBar: AppBar(title: const Text('관절 좌표 시각화')),
  //     body: ListView(
  //       padding: const EdgeInsets.all(16),
  //       children: [
  //         // 운동 유형
  //         Text(
  //           '운동 유형: $exerciseType',
  //           style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //           softWrap: true,
  //         ),
  //         const SizedBox(height: 12),
  //
  //         // 피드백 보기 버튼
  //         ElevatedButton.icon(
  //           onPressed: () => Navigator.of(context).push(
  //             MaterialPageRoute(
  //               builder: (_) => FeedbackScreen(
  //                 exerciseType: exerciseType,
  //                 joints: joints!,
  //               ),
  //             ),
  //           ),
  //           icon: const Icon(Icons.feedback),
  //           label: const Text('피드백 보기'),
  //         ),
  //         const SizedBox(height: 24),
  //
  //         // 썸네일 이미지
  //         Image.file(
  //           File(widget.thumbnailPath),
  //           width: double.infinity,
  //           fit: BoxFit.fitWidth,
  //         ),
  //         const SizedBox(height: 16),
  //
  //         // 관절 좌표 리스트
  //         const Text(
  //           '추출된 관절 좌표',
  //           style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //         ),
  //         const Divider(),
  //         ...joints!.map((j) {
  //           final x = (j['x'] as double).toStringAsFixed(1);
  //           final y = (j['y'] as double).toStringAsFixed(1);
  //           return ListTile(
  //             contentPadding: EdgeInsets.zero,
  //             title: Text(j['type'] as String),
  //             subtitle: Text('x: $x, y: $y'),
  //           );
  //         }).toList(),
  //       ],
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return FutureBuilder<List<Map<String, dynamic>>?>(
  //     future: _initFuture,
  //     builder: (context, snapshot) {
  //       if (!snapshot.hasData) {
  //         return const Scaffold(
  //           body: Center(child: CircularProgressIndicator()),
  //         );
  //       }
  //
  //       final joints = snapshot.data!;
  //
  //       return Scaffold(
  //         appBar: AppBar(title: const Text('관절 좌표 시각화')),
  //         body: ListView(
  //           padding: const EdgeInsets.all(16),
  //           children: [
  //             Text(
  //               '운동 유형: $exerciseType',
  //               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //               softWrap: true,
  //             ),
  //             const SizedBox(height: 12),
  //             ElevatedButton.icon(
  //               onPressed: () => Navigator.of(context).push(
  //                 MaterialPageRoute(
  //                   builder: (_) => FeedbackScreen(
  //                     exerciseType: exerciseType,
  //                     joints: joints,
  //                   ),
  //                 ),
  //               ),
  //               icon: const Icon(Icons.feedback),
  //               label: const Text('피드백 보기'),
  //             ),
  //             const SizedBox(height: 24),
  //             Image.file(
  //               File(widget.thumbnailPath),
  //               width: double.infinity,
  //               fit: BoxFit.fitWidth,
  //             ),
  //             const SizedBox(height: 16),
  //             const Text(
  //               '추출된 관절 좌표',
  //               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
  //             ),
  //             const Divider(),
  //             ...joints.map((j) {
  //               final x = (j['x'] as double).toStringAsFixed(1);
  //               final y = (j['y'] as double).toStringAsFixed(1);
  //               return ListTile(
  //                 contentPadding: EdgeInsets.zero,
  //                 title: Text(j['type'] as String),
  //                 subtitle: Text('x: $x, y: $y'),
  //               );
  //             }).toList(),
  //           ],
  //         ),
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<List<Map<String, dynamic>>?>?>(
      future: _initFutures,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final joints = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: const Text('관절 좌표 시각화')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                '운동 유형: $exerciseType',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                softWrap: true,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => FeedbackScreen(
                      exerciseType: exerciseType,
                      joints: (joints as List<dynamic>)
                          .expand((e) => (e as List<dynamic>))
                          .cast<Map<String, dynamic>>()
                          .toList(), // 필요에 따라 flatten
                    ),
                  ),
                ),
                icon: const Icon(Icons.feedback),
                label: const Text('피드백 보기'),
              ),
              const SizedBox(height: 24),
              Image.file(
                File(widget.thumbnailPath),
                width: double.infinity,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 16),
              const Text(
                '추출된 관절 좌표',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),

              // 중첩 리스트 각 그룹별로 위젯 생성
              ...joints.asMap().entries.expand((entry) {
                final groupIndex = entry.key;
                final jointGroup = entry.value; // List<Map<String, dynamic>>

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

class _JointDisplayScreenState extends State<JointDisplayScreen> {
  /// joints 데이터를 기반으로 운동 유형을 분류해서 반환
  String get exerciseType => _classifyExercise(widget.joints);

  String _classifyExercise(List<Map<String, dynamic>> joints) {
    Map<String, dynamic>? find(String type) {
      try {
        final m = joints.firstWhere((e) => e['type'] == type);
        return m.isNotEmpty ? m : null;
      } catch (_) {
        return null;
      }
    }

    double angle(String aKey, String bKey, String cKey) {
      final a = find(aKey), b = find(bKey), c = find(cKey);
      if (a == null || b == null || c == null) return 0.0;
      final dx1 = (a['x'] as double) - (b['x'] as double);
      final dy1 = (a['y'] as double) - (b['y'] as double);
      final dx2 = (c['x'] as double) - (b['x'] as double);
      final dy2 = (c['y'] as double) - (b['y'] as double);
      final dot = dx1 * dx2 + dy1 * dy2;
      final mag1 = sqrt(dx1 * dx1 + dy1 * dy1);
      final mag2 = sqrt(dx2 * dx2 + dy2 * dy2);
      if (mag1 == 0 || mag2 == 0) return 0.0;
      final cosTheta = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
      return acos(cosTheta) * 180 / pi;
    }

    double? yOf(String type) => find(type)?['y'] as double?;

    final pushElbow  = angle('leftShoulder', 'leftElbow', 'leftWrist');
    final torsoAngle = angle('leftShoulder', 'leftHip', 'leftKnee');
    final squatKnee  = angle('leftHip', 'leftKnee', 'leftAnkle');
    final wy = yOf('leftWrist');
    final sy = yOf('leftShoulder');
    final sitAngle   = angle('leftShoulder', 'leftHip', 'leftKnee');

    // 1) 팔굽혀펴기
    if (pushElbow >= 70 && pushElbow <= 120 &&
        torsoAngle >= 160 && torsoAngle <= 200) {
      return 'push_up';
    }
    // 2) 벤치프레스
    if (pushElbow >= 70 && pushElbow <= 120 &&
        torsoAngle >= 70 && torsoAngle <= 110) {
      return 'bench_press';
    }
    // 3) 스쿼트
    if (squatKnee > 0 && squatKnee <= 100) {
      return 'squat';
    }
    // 4) 턱걸이
    if (wy != null && sy != null && wy < sy - 20) {
      return 'pull_up';
    }
    // 5) 윗몸일으키기
    if (sitAngle >= 30 && sitAngle <= 100) {
      return 'sit_up';
    }
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관절 좌표 시각화')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 운동 유형
          Text(
            '운동 유형: $exerciseType',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            softWrap: true,
          ),
          const SizedBox(height: 12),

          // 피드백 보기 버튼
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => FeedbackScreen(
                  exerciseType: exerciseType,
                  joints: widget.joints,
                ),
              ),
            ),
            icon: const Icon(Icons.feedback),
            label: const Text('피드백 보기'),
          ),
          const SizedBox(height: 24),

          // 썸네일 이미지
          Image.file(
            File(widget.thumbnailPath),
            width: double.infinity,
            fit: BoxFit.fitWidth,
          ),
          const SizedBox(height: 16),

          // 관절 좌표 리스트
          const Text(
            '추출된 관절 좌표',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          ...widget.joints.map((j) {
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

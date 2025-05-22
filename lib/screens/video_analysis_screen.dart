// lib/screens/video_analysis_screen.dart

import 'dart:math';                  // ↖ sqrt, acos, pi
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/video_analysis_service.dart';
import 'JointDisplayScreen.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({Key? key}) : super(key: key);
  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  final VideoAnalysisService _service = VideoAnalysisService();
  bool _loading = false;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _analyzeAndDisplay(ImageSource source) async {
    setState(() => _loading = true);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);
      if (file == null) return;

      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (thumbnailPath == null) throw Exception('썸네일 생성 실패');

      final joints = await _service.extractJointData(file.path);

      final exerciseType = _classifyExercise(joints);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointDisplayScreen(
            exerciseType: exerciseType,
            thumbnailPath: thumbnailPath,
            joints: joints,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  String _classifyExercise(List<Map<String, dynamic>> j) {
    // 옵셔널 firstWhere
    Map<String, dynamic>? find(String type) {
      return j.firstWhere(
            (e) => e['type'] == type,
        orElse: () => <String, dynamic>{},
      ).isEmpty
          ? null
          : j.firstWhere((e) => e['type'] == type);
    }

    // 벡터 각도 계산 헬퍼
    double angleBetween(String aKey, String bKey, String cKey) {
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

    final pushUpAngle = angleBetween('leftShoulder', 'leftElbow', 'leftWrist');
    final squatAngle  = angleBetween('leftHip', 'leftKnee', 'leftAnkle');

    // 팔굽혀펴기 (70° ~ 120° 사이면)
    if (pushUpAngle >= 70 && pushUpAngle <= 120) return 'push_up';
    // 스쿼트 (100° 이하)
    if (squatAngle <= 100) return 'squat';
    // TODO: bench_press, pull_up, sit_up 추가 로직
    return 'unknown';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 교정')),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('영상 촬영 & 분석'),
              onPressed: () => _analyzeAndDisplay(ImageSource.camera),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('저장된 영상 선택 & 분석'),
              onPressed: () => _analyzeAndDisplay(ImageSource.gallery),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

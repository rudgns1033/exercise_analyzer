import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// 동영상 경로와 관절 좌표 데이터로 운동 유형을 분류하고, 썸네일과 좌표를 시각화하는 화면
class JointDisplayScreen extends StatefulWidget {
  final String videoFilePath;
  final List<Map<String, dynamic>> joints;

  const JointDisplayScreen({
    Key? key,
    required this.videoFilePath,
    required this.joints,
  }) : super(key: key);

  @override
  State<JointDisplayScreen> createState() => _JointDisplayScreenState();
}

class _JointDisplayScreenState extends State<JointDisplayScreen> {
  File? _thumbnailFile;
  bool _loading = true;
  String _exerciseType = '분류 중...';

  @override
  void initState() {
    super.initState();
    _exerciseType = _classifyExercise(widget.joints);
    _generateThumbnail();
  }

  /// 간단히 어깨-골반 벡터의 방향과 관절 위치로 동작 분류
  String _classifyExercise(List<Map<String, dynamic>> joints) {
    final ls = _getLandmark(joints, 'leftShoulder');
    final rs = _getLandmark(joints, 'rightShoulder');
    final lh = _getLandmark(joints, 'leftHip');
    final rh = _getLandmark(joints, 'rightHip');
    if (ls == null || rs == null || lh == null || rh == null) return '알 수 없음';

    final avgSh = Landmark((ls.x + rs.x) / 2, (ls.y + rs.y) / 2);
    final avgHip = Landmark((lh.x + rh.x) / 2, (lh.y + rh.y) / 2);
    final dx = (avgHip.x - avgSh.x).abs();
    final dy = (avgHip.y - avgSh.y).abs();

    if (dx > dy) {
      // 수평 자세: 팔굽혀펴기 vs 벤치프레스
      final lw = _getLandmark(joints, 'leftWrist');
      final rw = _getLandmark(joints, 'rightWrist');
      if (lw != null && rw != null) {
        final avgW = Landmark((lw.x + rw.x) / 2, (lw.y + rw.y) / 2);
        if (avgW.y < avgSh.y - 0.1) return '벤치프레스';
      }
      return '팔굽혀펴기';
    } else {
      // 수직 자세: 스쿼트 vs 턱걸이 vs 윗몸일으키기
      final lw = _getLandmark(joints, 'leftWrist');
      final rw = _getLandmark(joints, 'rightWrist');
      if (lw != null && rw != null) {
        final avgW = Landmark((lw.x + rw.x) / 2, (lw.y + rw.y) / 2);
        if (avgW.y < avgSh.y - 0.1) return '턱걸이';
      }
      final lk = _getLandmark(joints, 'leftKnee');
      final rk = _getLandmark(joints, 'rightKnee');
      if (lh != null && lk != null && rk != null) {
        final avgK = Landmark((lk.x + rk.x) / 2, (lk.y + rk.y) / 2);
        if (avgHip.y > avgK.y + 0.1) return '윗몸일으키기';
      }
      return '스쿼트';
    }
  }

  /// 리스트에서 특정 관절 좌표를 찾아 Landmark로 반환
  Landmark? _getLandmark(List<Map<String, dynamic>> joints, String type) {
    for (var j in joints) {
      if (j['type'] == type) return Landmark(j['x'] as double, j['y'] as double);
    }
    return null;
  }

  /// 동영상 첫 프레임 썸네일 생성
  Future<void> _generateThumbnail() async {
    try {
      final Uint8List? data = await VideoThumbnail.thumbnailData(
        video: widget.videoFilePath,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (data != null) {
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
        await file.writeAsBytes(data);
        setState(() => _thumbnailFile = file);
      }
    } catch (_) {
      // 실패 시 무시
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관절 좌표 시각화')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '운동 유형: $_exerciseType',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_thumbnailFile != null)
              Image.file(_thumbnailFile!, width: double.infinity, fit: BoxFit.cover),
            const SizedBox(height: 16),
            const Text(
              '추출된 관절 좌표',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            ...widget.joints.map((j) {
              final type = j['type'] as String;
              final x = (j['x'] as double).toStringAsFixed(1);
              final y = (j['y'] as double).toStringAsFixed(1);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(type),
                subtitle: Text('x: $x, y: $y'),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

/// 단순 좌표 저장용 클래스
class Landmark {
  final double x;
  final double y;
  Landmark(this.x, this.y);
}

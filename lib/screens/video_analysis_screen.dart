// lib/screens/video_analysis_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/video_analysis_service.dart';
import '../models/analysis_session.dart';
import '../services/analysis_history_service.dart';
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
    // **매번 호출 시 상태 초기화**
    setState(() => _loading = true);

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);
      if (file == null) {
        setState(() => _loading = false);
        return;
      }

      // 썸네일 생성
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (thumbnailPath == null) {
        throw Exception('썸네일 생성 실패');
      }

      // 관절 데이터 추출
      final joints = await _service.extractJointData(file.path, 0);

      // 분류: exerciseType 은 JointDisplayScreen에서 자체 분류
      // **교정 세션을 저장**
      final session = AnalysisSession(
        timestamp: DateTime.now(),
        exerciseType: '',         // 빈 문자열 넘기면 화면에서 다시 분류
        thumbnailPath: thumbnailPath,
        joints: joints,
      );
      await AnalysisHistoryService.saveSession(session);

      // JointDisplayScreen으로 이동
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointDisplayScreen(
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
      // **작업 완료 후 로딩 해제**
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndAnalyzeStream(ImageSource source) async {
    final picker = ImagePicker();
    XFile? file;
    file = await picker.pickVideo(source: source);

    setState(() { _loading = true; });

    try {
      // 1) 관절 좌표 추출
      final dir = await getApplicationDocumentsDirectory();
      final jointStream = _service.getDetectStream(file?.path, dir.path);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointStreamDisplayScreen(
            thumbnailPath: "${dir.path}/th_0.jpg",
            jointStream: jointStream,
          ),
        ),
      );


      // _feedback = '서버 응답: ${resp.feedback}';
    } catch (e) {

    } finally {
      setState(() { _loading = false; });
    }
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
              onPressed: () => _pickAndAnalyzeStream(ImageSource.camera),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('저장된 영상 선택 & 분석'),
              onPressed: () => _pickAndAnalyzeStream(ImageSource.gallery),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }
}

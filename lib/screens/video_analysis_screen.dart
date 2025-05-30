// lib/screens/video_analysis_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/video_analysis_service.dart';
import '../models/analysis_session.dart';
import '../services/analysis_history_service.dart';
import 'jointDisplayScreen.dart';

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

      final thumb = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (thumb == null) throw Exception('썸네일 생성 실패');

      final joints = await _service.extractJointData(file.path);

      // 세션 저장
      final session = AnalysisSession(
        timestamp: DateTime.now(),
        exerciseType: '',
        thumbnailPath: thumb,
        joints: joints,
      );
      await AnalysisHistoryService.saveSession(session);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointDisplayScreen(
            thumbnailPath: thumb,
            joints: joints,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));
    } finally {
      setState(() => _loading = false);
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

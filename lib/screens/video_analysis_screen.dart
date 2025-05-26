// lib/screens/video_analysis_screen.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

import '../services/video_analysis_service.dart';
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
      // 1) 비디오 선택 또는 촬영
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);
      if (file == null) {
        setState(() => _loading = false);
        return;
      }

      // 2) 첫 프레임 썸네일 생성
      final String? thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: file.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (thumbnailPath == null) {
        throw Exception('썸네일 생성에 실패했습니다.');
      }

      // 3) 관절 좌표 추출
      final joints = await _service.extractJointData(file.path);

      // 4) JointDisplayScreen으로 이동 (exerciseType은 그쪽에서 분류)
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
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('저장된 영상 선택 & 분석'),
              onPressed: () => _analyzeAndDisplay(ImageSource.gallery),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

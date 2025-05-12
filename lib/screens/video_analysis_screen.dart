import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/video_analysis.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';
import '../services/video_analysis_service.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({super.key});
  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  final VideoAnalysisService _service = VideoAnalysisService();
  bool _loading = false;
  String? _feedback;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.camera);
    if (file == null) return;

    setState(() { _loading = true; _feedback = null; });

    try {
      // 1) 관절 좌표 추출
      final jointData = await _service.extractJointData(file.path);

      // 2) 백엔드로 전송
      final resp = await _service.sendJointData(
        userId: 1,
        backendUrl: 'http://10.0.2.2:8080/analyze',
        jointData: jointData,
      );

      if (resp.statusCode == 200) {
        setState(() => _feedback = '서버 응답: ${resp.body}');
      } else {
        setState(() => _feedback = '전송 실패: ${resp.statusCode}');
      }
    } catch (e) {
      setState(() => _feedback = '오류 발생: $e');
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
            : _feedback != null
            ? Padding(
          padding: const EdgeInsets.all(16),
          child: Text(_feedback!, textAlign: TextAlign.center),
        )
            : ElevatedButton(
          child: const Text('운동 영상 촬영 및 분석'),
          onPressed: _pickAndAnalyze,
        ),
      ),
    );
  }
}
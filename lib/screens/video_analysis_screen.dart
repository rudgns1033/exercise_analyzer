// lib/screens/video_analysis_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../models/joints.dart';
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

  Future<void> _pickAndAnalyzeStream(ImageSource source) async {
    final picker = ImagePicker();
    XFile? file;
    file = await picker.pickVideo(source: source);

    setState(() { _loading = true; });

    try {
      // 1) 관절 좌표 추출
      final dir = await getApplicationDocumentsDirectory();
      final jointStream = _service.getDetectStreamThumb(file?.path, dir.path);
      final completer = Completer<List<Joints>>();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointStreamDisplayScreen(
            jointStream: jointStream,
            jointCompleter: completer,
          ),
        ),
      );

      final joints = await completer.future;

      print("await fin save session");

      // 세션 저장
      final session = AnalysisSession(
        timestamp: DateTime.now(),
        exerciseType: '',
        jointsArr: joints,
      );
      await AnalysisHistoryService.saveSession(session);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류 발생: $e')));

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

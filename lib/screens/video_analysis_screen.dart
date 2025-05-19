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
  List<VideoAnalysisResult>? _feedbacks;
  bool _file = true;

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    XFile? file;
    if (_file){
      file = await picker.pickVideo(source: ImageSource.gallery);
    }else{
      file = await picker.pickVideo(source: ImageSource.camera);
    }
    if (file == null) return;

    setState(() { _loading = true; _feedback = null; });

    try {
      // 1) 관절 좌표 추출
      final jointData = await _service.extractJointData(file.path, 0);

      // 2) 백엔드로 전송
      final resp = await _service.sendJointData(
        userId: 1,
        jointData: jointData,
      );
      _feedback = '서버 응답: ${resp.feedback}';
    } catch (e) {
      setState(() => _feedback = '오류 발생: $e');
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _pickAndAnalyzeStream() async {
    final picker = ImagePicker();
    XFile? file;
    if (_file){
      file = await picker.pickVideo(source: ImageSource.gallery);
    }else{
      file = await picker.pickVideo(source: ImageSource.camera);
    }
    if (file == null) return;

    setState(() { _loading = true; _feedback = null; });

    try {
      // 1) 관절 좌표 추출
      _service.getDetectStream(file.path)
          .asyncExpand((onData) {

        // analyzeStream은 Stream<VideoAnalysisResult>를 반환한다고 가정
        return _service.analyzeStream(
          userId: 1,
          jointData: onData,
        );
      })
          .listen((result) {
        print("분석 결과: ${result.feedback}");
      });

      // _feedback = '서버 응답: ${resp.feedback}';
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
          onPressed: _pickAndAnalyzeStream,
          // onPressed: _pickAndAnalyze,
        ),
      ),
    );
  }
}
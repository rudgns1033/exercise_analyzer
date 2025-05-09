import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/video_analysis.dart';
import '../providers/user_provider.dart';
import '../services/api_service.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({super.key});

  @override
  State<VideoAnalysisScreen> createState() => _VideoAnalysisScreenState();
}

class _VideoAnalysisScreenState extends State<VideoAnalysisScreen> {
  XFile? _videoFile;
  String? _feedback;
  bool _isProcessing = false;

  Future<void> _pickAndAnalyze() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.camera);
    if (file == null) return;

    setState(() {
      _videoFile = file;
      _isProcessing = true;
      _feedback = null;
    });

    // Pose Detection
    final inputImage = InputImage.fromFilePath(file.path);
    final poses = await GoogleMlKit.vision.poseDetector().processImage(inputImage);
    final landmarks = poses.first.landmarks;
    final landmarkMap = poses.first.landmarks;
    final landmarkList = landmarkMap.values;
    final jointData = landmarkList.map((l) => {
      'type': l.type.toString().split('.').last,
      'x': l.x,
      'y': l.y,
    }).toList();

    // 서버 전송
    final userId = context.read<UserProvider>().user?.id ?? 1;
    final req = VideoAnalysisRequest(userId: userId, jointData: jointData);
    final result = await ApiService().analyzeVideo(req);

    setState(() {
      _isProcessing = false;
      _feedback = result.feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 교정')),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : _feedback != null
            ? Text(_feedback!, textAlign: TextAlign.center)
            : ElevatedButton(
          child: const Text('운동 영상 촬영 및 분석'),
          onPressed: _pickAndAnalyze,
        ),
      ),
    );
  }
}

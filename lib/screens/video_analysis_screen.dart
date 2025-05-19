import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/video_analysis_service.dart';

class VideoAnalysisScreen extends StatefulWidget {
  const VideoAnalysisScreen({Key? key}) : super(key: key);

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

  Future<void> _analyzeVideo(ImageSource source) async {
    setState(() {
      _loading = true;
      _feedback = null;
    });

    try {
      // 1) 기기에서 비디오를 선택하거나 촬영
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);
      if (file == null) return;

      // 2) 관절 좌표 추출
      final jointData = await _service.extractJointData(file.path);

      // 3) 백엔드 전송
      final resp = await _service.sendJointData(
        userId: 1, // TODO: 실제 userId
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
            : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam),
              label: const Text('영상 촬영 & 분석'),
              onPressed: () => _analyzeVideo(ImageSource.camera),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.video_library),
              label: const Text('저장된 영상 선택 & 분석'),
              onPressed: () => _analyzeVideo(ImageSource.gallery),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 24),
            if (_feedback != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _feedback!,
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

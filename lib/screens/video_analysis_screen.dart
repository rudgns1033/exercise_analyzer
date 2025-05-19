import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'JointDisplayScreen.dart';
import '../services/video_analysis_service.dart';

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
    setState(() {
      _loading = true;
    });

    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickVideo(source: source);
      if (file == null) return;

      final jointData = await _service.extractJointData(file.path);

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => JointDisplayScreen(
            videoFilePath: file.path,
            joints: jointData,
          ),
        ),
      );

      // 서버 전송은 선택적으로 백그라운드에서 처리
      _service.sendJointData(
        userId: 1,
        // backendUrl 파라미터는 현재 로컬 테스트에서 사용하지 않도록 삭제
        jointData: jointData,
      ).catchError((e) {
        debugPrint('서버 전송 에러: \$e');
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      setState(() {
        _loading = false;
      });
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

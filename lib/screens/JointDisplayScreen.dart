import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

/// 동영상 경로에서 첫 프레임을 추출하여 관절 좌표와 함께 보여주는 화면
class JointDisplayScreen extends StatefulWidget {
  /// 분석할 비디오 파일 경로
  final String videoFilePath;
  /// 추출된 관절 좌표 데이터 리스트
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

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  /// 첫 프레임 썸네일 생성
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
        setState(() {
          _thumbnailFile = file;
        });
      }
    } catch (e) {
      // 썸네일 생성 실패 시 무시
    } finally {
      setState(() {
        _loading = false;
      });
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_thumbnailFile != null) ...[
              Center(
                child: Image.file(
                  _thumbnailFile!,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],
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
            }),
          ],
        ),
      ),
    );
  }
}

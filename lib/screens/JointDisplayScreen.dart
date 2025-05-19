import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';

class JointDisplayScreen extends StatefulWidget {
  const JointDisplayScreen({Key? key}) : super(key: key);

  @override
  State<JointDisplayScreen> createState() => _JointDisplayScreenState();
}

class _JointDisplayScreenState extends State<JointDisplayScreen> {
  File? _thumbFile;
  List<Map<String, dynamic>> _joints = [];
  bool _loading = false;

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.base),
  );

  Future<void> _pickAndExtract() async {
    final XFile? video = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (video == null) return;

    setState(() {
      _loading = true;
      _joints = [];
      _thumbFile = null;
    });

    try {
      // 1) 프레임 썸네일 생성
      final Uint8List? data = await VideoThumbnail.thumbnailData(
        video: video.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 512,
        timeMs: 0,
      );
      if (data == null) throw Exception('썸네일 생성 실패');

      // 2) 임시 파일로 저장
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(data);

      // 3) 관절 좌표 추출
      final inputImage = InputImage.fromFilePath(file.path);
      final List<Pose> poses = await _poseDetector.processImage(inputImage);
      if (poses.isNotEmpty) {
        final landmarkMap = poses.first.landmarks;
        _joints = landmarkMap.entries
            .map((e) => {
          'type': e.key.toString().split('.').last,
          'x': e.value.x,
          'y': e.value.y,
        })
            .toList();
      }

      setState(() {
        _thumbFile = file;
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
  void dispose() {
    _poseDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관절 좌표 시각화')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : (_thumbFile == null
          ? Center(
        child: ElevatedButton(
          onPressed: _pickAndExtract,
          child: const Text('영상 선택 및 좌표 추출'),
        ),
      )
          : LayoutBuilder(
        builder: (context, constraints) {
          final screenW = constraints.maxWidth;
          const thumbWidth = 512.0;
          final scale = screenW / thumbWidth;
          return SingleChildScrollView(
            child: Column(
              children: [
                Stack(
                  children: [
                    Image.file(_thumbFile!, width: screenW),
                    ..._joints.map((j) {
                      final dx = (j['x'] as double) * scale;
                      final dy = (j['y'] as double) * scale;
                      return Positioned(
                        left: dx,
                        top: dy,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '추출된 관절 좌표',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                ..._joints.map(
                      (j) => ListTile(
                    dense: true,
                    title: Text(j['type'] as String),
                    subtitle: Text(
                      "x: \${(j['x'] as double).toStringAsFixed(1)}, y: \${(j['y'] as double).toStringAsFixed(1)}",
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      )),
    );
  }
}

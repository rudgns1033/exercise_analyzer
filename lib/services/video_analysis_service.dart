import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:google_mlkit_commons/google_mlkit_commons.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class VideoAnalysisService {
  // PoseDetector 인스턴스 생성
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
    ),
  );

  /// 비디오에서 첫 프레임을 뽑아 관절 좌표 추출
  Future<List<Map<String, dynamic>>> extractJointData(String videoPath) async {
    // 1) 첫 프레임 썸네일 생성 (0ms 지점)
    final Uint8List? thumb = await VideoThumbnail.thumbnailData(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: 0,
      maxWidth: 512,
    );
    if (thumb == null) throw Exception('썸네일 생성 실패');

    // 2) 임시 파일로 저장
    final dir = await getTemporaryDirectory();
    final tempImage = File('${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await tempImage.writeAsBytes(thumb);

    // 3) ML Kit로 이미지 처리
    final inputImage = InputImage.fromFilePath(tempImage.path);
    final poses = await _poseDetector.processImage(inputImage);

    // 4) 첫 번째 Pose의 landmark 좌표만 추출
    if (poses.isEmpty) return [];
    final landmarkMap = poses.first.landmarks;
    final jointData = landmarkMap.entries.map((e) => {
      'type': e.key.toString().split('.').last,
      'x': e.value.x,
      'y': e.value.y,
    }).toList();

    return jointData;
  }

  /// 관절 좌표를 백엔드에 JSON으로 전송
  Future<http.Response> sendJointData({
    required int userId,
    required String backendUrl,
    required List<Map<String, dynamic>> jointData,
  }) {
    final body = jsonEncode({
      'user_id': userId,
      'joint_data': jointData,
    });
    return http.post(
      Uri.parse(backendUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );
  }

  void dispose() {
    _poseDetector.close();
  }
}

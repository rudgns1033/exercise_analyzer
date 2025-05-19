import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:get_thumbnail_video/index.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../models/video_analysis.dart';
import 'api_service.dart';

class VideoAnalysisService {
  // PoseDetector 인스턴스 생성
  final _api = ApiService();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
    ),
  );

  /// 비디오에서 첫 프레임을 뽑아 관절 좌표 추출
  Future<List<Map<String, dynamic>>> extractJointData(String videoPath) async {
    // 1) 첫 프레임 썸네일 생성 (0ms 지점)
    final XFile? thumbFile = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: 0,
      maxWidth: 512,
    );
    if (thumbFile == null) throw Exception('썸네일 생성 실패');

    // 2) 임시 파일로 저장

    // 3) ML Kit로 이미지 처리
    final inputImage = InputImage.fromFilePath(thumbFile.path);
    final poses = await _poseDetector.processImage(inputImage);

    // 4) 첫 번째 Pose의 landmark 좌표만 추출
    if (poses.isEmpty) return [];
    final jointData = poses.expand((pose) {
      return pose.landmarks.entries.map((entry) {
        final type = entry.key;
        final landmark = entry.value;
        return {
          'type': type.toString().split('.').last,
          'x': landmark.x,
          'y': landmark.y,
          'z': landmark.z,
        };
      }).toList();
    }).toList();

    return jointData;
  }

  /// 관절 좌표를 백엔드에 JSON으로 전송
  Future<VideoAnalysisResult> sendJointData({
    required int userId,
    required List<Map<String, dynamic>> jointData,
  }) {
    final req = VideoAnalysisRequest(
      userId: userId,
      jointData: jointData
    );
    return _api.analyzeVideo(req);
  }

  void dispose() {
    _poseDetector.close();
  }
}

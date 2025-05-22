// lib/services/video_analysis_service.dart

import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class VideoAnalysisService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.base),
  );

  /// 비디오 첫 프레임에서 관절 좌표 추출
  Future<List<Map<String, dynamic>>> extractJointData(String videoPath) async {
    final String? thumbPath = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: 0,
      maxWidth: 512,
    );
    if (thumbPath == null) throw Exception('썸네일 생성 실패');

    final input = InputImage.fromFilePath(thumbPath);
    final poses = await _poseDetector.processImage(input);
    if (poses.isEmpty) return [];

    final jointData = <Map<String, dynamic>>[];
    poses.first.landmarks.forEach((type, lm) {
      jointData.add({
        'type': type.toString().split('.').last,
        'x': lm.x,
        'y': lm.y,
      });
    });
    return jointData;
  }

  /// 리소스 해제용 dispose 메서드
  void dispose() {
    _poseDetector.close();
  }
}

// lib/services/video_analysis_service.dart

import 'dart:io';

import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';

class VideoAnalysisService {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(model: PoseDetectionModel.base),
  );

  Future<List<Map<String, dynamic>>> extractJointData(String videoPath,
      int timeMs, {String? thumbpath}) async {
    // 1) 첫 프레임 썸네일 생성 (0ms 지점)
    if (thumbpath != null){
      thumbpath = "$thumbpath/th_$timeMs.jpg";
    }
    final String? thumbFile = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbpath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs*1000,
      maxWidth: 512,
    );
    if (thumbFile == null) throw Exception('썸네일 생성 실패');

    // 2) 임시 파일로 저장

    // 3) ML Kit로 이미지 처리
    final inputImage = InputImage.fromFilePath(thumbFile);
    print(thumbFile);
    final poses = await _poseDetector.processImage(inputImage);

    // 4) 첫 번째 Pose의 landmark 좌표만 추출
    if (poses.isEmpty) return [];
    final jointData = poses.expand((pose) {
      return pose.landmarks.entries.map((entry) {
        final type = entry.key;
        final landmark = entry.value;
        return {
          'type': type
              .toString()
              .split('.')
              .last,
          'x': landmark.x,
          'y': landmark.y,
        };
      }).toList();
    }).toList();

    return jointData;
  }

  /// 비디오 첫 프레임에서 관절 좌표 추출
  // Future<List<Map<String, dynamic>>> extractJointData(String videoPath) async {
  //   final String? thumbPath = await VideoThumbnail.thumbnailFile(
  //     video: videoPath,
  //     imageFormat: ImageFormat.JPEG,
  //     timeMs: 0,
  //     maxWidth: 512,
  //   );
  //   if (thumbPath == null) throw Exception('썸네일 생성 실패');
  //
  //   final input = InputImage.fromFilePath(thumbPath);
  //   final poses = await _poseDetector.processImage(input);
  //   if (poses.isEmpty) return [];
  //
  //   final jointData = <Map<String, dynamic>>[];
  //   poses.first.landmarks.forEach((type, lm) {
  //     jointData.add({
  //       'type': type.toString().split('.').last,
  //       'x': lm.x,
  //       'y': lm.y,
  //     });
  //   });
  //   return jointData;
  // }

  Stream<List<Map<String, dynamic>>> getDetectStream(String? videoPath, String dir) async* {
    int second = 0;
    final controller = VideoPlayerController.file(File(videoPath!));
    await controller.initialize();
    final duration = controller.value.duration.inSeconds;

    for (second = 0; second < duration; second++) {
      var thumnailData = await extractJointData(videoPath, second, thumbpath: dir);
      // var jsB = jsonEncode(thumnailData);
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/$second.json');
      // file.writeAsString(jsB);
      // print(file.path);
      yield thumnailData;
    }
  }

  /// 리소스 해제용 dispose 메서드
  void dispose() {
    _poseDetector.close();
  }
}

// lib/services/video_analysis_service.dart

import 'dart:io';

import '../models/joints.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:video_player/video_player.dart';
import 'dart:typed_data';

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

  Future<Joints> extractJoints(String videoPath,
      int timeMs, {String? thumbpath}) async {
    // 1) 첫 프레임 썸네일 생성 (0ms 지점)
    if (thumbpath != null){
      thumbpath = "$thumbpath/th_$timeMs.jpg";
    }
    final String? thumbFile = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: thumbpath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      maxWidth: 512,
    );
    if (thumbFile == null) throw Exception('썸네일 생성 실패');

    // 2) 임시 파일로 저장

    // 3) ML Kit로 이미지 처리
    final file = File(thumbFile);
    final Uint8List bytes = await file.readAsBytes();
    final inputImage = InputImage.fromFile(file);
    print(thumbFile);

    final poses = await _poseDetector.processImage(inputImage);

    // 4) 첫 번째 Pose의 landmark 좌표만 추출
    if (poses.isEmpty) return Future.error('pose isEmpty');
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

    return Joints(frameBytes: bytes,  joints: jointData);
  }

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

  Stream<Joints> getDetectStreamThumb(String? videoPath, String dir) async* {
    int second = 0;
    final controller = VideoPlayerController.file(File(videoPath!));
    await controller.initialize();
    final duration = controller.value.duration.inMilliseconds;

    for (second = 0; second < duration;) {
      try {
        var thumnailData = await extractJoints(videoPath, second, thumbpath: dir);
          // 성공했을 때 처리
          yield thumnailData;
        } catch (e) {
          // 여기서 e는 'pose isEmpty'가 됩니다.
          print('에러 발생: $e');
        }
      second+=500;
    }
  }

  /// 리소스 해제용 dispose 메서드
  void dispose() {
    _poseDetector.close();
  }
}

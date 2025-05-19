import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:get_thumbnail_video/index.dart';
import 'package:video_player/video_player.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:get_thumbnail_video/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import '../models/video_analysis.dart';
import 'api_service.dart';
import 'websocket_api_service.dart';
import '../models/websocket.dart';

import 'package:path_provider/path_provider.dart';

class VideoAnalysisService {
  // PoseDetector 인스턴스 생성
  final _api = ApiService();
  final _wsapi = WebSocketStreamService();
  final _uuid = Uuid();

  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      model: PoseDetectionModel.base,
    ),
  );

  Stream<List<Map<String, dynamic>>> getDetectStream(String videoPath) async* {
    int second = 0;
    final controller = VideoPlayerController.file(File(videoPath));
    await controller.initialize();
    final duration = controller.value.duration.inSeconds;
    for (second = 0; second < duration; second++) {
      var thumnailData = await extractJointData(videoPath, second * 1000);
      // var jsB = jsonEncode(thumnailData);
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/$second.json');
      // file.writeAsString(jsB);
      // print(file.path);
      yield thumnailData;
    }
  }

  /// 비디오에서 첫 프레임을 뽑아 관절 좌표 추출
  Future<List<Map<String, dynamic>>> extractJointData(String videoPath,
      int timeMs) async {
    // 1) 첫 프레임 썸네일 생성 (0ms 지점)
    final XFile? thumbFile = await VideoThumbnail.thumbnailFile(
      video: videoPath,
      imageFormat: ImageFormat.JPEG,
      timeMs: timeMs,
      maxWidth: 512,
    );
    if (thumbFile == null) throw Exception('썸네일 생성 실패');

    // 2) 임시 파일로 저장

    // 3) ML Kit로 이미지 처리
    final inputImage = InputImage.fromFilePath(thumbFile.path);
    print(thumbFile.path);
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

  /// 관절 좌표를 백엔드에 JSON으로 전송
  String sendJointDatas({
    required int userId,
    required List<Map<String, dynamic>> jointData,
  }) {
    final req = VideoAnalysisRequest(
        userId: userId,
        jointData: jointData
    );
    final msgID = _uuid.v4(); // 랜덤 UUID (버전 4)
    final message = WebsocketMessage(
        msgID: msgID, type: "frame", data: req.toJson());
    _wsapi.send(message);
    return msgID;
  }

  Stream<VideoAnalysisResult> analyzeStream({
    required int userId,
    required List<Map<String, dynamic>> jointData,
  }) {
    final req = VideoAnalysisRequest(
        userId: userId,
        jointData: jointData
    );

    return _wsapi.sendWithStream(
      type: "frame",
      payload: req.toJson(),
    ).map((wsMessage) {
      // wsMessage.data 는 dynamic 또는 Map<String, dynamic> 이라고 가정
      return VideoAnalysisResult.fromJson(wsMessage.data);
    });
  }

  void dispose(){
    _poseDetector.close();
  }
}

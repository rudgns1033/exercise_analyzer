import 'dart:convert';

import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../models/video_analysis.dart';
import '../models/websocket.dart';
import '../services/websocket_client.dart';

class WebSocketStreamService {
  final _controller = StreamController<WebsocketMessage>.broadcast();
  late final WebSocketChannel _channel;
  static const _baseUrl = 'ws://129.154.48.51:9090/ws';
  final _uuid = Uuid();
  late final StreamSubscription _subscription;

  Stream<WebsocketMessage> get messageStream => _controller.stream;
  final _pendingRequests = <String, Completer<WebsocketMessage>>{};
  final _streamControllers = <String, StreamController<WebsocketMessage>>{};

  void start() {
    _channel = WebSocketChannel.connect(Uri.parse(_baseUrl));
    // 수신 메시지를 stream 으로 흘려보냄

    _subscription = _channel.stream.listen((message) {
      final data = jsonDecode(message);
      final requestId = data['request_id'];
      if (_streamControllers.containsKey(requestId)) {
        _streamControllers[requestId]!.add(WebsocketMessage.fromJson(data));
        _streamControllers[requestId]!.close();
        _streamControllers.remove(requestId);
      }
      switch (data['type']) {
        case "frame":
          break;
      }
      _controller.add(data); // 이게 핵심!
    }, onDone: () {
      _controller.close();
    }, onError: (error) {
      _controller.addError(error);
    });
  }

  // WebSocketStreamService() {
  //   _channel = WebSocketChannel.connect(Uri.parse(_baseUrl));
  //
  //   // 수신 메시지를 stream 으로 흘려보냄
  //   _channel.stream.listen((message) {
  //     final data = jsonDecode(message);
  //     final requestId = data['request_id'];
  //     if (_streamControllers.containsKey(requestId)) {
  //       _streamControllers[requestId]!.add(data['payload']);
  //       _streamControllers[requestId]!.close();
  //     }
  //
  //     switch (data['type']) {
  //       case "frame":
  //         break;
  //     }
  //     _controller.add(data); // 이게 핵심!
  //   }, onDone: () {
  //     _controller.close();
  //   }, onError: (error) {
  //     _controller.addError(error);
  //   });
  // }


  Future<WebsocketMessage> sendWithResponse(Map<String, dynamic> payload) {
    final requestId = _uuid.v4();
    final completer = Completer<WebsocketMessage>();
    _pendingRequests[requestId] = completer;

    final message = WebsocketMessage(msgID: requestId, type: "frame", data: payload);

    _channel.sink.add(jsonEncode(message));
    return completer.future;
  }

  Stream<WebsocketMessage> sendWithStream({
    required String type,
    required Map<String, dynamic> payload,
  }) {
    final requestId = Uuid().v4();
    final controller = StreamController<WebsocketMessage>();
    final message = WebsocketMessage(msgID: requestId, type: type, data: payload);

    _streamControllers[requestId] = controller;
    _channel.sink.add(jsonEncode(message.toJson()));

    return controller.stream;
  }

  void send(WebsocketMessage message) {
    _channel.sink.add(jsonEncode(message));
  }

  void dispose(){
    _subscription.cancel();
    _channel.sink.close();
    _controller.close();
  }
}


// class SocketService {
//   final WebSocketClient _client;
//   static const _baseUrl = 'ws://129.154.48.51:9090/ws';
//
//   SocketService(String url) : _client = WebSocketClient(url: url);
//
//   void initialize() {
//     _client.onMessage = _handleMessage;
//     _client.connect();
//   }
//
//   void _handleMessage(String raw) {
//     final data = jsonDecode(raw);
//     final type = data['type'];
//
//     switch (type) {
//       case 'frame':
//         _handleFeedback(data);
//         break;
//       case 'notification':
//         _handleNotification(data);
//         break;
//       default:
//         print('알 수 없는 메시지: $data');
//     }
//   }
//
//   void _handleFeedback(Map<String, dynamic> data) {
//     // 예: UI 갱신 또는 이벤트 발송
//   }
//
//   void _handleNotification(Map<String, dynamic> data) {
//     // 예: 알림 띄우기
//   }
//
//   void send(String type, Map<String, dynamic> payload) {
//     final msg = {'type': type, ...payload};
//     _client.send(jsonEncode(msg));
//   }
//
//   void dispose() => _client.disconnect();
// }

import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketClient {
  final String url;
  late WebSocketChannel _channel;
  Function(String message)? onMessage;
  Function()? onDone;
  Function(dynamic error)? onError;

  WebSocketClient({required this.url});

  /// 웹소켓 연결 시작
  void connect() {
    _channel = WebSocketChannel.connect(Uri.parse(url));

    _channel.stream.listen(
          (message) {
        print('수신: $message');
        if (onMessage != null) onMessage!(message);
      },
      onDone: () {
        print('웹소켓 연결 종료');
        if (onDone != null) onDone!();
      },
      onError: (error) {
        print('웹소켓 오류: $error');
        if (onError != null) onError!(error);
      },
    );

    print('웹소켓 연결됨: $url');
  }

  /// 메시지 전송
  void send(String message) {
    _channel.sink.add(message);
    print('송신: $message');
  }

  /// 연결 닫기
  void disconnect() {
    _channel.sink.close(status.normalClosure);
    print('웹소켓 연결 닫힘');
  }
}

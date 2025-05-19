class WebsocketMessage {
  final String msgID;
  final String type;
  final Map<String, dynamic> data;

  WebsocketMessage({
    required this.msgID,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'id': msgID,
    'type': type,
    'data': {
      data
    }
  };

  factory WebsocketMessage.fromJson(Map<String, dynamic> json) =>
      WebsocketMessage(
        msgID: json['id'] as String,
        type: json['type'] as String,
        data: json['data'],
      );
}
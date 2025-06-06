import 'dart:convert';
import 'dart:typed_data';

class Joints {
  final Uint8List? frameBytes;
  final List<Map<String, dynamic>> joints;

  Joints({
    required this.frameBytes,
    required this.joints
  });

  factory Joints.fromJson(Map<String, dynamic> json) => Joints(
    frameBytes:  base64Decode(json['frameBytes'] as String),
    joints: (json['joints'] as List)
        .map((item) => Map<String, dynamic>.from(item))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'frameBytes': base64Encode(frameBytes!),
    'joints': joints,
  };
}

import 'joints.dart';

class AnalysisSession {
final DateTime timestamp;
final String exerciseType;
final List<Joints> jointsArr;

AnalysisSession({
  required this.timestamp,
  required this.exerciseType,
  required this.jointsArr,
});

factory AnalysisSession.fromJson(Map<String, dynamic> json) {
return AnalysisSession(
timestamp: DateTime.parse(json['timestamp'] as String),
exerciseType: json['exerciseType'] as String,
  jointsArr: (json['jointsArr'] as List)
      .map((item) => Joints.fromJson(item as Map<String, dynamic>))
      .toList(),
);
}

Map<String, dynamic> toJson() => {
'timestamp': timestamp.toIso8601String(),
'exerciseType': exerciseType,
'jointsArr': jointsArr.map((j) => j.toJson()).toList(),
};
}

class AnalysisSession {
final DateTime timestamp;
final String exerciseType;
final String thumbnailPath;
final List<Map<String,dynamic>> joints;

AnalysisSession({
  required this.timestamp,
  required this.exerciseType,
  required this.thumbnailPath,
  required this.joints,
});

factory AnalysisSession.fromJson(Map<String, dynamic> json) {
return AnalysisSession(
timestamp: DateTime.parse(json['timestamp'] as String),
exerciseType: json['exerciseType'] as String,
thumbnailPath: json['thumbnailPath'] as String,
joints: List<Map<String,dynamic>>.from(json['joints'] as List),
);
}

Map<String, dynamic> toJson() => {
'timestamp': timestamp.toIso8601String(),
'exerciseType': exerciseType,
'thumbnailPath': thumbnailPath,
'joints': joints,
};
}

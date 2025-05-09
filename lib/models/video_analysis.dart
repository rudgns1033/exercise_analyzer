class VideoAnalysisRequest {
  final int userId;
  final List<Map<String, dynamic>> jointData; // [{ 'type': ..., 'x': ..., 'y': ...}, ...]

  VideoAnalysisRequest({
    required this.userId,
    required this.jointData,
  });

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'joint_data': jointData,
  };
}

class VideoAnalysisResult {
  final bool correct;
  final String feedback;
  final int caloriesBurned;

  VideoAnalysisResult({
    required this.correct,
    required this.feedback,
    required this.caloriesBurned,
  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) =>
      VideoAnalysisResult(
        correct: json['correct'] as bool,
        feedback: json['feedback'] as String,
        caloriesBurned: json['calories'] as int,
      );
}

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
git
class VideoAnalysisResult {
  final bool correct;
  final String feedback;


  VideoAnalysisResult({
    required this.correct,
    required this.feedback,

  });

  factory VideoAnalysisResult.fromJson(Map<String, dynamic> json) =>
      VideoAnalysisResult(
        correct: json['correct'] as bool,
        feedback: json['feedback'] as String,

      );
}
